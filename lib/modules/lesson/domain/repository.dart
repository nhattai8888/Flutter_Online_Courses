import 'entity.dart';

abstract class LessonRepository {
  Future<List<LessonItem>> listItemsByLesson(String lessonId);

  Future<AttemptStartResponse> startAttempt(String lessonId);

  Future<AttemptSubmitResponse> submitAttempt({
    required String attemptId,
    required Map<String, dynamic> answers, // Dict[item_id] = {answer, meta}
    int durationSec = 0,
  });

  Future<AttemptOut> getAttempt(String attemptId);
}
