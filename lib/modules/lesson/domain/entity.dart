
enum LessonItemType {
  mcq,
  cloze,
  match,
  reorder,
  listen,
  speak,
  dialogue,
  recorder,
  other;

  static LessonItemType fromApi(String raw) {
    switch (raw.toUpperCase()) {
      case 'MCQ':
        return LessonItemType.mcq;
      case 'CLOZE':
        return LessonItemType.cloze;
      case 'MATCH':
        return LessonItemType.match;
      case 'REORDER':
        return LessonItemType.reorder;
      case 'LISTEN':
        return LessonItemType.listen;
      case 'SPEAK':
        return LessonItemType.speak;
      case 'DIALOGUE':
        return LessonItemType.dialogue;
      case 'RECORDER':
        return LessonItemType.recorder;
      default:
        return LessonItemType.other;
    }
  }

  String get apiValue {
    switch (this) {
      case LessonItemType.mcq:
        return 'MCQ';
      case LessonItemType.cloze:
        return 'CLOZE';
      case LessonItemType.match:
        return 'MATCH';
      case LessonItemType.reorder:
        return 'REORDER';
      case LessonItemType.listen:
        return 'LISTEN';
      case LessonItemType.speak:
        return 'SPEAK';
      case LessonItemType.dialogue:
        return 'DIALOGUE';
      case LessonItemType.recorder:
        return 'RECORDER';
      case LessonItemType.other:
        return 'OTHER';
    }
  }
}

enum AttemptStatus {
  started,
  submitted,
  pendingAi,
  scored,
  failed;

  static AttemptStatus fromApi(String raw) {
    switch (raw.toUpperCase()) {
      case 'STARTED':
        return AttemptStatus.started;
      case 'SUBMITTED':
        return AttemptStatus.submitted;
      case 'PENDING_AI':
        return AttemptStatus.pendingAi;
      case 'SCORED':
        return AttemptStatus.scored;
      case 'FAILED':
        return AttemptStatus.failed;
      default:
        return AttemptStatus.failed;
    }
  }
}

class LessonChoice {
  final String key;
  final String text;
  final bool isCorrect; // usually false in attempt start response (security)
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
  final LessonItemType itemType;
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
  final AttemptStatus status;
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
