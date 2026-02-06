import 'entity.dart';
import 'repository.dart';

class ListItemsByLessonUseCase {
  final LessonRepository repo;
  ListItemsByLessonUseCase(this.repo);

  Future<List<LessonItem>> call(String lessonId) {
    return repo.listItemsByLesson(lessonId);
  }
}

class StartLessonAttemptUseCase {
  final LessonRepository repo;
  StartLessonAttemptUseCase(this.repo);

  Future<AttemptStartResponse> call(String lessonId) {
    return repo.startLessonAttempt(lessonId);
  }
}

class SubmitLessonAttemptUseCase {
  final LessonRepository repo;
  SubmitLessonAttemptUseCase(this.repo);

  Future<AttemptSubmitResponse> call({
    required String lessonId,
    required String attemptId,
    required Map<String, dynamic> answers,
    required int durationSec,
  }) {
    return repo.submitLessonAttempt(
      lessonId: lessonId,
      attemptId: attemptId,
      answers: answers,
      durationSec: durationSec,
    );
  }
}

