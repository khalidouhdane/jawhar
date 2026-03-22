import 'package:quran_app/models/flashcard_models.dart';

/// SM-2 Spaced Repetition System engine.
///
/// Rating effects on interval:
/// - Strong (instant recall): interval × 2.5
/// - OK (recalled with effort): interval × 1.5
/// - Weak (struggled): interval stays
/// - Forgot (couldn't recall): reset to 1 day
class SrsEngine {
  /// Calculate the next SRS state after a review.
  ///
  /// Returns a new [Flashcard] with updated interval, easeFactor, dueDate,
  /// lastReviewedAt, and reviewCount.
  static Flashcard processReview(Flashcard card, FlashcardRating rating) {
    double newInterval;
    double newEase = card.easeFactor;

    switch (rating) {
      case FlashcardRating.strong:
        newInterval = card.interval * 2.5;
        newEase = (card.easeFactor + 0.1).clamp(1.3, 3.0);
        break;
      case FlashcardRating.ok:
        newInterval = card.interval * 1.5;
        // Ease factor stays the same
        break;
      case FlashcardRating.weak:
        newInterval = card.interval; // Same interval
        newEase = (card.easeFactor - 0.1).clamp(1.3, 3.0);
        break;
      case FlashcardRating.forgot:
        newInterval = 1.0; // Reset to 1 day
        newEase = (card.easeFactor - 0.2).clamp(1.3, 3.0);
        break;
    }

    // Ensure minimum of 1 day, max of 180 days
    newInterval = newInterval.clamp(1.0, 180.0);

    final now = DateTime.now();
    final nextDue = DateTime(
      now.year, now.month, now.day,
    ).add(Duration(days: newInterval.round()));

    return card.copyWith(
      interval: newInterval,
      easeFactor: newEase,
      dueDate: nextDue,
      lastReviewedAt: now,
      reviewCount: card.reviewCount + 1,
    );
  }

  /// Calculate estimated review time for a set of due cards.
  /// Assumes ~10 seconds per card on average.
  static int estimateMinutes(int cardCount) {
    return ((cardCount * 10) / 60).ceil().clamp(1, 60);
  }
}
