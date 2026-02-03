class Lexeme {
  final String id;
  final String languageId;
  final String type; // NOUN | VERB | ...
  final String lemma;
  final String? phoenic;
  final String? audioUrl;
  final int difficulty; // 1..10
  final Map<String, dynamic>? tags;
  final String status; // EntityStatus
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Lexeme({
    required this.id,
    required this.languageId,
    required this.type,
    required this.lemma,
    required this.phoenic,
    required this.audioUrl,
    required this.difficulty,
    required this.tags,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
}

class Sense {
  final String id;
  final String lexemeId;
  final int senseIndex;
  final String definition;
  final String domain; // DAILY | ACADEMIC | ...
  final String? cefrLevel;
  final Map<String, dynamic>? translations;
  final Map<String, dynamic>? collocations;
  final String status; // PublishStatus
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Sense({
    required this.id,
    required this.lexemeId,
    required this.senseIndex,
    required this.definition,
    required this.domain,
    required this.cefrLevel,
    required this.translations,
    required this.collocations,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
}

class ExampleSentence {
  final String id;
  final String senseId;
  final String sentence;
  final Map<String, dynamic>? translation;
  final String? audioUrl;
  final int difficulty;
  final Map<String, dynamic>? tags;
  final DateTime? createdAt;

  const ExampleSentence({
    required this.id,
    required this.senseId,
    required this.sentence,
    required this.translation,
    required this.audioUrl,
    required this.difficulty,
    required this.tags,
    required this.createdAt,
  });
}

class WeakWord {
  final String lexemeId;
  final String lemma;
  final String type; // LexemeType
  final String severity; // GOOD | OK | BAD
  final String errorType; // WordErrorType
  final int occurCount;
  final DateTime? lastOccurredAt;
  final Map<String, dynamic>? evidence;

  const WeakWord({
    required this.lexemeId,
    required this.lemma,
    required this.type,
    required this.severity,
    required this.errorType,
    required this.occurCount,
    required this.lastOccurredAt,
    required this.evidence,
  });
}

class ReviewCard {
  final Lexeme lexeme;
  final List<Sense> senses;
  final List<ExampleSentence> examples;
  final Map<String, dynamic>? state;

  const ReviewCard({
    required this.lexeme,
    required this.senses,
    required this.examples,
    required this.state,
  });
}

class ReviewTodayResponse {
  final List<ReviewCard> items;
  final int total;

  const ReviewTodayResponse({
    required this.items,
    required this.total,
  });
}
