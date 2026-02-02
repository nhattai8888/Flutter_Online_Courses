import 'entity.dart';
import 'repository.dart';

class ListLanguagesUseCase {
  final CurriculumRepository repository;
  ListLanguagesUseCase(this.repository);
  Future<List<Language>> call() => repository.listLanguages();
}

class GetLanguageUseCase {
  final CurriculumRepository repository;
  GetLanguageUseCase(this.repository);
  Future<Language> call(String languageId) => repository.getLanguage(languageId);
}

class ListLevelsByLanguageUseCase {
  final CurriculumRepository repository;
  ListLevelsByLanguageUseCase(this.repository);
  Future<List<Level>> call(String languageId) => repository.listLevelsByLanguage(languageId);
}

class ListUnitsByLanguageUseCase {
  final CurriculumRepository repository;
  ListUnitsByLanguageUseCase(this.repository);
  Future<List<Unit>> call({required String languageId, String? levelId}) =>
      repository.listUnitsByLanguage(languageId: languageId, levelId: levelId);
}

// UPDATED: lessons by unit
class ListLessonsByUnitUseCase {
  final CurriculumRepository repository;
  ListLessonsByUnitUseCase(this.repository);

  Future<List<Lesson>> call({
    required String unitId,
    int limit = 50,
    int offset = 0,
  }) =>
      repository.listLessonsByUnit(unitId: unitId, limit: limit, offset: offset);
}

class GetLessonUseCase {
  final CurriculumRepository repository;
  GetLessonUseCase(this.repository);
  Future<Lesson> call(String lessonId) => repository.getLesson(lessonId);
}
