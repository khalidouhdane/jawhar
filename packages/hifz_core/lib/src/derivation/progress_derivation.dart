/// Pure progress promotion: session facts + prior page progress → new
/// page progress, byte-identical to the client's `completeSession`
/// promotion (lib/providers/session_provider.dart:459–546), which the
/// user already watched happen (roadmap §5/§10 — the mandatory
/// multi-page-`actualPagesCovered` parity fixture runs against this).
///
/// Ported semantics, in order, per session fact:
/// 1. covered = `actualPagesCovered` if non-empty, else `[sabaq.page]`.
/// 2. Sabaq completed → each covered page becomes `learning`,
///    `reviewCount` increments against the LIVE evolving state (the client
///    re-reads inside the loop), `lastVerseLearned`/`totalVersesOnPage`
///    land only on the LAST covered page (null on the others), and
///    `memorizedAt` is dropped (the client constructs a fresh row).
/// 3. Sabqi completed → each `sabqi.pages` page becomes `reviewing`;
///    `reviewCount` increments against a SNAPSHOT taken at the start of
///    the sabqi block (client reads the map once); `memorizedAt`/verse
///    fields dropped.
/// 4. Manzil completed → each `manzil.pages` page becomes `memorized` when
///    the manzil assessment is strong (also stamping `memorizedAt`), else
///    `reviewing` (carrying the prior `memorizedAt`); snapshot semantics
///    as in 3.
///
/// All derived timestamps use the fact's `recordedAtUtc` (the client used
/// `DateTime.now().toUtc()` at write time — the fact carries that instant).
///
/// Ordering rule for batches: sort by (`recordedAtUtc` asc, `id` asc),
/// duplicates by id fold once — same contract as the SRS fold.
library;

import '../dto/facts.dart';
import '../models/hifz_models.dart';

/// Pure derivation of page progress from session facts.
final class ProgressDerivation {
  ProgressDerivation._();

  /// Applies one session fact. Returns a NEW map; [prior] is not mutated.
  static Map<int, PageProgress> applySessionFact({
    required Map<int, PageProgress> prior,
    required SessionFact fact,
  }) {
    final state = Map<int, PageProgress>.of(prior);
    final now = fact.recordedAtUtc.toUtc();
    final profileId = fact.profileId;

    final coveredPages = fact.actualPagesCovered.isNotEmpty
        ? fact.actualPagesCovered
        : (fact.sabaq.page != null ? [fact.sabaq.page!] : const <int>[]);

    // ── Sabaq pages → learning (live state lookups, client parity) ──
    if (fact.sabaq.completed) {
      for (var i = 0; i < coveredPages.length; i++) {
        final page = coveredPages[i];
        final isLastPage = i == coveredPages.length - 1;
        final prev = state[page];
        state[page] = PageProgress(
          pageNumber: page,
          profileId: profileId,
          status: PageStatus.learning,
          lastReviewedAt: now,
          reviewCount: (prev?.reviewCount ?? 0) + 1,
          lastVerseLearned: isLastPage ? fact.lastVerseLearned : null,
          totalVersesOnPage: isLastPage ? fact.totalVersesOnPage : null,
        );
      }
    }

    // ── Sabqi pages → reviewing (snapshot at block start, client parity) ──
    if (fact.sabqi.completed) {
      final snapshot = Map<int, PageProgress>.of(state);
      for (final page in fact.sabqi.pages) {
        final prev = snapshot[page];
        state[page] = PageProgress(
          pageNumber: page,
          profileId: profileId,
          status: PageStatus.reviewing,
          lastReviewedAt: now,
          reviewCount: (prev?.reviewCount ?? 0) + 1,
        );
      }
    }

    // ── Manzil pages → memorized (strong) or reviewing ──
    if (fact.manzil.completed) {
      final isStrong = fact.manzil.assessment == SelfAssessment.strong;
      final snapshot = Map<int, PageProgress>.of(state);
      for (final page in fact.manzil.pages) {
        final prev = snapshot[page];
        state[page] = PageProgress(
          pageNumber: page,
          profileId: profileId,
          status: isStrong ? PageStatus.memorized : PageStatus.reviewing,
          lastReviewedAt: now,
          reviewCount: (prev?.reviewCount ?? 0) + 1,
          memorizedAt: isStrong ? now : prev?.memorizedAt,
        );
      }
    }

    return state;
  }

  /// Folds a batch: sorts by (`recordedAtUtc` asc, `id` asc), skips
  /// [alreadyAppliedFactIds] and in-batch duplicates, applies each fact.
  static Map<int, PageProgress> foldSessionFacts({
    required Map<int, PageProgress> prior,
    required Iterable<SessionFact> facts,
    Set<String> alreadyAppliedFactIds = const {},
  }) {
    final ordered = sortSessionFacts(facts);
    final seen = Set<String>.of(alreadyAppliedFactIds);
    var state = prior;
    for (final fact in ordered) {
      if (!seen.add(fact.id)) continue;
      state = applySessionFact(prior: state, fact: fact);
    }
    return state;
  }

  /// The documented session-fact ordering rule:
  /// (`recordedAtUtc` ascending, then `id` ascending).
  static List<SessionFact> sortSessionFacts(Iterable<SessionFact> facts) =>
      facts.toList()..sort((a, b) {
        final byTime = a.recordedAtUtc.compareTo(b.recordedAtUtc);
        if (byTime != 0) return byTime;
        return a.id.compareTo(b.id);
      });
}
