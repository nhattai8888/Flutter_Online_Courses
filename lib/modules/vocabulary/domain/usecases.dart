import 'entity.dart';
import 'repository.dart';

class ListLexemesByLessonUseCase {
  final VocabularyRepository repo;
  ListLexemesByLessonUseCase(this.repo);

  Future<List<Lexeme>> call({required String lessonId}) {
    return repo.listLexemesByLesson(lessonId: lessonId);
  }
}

class ListLexemesUseCase {
  final VocabularyRepository repo;
  ListLexemesUseCase(this.repo);

  Future<List<Lexeme>> call({
    required String languageId,
    String? q,
    int limit = 50,
    int offset = 0,
  }) {
    return repo.listLexemes(
      languageId: languageId,
      q: q,
      limit: limit,
      offset: offset,
    );
  }
}

class GetLexemeUseCase {
  final VocabularyRepository repo;
  GetLexemeUseCase(this.repo);

  Future<Lexeme> call({required String lexemeId}) {
    return repo.getLexeme(lexemeId: lexemeId);
  }
}

class ListSensesByLexemeUseCase {
  final VocabularyRepository repo;
  ListSensesByLexemeUseCase(this.repo);

  Future<List<Sense>> call({required String lexemeId}) {
    return repo.listSensesByLexeme(lexemeId: lexemeId);
  }
}

class ListExamplesBySenseUseCase {
  final VocabularyRepository repo;
  ListExamplesBySenseUseCase(this.repo);

  Future<List<ExampleSentence>> call({required String senseId, int limit = 20}) {
    return repo.listExamplesBySense(senseId: senseId, limit: limit);
  }
}
