import 'entity.dart';
import 'repository.dart';

class ListLexemesUseCase {
  final VocabularyRepository repo;
  const ListLexemesUseCase(this.repo);

  Future<List<Lexeme>> call({
    required String languageId,
    String? q,
    int limit = 50,
    int offset = 0,
  }) {
    return repo.listLexemes(languageId: languageId, q: q, limit: limit, offset: offset);
  }
}

class GetLexemeUseCase {
  final VocabularyRepository repo;
  const GetLexemeUseCase(this.repo);

  Future<Lexeme> call(String lexemeId) => repo.getLexeme(lexemeId);
}

class ListSensesByLexemeUseCase {
  final VocabularyRepository repo;
  const ListSensesByLexemeUseCase(this.repo);

  Future<List<Sense>> call(String lexemeId) => repo.listSensesByLexeme(lexemeId);
}

class ListExamplesBySenseUseCase {
  final VocabularyRepository repo;
  const ListExamplesBySenseUseCase(this.repo);

  Future<List<ExampleSentence>> call({required String senseId, int limit = 20}) {
    return repo.listExamplesBySense(senseId: senseId, limit: limit);
  }
}

class GetReviewTodayUseCase {
  final VocabularyRepository repo;
  const GetReviewTodayUseCase(this.repo);

  Future<ReviewTodayResponse> call() => repo.getReviewToday();
}

class SubmitReviewResultUseCase {
  final VocabularyRepository repo;
  const SubmitReviewResultUseCase(this.repo);

  Future<void> call({
    required String lexemeId,
    required int rating,
    required String source,
  }) {
    return repo.submitReviewResult(lexemeId: lexemeId, rating: rating, source: source);
  }
}

class GetWeakWordsUseCase {
  final VocabularyRepository repo;
  const GetWeakWordsUseCase(this.repo);

  Future<List<WeakWord>> call({int limit = 50, String? severity}) {
    return repo.getWeakWords(limit: limit, severity: severity);
  }
}
