import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

void main() {
  Flashcard card({double interval = 2, double ease = 2.5}) => Flashcard(
    id: 'card',
    type: FlashcardType.nextVerse,
    profileId: 'profile',
    verseKey: '2:255',
    questionData: const {},
    answerData: const {},
    interval: interval,
    easeFactor: ease,
    dueDate: DateTime(2026, 1, 1),
  );

  test('strong review advances interval and stores a UTC review timestamp', () {
    final updated = SrsEngine.processReview(card(), FlashcardRating.strong);

    expect(updated.interval, 5);
    expect(updated.easeFactor, 2.6);
    expect(updated.reviewCount, 1);
    expect(updated.lastReviewedAt!.isUtc, isTrue);
    expect(updated.dueDate.isUtc, isFalse);
  });

  test(
    'weak review resets a long interval back to one day with ease decay',
    () {
      final updated = SrsEngine.processReview(
        card(interval: 30, ease: 2.5),
        FlashcardRating.weak,
      );

      expect(updated.interval, 1);
      expect(updated.easeFactor, 2.4);
    },
  );

  test('forgot review resets interval and never drops ease below floor', () {
    final updated = SrsEngine.processReview(
      card(interval: 90, ease: 1.3),
      FlashcardRating.forgot,
    );

    expect(updated.interval, 1);
    expect(updated.easeFactor, 1.3);
  });
}
