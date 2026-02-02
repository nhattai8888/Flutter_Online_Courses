import 'entity.dart';

abstract class CurriculumRepository {
  // Languages
  Future<List<Language>> listLanguages();
  Future<Language> getLanguage(String languageId);

  // Levels
  Future<List<Level>> listLevelsByLanguage(String languageId);

  // Units
  Future<List<Unit>> listUnitsByLanguage({
    required String languageId,
    String? levelId,
  });

  // Lessons (UPDATED: by-unit)
  Future<List<Lesson>> listLessonsByUnit({
    required String unitId,
    int limit = 50,
    int offset = 0,
  });

  Future<Lesson> getLesson(String lessonId);
}
