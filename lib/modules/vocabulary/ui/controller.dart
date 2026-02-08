import 'package:flutter/foundation.dart';
import '../domain/entity.dart';
import '../domain/usecases.dart';

enum VocabularyStatus { idle, loading, ready, error }

class VocabularyController extends ChangeNotifier {
  final ListLexemesByLessonUseCase listLexemesByLesson;
  final GetLexemeUseCase getLexeme;
  final ListSensesByLexemeUseCase listSensesByLexeme;
  final ListExamplesBySenseUseCase listExamplesBySense;

  VocabularyController({
    required this.listLexemesByLesson,
    required this.getLexeme,
    required this.listSensesByLexeme,
    required this.listExamplesBySense,
  });

  VocabularyStatus status = VocabularyStatus.idle;
  String? error;

  String? lessonId;
  String? lexemeId;

  List<Lexeme> lexemes = const [];
  Lexeme? selectedLexeme;
  List<Sense> senses = const [];
  List<ExampleSentence> examples = const [];
  String? expandedSenseId;

  Future<void> init({String? lessonId, String? lexemeId}) async {
    this.lessonId = lessonId;
    this.lexemeId = lexemeId;

    if (lexemeId != null) {
      await loadLexemeDetail(lexemeId);
      return;
    }

    if (lessonId != null) {
      await loadLexemesByLesson(lessonId);
      return;
    }

    status = VocabularyStatus.error;
    error = 'Missing lessonId or lexemeId';
    notifyListeners();
  }

  Future<void> loadLexemesByLesson(String lessonId) async {
    status = VocabularyStatus.loading;
    error = null;
    notifyListeners();

    try {
      final list = await listLexemesByLesson(lessonId: lessonId);
      lexemes = list;
      status = VocabularyStatus.ready;
      notifyListeners();

      if (lexemes.isNotEmpty) {
        await selectLexeme(lexemes.first);
      }
    } catch (e) {
      status = VocabularyStatus.error;
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> selectLexeme(Lexeme l) async {
    selectedLexeme = l;
    senses = const [];
    examples = const [];
    expandedSenseId = null;
    notifyListeners();

    await loadSenses(l.id);
  }

  Future<void> loadLexemeDetail(String lexemeId) async {
    status = VocabularyStatus.loading;
    error = null;
    notifyListeners();

    try {
      selectedLexeme = await getLexeme(lexemeId: lexemeId);
      status = VocabularyStatus.ready;
      notifyListeners();

      await loadSenses(lexemeId);
    } catch (e) {
      status = VocabularyStatus.error;
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadSenses(String lexemeId) async {
    try {
      senses = await listSensesByLexeme(lexemeId: lexemeId);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleSenseExamples(Sense s) async {
    if (expandedSenseId == s.id) {
      expandedSenseId = null;
      examples = const [];
      notifyListeners();
      return;
    }

    expandedSenseId = s.id;
    examples = const [];
    notifyListeners();

    try {
      examples = await listExamplesBySense(senseId: s.id, limit: 20);
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
