import '../../../core/types/app_error.dart';
import '../domain/entity.dart';
import '../domain/repository.dart';
import 'api.dart';

class LessonRepositoryImpl implements LessonRepository {
  final LessonApi api;
  LessonRepositoryImpl(this.api);

  Map<String, dynamic> _unwrapEnvelope(Map<String, dynamic> json) {
    // Support BOTH shapes:
    // A) {status:"success", data:..., message, error}
    // B) {code:200, data:..., message}
    if (json.containsKey('status')) {
      final status = (json['status'] as String?) ?? 'error';
      if (status != 'success') {
        throw AppError(
          code: 'API_ERROR',
          message: (json['message'] as String?) ?? 'Request failed',
          status: null,
          raw: json['error'],
        );
      }
      final data = json['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return data.cast<String, dynamic>();
      if (data == null) return <String, dynamic>{};
      return <String, dynamic>{'data': data};
    }

    final code = json['code'];
    if (code is int && code >= 200 && code < 300) {
      final data = json['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return data.cast<String, dynamic>();
      if (data == null) return <String, dynamic>{};
      return <String, dynamic>{'data': data};
    }

    throw AppError(
      code: 'API_ERROR',
      message: (json['message'] as String?) ?? 'Request failed',
      status: code is int ? code : null,
      raw: json,
    );
  }

  LessonChoice _mapChoice(Map<String, dynamic> m) {
    return LessonChoice(
      key: (m['key'] ?? '').toString(),
      text: (m['text'] ?? '').toString(),
      isCorrect: (m['is_correct'] as bool?) ?? false,
      sortOrder: (m['sort_order'] as int?) ?? 0,
    );
  }

  LessonItem _mapItem(Map<String, dynamic> m) {
    final id = (m['id'] ?? '').toString();
    final lessonId = (m['lesson_id'] ?? '').toString();
    final typeRaw = (m['item_type'] ?? '').toString();

    final choicesAny = m['choices'];
    final choices = <LessonChoice>[];
    if (choicesAny is List) {
      for (final c in choicesAny) {
        if (c is Map) choices.add(_mapChoice(c.cast<String, dynamic>()));
      }
      choices.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    Map<String, dynamic>? content;
    final contentAny = m['content'];
    if (contentAny is Map) content = contentAny.cast<String, dynamic>();

    Map<String, dynamic>? correct;
    final correctAny = m['correct_answer'];
    if (correctAny is Map) correct = correctAny.cast<String, dynamic>();

    return LessonItem(
      id: id,
      lessonId: lessonId,
      itemType: LessonItemType.fromApi(typeRaw),
      prompt: (m['prompt'] as String?),
      content: content,
      correctAnswer: correct,
      points: (m['points'] as int?) ?? 1,
      sortOrder: (m['sort_order'] as int?) ?? 0,
      choices: choices,
    );
  }

  @override
  Future<List<LessonItem>> listItemsByLesson(String lessonId) async {
    final json = await api.getItemsByLesson(lessonId);
    final data = _unwrapEnvelope(json);

    // expected: {items: [...] } OR directly a list
    final itemsAny = data['items'] ?? data['data'] ?? data['results'] ?? data;
    final list = <LessonItem>[];

    if (itemsAny is List) {
      for (final x in itemsAny) {
        if (x is Map) list.add(_mapItem(x.cast<String, dynamic>()));
      }
    } else if (itemsAny is Map && itemsAny['items'] is List) {
      for (final x in (itemsAny['items'] as List)) {
        if (x is Map) list.add(_mapItem(x.cast<String, dynamic>()));
      }
    }

    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  @override
  Future<AttemptStartResponse> startLessonAttempt(String lessonId) async {
    final json = await api.startAttempt(lessonId);
    final data = _unwrapEnvelope(json);

    final attemptId = (data['attempt_id'] ?? '').toString();
    final lId = (data['lesson_id'] ?? lessonId).toString();

    final itemsAny = data['items'];
    final items = <LessonItem>[];
    if (itemsAny is List) {
      for (final x in itemsAny) {
        if (x is Map) items.add(_mapItem(x.cast<String, dynamic>()));
      }
    }
    items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return AttemptStartResponse(
      attemptId: attemptId,
      lessonId: lId,
      items: items,
    );
  }

  @override
  Future<AttemptSubmitResponse> submitLessonAttempt({
    required String lessonId,
    required String attemptId,
    required Map<String, dynamic> answers,
    required int durationSec,
  }) async {
    final json = await api.submitAttempt(
  lessonId: lessonId,
  attemptId: attemptId,
  answers: answers,
  durationSec: durationSec,
);

    final data = _unwrapEnvelope(json);

    final status = AttemptStatus.fromApi((data['status'] ?? 'FAILED').toString());
    final scorePoints = (data['score_points'] as int?) ?? 0;
    final maxPoints = (data['max_points'] as int?) ?? 0;
    final scorePercent = (data['score_percent'] as int?) ?? 0;

    final resultsAny = data['results'];
    final results = <ItemResult>[];
    if (resultsAny is List) {
      for (final r in resultsAny) {
        if (r is! Map) continue;
        final m = r.cast<String, dynamic>();
        Map<String, dynamic>? detail;
        final d = m['detail'];
        if (d is Map) detail = d.cast<String, dynamic>();

        results.add(ItemResult(
          itemId: (m['item_id'] ?? '').toString(),
          isCorrect: (m['is_correct'] as bool?) ?? false,
          earnedPoints: (m['earned_points'] as int?) ?? 0,
          maxPoints: (m['max_points'] as int?) ?? 0,
          detail: detail,
        ));
      }
    }

    return AttemptSubmitResponse(
      attemptId: attemptId,
      status: status,
      scorePoints: scorePoints,
      maxPoints: maxPoints,
      scorePercent: scorePercent,
      results: results,
    );
  }
}
