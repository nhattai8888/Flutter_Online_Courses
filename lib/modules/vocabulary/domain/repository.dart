import 'entity.dart';

abstract class VocabularyRepository {
  Future<List<Lexeme>> listLexemes({
    required String languageId,
    String? q,
    int limit = 50,
    int offset = 0,
  });

  Future<Lexeme> getLexeme(String lexemeId);

  Future<List<Sense>> listSensesByLexeme(String lexemeId);

  Future<List<ExampleSentence>> listExamplesBySense({
    required String senseId,
    int limit = 20,
  });

  Future<ReviewTodayResponse> getReviewToday();

  Future<void> submitReviewResult({
    required String lexemeId,
    required int rating, // 0..5
    required String source, // SPEAKING | LISTENING | ...
  });

  Future<List<WeakWord>> getWeakWords({int limit = 50, String? severity});
}
