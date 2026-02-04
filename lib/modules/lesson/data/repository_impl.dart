import '../../../core/types/api_response.dart';
import '../../../core/types/app_error.dart';
import '../domain/entity.dart';
import '../domain/repository.dart';
import 'api.dart';

class LessonRepositoryImpl implements LessonRepository {
  final LessonApi _api;
  LessonRepositoryImpl(this._api);

  T _unwrap<T>(ApiResponse<dynamic> res, T Function(dynamic data) mapper) {
    if (res.status != 'success') {
      throw AppError(
        code: 'API_ERROR',
        message: res.message ?? 'Request failed',
        status: null,
        raw: res.error,
      );
    }
    return mapper(res.data);
  }

  DateTime? _dt(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  LessonChoice _choiceFromMap(Map<String, dynamic> m) {
    return LessonChoice(
      key: (m['key'] ?? '').toString(),
      text: (m['text'] ?? '').toString(),
      isCorrect: (m['is_correct'] is bool) ? (m['is_correct'] as bool) : false,
      sortOrder: (m['sort_order'] is int) ? (m['sort_order'] as int) : int.tryParse('${m['sort_order']}') ?? 0,
    );
  }

  LessonItem _itemFromMap(Map<String, dynamic> m) {
    final rawChoices = (m['choices'] as List?) ?? const [];
    final choices = rawChoices
        .whereType<Map>()
        .map((e) => _choiceFromMap((e as Map).cast<String, dynamic>()))
        .toList(growable: false);

    return LessonItem(
      id: (m['id'] ?? '').toString(),
      lessonId: (m['lesson_id'] ?? '').toString(),
      itemType: (m['item_type'] ?? '').toString(),
      prompt: m['prompt']?.toString(),
      content: (m['content'] is Map) ? (m['content'] as Map).cast<String, dynamic>() : null,
      correctAnswer: (m['correct_answer'] is Map) ? (m['correct_answer'] as Map).cast<String, dynamic>() : null,
      points: (m['points'] is int) ? (m['points'] as int) : int.tryParse('${m['points']}') ?? 1,
      sortOrder: (m['sort_order'] is int) ? (m['sort_order'] as int) : int.tryParse('${m['sort_order']}') ?? 0,
      choices: choices,
    );
  }

  ItemResult _resultFromMap(Map<String, dynamic> m) {
    return ItemResult(
      itemId: (m['item_id'] ?? '').toString(),
      isCorrect: (m['is_correct'] is bool) ? (m['is_correct'] as bool) : false,
      earnedPoints: (m['earned_points'] is int) ? (m['earned_points'] as int) : int.tryParse('${m['earned_points']}') ?? 0,
      maxPoints: (m['max_points'] is int) ? (m['max_points'] as int) : int.tryParse('${m['max_points']}') ?? 0,
      detail: (m['detail'] is Map) ? (m['detail'] as Map).cast<String, dynamic>() : null,
    );
  }

  AttemptOut _attemptOutFromMap(Map<String, dynamic> m) {
    return AttemptOut(
      id: (m['id'] ?? '').toString(),
      userId: (m['user_id'] ?? '').toString(),
      lessonId: (m['lesson_id'] ?? '').toString(),
      status: (m['status'] ?? '').toString(),
      startedAt: _dt(m['started_at']),
      submittedAt: _dt(m['submitted_at']),
      scorePoints: (m['score_points'] is int) ? (m['score_points'] as int) : int.tryParse('${m['score_points']}') ?? 0,
      maxPoints: (m['max_points'] is int) ? (m['max_points'] as int) : int.tryParse('${m['max_points']}') ?? 0,
      scorePercent: (m['score_percent'] is int) ? (m['score_percent'] as int) : int.tryParse('${m['score_percent']}') ?? 0,
      durationSec: (m['duration_sec'] is int) ? (m['duration_sec'] as int) : int.tryParse('${m['duration_sec']}') ?? 0,
      answers: (m['answers'] is Map) ? (m['answers'] as Map).cast<String, dynamic>() : null,
      resultBreakdown: (m['result_breakdown'] is Map) ? (m['result_breakdown'] as Map).cast<String, dynamic>() : null,
    );
  }

  @override
  Future<List<LessonItem>> listItemsByLesson(String lessonId) async {
    final res = await _api.listItemsByLesson(lessonId);
    return _unwrap<List<LessonItem>>(res, (data) {
      final list = (data as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => _itemFromMap((e as Map).cast<String, dynamic>()))
          .toList(growable: false);
    });
  }

  @override
  Future<AttemptStartResponse> startAttempt(String lessonId) async {
    final res = await _api.startAttempt(lessonId);
    return _unwrap<AttemptStartResponse>(res, (data) {
      final m = (data as Map).cast<String, dynamic>();
      final items = (m['items'] as List?) ?? const [];
      return AttemptStartResponse(
        attemptId: (m['attempt_id'] ?? '').toString(),
        lessonId: (m['lesson_id'] ?? lessonId).toString(),
        items: items
            .whereType<Map>()
            .map((e) => _itemFromMap((e as Map).cast<String, dynamic>()))
            .toList(growable: false),
      );
    });
  }

  @override
  Future<AttemptSubmitResponse> submitAttempt({
    required String attemptId,
    required Map<String, dynamic> answers,
    int durationSec = 0,
  }) async {
    final res = await _api.submitAttempt(attemptId: attemptId, answers: answers, durationSec: durationSec);
    return _unwrap<AttemptSubmitResponse>(res, (data) {
      final m = (data as Map).cast<String, dynamic>();
      final results = (m['results'] as List?) ?? const [];
      return AttemptSubmitResponse(
        attemptId: (m['attempt_id'] ?? attemptId).toString(),
        status: (m['status'] ?? '').toString(),
        scorePoints: (m['score_points'] is int) ? (m['score_points'] as int) : int.tryParse('${m['score_points']}') ?? 0,
        maxPoints: (m['max_points'] is int) ? (m['max_points'] as int) : int.tryParse('${m['max_points']}') ?? 0,
        scorePercent: (m['score_percent'] is int) ? (m['score_percent'] as int) : int.tryParse('${m['score_percent']}') ?? 0,
        results: results
            .whereType<Map>()
            .map((e) => _resultFromMap((e as Map).cast<String, dynamic>()))
            .toList(growable: false),
      );
    });
  }

  @override
  Future<AttemptOut> getAttempt(String attemptId) async {
    final res = await _api.getAttempt(attemptId);
    return _unwrap<AttemptOut>(res, (data) => _attemptOutFromMap((data as Map).cast<String, dynamic>()));
  }
}
