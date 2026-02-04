import '../../../core/network/api_client.dart';
import '../../../core/types/api_response.dart';

class LessonApi {
  final _dio = ApiClient.instance.dio;

  // --- Paths (lesson-engine) ---
  static const String _itemsByLesson = '/lesson-engine/items/by-lesson';
  static const String _attemptStart = '/lesson-engine/lessons';
  static const String _attempts = '/lesson-engine/attempts';

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

  Future<ApiResponse<dynamic>> listItemsByLesson(String lessonId) async {
    final res = await _dio.get('$_itemsByLesson/$lessonId');
    return _wrap(res.data);
  }

  Future<ApiResponse<dynamic>> startAttempt(String lessonId) async {
    final res = await _dio.post('$_attemptStart/$lessonId/attempts/start');
    return _wrap(res.data);
  }

  Future<ApiResponse<dynamic>> submitAttempt({
    required String attemptId,
    required Map<String, dynamic> answers,
    int durationSec = 0,
  }) async {
    final res = await _dio.post(
      '$_attempts/$attemptId/submit',
      data: {
        'answers': answers,
        'duration_sec': durationSec,
      },
    );
    return _wrap(res.data);
  }

  Future<ApiResponse<dynamic>> getAttempt(String attemptId) async {
    final res = await _dio.get('$_attempts/$attemptId');
    return _wrap(res.data);
  }
}
