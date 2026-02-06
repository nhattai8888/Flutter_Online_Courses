import '../../../core/network/api_client.dart';

class LessonApi {
  LessonApi({ApiClient? client}) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static String itemsByLessonPath(String lessonId) => '/lesson-engine/items/by-lesson/$lessonId';
  static String startAttemptPath(String lessonId) => '/lesson-engine/lessons/$lessonId/attempts/start';
  static String submitAttemptPath({
  required String lessonId,
  required String attemptId,
}) =>
  '/lesson-engine/lessons/$lessonId/attempts/$attemptId/submit';


  Future<Map<String, dynamic>> getItemsByLesson(String lessonId) async {
    final res = await _client.dio.get(itemsByLessonPath(lessonId));
    return (res.data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> startAttempt(String lessonId) async {
    final res = await _client.dio.post(startAttemptPath(lessonId));
    return (res.data as Map).cast<String, dynamic>();
  }

Future<Map<String, dynamic>> submitAttempt({
  required String lessonId,
  required String attemptId,
  required Map<String, dynamic> answers,
  required int durationSec,
}) async {
  final res = await _client.dio.post(
    submitAttemptPath(
      lessonId: lessonId,
      attemptId: attemptId,
    ),
    data: {
      'answers': answers,
      'duration_sec': durationSec,
    },
  );
  return (res.data as Map).cast<String, dynamic>();
}
}
