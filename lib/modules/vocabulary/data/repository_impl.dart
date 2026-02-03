import '../../../core/types/app_error.dart';
import '../../../core/types/api_response.dart';
import '../domain/entity.dart';
import '../domain/repository.dart';
import 'api.dart';

class VocabularyRepositoryImpl implements VocabularyRepository {
  final VocabularyApi _api;
  VocabularyRepositoryImpl(this._api);

  T _unwrap<T>(ApiResponse<dynamic> res, T Function(dynamic data) mapper) {
    if (res.status != 'success') {
      final err = res.error;
      final msg = res.message ?? 'Request failed';
      throw AppError(code: 'API_ERROR', message: msg, status: null, raw: err);
    }
    return mapper(res.data);
  }

  DateTime? _dt(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  Lexeme _lexemeFromMap(Map<String, dynamic> m) {
    return Lexeme(
      id: (m['id'] ?? '').toString(),
      languageId: (m['language_id'] ?? '').toString(),
      type: (m['type'] ?? '').toString(),
      lemma: (m['lemma'] ?? '').toString(),
      phoenic: m['phoenic']?.toString(),
      audioUrl: m['audio_url']?.toString(),
      difficulty: (m['difficulty'] is int) ? m['difficulty'] as int : int.tryParse('${m['difficulty']}') ?? 1,
      tags: (m['tags'] is Map) ? (m['tags'] as Map).cast<String, dynamic>() : null,
      status: (m['status'] ?? '').toString(),
      createdAt: _dt(m['created_at']),
      updatedAt: _dt(m['updated_at']),
    );
  }

  Sense _senseFromMap(Map<String, dynamic> m) {
    return Sense(
      id: (m['id'] ?? '').toString(),
      lexemeId: (m['lexeme_id'] ?? '').toString(),
      senseIndex: (m['sense_index'] is int) ? m['sense_index'] as int : int.tryParse('${m['sense_index']}') ?? 1,
      definition: (m['definition'] ?? '').toString(),
      domain: (m['domain'] ?? '').toString(),
      cefrLevel: m['cefr_level']?.toString(),
      translations: (m['translations'] is Map) ? (m['translations'] as Map).cast<String, dynamic>() : null,
      collocations: (m['collocations'] is Map) ? (m['collocations'] as Map).cast<String, dynamic>() : null,
      status: (m['status'] ?? '').toString(),
      createdAt: _dt(m['created_at']),
      updatedAt: _dt(m['updated_at']),
    );
  }

  ExampleSentence _exampleFromMap(Map<String, dynamic> m) {
    return ExampleSentence(
      id: (m['id'] ?? '').toString(),
      senseId: (m['sense_id'] ?? '').toString(),
      sentence: (m['sentence'] ?? '').toString(),
      translation: (m['translation'] is Map) ? (m['translation'] as Map).cast<String, dynamic>() : null,
      audioUrl: m['audio_url']?.toString(),
      difficulty: (m['difficulty'] is int) ? m['difficulty'] as int : int.tryParse('${m['difficulty']}') ?? 1,
      tags: (m['tags'] is Map) ? (m['tags'] as Map).cast<String, dynamic>() : null,
      createdAt: _dt(m['created_at']),
    );
  }

  WeakWord _weakWordFromMap(Map<String, dynamic> m) {
    return WeakWord(
      lexemeId: (m['lexeme_id'] ?? '').toString(),
      lemma: (m['lemma'] ?? '').toString(),
      type: (m['type'] ?? '').toString(),
      severity: (m['severity'] ?? '').toString(),
      errorType: (m['error_type'] ?? '').toString(),
      occurCount: (m['occur_count'] is int) ? m['occur_count'] as int : int.tryParse('${m['occur_count']}') ?? 0,
      lastOccurredAt: _dt(m['last_occurred_at']),
      evidence: (m['evidence'] is Map) ? (m['evidence'] as Map).cast<String, dynamic>() : null,
    );
  }

  @override
  Future<List<Lexeme>> listLexemes({
    required String languageId,
    String? q,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _api.listLexemes(languageId: languageId, q: q, limit: limit, offset: offset);
    return _unwrap<List<Lexeme>>(res, (data) {
      final list = (data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => _lexemeFromMap((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
    });
  }

  @override
  Future<Lexeme> getLexeme(String lexemeId) async {
    final res = await _api.getLexeme(lexemeId);
    return _unwrap<Lexeme>(res, (data) => _lexemeFromMap((data as Map).cast<String, dynamic>()));
  }

  @override
  Future<List<Sense>> listSensesByLexeme(String lexemeId) async {
    final res = await _api.listSensesByLexeme(lexemeId);
    return _unwrap<List<Sense>>(res, (data) {
      final list = (data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => _senseFromMap((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
    });
  }

  @override
  Future<List<ExampleSentence>> listExamplesBySense({required String senseId, int limit = 20}) async {
    final res = await _api.listExamplesBySense(senseId: senseId, limit: limit);
    return _unwrap<List<ExampleSentence>>(res, (data) {
      final list = (data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => _exampleFromMap((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
    });
  }

  @override
  Future<ReviewTodayResponse> getReviewToday() async {
    final res = await _api.getReviewToday();
    return _unwrap<ReviewTodayResponse>(res, (data) {
      final m = (data as Map).cast<String, dynamic>();
      final items = (m['items'] as List?) ?? const [];
      final total = (m['total'] is int) ? m['total'] as int : int.tryParse('${m['total']}') ?? items.length;

      final cards = <ReviewCard>[];
      for (final raw in items) {
        if (raw is! Map) continue;
        final card = raw.cast<String, dynamic>();

        final lex = card['lexeme'];
        final senses = (card['senses'] as List?) ?? const [];
        final examples = (card['examples'] as List?) ?? const [];

        if (lex is! Map) continue;

        cards.add(
          ReviewCard(
            lexeme: _lexemeFromMap(lex.cast<String, dynamic>()),
            senses: senses
                .whereType<Map>()
                .map((e) => _senseFromMap((e as Map).cast<String, dynamic>()))
                .toList(growable: false),
            examples: examples
                .whereType<Map>()
                .map((e) => _exampleFromMap((e as Map).cast<String, dynamic>()))
                .toList(growable: false),
            state: (card['state'] is Map) ? (card['state'] as Map).cast<String, dynamic>() : null,
          ),
        );
      }

      return ReviewTodayResponse(items: cards, total: total);
    });
  }

  @override
  Future<void> submitReviewResult({
    required String lexemeId,
    required int rating,
    required String source,
  }) async {
    final res = await _api.submitReviewResult(lexemeId: lexemeId, rating: rating, source: source);
    _unwrap<void>(res, (_) => null);
  }

  @override
  Future<List<WeakWord>> getWeakWords({int limit = 50, String? severity}) async {
    final res = await _api.getWeakWords(limit: limit, severity: severity);
    return _unwrap<List<WeakWord>>(res, (data) {
      final list = (data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => _weakWordFromMap((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
    });
  }
}
