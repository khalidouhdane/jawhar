import '../models/flashcard_models.dart';

/// Returns the current instant. Injectable so the server (and tests) can
/// replay reviews at their recorded timestamps instead of wall-clock time.
typedef Clock = DateTime Function();

/// Maps the instant a review happened to the start of that day in the
/// *reviewer's* local timezone (a timezone-naive local midnight).
///
/// SM-2 due dates are computed from this boundary — historically
/// `DateTime(localNow.year, localNow.month, localNow.day)` on the device.
/// The server must fold reviews with the day boundary derived from the
/// fact's `tzOffsetMinutes`, NOT from UTC, or due dates shift ±1 day for
/// any non-UTC user (roadmap §3/§5/§7.5).
typedef LocalDayBoundary = DateTime Function(DateTime now);

/// SM-2 Spaced Repetition System engine.
///
/// Rating effects on interval:
/// - Strong (instant recall): interval × 2.5
/// - OK (recalled with effort): interval × 1.5
/// - Weak (struggled): reset to 1 day, ease decays
/// - Forgot (couldn't recall): reset to 1 day, ease decays harder
class SrsEngine {
  /// Calculate the next SRS state after a review.
  ///
  /// Returns a new [Flashcard] with updated interval, easeFactor, dueDate,
  /// lastReviewedAt, and reviewCount.
  ///
  /// [clock] defaults to `DateTime.now()` (device-local wall clock) and
  /// [localDayBoundary] defaults to [systemLocalDayBoundary] — together they
  /// reproduce the historical on-device behavior exactly. The server passes
  /// the review's recorded instant as [clock] and
  /// `dayBoundaryForOffset(fact.tzOffsetMinutes)` as [localDayBoundary].
  static Flashcard processReview(
    Flashcard card,
    FlashcardRating rating, {
    Clock? clock,
    LocalDayBoundary? localDayBoundary,
  }) {
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
        // Struggling cards come back tomorrow instead of staying stuck at
        // their current (possibly long) interval.
        newInterval = 1.0;
        newEase = (card.easeFactor - 0.1).clamp(1.3, 3.0);
        break;
      case FlashcardRating.forgot:
        newInterval = 1.0; // Reset to 1 day
        newEase = (card.easeFactor - 0.2).clamp(1.3, 3.0);
        break;
    }

    // Ensure minimum of 1 day, max of 180 days
    newInterval = newInterval.clamp(1.0, 180.0);

    final now = (clock ?? DateTime.now)();
    final reviewedAt = now.toUtc();
    final dayStart = (localDayBoundary ?? systemLocalDayBoundary)(now);
    final nextDue = dayStart.add(Duration(days: newInterval.round()));

    return card.copyWith(
      interval: newInterval,
      easeFactor: newEase,
      dueDate: nextDue,
      lastReviewedAt: reviewedAt,
      reviewCount: card.reviewCount + 1,
    );
  }

  /// Default day boundary: midnight of [now] in the *system* local timezone —
  /// byte-identical to the historical
  /// `DateTime(localNow.year, localNow.month, localNow.day)`.
  static DateTime systemLocalDayBoundary(DateTime now) {
    final local = now.isUtc ? now.toLocal() : now;
    return DateTime(local.year, local.month, local.day);
  }

  /// Day boundary for an explicit UTC offset in minutes (e.g. UTC+3 = 180).
  ///
  /// Used server-side with the `tzOffsetMinutes` carried on review facts so
  /// a 23:30-local review computes the same due date the device computed.
  /// The returned boundary is timezone-naive local midnight, matching the
  /// device representation.
  static LocalDayBoundary dayBoundaryForOffset(int tzOffsetMinutes) {
    return (DateTime now) {
      final shifted = now.toUtc().add(Duration(minutes: tzOffsetMinutes));
      return DateTime(shifted.year, shifted.month, shifted.day);
    };
  }

  /// Calculate estimated review time for a set of due cards.
  /// Assumes ~10 seconds per card on average.
  static int estimateMinutes(int cardCount) {
    return ((cardCount * 10) / 60).ceil().clamp(1, 60);
  }
}
