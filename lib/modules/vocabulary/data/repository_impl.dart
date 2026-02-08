import '../../../core/types/app_error.dart';
import '../../../core/types/api_response.dart';
import '../domain/entity.dart';
import '../domain/repository.dart';
import 'api.dart';

class VocabularyRepositoryImpl implements VocabularyRepository {
  final VocabularyApi api;

  VocabularyRepositoryImpl(this.api);

  T _unwrap<T>(ApiResponse<T> res) {
    if (res.status != 'success') {
      throw AppError(
        code: 'API_ERROR',
        message: res.message ?? 'Request failed',
        status: null,
        raw: res.error,
      );
    }
    return res.data;
  }

  Lexeme _mapLexeme(Map<String, dynamic> j) {
    return Lexeme(
      id: j['id'].toString(),
      languageId: j['language_id'].toString(),
      type: lexemeTypeFromString(j['type']?.toString() ?? 'OTHER'),
      lemma: (j['lemma'] ?? '').toString(),
      phoenic: j['phoenic']?.toString(),
      audioUrl: j['audio_url']?.toString(),
      difficulty: (j['difficulty'] is int) ? (j['difficulty'] as int) : int.tryParse('${j['difficulty']}') ?? 1,
      tags: (j['tags'] is Map) ? (j['tags'] as Map).cast<String, dynamic>() : null,
    );
  }

  Sense _mapSense(Map<String, dynamic> j) {
    return Sense(
      id: j['id'].toString(),
      lexemeId: j['lexeme_id'].toString(),
      senseIndex: (j['sense_index'] is int) ? (j['sense_index'] as int) : int.tryParse('${j['sense_index']}') ?? 1,
      definition: (j['definition'] ?? '').toString(),
      domain: (j['domain'] ?? 'OTHER').toString(),
      cefrLevel: j['cefr_level']?.toString(),
      translations: (j['translations'] is Map) ? (j['translations'] as Map).cast<String, dynamic>() : null,
      collocations: (j['collocations'] is Map) ? (j['collocations'] as Map).cast<String, dynamic>() : null,
      status: (j['status'] ?? 'DRAFT').toString(),
    );
  }

  ExampleSentence _mapExample(Map<String, dynamic> j) {
    return ExampleSentence(
      id: j['id'].toString(),
      senseId: j['sense_id'].toString(),
      sentence: (j['sentence'] ?? '').toString(),
      translation: (j['translation'] is Map) ? (j['translation'] as Map).cast<String, dynamic>() : null,
      audioUrl: j['audio_url']?.toString(),
      difficulty: (j['difficulty'] is int) ? (j['difficulty'] as int) : int.tryParse('${j['difficulty']}') ?? 1,
      tags: (j['tags'] is Map) ? (j['tags'] as Map).cast<String, dynamic>() : null,
    );
  }

  @override
  Future<List<Lexeme>> listLexemesByLesson({required String lessonId}) async {
    final res = await api.listLexemesByLesson(lessonId: lessonId);
    final list = _unwrap(res);
    return list.map(_mapLexeme).toList();
  }

  @override
  Future<List<Lexeme>> listLexemes({
    required String languageId,
    String? q,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await api.listLexemes(languageId: languageId, q: q, limit: limit, offset: offset);
    final list = _unwrap(res);
    return list.map(_mapLexeme).toList();
  }

  @override
  Future<Lexeme> getLexeme({required String lexemeId}) async {
    final res = await api.getLexeme(lexemeId: lexemeId);
    final j = _unwrap(res);
    return _mapLexeme(j);
  }

  @override
  Future<List<Sense>> listSensesByLexeme({required String lexemeId}) async {
    final res = await api.listSensesByLexeme(lexemeId: lexemeId);
    final list = _unwrap(res);
    return list.map(_mapSense).toList();
  }

  @override
  Future<List<ExampleSentence>> listExamplesBySense({required String senseId, int limit = 20}) async {
    final res = await api.listExamplesBySense(senseId: senseId, limit: limit);
    final list = _unwrap(res);
    return list.map(_mapExample).toList();
  }

  @override
  Future<List<ReviewCard>> getReviewToday() async {
    final res = await api.getReviewToday();
    final data = _unwrap(res);

    final items = (data['items'] as List? ?? const []);
    final cards = <ReviewCard>[];

    for (final it in items) {
      final m = (it as Map).cast<String, dynamic>();
      final lexeme = _mapLexeme((m['lexeme'] as Map).cast<String, dynamic>());

      final senses = ((m['senses'] as List?) ?? const [])
          .map((e) => _mapSense((e as Map).cast<String, dynamic>()))
          .toList();

      final examples = ((m['examples'] as List?) ?? const [])
          .map((e) => _mapExample((e as Map).cast<String, dynamic>()))
          .toList();

      final state = (m['state'] is Map) ? (m['state'] as Map).cast<String, dynamic>() : <String, dynamic>{};

      cards.add(ReviewCard(lexeme: lexeme, senses: senses, examples: examples, state: state));
    }

    return cards;
  }

  @override
  Future<void> submitReviewResult({required String lexemeId, required int rating, required String source}) async {
    final res = await api.submitReviewResult(lexemeId: lexemeId, rating: rating, source: source);
    _unwrap(res);
  }

  @override
  Future<List<Map<String, dynamic>>> getWeakWords({int limit = 50, String? severity}) async {
    final res = await api.getWeakWords(limit: limit, severity: severity);
    return _unwrap(res);
  }
}
