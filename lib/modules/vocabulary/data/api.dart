import '../../../core/network/api_client.dart';
import '../../../core/types/api_response.dart';

class VocabularyApi {
  final _dio = ApiClient.instance.dio;

  // --- Paths (vocab) ---
  static const String _lexemes = '/vocab/lexemes';
  static const String _sensesByLexeme = '/vocab/senses/by-lexeme';
  static const String _examplesBySense = '/vocab/examples/by-sense';
  static const String _reviewToday = '/vocab/review/today';
  static const String _reviewResult = '/vocab/review/result';
  static const String _weakWords = '/vocab/weak-words';

  ApiResponse<dynamic> _wrap(dynamic raw) {
    final map = (raw as Map).cast<String, dynamic>();
    final code = map['code'];
    final ok = code == 200;
    return ApiResponse<dynamic>(
      status: ok ? 'success' : 'error',
      data: map['data'],
      message: map['message'] as String?,
      error: map,
    );
  }

  Future<ApiResponse<dynamic>> listLexemes({
    required String languageId,
    String? q,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      _lexemes,
      queryParameters: {
        'language_id': languageId,
        if (q != null && q.isNotEmpty) 'q': q,
        'limit': limit,
        'offset': offset,
      },
    );
    return _wrap(res.data);
  }

  Future<ApiResponse<dynamic>> getLexeme(String lexemeId) async {
    final res = await _dio.get('$_lexemes/$lexemeId');
    return _wrap(res.data);
  }

  Future<ApiResponse<dynamic>> listSensesByLexeme(String lexemeId) async {
    final res = await _dio.get('$_sensesByLexeme/$lexemeId');
    return _wrap(res.data);
  }

  Future<ApiResponse<dynamic>> listExamplesBySense({
    required String senseId,
    int limit = 20,
  }) async {
    final res = await _dio.get(
      '$_examplesBySense/$senseId',
      queryParameters: {'limit': limit},
    );
    return _wrap(res.data);
  }

  Future<ApiResponse<dynamic>> getReviewToday() async {
    final res = await _dio.get(_reviewToday);
    return _wrap(res.data);
  }

  Future<ApiResponse<dynamic>> submitReviewResult({
    required String lexemeId,
    required int rating,
    required String source,
  }) async {
    final res = await _dio.post(
      _reviewResult,
      data: {
        'lexeme_id': lexemeId,
        'rating': rating,
        'source': source,
      },
    );
    return _wrap(res.data);
  }

  Future<ApiResponse<dynamic>> getWeakWords({
    int limit = 50,
    String? severity,
  }) async {
    final res = await _dio.get(
      _weakWords,
      queryParameters: {
        'limit': limit,
        if (severity != null && severity.isNotEmpty) 'severity': severity,
      },
    );
    return _wrap(res.data);
  }
}
