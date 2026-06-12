/// Pure manzil-rotation derivation (roadmap §8 Phase 5 task 4).
///
/// The rotation list is server-owned state under
/// `users/{uid}/meta/manzil_rotation`, keyed by `profileId`. Edits arrive
/// as `rotationChanged` facts carrying the FULL list (snapshot semantics);
/// reconciliation is last-write-wins per profile, ordered by
/// (`changedAtUtc` asc, `id` asc).
///
/// Idempotency: a fact whose (`changedAtUtc`, `id`) pair is not strictly
/// greater than the incumbent's loses — so replaying an already-applied
/// fact (equal pair) never changes state, and folding is input-order
/// independent (the fold sorts internally).
library;

import '../dto/facts.dart';

/// The canonical rotation for one profile: the winning fact's list plus the
/// LWW key that made it win.
final class RotationState {
  /// Juz numbers 1–30, distinct, order preserved (the generator
  /// round-robins by index, so order is semantic).
  final List<int> juz;

  /// The winning fact's `changedAtUtc` — primary LWW key.
  final DateTime changedAtUtc;

  /// The winning fact's id — LWW tiebreak and replay marker.
  final String factId;

  const RotationState({
    required this.juz,
    required this.changedAtUtc,
    required this.factId,
  });
}

/// Pure derivation of canonical rotation state from rotation facts.
final class RotationDerivation {
  RotationDerivation._();

  /// Whether [fact] beats [incumbent] under the LWW rule:
  /// (`changedAtUtc`, `id`) strictly greater, lexicographically.
  static bool wins(RotationChangedFact fact, RotationState? incumbent) {
    if (incumbent == null) return true;
    final byInstant = fact.changedAtUtc.compareTo(incumbent.changedAtUtc);
    if (byInstant != 0) return byInstant > 0;
    return fact.id.compareTo(incumbent.factId) > 0;
  }

  /// Folds rotation facts into [prior] (profileId → state). Returns a NEW
  /// map; [prior] is not mutated. Duplicate fact ids fold once.
  static Map<String, RotationState> fold({
    required Map<String, RotationState> prior,
    required Iterable<RotationChangedFact> facts,
  }) {
    final result = Map<String, RotationState>.of(prior);
    final ordered = facts.toList()
      ..sort((a, b) {
        final byInstant = a.changedAtUtc.compareTo(b.changedAtUtc);
        if (byInstant != 0) return byInstant;
        return a.id.compareTo(b.id);
      });
    final seen = <String>{};
    for (final fact in ordered) {
      if (!seen.add(fact.id)) continue;
      if (wins(fact, result[fact.profileId])) {
        result[fact.profileId] = RotationState(
          juz: List<int>.unmodifiable(fact.juz),
          changedAtUtc: fact.changedAtUtc.toUtc(),
          factId: fact.id,
        );
      }
    }
    return result;
  }
}
