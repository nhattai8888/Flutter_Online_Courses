import 'entity.dart';

abstract class VocabularyRepository {
  Future<List<Lexeme>> listLexemesByLesson({
    required String lessonId,
  });

  Future<List<Lexeme>> listLexemes({
    required String languageId,
    String? q,
    int limit = 50,
    int offset = 0,
  });

  Future<Lexeme> getLexeme({
    required String lexemeId,
  });

  Future<List<Sense>> listSensesByLexeme({
    required String lexemeId,
  });

  Future<List<ExampleSentence>> listExamplesBySense({
    required String senseId,
    int limit = 20,
  });

  Future<List<ReviewCard>> getReviewToday();

  Future<void> submitReviewResult({
    required String lexemeId,
    required int rating,
    required String source,
  });

  Future<List<Map<String, dynamic>>> getWeakWords({
    int limit = 50,
    String? severity,
  });
}
