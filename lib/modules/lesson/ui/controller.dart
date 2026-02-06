import 'package:flutter/foundation.dart';

import '../../../core/types/app_error.dart';
import '../domain/entity.dart';
import '../domain/usecases.dart';

enum LessonMvpPhase {
  loadingPreview,
  preview,
  loadingAttempt,
  practicing,
  submitting,
  completed, // final or optimistic
  error,
}

enum CheckState {
  idle,
  checked,
}

class LessonController extends ChangeNotifier {
  final ListItemsByLessonUseCase listItemsByLesson;
  final StartLessonAttemptUseCase startAttempt;
  final SubmitLessonAttemptUseCase submitAttempt;

  LessonController({
    required this.listItemsByLesson,
    required this.startAttempt,
    required this.submitAttempt,
  });

  LessonMvpPhase _phase = LessonMvpPhase.loadingPreview;
  LessonMvpPhase get phase => _phase;

  String? _error;
  String? get error => _error;

  String lessonId = '';

  // Preview items (counts/type tiles)
  List<LessonItem> previewItems = const [];

  // Attempt (single attempt for whole lesson)
  AttemptStartResponse? attempt;

  // Practice selection
  LessonItemType? activeType;
  List<LessonItem> activeItems = const [];
  int activeIndex = 0;

  // per item state
  CheckState checkState = CheckState.idle;

  // answers[item_id] = {answer, meta}
  final Map<String, Map<String, dynamic>> answers = {};

  // Type completion
  final Set<LessonItemType> completedTypes = <LessonItemType>{};

  // Submit result
  AttemptSubmitResponse? submitResult;

  // Optimistic submit UI state
  bool isOptimisticSubmitting = false;
  String? optimisticMessage; // e.g. "Đang chấm điểm…"
  String? optimisticError;   // show retry

  final Stopwatch _sw = Stopwatch();

  Future<void> init(String lessonId) async {
    this.lessonId = lessonId;
    await loadPreview();
  }

  Future<void> loadPreview() async {
    _setPhase(LessonMvpPhase.loadingPreview);
    try {
      previewItems = await listItemsByLesson.call(lessonId);
      previewItems = List<LessonItem>.from(previewItems)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      attempt = null;
      activeType = null;
      activeItems = const [];
      activeIndex = 0;
      checkState = CheckState.idle;
      answers.clear();
      completedTypes.clear();

      submitResult = null;
      isOptimisticSubmitting = false;
      optimisticMessage = null;
      optimisticError = null;

      _sw.reset();
      _setPhase(LessonMvpPhase.preview);
    } catch (e) {
      _setError(_friendlyError(e));
    }
  }

  Map<LessonItemType, List<LessonItem>> groupPreviewByType() {
    final Map<LessonItemType, List<LessonItem>> map = {};
    for (final it in previewItems) {
      map.putIfAbsent(it.itemType, () => <LessonItem>[]).add(it);
    }
    for (final e in map.entries) {
      e.value.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return map;
  }

  bool get hasAttempt => attempt != null;

  Future<void> _ensureAttemptStarted() async {
    if (attempt != null) return;

    _setPhase(LessonMvpPhase.loadingAttempt);
    try {
      final res = await startAttempt.call(lessonId);
      attempt = AttemptStartResponse(
        attemptId: res.attemptId,
        lessonId: res.lessonId,
        items: List<LessonItem>.from(res.items)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );

      _sw
        ..reset()
        ..start();

      _setPhase(LessonMvpPhase.preview);
    } catch (e) {
      _setError(_friendlyError(e));
    }
  }

  Future<void> startType(LessonItemType type) async {
    await _ensureAttemptStarted();
    if (attempt == null) return;

    activeType = type;
    activeIndex = 0;
    checkState = CheckState.idle;

    final items = attempt!.items.where((x) => x.itemType == type).toList(growable: false);
    activeItems = items;

    _setPhase(LessonMvpPhase.practicing);
  }

  LessonItem? get currentItem {
    if (_phase != LessonMvpPhase.practicing) return null;
    if (activeItems.isEmpty) return null;
    if (activeIndex < 0 || activeIndex >= activeItems.length) return null;
    return activeItems[activeIndex];
  }

  double get activeProgress {
    if (activeItems.isEmpty) return 0;
    return ((activeIndex + 1) / activeItems.length).clamp(0, 1);
  }

  bool get canCheck {
    final it = currentItem;
    if (it == null) return false;
    final v = answers[it.id];
    return v != null && v.isNotEmpty && checkState == CheckState.idle;
  }

  bool get canContinue => checkState == CheckState.checked;

  void setAnswer(String itemId, dynamic answer, {Map<String, dynamic>? meta}) {
    // Backend expects: answers: Dict[item_id] -> {answer, meta}
    answers[itemId] = <String, dynamic>{
      'answer': answer,
      if (meta != null) 'meta': meta,
    };
    notifyListeners();
  }

  Map<String, dynamic>? getAnswerEntry(String itemId) => answers[itemId];

  void markItemSkipped(String itemId, {String? reason}) {
    answers[itemId] = <String, dynamic>{
      'answer': null,
      'meta': <String, dynamic>{
        'skipped': true,
        if (reason != null) 'reason': reason,
      },
    };
    notifyListeners();
  }

  void onCheck() {
    if (!canCheck) return;
    checkState = CheckState.checked;
    notifyListeners();
  }

  void onContinue() {
    if (!canContinue) return;

    checkState = CheckState.idle;

    if (activeIndex < activeItems.length - 1) {
      activeIndex += 1;
      notifyListeners();
      return;
    }

    final t = activeType;
    if (t != null) completedTypes.add(t);

    activeType = null;
    activeItems = const [];
    activeIndex = 0;

    _setPhase(LessonMvpPhase.preview);
  }

  void backToPreview() {
    activeType = null;
    activeItems = const [];
    activeIndex = 0;
    checkState = CheckState.idle;
    _setPhase(LessonMvpPhase.preview);
  }

  bool get allTypesCompleted {
    final grouped = groupPreviewByType();
    if (grouped.isEmpty) return false;
    final types = grouped.keys.toSet();
    return completedTypes.containsAll(types);
  }

  Future<void> submitWholeLessonOptimistic() async {
    final a = attempt;
    if (a == null) return;

    // optimistic UI: show Completed screen immediately with spinner
    isOptimisticSubmitting = true;
    optimisticMessage = 'Đang chấm điểm…';
    optimisticError = null;
    submitResult = null;
    _phase = LessonMvpPhase.completed;
    notifyListeners();

    try {
      _sw.stop();

      // Ensure every item has an entry (allow skipped)
      for (final it in a.items) {
        answers.putIfAbsent(
          it.id,
          () => <String, dynamic>{
            'answer': null,
            'meta': <String, dynamic>{'skipped': true},
          },
        );
      }

      final payload = <String, dynamic>{};
      for (final e in answers.entries) {
        payload[e.key] = e.value;
      }

      // IMPORTANT: Backend schema
      // AttemptSubmitRequest: { answers: Dict[str, AnswerPayload], duration_sec: int }
      final res = await submitAttempt.call(
        lessonId: lessonId,
        attemptId: a.attemptId,
        answers: payload,
        durationSec: _sw.elapsed.inSeconds,
      );

      submitResult = res;
      isOptimisticSubmitting = false;
      optimisticMessage = null;
      optimisticError = null;
      notifyListeners();
    } catch (e) {
      isOptimisticSubmitting = false;
      optimisticMessage = null;
      optimisticError = _friendlyError(e);
      notifyListeners();
    }
  }

  Future<void> retrySubmit() async {
    if (attempt == null) return;
    await submitWholeLessonOptimistic();
  }

  void _setPhase(LessonMvpPhase p) {
    _phase = p;
    _error = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _phase = LessonMvpPhase.error;
    _error = msg;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    if (e is AppError) return e.message;
    return e.toString().replaceFirst('Exception: ', '');
  }
}
