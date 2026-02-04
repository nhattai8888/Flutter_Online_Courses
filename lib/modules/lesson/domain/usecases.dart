import 'entity.dart';
import 'repository.dart';

class ListItemsByLessonUseCase {
  final LessonRepository repo;
  const ListItemsByLessonUseCase(this.repo);

  Future<List<LessonItem>> call(String lessonId) => repo.listItemsByLesson(lessonId);
}

class StartLessonAttemptUseCase {
  final LessonRepository repo;
  const StartLessonAttemptUseCase(this.repo);

  Future<AttemptStartResponse> call(String lessonId) => repo.startAttempt(lessonId);
}

class SubmitLessonAttemptUseCase {
  final LessonRepository repo;
  const SubmitLessonAttemptUseCase(this.repo);

  Future<AttemptSubmitResponse> call({
    required String attemptId,
    required Map<String, dynamic> answers,
    int durationSec = 0,
  }) {
    return repo.submitAttempt(attemptId: attemptId, answers: answers, durationSec: durationSec);
  }
}

class GetAttemptUseCase {
  final LessonRepository repo;
  const GetAttemptUseCase(this.repo);

  Future<AttemptOut> call(String attemptId) => repo.getAttempt(attemptId);
}
