import 'package:flutter/foundation.dart';
import '../domain/entity.dart';
import '../domain/usecases.dart';
import '../../../core/types/app_error.dart';

enum CurriculumStatus { idle, loading, ready, error }

class CurriculumController extends ChangeNotifier {
  final ListLanguagesUseCase listLanguages;
  final ListLevelsByLanguageUseCase listLevels;
  final ListUnitsByLanguageUseCase listUnits;

  // UPDATED
  final ListLessonsByUnitUseCase listLessonsByUnit;

  final GetLessonUseCase getLesson;

  CurriculumController({
    required this.listLanguages,
    required this.listLevels,
    required this.listUnits,
    required this.listLessonsByUnit,
    required this.getLesson,
  });

  CurriculumStatus _status = CurriculumStatus.idle;
  CurriculumStatus get status => _status;

  String? _error;
  String? get error => _error;

  // State
  List<Language> languages = const [];
  Language? selectedLanguage;

  List<Level> levels = const [];
  Level? selectedLevel;

  List<Unit> units = const [];
  Unit? selectedUnit;

  List<Lesson> lessons = const [];

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
    notifyListeners();
    await _loadLanguageBundle(lang.id);
  }

  Future<void> selectLevel(Level? level) async {
    selectedLevel = level;
    selectedUnit = null;
    notifyListeners();
    await loadUnits();

    // auto pick first unit (Duolingo vibe: luôn có "unit đang học")
    if (units.isNotEmpty) {
      selectedUnit = units.first;
    }
    notifyListeners();

    await refreshLessons();
  }

  Future<void> selectUnit(Unit? unit) async {
    selectedUnit = unit;
    notifyListeners();
    await refreshLessons();
  }

  Future<void> _loadLanguageBundle(String languageId) async {
    _setLoading();
    try {
      levels = await listLevels.call(languageId);
      selectedLevel = levels.isNotEmpty ? levels.first : null;

      await loadUnits();

      // auto pick first unit
      selectedUnit = units.isNotEmpty ? units.first : null;

      await refreshLessons();
      _setReady();
    } catch (e) {
      _setError(_friendlyError(e));
    }
  }

  Future<void> loadUnits() async {
    final langId = selectedLanguage?.id;
    if (langId == null) return;

    units = await listUnits.call(
      languageId: langId,
      levelId: selectedLevel?.id,
    );
    notifyListeners();
  }

  Future<void> refreshLessons() async {
    final unitId = selectedUnit?.id;
    lessonOffset = 0;
    hasMoreLessons = true;
    lessons = const [];
    notifyListeners();

    // Nếu chưa chọn unit thì không gọi lessons
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
