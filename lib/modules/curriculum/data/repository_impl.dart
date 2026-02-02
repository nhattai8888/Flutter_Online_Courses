import '../domain/entity.dart';
import '../domain/repository.dart';
import '../../../core/types/api_response.dart';
import 'api.dart';

class CurriculumRepositoryImpl implements CurriculumRepository {
  final CurriculumApi api;
  CurriculumRepositoryImpl(this.api);

  Language _mapLanguage(Map<String, dynamic> m) {
    return Language(
      id: (m['id'] ?? '').toString(),
      code: (m['code'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      script: m['script']?.toString(),
    );
  }

  Level _mapLevel(Map<String, dynamic> m) {
    return Level(
      id: (m['id'] ?? '').toString(),
      languageId: (m['language_id'] ?? '').toString(),
      code: (m['code'] ?? '').toString(),
      name: (m['name'] ?? '').toString(),
      sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Unit _mapUnit(Map<String, dynamic> m) {
    return Unit(
      id: (m['id'] ?? '').toString(),
      languageId: (m['language_id'] ?? '').toString(),
      levelId: m['level_id']?.toString(),
      title: (m['title'] ?? '').toString(),
      description: m['description']?.toString(),
      sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  LessonType _mapLessonType(dynamic v) {
    final s = (v ?? 'STANDARD').toString().toUpperCase();
    return switch (s) {
      'BOSS' => LessonType.boss,
      'REVIEW' => LessonType.review,
      _ => LessonType.standard,
    };
  }

  PublishStatus _mapPublishStatus(dynamic v) {
    final s = (v ?? 'DRAFT').toString().toUpperCase();
    return switch (s) {
      'REVIEW' => PublishStatus.review,
      'PUBLISHED' => PublishStatus.published,
      'ARCHIVED' => PublishStatus.archived,
      _ => PublishStatus.draft,
    };
  }

  Lesson _mapLesson(Map<String, dynamic> m) {
    return Lesson(
      id: (m['id'] ?? '').toString(),
      languageId: (m['language_id'] ?? '').toString(),
      unitId: m['unit_id']?.toString(),
      title: (m['title'] ?? '').toString(),
      objective: m['objective']?.toString(),
      estimatedMinutes: (m['estimated_minutes'] as num?)?.toInt() ?? 6,
      lessonType: _mapLessonType(m['lesson_type']),
      publishStatus: _mapPublishStatus(m['publish_status']),
      version: (m['version'] as num?)?.toInt() ?? 1,
      slug: (m['slug'] ?? '').toString(),
      sortOrder: (m['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  List<T> _mapList<T>(dynamic data, T Function(Map<String, dynamic>) mapper) {
    final raw = (data as List<dynamic>? ?? const []);
    return raw.whereType<Map>().map((e) => mapper(e.cast<String, dynamic>())).toList();
  }

  @override
  Future<List<Language>> listLanguages() async {
    final res = await api.listLanguages();
    final data = unwrap(res);
    return _mapList<Language>(data, _mapLanguage);
  }

  @override
  Future<Language> getLanguage(String languageId) async {
    final res = await api.getLanguage(languageId);
    final data = unwrap(res) as Map<String, dynamic>;
    return _mapLanguage(data);
  }

  @override
  Future<List<Level>> listLevelsByLanguage(String languageId) async {
    final res = await api.listLevelsByLanguage(languageId);
    final data = unwrap(res);
    final items = _mapList<Level>(data, _mapLevel);
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  @override
  Future<List<Unit>> listUnitsByLanguage({required String languageId, String? levelId}) async {
    final res = await api.listUnitsByLanguage(languageId: languageId, levelId: levelId);
    final data = unwrap(res);
    final items = _mapList<Unit>(data, _mapUnit);
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  // UPDATED: lessons by unit
  @override
  Future<List<Lesson>> listLessonsByUnit({required String unitId, int limit = 50, int offset = 0}) async {
    final res = await api.listLessonsByUnit(unitId: unitId, limit: limit, offset: offset);
    final data = unwrap(res);
    final items = _mapList<Lesson>(data, _mapLesson);
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return items;
  }

  @override
  Future<Lesson> getLesson(String lessonId) async {
    final res = await api.getLesson(lessonId);
    final data = unwrap(res) as Map<String, dynamic>;
    return _mapLesson(data);
  }
}
