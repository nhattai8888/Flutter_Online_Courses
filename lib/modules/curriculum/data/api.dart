import '../../../core/network/api_client.dart';
import '../../../core/types/api_response.dart';

class CurriculumApi {
  final _dio = ApiClient.instance.dio;

  // --- Paths (curriculum) ---
  static const String _languages = '/curriculum/languages';
  static const String _levelsByLanguage = '/curriculum/levels/by-language';
  static const String _unitsByLanguage = '/curriculum/units/by-language';
  static const String _lessonsByUnit = '/curriculum/lessons/by-unit';
  static const String _lessons = '/curriculum/lessons';

  // --- Paths (auth / lesson-engine) ---
  static const String _authMe = '/auth/me';
  static const String _attemptsUser = '/lesson-engine/attempts/user';

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

  // Languages
  Future<ApiResponse<dynamic>> listLanguages() async {
    final res = await _dio.get(_languages);
    return _wrap(res.data);
  }

  Future<ApiResponse<dynamic>> getLanguage(String languageId) async {
    final res = await _dio.get('$_languages/$languageId');
    return _wrap(res.data);
  }

  // Levels
  Future<ApiResponse<dynamic>> listLevelsByLanguage(String languageId) async {
    final res = await _dio.get('$_levelsByLanguage/$languageId');
    return _wrap(res.data);
  }

  // Units
  Future<ApiResponse<dynamic>> listUnitsByLanguage({
    required String languageId,
    String? levelId,
  }) async {
    final res = await _dio.get(
      '$_unitsByLanguage/$languageId',
      queryParameters: {
        if (levelId != null && levelId.isNotEmpty) 'level_id': levelId,
      },
    );
    return _wrap(res.data);
  }

  // Lessons by unit (REAL API)
  Future<ApiResponse<dynamic>> listLessonsByUnit({
    required String unitId,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '$_lessonsByUnit/$unitId',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
    return _wrap(res.data);
  }

  Future<ApiResponse<dynamic>> getLesson(String lessonId) async {
    final res = await _dio.get('$_lessons/$lessonId');
    return _wrap(res.data);
  }

  // Auth Me (REAL API)
  Future<ApiResponse<dynamic>> getMe() async {
    final res = await _dio.get(_authMe);
    return _wrap(res.data);
  }

  // Lesson attempts list (REAL API)
  Future<ApiResponse<dynamic>> listUserAttempts({
    required String userId,
    String? lessonId,
    int limit = 200,
    int offset = 0,
  }) async {
    final path = '$_attemptsUser/$userId';
    final res = await _dio.get(
      path,
      queryParameters: {
        if (lessonId != null && lessonId.isNotEmpty) 'lesson_id': lessonId,
        'limit': limit,
        'offset': offset,
      },
    );
    return _wrap(res.data);
  }
}
