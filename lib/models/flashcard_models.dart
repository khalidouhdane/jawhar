import 'dart:convert';

// ── Flashcard & Mutashabihat Data Models ──

// ── Enums ──

/// The 6 flashcard types (3 implemented for MVP).
enum FlashcardType {
  nextVerse,         // Show verse → "What comes next?"
  surahDetective,    // Verse without ref → pick the surah
  mutashabihatDuel,  // Two similar verses → pick correct surah
  verseCompletion,   // Partially hidden verse → fill in  (later)
  previousVerse,     // Show verse → "What came before?"   (later)
  connectSequence,   // Reorder scrambled verses            (later)
}

/// How well the user recalled the answer.
enum FlashcardRating {
  strong,  // Instant recall   → interval × 2.5
  ok,      // Recalled w/ effort → interval × 1.5
  weak,    // Struggled          → interval stays
  forgot,  // Couldn't recall   → reset to 1 day
}

/// User's mastery status on a mutashabihat group.
enum MutashabihatStatus {
  notStudied,
  needsPractice,
  mastered,
}

/// Category of mutashabihat difference.
enum MutashabihatCategory {
  wordSwap,
  wordOrder,
  extraWord,
  endingChange,
  pronounChange,
}

// ── Data Classes ──

/// A single flashcard for SRS review.
class Flashcard {
  final String id;
  final FlashcardType type;
  final String profileId;
  final String verseKey;
  final Map<String, dynamic> questionData;
  final Map<String, dynamic> answerData;
  final double interval;
  final double easeFactor;
  final DateTime dueDate;
  final DateTime? lastReviewedAt;
  final int reviewCount;

  const Flashcard({
    required this.id,
    required this.type,
    required this.profileId,
    required this.verseKey,
    required this.questionData,
    required this.answerData,
    this.interval = 1.0,
    this.easeFactor = 2.5,
    required this.dueDate,
    this.lastReviewedAt,
    this.reviewCount = 0,
  });

  Flashcard copyWith({
    double? interval,
    double? easeFactor,
    DateTime? dueDate,
    DateTime? lastReviewedAt,
    int? reviewCount,
  }) => Flashcard(
    id: id, type: type, profileId: profileId, verseKey: verseKey,
    questionData: questionData, answerData: answerData,
    interval: interval ?? this.interval,
    easeFactor: easeFactor ?? this.easeFactor,
    dueDate: dueDate ?? this.dueDate,
    lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    reviewCount: reviewCount ?? this.reviewCount,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.index,
    'profile_id': profileId,
    'verse_key': verseKey,
    'question_data': jsonEncode(questionData),
    'answer_data': jsonEncode(answerData),
    'interval': interval,
    'ease_factor': easeFactor,
    'due_date': dueDate.toIso8601String(),
    'last_reviewed_at': lastReviewedAt?.toIso8601String(),
    'review_count': reviewCount,
  };

  factory Flashcard.fromMap(Map<String, dynamic> m) => Flashcard(
    id: m['id'],
    type: FlashcardType.values[m['type']],
    profileId: m['profile_id'],
    verseKey: m['verse_key'],
    questionData: jsonDecode(m['question_data'] ?? '{}'),
    answerData: jsonDecode(m['answer_data'] ?? '{}'),
    interval: (m['interval'] as num).toDouble(),
    easeFactor: (m['ease_factor'] as num).toDouble(),
    dueDate: DateTime.parse(m['due_date']),
    lastReviewedAt: m['last_reviewed_at'] != null
        ? DateTime.parse(m['last_reviewed_at']) : null,
    reviewCount: m['review_count'] ?? 0,
  );
}

/// A single review event for analytics.
class FlashcardReview {
  final String id;
  final String cardId;
  final FlashcardRating rating;
  final DateTime reviewedAt;

  const FlashcardReview({
    required this.id,
    required this.cardId,
    required this.rating,
    required this.reviewedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'card_id': cardId,
    'rating': rating.index,
    'reviewed_at': reviewedAt.toIso8601String(),
  };

  factory FlashcardReview.fromMap(Map<String, dynamic> m) => FlashcardReview(
    id: m['id'],
    cardId: m['card_id'],
    rating: FlashcardRating.values[m['rating']],
    reviewedAt: DateTime.parse(m['reviewed_at']),
  );
}

/// A group of mutashabihat (similar verse pairs).
class MutashabihatGroup {
  final String groupId;
  final String sourceVerseKey;
  final String sourceText;
  final List<MutashabihatVerse> similarVerses;
  final Map<String, List<String>> uniqueWords;
  final MutashabihatCategory category;
  final String difficulty;
  final bool needsContext;
  final MutashabihatStatus userStatus;

  const MutashabihatGroup({
    required this.groupId,
    required this.sourceVerseKey,
    required this.sourceText,
    required this.similarVerses,
    required this.uniqueWords,
    required this.category,
    this.difficulty = 'medium',
    this.needsContext = false,
    this.userStatus = MutashabihatStatus.notStudied,
  });

  MutashabihatGroup copyWith({MutashabihatStatus? userStatus}) =>
      MutashabihatGroup(
        groupId: groupId, sourceVerseKey: sourceVerseKey,
        sourceText: sourceText, similarVerses: similarVerses,
        uniqueWords: uniqueWords, category: category,
        difficulty: difficulty, needsContext: needsContext,
        userStatus: userStatus ?? this.userStatus,
      );

  Map<String, dynamic> toMap() => {
    'group_id': groupId,
    'source_verse_key': sourceVerseKey,
    'source_text': sourceText,
    'similar_verses': jsonEncode(similarVerses.map((v) => v.toMap()).toList()),
    'unique_words': jsonEncode(uniqueWords),
    'category': category.index,
    'difficulty': difficulty,
    'needs_context': needsContext ? 1 : 0,
    'user_status': userStatus.index,
  };

  factory MutashabihatGroup.fromMap(Map<String, dynamic> m) {
    final similars = jsonDecode(m['similar_verses'] ?? '[]') as List;
    final wordsRaw = jsonDecode(m['unique_words'] ?? '{}') as Map<String, dynamic>;
    return MutashabihatGroup(
      groupId: m['group_id'],
      sourceVerseKey: m['source_verse_key'],
      sourceText: m['source_text'] ?? '',
      similarVerses: similars
          .map((s) => MutashabihatVerse.fromMap(Map<String, dynamic>.from(s)))
          .toList(),
      uniqueWords: wordsRaw.map((k, v) =>
          MapEntry(k, (v as List).map((e) => e.toString()).toList())),
      category: MutashabihatCategory.values[(m['category'] ?? 0) as int],
      difficulty: m['difficulty'] ?? 'medium',
      needsContext: m['needs_context'] == 1,
      userStatus: MutashabihatStatus.values[(m['user_status'] ?? 0) as int],
    );
  }
}

/// A single similar verse within a mutashabihat group.
class MutashabihatVerse {
  final String verseKey;
  final String text;

  const MutashabihatVerse({required this.verseKey, required this.text});

  Map<String, dynamic> toMap() => {'verse_key': verseKey, 'text': text};

  factory MutashabihatVerse.fromMap(Map<String, dynamic> m) =>
      MutashabihatVerse(verseKey: m['verse_key'] ?? '', text: m['text'] ?? '');
}
