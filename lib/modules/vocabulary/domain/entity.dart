enum LexemeType { noun, verb, adj, adv, prep, phrase, other }

LexemeType lexemeTypeFromString(String v) {
  switch (v) {
    case 'NOUN':
      return LexemeType.noun;
    case 'VERB':
      return LexemeType.verb;
    case 'ADJ':
      return LexemeType.adj;
    case 'ADV':
      return LexemeType.adv;
    case 'PREP':
      return LexemeType.prep;
    case 'PHRASE':
      return LexemeType.phrase;
    default:
      return LexemeType.other;
  }
}

String lexemeTypeToString(LexemeType t) {
  switch (t) {
    case LexemeType.noun:
      return 'NOUN';
    case LexemeType.verb:
      return 'VERB';
    case LexemeType.adj:
      return 'ADJ';
    case LexemeType.adv:
      return 'ADV';
    case LexemeType.prep:
      return 'PREP';
    case LexemeType.phrase:
      return 'PHRASE';
    case LexemeType.other:
      return 'OTHER';
  }
}

class Lexeme {
  final String id;
  final String languageId;
  final LexemeType type;
  final String lemma;
  final String? phonetic;
  final String? audioUrl;
  final int difficulty;
  final Map<String, dynamic>? tags;

  const Lexeme({
    required this.id,
    required this.languageId,
    required this.type,
    required this.lemma,
    required this.phonetic,
    required this.audioUrl,
    required this.difficulty,
    required this.tags,
  });
}

class Sense {
  final String id;
  final String lexemeId;
  final int senseIndex;
  final String definition;
  final String domain; // DAILY/ACADEMIC/...
  final String? cefrLevel;
  final Map<String, dynamic>? translations;
  final Map<String, dynamic>? collocations;
  final String status; // DRAFT/REVIEW/PUBLISHED...

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

  const ExampleSentence({
    required this.id,
    required this.senseId,
    required this.sentence,
    required this.translation,
    required this.audioUrl,
    required this.difficulty,
    required this.tags,
  });
}

class ReviewCard {
  final Lexeme lexeme;
  final List<Sense> senses;
  final List<ExampleSentence> examples;
  final Map<String, dynamic> state;

  const ReviewCard({
    required this.lexeme,
    required this.senses,
    required this.examples,
    required this.state,
  });
}
