/// Pure SRS fold: review facts + prior card state → new card state.
///
/// Ordering rule (roadmap §5/§7.5, documented contract): facts may replay
/// in any order within a batch, so before folding, reviews are sorted by
/// (`reviewedAtUtc` ascending, then fact `id` ascending) — the id tiebreak
/// makes equal-timestamp folds deterministic on every host. Future-dated
/// reviews are clamped to [nowUtc] (the ported `f342e80` clock-skew guard).
///
/// Unknown-card tolerance (§5): a review whose `cardId` has no known card
/// creates placeholder SRS state keyed by that id; identity attaches
/// when/if the `cardCreated` fact arrives ([SrsFold.attachIdentity]).
/// Without this, a poisoned or never-synced `cardCreated` would silently
/// void every later review of that card.
///
/// Idempotency: fact ids in [SrsFold.fold]'s `alreadyAppliedFactIds` are
/// skipped, and duplicate ids inside one batch fold once — replaying the
/// same batch over the same prior state yields byte-identical output.
library;

import '../dto/facts.dart';
import '../models/flashcard_models.dart';
import '../srs/srs_engine.dart';

/// Result of folding a batch of review facts.
final class SrsFoldResult {
  /// Canonical card state after the fold, keyed by card id. Contains every
  /// card that was touched OR present in the prior state.
  final Map<String, Flashcard> cards;

  /// Ids of cards that exist only as placeholders (reviews arrived before
  /// their `cardCreated` fact).
  final Set<String> placeholderCardIds;

  /// Ids of review facts that actually applied (not skipped as replays).
  final List<String> appliedFactIds;

  const SrsFoldResult({
    required this.cards,
    required this.placeholderCardIds,
    required this.appliedFactIds,
  });
}

/// Pure derivation of canonical SRS state from review facts.
final class SrsFold {
  SrsFold._();

  /// Folds [reviews] over [priorCards] and returns the new state.
  ///
  /// [priorPlaceholderIds] carries placeholder markers across folds (cards
  /// the server created from reviews in earlier batches).
  /// [alreadyAppliedFactIds] are fact ids the server has stored before —
  /// skipped (replay is never an error).
  /// [nowUtc] enables the future-timestamp clamp; pass the processing
  /// wall-clock. When null, timestamps are trusted as-is (deterministic
  /// replay in tests/backfills).
  static SrsFoldResult fold({
    required Map<String, Flashcard> priorCards,
    required Iterable<ReviewFact> reviews,
    Set<String> priorPlaceholderIds = const {},
    Set<String> alreadyAppliedFactIds = const {},
    DateTime? nowUtc,
  }) {
    final clampCeiling = nowUtc?.toUtc();

    DateTime effectiveInstant(ReviewFact fact) {
      final instant = fact.reviewedAtUtc.toUtc();
      if (clampCeiling != null && instant.isAfter(clampCeiling)) {
        return clampCeiling;
      }
      return instant;
    }

    // Sort by (clamped reviewedAtUtc, id) — the documented ordering rule.
    final ordered = reviews.toList()
      ..sort((a, b) {
        final byTime = effectiveInstant(a).compareTo(effectiveInstant(b));
        if (byTime != 0) return byTime;
        return a.id.compareTo(b.id);
      });

    final cards = Map<String, Flashcard>.of(priorCards);
    final placeholders = Set<String>.of(priorPlaceholderIds);
    final seenFactIds = Set<String>.of(alreadyAppliedFactIds);
    final applied = <String>[];

    for (final fact in ordered) {
      if (!seenFactIds.add(fact.id)) continue; // replay / in-batch duplicate

      final instant = effectiveInstant(fact);
      final boundary = SrsEngine.dayBoundaryForOffset(fact.tzOffsetMinutes);

      var card = cards[fact.cardId];
      if (card == null) {
        card = placeholderCard(
          cardId: fact.cardId,
          firstSeenUtc: instant,
          tzOffsetMinutes: fact.tzOffsetMinutes,
        );
        placeholders.add(fact.cardId);
      }

      cards[fact.cardId] = SrsEngine.processReview(
        card,
        fact.rating,
        clock: () => instant,
        localDayBoundary: boundary,
      );
      applied.add(fact.id);
    }

    return SrsFoldResult(
      cards: cards,
      placeholderCardIds: placeholders,
      appliedFactIds: applied,
    );
  }

  /// A brand-new card's SRS state as the client creates it (interval 1.0,
  /// ease 2.5, due immediately — `card_generation_service.dart` sets
  /// `dueDate: DateTime.now()`), with empty identity fields that
  /// [attachIdentity] fills in when the `cardCreated` fact arrives.
  ///
  /// `dueDate` anchors to the reviewer-local day boundary of
  /// [firstSeenUtc] so the placeholder is due "today" in the user's frame.
  static Flashcard placeholderCard({
    required String cardId,
    required DateTime firstSeenUtc,
    required int tzOffsetMinutes,
  }) => Flashcard(
    id: cardId,
    type: FlashcardType.nextVerse,
    profileId: '',
    verseKey: '',
    questionData: const {},
    answerData: const {},
    dueDate: SrsEngine.dayBoundaryForOffset(tzOffsetMinutes)(firstSeenUtc),
  );

  /// Builds the canonical card for a `cardCreated` fact when no placeholder
  /// exists (the common, in-order case). `dueDate` defaults to
  /// [CardCreatedFact.createdAtUtc] — due immediately, matching the
  /// client's creation behavior.
  static Flashcard fromCardCreated(CardCreatedFact fact, {DateTime? dueDate}) =>
      Flashcard(
        id: fact.id,
        type: fact.type,
        profileId: fact.profileId,
        verseKey: fact.verseKey,
        questionData: const {},
        answerData: const {},
        dueDate: dueDate ?? fact.createdAtUtc,
      );

  /// Order-independence helper: attaches the identity carried by a late
  /// `cardCreated` fact to an existing placeholder, KEEPING the folded SRS
  /// state (interval/ease/due/reviewCount survive — the reviews already
  /// happened).
  static Flashcard attachIdentity(Flashcard placeholder, CardCreatedFact fact) {
    if (placeholder.id != fact.id) {
      throw ArgumentError(
        'cardCreated fact ${fact.id} does not match placeholder '
        '${placeholder.id}',
      );
    }
    return Flashcard(
      id: placeholder.id,
      type: fact.type,
      profileId: fact.profileId,
      verseKey: fact.verseKey,
      questionData: placeholder.questionData,
      answerData: placeholder.answerData,
      interval: placeholder.interval,
      easeFactor: placeholder.easeFactor,
      dueDate: placeholder.dueDate,
      lastReviewedAt: placeholder.lastReviewedAt,
      reviewCount: placeholder.reviewCount,
    );
  }
}
