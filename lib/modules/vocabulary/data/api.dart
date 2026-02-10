import 'package:lingougo/core/network/api_client.dart';

import '../../../core/types/api_response.dart';

class VocabularyApi {
  final ApiClient _client;

  VocabularyApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  // NEW: lexemes by lesson
  static String lexemesByLessonPath(String lessonId) => '/vocab/lessons/$lessonId/lexemes';

  // Vocab routers
  static const _lexemesPath = '/vocab/lexemes';
  static String lexemePath(String lexemeId) => '/vocab/lexemes/$lexemeId';
  static String sensesByLexemePath(String lexemeId) => '/vocab/senses/by-lexeme/$lexemeId';
  static String examplesBySensePath(String senseId) => '/vocab/examples/by-sense/$senseId';
  static const _reviewTodayPath = '/vocab/review/today';
  static const _reviewResultPath = '/vocab/review/result';
  static const _weakWordsPath = '/vocab/weak-words';

  ApiResponse<T> _wrap<T>(Map<String, dynamic> raw, T Function(dynamic v) mapper) {
    final code = raw['code'];
    final data = raw['data'];
    final msg = raw['message']?.toString();
    final ok = code == 200;
    return ApiResponse<T>(
      status: ok ? 'success' : 'error',
      data: mapper(data),
      message: msg,
      error: ok ? null : raw,
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> listLexemesByLesson({
    required String lessonId,
  }) async {
    final res = await _client.dio.get(lexemesByLessonPath(lessonId));
    return _wrap((res.data as Map).cast<String, dynamic>(), (v) {
      final list = (v as List? ?? const []);
      return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
    });
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> listLexemes({
    required String languageId,
    String? q,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _client.dio.get(
      _lexemesPath,
      queryParameters: {
        'language_id': languageId,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'limit': limit,
        'offset': offset,
      },
    );
    return _wrap((res.data as Map).cast<String, dynamic>(), (v) {
      final list = (v as List? ?? const []);
      return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getLexeme({
    required String lexemeId,
  }) async {
    final res = await _client.dio.get(lexemePath(lexemeId));
    return _wrap((res.data as Map).cast<String, dynamic>(), (v) {
      return (v as Map).cast<String, dynamic>();
    });
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> listSensesByLexeme({
    required String lexemeId,
  }) async {
    final res = await _client.dio.get(sensesByLexemePath(lexemeId));
    return _wrap((res.data as Map).cast<String, dynamic>(), (v) {
      final list = (v as List? ?? const []);
      return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
    });
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> listExamplesBySense({
    required String senseId,
    int limit = 20,
  }) async {
    final res = await _client.dio.get(
      examplesBySensePath(senseId),
      queryParameters: {'limit': limit},
    );
    return _wrap((res.data as Map).cast<String, dynamic>(), (v) {
      final list = (v as List? ?? const []);
      return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getReviewToday() async {
    final res = await _client.dio.get(_reviewTodayPath);
    return _wrap((res.data as Map).cast<String, dynamic>(), (v) {
      return (v as Map).cast<String, dynamic>();
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> submitReviewResult({
    required String lexemeId,
    required int rating,
    required String source,
  }) async {
    final res = await _client.dio.post(
      _reviewResultPath,
      data: {
        'lexeme_id': lexemeId,
        'rating': rating,
        'source': source,
      },
    );
    return _wrap((res.data as Map).cast<String, dynamic>(), (v) {
      return (v as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    });
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getWeakWords({
    int limit = 50,
    String? severity,
  }) async {
    final res = await _client.dio.get(
      _weakWordsPath,
      queryParameters: {
        'limit': limit,
        if (severity != null && severity.trim().isNotEmpty) 'severity': severity.trim(),
      },
    );
    return _wrap((res.data as Map).cast<String, dynamic>(), (v) {
      final list = (v as List? ?? const []);
      return list.map((e) => (e as Map).cast<String, dynamic>()).toList();
    });
  }
}
