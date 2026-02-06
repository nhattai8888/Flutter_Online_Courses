import 'entity.dart';

abstract class LessonRepository {
  Future<List<LessonItem>> listItemsByLesson(String lessonId);

  Future<AttemptStartResponse> startLessonAttempt(String lessonId);

Future<AttemptSubmitResponse> submitLessonAttempt({
  required String lessonId,
  required String attemptId,
  required Map<String, dynamic> answers,
  required int durationSec,
});

}
