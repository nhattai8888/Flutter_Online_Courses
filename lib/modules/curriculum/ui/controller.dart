import 'package:flutter/foundation.dart';

import '../domain/entity.dart';
import '../domain/usecases.dart';
import '../../../core/types/app_error.dart';
import '../data/api.dart';
import '../../../core/types/api_response.dart';

enum CurriculumStatus { idle, loading, ready, error }

class UnitMeta {
  final int progressPercent; // 0..100
  final bool locked;
  final bool hasBoss;
  const UnitMeta({
    required this.progressPercent,
    required this.locked,
    required this.hasBoss,
  });

  UnitMeta copyWith({int? progressPercent, bool? locked, bool? hasBoss}) {
    return UnitMeta(
      progressPercent: progressPercent ?? this.progressPercent,
      locked: locked ?? this.locked,
      hasBoss: hasBoss ?? this.hasBoss,
    );
  }
}

class CurriculumController extends ChangeNotifier {
  final ListLanguagesUseCase listLanguages;
  final ListLevelsByLanguageUseCase listLevels;
  final ListUnitsByLanguageUseCase listUnits;
  final ListLessonsByUnitUseCase listLessonsByUnit;
  final GetLessonUseCase getLesson;

  // Using REAL APIs (auth/me + attempts) without importing other modules.
  final CurriculumApi _rawApi;

  CurriculumController({
    required this.listLanguages,
    required this.listLevels,
    required this.listUnits,
    required this.listLessonsByUnit,
    required this.getLesson,
    CurriculumApi? rawApi,
  }) : _rawApi = rawApi ?? CurriculumApi();

  CurriculumStatus _status = CurriculumStatus.idle;
  CurriculumStatus get status => _status;

  String? _error;
  String? get error => _error;

  // State
  List<Language> languages = const [];
  Language? selectedLanguage;

  List<Level> levels = const [];
  Level? selectedLevel;

  // Units of selected level (for main map)
  List<Unit> units = const [];
  Unit? selectedUnit;

  // All units by level (for picker grouping)
  final Map<String, List<Unit>> unitsByLevelId = <String, List<Unit>>{};

  List<Lesson> lessons = const [];

  // Unit meta cache (progress + lock + boss)
  final Map<String, UnitMeta> unitMetaById = <String, UnitMeta>{};
  bool unitMetaLoading = false;

  // Attempts cache
  String? _userId;
  final Set<String> _completedLessonIds = <String>{};

  int lessonLimit = 50;
  int lessonOffset = 0;
  bool hasMoreLessons = true;
  bool loadingMore = false;

  Future<void> init() async {
    await loadLanguages();
  }

  Future<void> loadLanguages() async {
    _setLoading();
    try {
      languages = await listLanguages.call();
      if (languages.isNotEmpty) {
        selectedLanguage = languages.first;
        await _loadLanguageBundle(selectedLanguage!.id);
      } else {
        selectedLanguage = null;
        levels = const [];
        units = const [];
        lessons = const [];
      }
      _setReady();
    } catch (e) {
      _setError(_friendlyError(e));
    }
  }

  Future<void> selectLanguage(Language lang) async {
    if (selectedLanguage?.id == lang.id) return;
    selectedLanguage = lang;
    // reset caches bound to user/language context
    unitsByLevelId.clear();
    units = const [];
    selectedLevel = null;
    selectedUnit = null;
    lessons = const [];
    unitMetaById.clear();
    _completedLessonIds.clear();
    notifyListeners();

    await _loadLanguageBundle(lang.id);
  }

  Future<void> selectLevel(Level? level) async {
    selectedLevel = level;
    selectedUnit = null;
    lessons = const [];
    notifyListeners();

    await loadUnitsForSelectedLevel();
    if (units.isNotEmpty) selectedUnit = units.first;
    notifyListeners();

    await refreshLessons();
    await refreshUnitMetasForCurrentLevel(); // progress/lock/boss
  }

  Future<void> selectUnit(Unit? unit) async {
    selectedUnit = unit;
    notifyListeners();
    await refreshLessons();

    // ensure metas computed so UI shows lock/progress correctly
    await refreshUnitMetasForCurrentLevel();
  }

  Future<void> _loadLanguageBundle(String languageId) async {
    _setLoading();
    try {
      levels = await listLevels.call(languageId);
      // pick first level by default
      selectedLevel = levels.isNotEmpty ? levels.first : null;

      await loadUnitsForSelectedLevel();
      selectedUnit = units.isNotEmpty ? units.first : null;

      await refreshLessons();
      await _ensureUserAndAttemptsLoaded();
      await refreshUnitMetasForCurrentLevel();

      _setReady();
    } catch (e) {
      _setError(_friendlyError(e));
    }
  }

  Future<void> loadUnitsForSelectedLevel() async {
    final langId = selectedLanguage?.id;
    if (langId == null) return;

    // For grouping: fetch units per level
    unitsByLevelId.clear();

    for (final lv in levels) {
      final lvUnits = await listUnits.call(languageId: langId, levelId: lv.id);
      final sorted = [...lvUnits]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      unitsByLevelId[lv.id] = sorted;
    }

    // Main view uses selectedLevel units
    if (selectedLevel != null) {
      units = unitsByLevelId[selectedLevel!.id] ?? const [];
    } else {
      // if no levels, fetch by language without level filter
      final all = await listUnits.call(languageId: langId, levelId: null);
      units = [...all]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    notifyListeners();
  }

  Future<void> refreshLessons() async {
    final unitId = selectedUnit?.id;
    lessonOffset = 0;
    hasMoreLessons = true;
    lessons = const [];
    notifyListeners();

    if (unitId == null) {
      _setReady();
      return;
    }

    await _loadLessonsPage(unitId: unitId, reset: true);
  }

  Future<void> loadMoreLessons() async {
    final unitId = selectedUnit?.id;
    if (unitId == null) return;
    if (loadingMore || !hasMoreLessons) return;
    await _loadLessonsPage(unitId: unitId, reset: false);
  }

  Future<void> _loadLessonsPage({required String unitId, required bool reset}) async {
    if (reset) {
      _setLoading();
    } else {
      loadingMore = true;
      notifyListeners();
    }

    try {
      final page = await listLessonsByUnit.call(
        unitId: unitId,
        limit: lessonLimit,
        offset: lessonOffset,
      );

      lessons = reset ? page : [...lessons, ...page];

      lessonOffset += page.length;
      hasMoreLessons = page.length == lessonLimit;

      loadingMore = false;
      _setReady();
    } catch (e) {
      loadingMore = false;
      _setError(_friendlyError(e));
    }
  }

  Future<Lesson?> fetchLesson(String lessonId) async {
    try {
      return await getLesson.call(lessonId);
    } catch (_) {
      return null;
    }
  }

  // ---------------- REAL progress per unit (computed from REAL APIs) ----------------
  Future<void> refreshUnitMetasForCurrentLevel() async {
    if (selectedLevel == null) return;
    final levelId = selectedLevel!.id;
    final list = unitsByLevelId[levelId] ?? units;
    if (list.isEmpty) return;

    unitMetaLoading = true;
    notifyListeners();

    try {
      await _ensureUserAndAttemptsLoaded();

      // Fetch lessons for each unit (REAL API), then compute:
      // progress = completedLessons/totalLessons, boss if any lesson_type == BOSS
      final metas = <String, UnitMeta>{};

      for (final u in list) {
        final lessonsInUnit = await _fetchAllLessonsForUnit(u.id);

        final total = lessonsInUnit.length;
        final completed = lessonsInUnit.where((l) => _completedLessonIds.contains(l.id)).length;
        final progress = total == 0 ? 0 : ((completed / total) * 100).round();

        final hasBoss = lessonsInUnit.any((l) => l.lessonType == LessonType.boss);

        metas[u.id] = UnitMeta(
          progressPercent: progress.clamp(0, 100),
          locked: false, // will be computed by gating rule below
          hasBoss: hasBoss,
        );
      }

      // Lock rule (Duolingo-ish):
      // - unit[0] unlocked
      // - unit[i] locked if unit[i-1] progress < 100
      final sorted = [...list]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      for (int i = 0; i < sorted.length; i++) {
        final u = sorted[i];
        final prev = i == 0 ? null : sorted[i - 1];
        final prevMeta = prev == null ? null : metas[prev.id];
        final locked = i == 0 ? false : ((prevMeta?.progressPercent ?? 0) < 100);

        final base = metas[u.id] ?? const UnitMeta(progressPercent: 0, locked: false, hasBoss: false);
        metas[u.id] = base.copyWith(locked: locked);
      }

      unitMetaById.addAll(metas);
      unitMetaLoading = false;
      notifyListeners();
    } catch (e) {
      unitMetaLoading = false;
      _setError(_friendlyError(e));
    }
  }

  Future<List<Lesson>> _fetchAllLessonsForUnit(String unitId) async {
    // paginate using REAL API
    const int pageSize = 200;
    int offset = 0;
    final all = <Lesson>[];

    while (true) {
      final page = await listLessonsByUnit.call(unitId: unitId, limit: pageSize, offset: offset);
      all.addAll(page);
      if (page.length < pageSize) break;
      offset += page.length;
      if (offset > 2000) break; // safety
    }

    all.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return all;
  }

  Future<void> _ensureUserAndAttemptsLoaded() async {
    if (_userId != null && _completedLessonIds.isNotEmpty) return;

    // 1) auth/me to get user_id (REAL API)
    final meRes = await _rawApi.getMe();
    final me = unwrap(meRes) as Map<String, dynamic>;
    _userId = (me['user_id'] ?? '').toString();

    if (_userId == null || _userId!.isEmpty) {
      throw AppError(code: 'AUTH_ME_INVALID', message: 'Không lấy được user_id từ /auth/me');
    }

    // 2) attempts list for user (REAL API)
    // Pull pages until exhausted (limit=200)
    _completedLessonIds.clear();
    int offset = 0;
    const limit = 200;

    while (true) {
      final res = await _rawApi.listUserAttempts(userId: _userId!, limit: limit, offset: offset);
      final data = unwrap(res);

      // schema: ApiResponse[AttemptsListResponse] => { items: [...], total: int }
      final map = (data as Map).cast<String, dynamic>();
      final items = (map['items'] as List<dynamic>? ?? const []);

      for (final it in items) {
        if (it is Map) {
          final m = it.cast<String, dynamic>();
          final lessonId = (m['lesson_id'] ?? '').toString();
          final status = (m['status'] ?? '').toString().toUpperCase();

          // consider completed if SCORED (or SUBMITTED treated as done? keep strict)
          if (lessonId.isNotEmpty && status == 'SCORED') {
            _completedLessonIds.add(lessonId);
          }
        }
      }

      if (items.length < limit) break;
      offset += items.length;
      if (offset > 4000) break; // safety
    }
  }

  UnitMeta metaOf(Unit u) => unitMetaById[u.id] ?? const UnitMeta(progressPercent: 0, locked: false, hasBoss: false);

  // ---------------- misc ----------------
  void clearError() {
    _error = null;
    if (_status == CurriculumStatus.error) _status = CurriculumStatus.ready;
    notifyListeners();
  }

  void _setLoading() {
    _status = CurriculumStatus.loading;
    _error = null;
    notifyListeners();
  }

  void _setReady() {
    _status = CurriculumStatus.ready;
    _error = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = CurriculumStatus.error;
    _error = msg;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    if (e is AppError) return e.message;
    return e.toString().replaceFirst('Exception: ', '');
  }
}
