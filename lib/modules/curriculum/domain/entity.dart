enum LessonType { standard, boss, review }
enum PublishStatus { draft, review, published, archived }

class Language {
  final String id; // UUID as string
  final String code;
  final String name;
  final String? script;

  const Language({
    required this.id,
    required this.code,
    required this.name,
    this.script,
  });
}

class Level {
  final String id; // UUID
  final String languageId; // UUID
  final String code;
  final String name;
  final int sortOrder;

  const Level({
    required this.id,
    required this.languageId,
    required this.code,
    required this.name,
    required this.sortOrder,
  });
}

class Unit {
  final String id; // UUID
  final String languageId; // UUID
  final String? levelId; // UUID?
  final String title;
  final String? description;
  final int sortOrder;

  const Unit({
    required this.id,
    required this.languageId,
    required this.levelId,
    required this.title,
    required this.description,
    required this.sortOrder,
  });
}

class Lesson {
  final String id; // UUID
  final String languageId; // UUID
  final String? unitId; // UUID?
  final String title;
  final String? objective;
  final int estimatedMinutes;
  final LessonType lessonType;
  final PublishStatus publishStatus;
  final int version;
  final String slug;
  final int sortOrder;

  const Lesson({
    required this.id,
    required this.languageId,
    required this.unitId,
    required this.title,
    required this.objective,
    required this.estimatedMinutes,
    required this.lessonType,
    required this.publishStatus,
    required this.version,
    required this.slug,
    required this.sortOrder,
  });
}
class LessonProgress {
  final String lessonId;
  final double progress; // 0..1
  final bool completed;

  LessonProgress({
    required this.lessonId,
    required this.progress,
    required this.completed,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    final p = (json['progress'] ?? 0).toDouble();
    return LessonProgress(
      lessonId: (json['lesson_id'] ?? json['lessonId'] ?? '') as String,
      progress: p.clamp(0.0, 1.0),
      completed: (json['completed'] ?? (p >= 1.0)) as bool,
    );
  }
}
