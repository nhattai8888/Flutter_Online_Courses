import 'package:flutter/foundation.dart';

import '../../../core/types/app_error.dart';
import '../domain/entity.dart';
import '../domain/usecases.dart';

enum VocabularyStatus { idle, loading, ready, error }

class VocabularyController extends ChangeNotifier {
  final ListLexemesUseCase listLexemes;
  final GetLexemeUseCase getLexeme;
  final ListSensesByLexemeUseCase listSensesByLexeme;
  final ListExamplesBySenseUseCase listExamplesBySense;
  final GetReviewTodayUseCase getReviewToday;
  final SubmitReviewResultUseCase submitReviewResult;
  final GetWeakWordsUseCase getWeakWords;

  VocabularyController({
    required this.listLexemes,
    required this.getLexeme,
    required this.listSensesByLexeme,
    required this.listExamplesBySense,
    required this.getReviewToday,
    required this.submitReviewResult,
    required this.getWeakWords,
  });

  VocabularyStatus _status = VocabularyStatus.idle;
  VocabularyStatus get status => _status;

  String? _error;
  String? get error => _error;

  // UI state
  String? languageId; // required to list lexemes
  String query = '';

  List<Lexeme> items = const [];
  bool loadingMore = false;
  bool hasMore = true;
  int limit = 50;
  int offset = 0;

  // Detail
  Lexeme? selectedLexeme;
  List<Sense> senses = const [];
  final Map<String, List<ExampleSentence>> examplesBySenseId = <String, List<ExampleSentence>>{};

  // Gamification tabs
  ReviewTodayResponse? reviewToday;
  List<WeakWord> weakWords = const [];

  Future<void> init({required String languageId}) async {
    this.languageId = languageId;
    await refresh();
    await preloadSidePanels();
  }

  Future<void> refresh() async {
    final lang = languageId;
    if (lang == null || lang.isEmpty) return;

    _setLoading();
    try {
      offset = 0;
      hasMore = true;
      items = await listLexemes.call(languageId: lang, q: query, limit: limit, offset: offset);
      offset += items.length;
      hasMore = items.length == limit;
      _setReady();
    } catch (e) {
      _setError(_friendlyError(e));
    }
  }

  Future<void> loadMore() async {
    final lang = languageId;
    if (lang == null || lang.isEmpty) return;
    if (!hasMore || loadingMore) return;

    loadingMore = true;
    notifyListeners();

    try {
      final page = await listLexemes.call(languageId: lang, q: query, limit: limit, offset: offset);
      items = [...items, ...page];
      offset += page.length;
      hasMore = page.length == limit;
    } catch (e) {
      _setError(_friendlyError(e));
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> setQuery(String q) async {
    query = q.trim();
    await refresh();
  }

  Future<void> openLexeme(String lexemeId) async {
    _setLoading();
    try {
      selectedLexeme = await getLexeme.call(lexemeId);
      senses = await listSensesByLexeme.call(lexemeId);
      examplesBySenseId.clear();

      // Load examples for first 2 senses to keep it fast
      for (int i = 0; i < senses.length && i < 2; i++) {
        final s = senses[i];
        final ex = await listExamplesBySense.call(senseId: s.id, limit: 20);
        examplesBySenseId[s.id] = ex;
      }

      _setReady();
    } catch (e) {
      _setError(_friendlyError(e));
    }
  }

  Future<void> loadExamplesForSense(String senseId) async {
    if (examplesBySenseId.containsKey(senseId)) return;
    try {
      final ex = await listExamplesBySense.call(senseId: senseId, limit: 20);
      examplesBySenseId[senseId] = ex;
      notifyListeners();
    } catch (e) {
      _setError(_friendlyError(e));
    }
  }

  Future<void> preloadSidePanels() async {
    try {
      // These are optional panels; don't block main.
      reviewToday = await getReviewToday.call();
      weakWords = await getWeakWords.call(limit: 50);
      notifyListeners();
    } catch (_) {
      // ignore - keep UI usable
    }
  }

  Future<void> rateReviewCard({
    required String lexemeId,
    required int rating,
    String source = 'QUIZ',
  }) async {
    try {
      await submitReviewResult.call(lexemeId: lexemeId, rating: rating, source: source);
      await preloadSidePanels();
    } catch (e) {
      _setError(_friendlyError(e));
    }
  }

  void clearError() {
    _error = null;
    if (_status == VocabularyStatus.error) _status = VocabularyStatus.ready;
    notifyListeners();
  }

  void _setLoading() {
    _status = VocabularyStatus.loading;
    _error = null;
    notifyListeners();
  }

  void _setReady() {
    _status = VocabularyStatus.ready;
    _error = null;
    notifyListeners();
  }

  void _setError(String msg) {
    _status = VocabularyStatus.error;
    _error = msg;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    if (e is AppError) return e.message;
    return e.toString().replaceFirst('Exception: ', '');
  }
}
