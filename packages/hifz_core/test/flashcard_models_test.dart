import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

void main() {
  group('Flashcard', () {
    final card = Flashcard(
      id: 'card-1',
      type: FlashcardType.surahDetective,
      profileId: 'p1',
      verseKey: '2:255',
      questionData: const {'text': 'Which surah?'},
      answerData: const {'surah': 2},
      interval: 4.5,
      easeFactor: 2.1,
      dueDate: DateTime(2026, 6, 12),
      lastReviewedAt: DateTime.utc(2026, 6, 10, 19, 30),
      reviewCount: 7,
    );

    test('toMap/fromMap round-trips including the JSON blobs', () {
      final restored = Flashcard.fromMap(card.toMap());
      expect(restored.id, 'card-1');
      expect(restored.type, FlashcardType.surahDetective);
      expect(restored.profileId, 'p1');
      expect(restored.verseKey, '2:255');
      expect(restored.questionData, {'text': 'Which surah?'});
      expect(restored.answerData, {'surah': 2});
      expect(restored.interval, 4.5);
      expect(restored.easeFactor, 2.1);
      expect(restored.dueDate, DateTime(2026, 6, 12));
      expect(restored.lastReviewedAt, DateTime.utc(2026, 6, 10, 19, 30));
      expect(restored.reviewCount, 7);
    });

    test('fromMap applies SRS defaults for a sparse row', () {
      final restored = Flashcard.fromMap(<String, dynamic>{
        'id': 'card-2',
        'profile_id': 'p1',
        'verse_key': '3:21',
        'due_date': '2026-06-10T00:00:00.000',
        'type': 99,
      });
      expect(restored.type, FlashcardType.nextVerse, reason: 'enum fallback');
      expect(restored.questionData, isEmpty);
      expect(restored.answerData, isEmpty);
      expect(restored.interval, 1.0);
      expect(restored.easeFactor, 2.5);
      expect(restored.lastReviewedAt, isNull);
      expect(restored.reviewCount, 0);
    });

    test('copyWith replaces only the SRS state fields', () {
      final updated = card.copyWith(
        interval: 11.25,
        easeFactor: 2.2,
        dueDate: DateTime(2026, 6, 23),
        lastReviewedAt: DateTime.utc(2026, 6, 11),
        reviewCount: 8,
      );
      expect(updated.id, card.id);
      expect(updated.type, card.type);
      expect(updated.questionData, card.questionData);
      expect(updated.interval, 11.25);
      expect(updated.easeFactor, 2.2);
      expect(updated.dueDate, DateTime(2026, 6, 23));
      expect(updated.reviewCount, 8);

      final untouched = card.copyWith();
      expect(untouched.interval, card.interval);
      expect(untouched.dueDate, card.dueDate);
    });
  });

  group('FlashcardReview', () {
    test('toMap/fromMap round-trips', () {
      final review = FlashcardReview(
        id: 'rev-1',
        cardId: 'card-1',
        rating: FlashcardRating.weak,
        reviewedAt: DateTime.utc(2026, 6, 10, 20),
      );
      final restored = FlashcardReview.fromMap(review.toMap());
      expect(restored.id, 'rev-1');
      expect(restored.cardId, 'card-1');
      expect(restored.rating, FlashcardRating.weak);
      expect(restored.reviewedAt, DateTime.utc(2026, 6, 10, 20));
    });

    test('fromMap falls back to strong for out-of-range ratings', () {
      final restored = FlashcardReview.fromMap(<String, dynamic>{
        'id': 'rev-2',
        'card_id': 'card-1',
        'rating': 99,
        'reviewed_at': '2026-06-10T20:00:00.000Z',
      });
      expect(restored.rating, FlashcardRating.strong);
    });
  });

  group('MutashabihatGroup', () {
    const group = MutashabihatGroup(
      groupId: 'g1',
      sourceVerseKey: '2:48',
      sourceText: 'source text',
      similarVerses: [
        MutashabihatVerse(verseKey: '2:123', text: 'similar text'),
      ],
      uniqueWords: {
        '2:48': ['word_a'],
        '2:123': ['word_b', 'word_c'],
      },
      category: MutashabihatCategory.wordOrder,
      difficulty: 'hard',
      needsContext: true,
      userStatus: MutashabihatStatus.needsPractice,
    );

    test('toMap/fromMap round-trips nested verses and unique words', () {
      final restored = MutashabihatGroup.fromMap(group.toMap());
      expect(restored.groupId, 'g1');
      expect(restored.sourceVerseKey, '2:48');
      expect(restored.sourceText, 'source text');
      expect(restored.similarVerses, hasLength(1));
      expect(restored.similarVerses.single.verseKey, '2:123');
      expect(restored.similarVerses.single.text, 'similar text');
      expect(restored.uniqueWords, {
        '2:48': ['word_a'],
        '2:123': ['word_b', 'word_c'],
      });
      expect(restored.category, MutashabihatCategory.wordOrder);
      expect(restored.difficulty, 'hard');
      expect(restored.needsContext, isTrue);
      expect(restored.userStatus, MutashabihatStatus.needsPractice);
    });

    test('fromMap applies defaults for a sparse row', () {
      final restored = MutashabihatGroup.fromMap(<String, dynamic>{
        'group_id': 'g2',
        'source_verse_key': '3:7',
      });
      expect(restored.sourceText, '');
      expect(restored.similarVerses, isEmpty);
      expect(restored.uniqueWords, isEmpty);
      expect(restored.category, MutashabihatCategory.wordSwap);
      expect(restored.difficulty, 'medium');
      expect(restored.needsContext, isFalse);
      expect(restored.userStatus, MutashabihatStatus.notStudied);
    });

    test('copyWith only changes the user status', () {
      final mastered = group.copyWith(userStatus: MutashabihatStatus.mastered);
      expect(mastered.userStatus, MutashabihatStatus.mastered);
      expect(mastered.groupId, group.groupId);
      expect(mastered.similarVerses, group.similarVerses);
      expect(group.copyWith().userStatus, MutashabihatStatus.needsPractice);
    });
  });

  group('MutashabihatVerse', () {
    test('round-trips and tolerates missing fields', () {
      const verse = MutashabihatVerse(verseKey: '2:5', text: 'text');
      final restored = MutashabihatVerse.fromMap(verse.toMap());
      expect(restored.verseKey, '2:5');
      expect(restored.text, 'text');

      final empty = MutashabihatVerse.fromMap(<String, dynamic>{});
      expect(empty.verseKey, '');
      expect(empty.text, '');
    });
  });
}
