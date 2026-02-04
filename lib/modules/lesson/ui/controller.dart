import 'package:flutter/foundation.dart';

import '../../../core/types/app_error.dart';
import '../domain/entity.dart';
import '../domain/usecases.dart';

enum LessonUiPhase {
  preview, // grouped skill tiles
  loading, // generic loading
  practicing, // doing items of a selected type
  submitting, // submitting attempt
  completed, // result screen
  error,
}

class LessonController extends ChangeNotifier {
  final ListItemsByLessonUseCase listItemsByLesson;
  final StartLessonAttemptUseCase startAttempt;
  final SubmitLessonAttemptUseCase submitAttempt;
  final GetAttemptUseCase? getAttempt; // optional future use

  LessonController({
    required this.listItemsByLesson,
    required this.startAttempt,
    required this.submitAttempt,
    this.getAttempt,
  });

  LessonUiPhase _phase = LessonUiPhase.preview;
  LessonUiPhase get phase => _phase;

  String? _error;
  String? get error => _error;

  String? lessonId;

  // Preview data
  List<LessonItem> previewItems = const [];

  // Attempt data
  AttemptStartResponse? attempt;
  AttemptSubmitResponse? result;

  // UX state
  String? activeType;
  List<LessonItem> activeItems = const [];
  int activeIndex = 0;

  // answers[itemId] = {answer, meta}
  final Map<String, Map<String, dynamic>> answers = <String, Map<String, dynamic>>{};
  final Stopwatch _sw = Stopwatch();

  Future<void> init(String lessonId) async {
    this.lessonId = lessonId;
    await loadPreview();
  }

  Future<void> loadPreview() async {
    final id = lessonId;
    if (id == null || id.isEmpty) return;

    _setPhase(LessonUiPhase.loading);
    try {
      previewItems = await listItemsByLesson.call(id);
      // stay in preview until user selects a type
      activeType = null;
      activeItems = const [];
      activeIndex = 0;
      result = null;
      attempt = null;
      answers.clear();
      _sw.reset();
      _setPhase(LessonUiPhase.preview);
    } catch (e) {
      _setError(_friendlyError(e));
    }
  }

  Map<String, List<LessonItem>> groupPreviewByType() {
    final Map<String, List<LessonItem>> map = {};
    for (final it in previewItems) {
      map.putIfAbsent(it.itemType, () => <LessonItem>[]).add(it);
    }
    return map;
  }

  Future<void> startType(String type) async {
    final id = lessonId;
    if (id == null || id.isEmpty) return;

    activeType = type;
    activeIndex = 0;
    activeItems = const [];
    answers.clear();
    result = null;

    _setPhase(LessonUiPhase.loading);

    try {
      attempt = await startAttempt.call(id);

      final items = attempt!.items.where((x) => x.itemType == type).toList(growable: false);
      activeItems = items;

      _sw
        ..reset()
        ..start();

      _setPhase(LessonUiPhase.practicing);
    } catch (e) {
      _setError(_friendlyError(e));
    }
  }

  LessonItem? get currentItem {
    if (_phase != LessonUiPhase.practicing) return null;
    if (activeItems.isEmpty) return null;
    if (activeIndex < 0 || activeIndex >= activeItems.length) return null;
    return activeItems[activeIndex];
  }

  int get totalActive => activeItems.length;

  double get progress {
    if (totalActive == 0) return 0;
    // progress based on position (0..1)
    return (activeIndex / totalActive).clamp(0, 1);
  }

  bool get canCheck {
    final it = currentItem;
    if (it == null) return false;
    final ans = answers[it.id];
    return ans != null && ans.isNotEmpty;
  }

  void setAnswer(String itemId, dynamic answer, {Map<String, dynamic>? meta}) {
    answers[itemId] = <String, dynamic>{
      'answer': answer,
      if (meta != null) 'meta': meta,
    };
    notifyListeners();
  }

  void next() {
    if (_phase != LessonUiPhase.practicing) return;
    if (activeIndex < totalActive - 1) {
      activeIndex += 1;
      notifyListeners();
    } else {
      // reached end of this type -> submit whole attempt answers (only those user answered)
      submitCurrentAttempt();
    }
  }

  void prev() {
    if (_phase != LessonUiPhase.practicing) return;
    if (activeIndex > 0) {
      activeIndex -= 1;
      notifyListeners();
    }
  }

  Future<void> submitCurrentAttempt() async {
    final a = attempt;
    if (a == null) return;

    _setPhase(LessonUiPhase.submitting);

    try {
      _sw.stop();

      final payload = <String, dynamic>{};
      for (final e in answers.entries) {
        payload[e.key] = e.value;
      }

      result = await submitAttempt.call(
        attemptId: a.attemptId,
        answers: payload,
        durationSec: _sw.elapsed.inSeconds,
      );

      _setPhase(LessonUiPhase.completed);
    } catch (e) {
      _setError(_friendlyError(e));
    }
  }

  void backToPreview() {
    activeType = null;
    activeItems = const [];
    activeIndex = 0;
    attempt = null;
    result = null;
    answers.clear();
    _sw.reset();
    _error = null;
    _setPhase(LessonUiPhase.preview);
  }

  void clearError() {
    _error = null;
    if (_phase == LessonUiPhase.error) _setPhase(LessonUiPhase.preview);
    notifyListeners();
  }

  void _setPhase(LessonUiPhase p) {
    _phase = p;
    _error = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _phase = LessonUiPhase.error;
    _error = msg;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    if (e is AppError) return e.message;
    return e.toString().replaceFirst('Exception: ', '');
  }
}
