/// Pure streak fold: session facts + prior streak → new streak.
///
/// Ports the device semantics of
/// `HifzDatabaseService.recordActiveDay` (lib/services/
/// hifz_database_service.dart:538–557): every completed session marks its
/// CLIENT-LOCAL day active; a day already counted is never double-counted;
/// `totalActiveDays` only ever grows. The client-local `date` string on
/// the fact is canonical (roadmap §5 date semantics) — `recordedAtUtc`
/// plays no role here.
///
/// Ordering/idempotency rule (documented contract): facts may replay in
/// any order, so the fold sorts the distinct `date` values ascending and
/// counts only dates STRICTLY AFTER the prior `lastActiveDate`. This is
/// deliberately stronger than the device guard (which only skips the
/// same-day case, because on-device dates are wall-clock monotonic):
/// counting a backdated date here would re-increment on every backfill
/// replay, since `(totalActiveDays, lastActiveDate)` cannot remember which
/// historical dates were already counted. Backfills therefore replay
/// history in chronological order to count every day exactly once.
library;

import '../dto/facts.dart';
import '../models/hifz_models.dart';

/// Pure derivation of [StreakData] from session facts.
final class StreakDerivation {
  StreakDerivation._();

  /// Folds [sessions] over [prior] and returns the new streak.
  static StreakData fold({
    required StreakData prior,
    required Iterable<SessionFact> sessions,
  }) {
    // Normalize the prior marker to a local-naive midnight (recordActiveDay
    // stores exactly that shape).
    DateTime? last = prior.lastActiveDate == null
        ? null
        : DateTime(
            prior.lastActiveDate!.year,
            prior.lastActiveDate!.month,
            prior.lastActiveDate!.day,
          );
    var total = prior.totalActiveDays;

    // Distinct client-local dates, ascending. `YYYY-MM-DD` sorts
    // lexicographically in chronological order.
    final dates = sessions.map((s) => s.date).toSet().toList()..sort();

    for (final dateString in dates) {
      final day = DateTime.parse(dateString); // local-naive midnight
      if (last != null && !day.isAfter(last)) continue; // already counted
      total += 1;
      last = day;
    }

    return StreakData(totalActiveDays: total, lastActiveDate: last);
  }
}
