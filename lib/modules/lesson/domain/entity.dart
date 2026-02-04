class LessonChoice {
  final String key;
  final String text;
  final bool isCorrect; // server usually false for security
  final int sortOrder;

  const LessonChoice({
    required this.key,
    required this.text,
    required this.isCorrect,
    required this.sortOrder,
  });
}

class LessonItem {
  final String id;
  final String lessonId;
  final String itemType; // MCQ | CLOZE | MATCH | REORDER | LISTEN | SPEAK
  final String? prompt;
  final Map<String, dynamic>? content;
  final Map<String, dynamic>? correctAnswer;
  final int points;
  final int sortOrder;
  final List<LessonChoice> choices;

  const LessonItem({
    required this.id,
    required this.lessonId,
    required this.itemType,
    required this.prompt,
    required this.content,
    required this.correctAnswer,
    required this.points,
    required this.sortOrder,
    required this.choices,
  });
}

class AttemptStartResponse {
  final String attemptId;
  final String lessonId;
  final List<LessonItem> items;

  const AttemptStartResponse({
    required this.attemptId,
    required this.lessonId,
    required this.items,
  });
}

class ItemResult {
  final String itemId;
  final bool isCorrect;
  final int earnedPoints;
  final int maxPoints;
  final Map<String, dynamic>? detail;

  const ItemResult({
    required this.itemId,
    required this.isCorrect,
    required this.earnedPoints,
    required this.maxPoints,
    required this.detail,
  });
}

class AttemptSubmitResponse {
  final String attemptId;
  final String status; // STARTED | SUBMITTED | PENDING_AI | SCORED | FAILED
  final int scorePoints;
  final int maxPoints;
  final int scorePercent;
  final List<ItemResult> results;

  const AttemptSubmitResponse({
    required this.attemptId,
    required this.status,
    required this.scorePoints,
    required this.maxPoints,
    required this.scorePercent,
    required this.results,
  });
}

class AttemptOut {
  final String id;
  final String userId;
  final String lessonId;
  final String status;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final int scorePoints;
  final int maxPoints;
  final int scorePercent;
  final int durationSec;
  final Map<String, dynamic>? answers;
  final Map<String, dynamic>? resultBreakdown;

  const AttemptOut({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.status,
    required this.startedAt,
    required this.submittedAt,
    required this.scorePoints,
    required this.maxPoints,
    required this.scorePercent,
    required this.durationSec,
    required this.answers,
    required this.resultBreakdown,
  });
}
