/// Pure plan derivation (roadmap §5 plan identity & revision semantics).
///
/// The daily plan is DERIVED state. Identity is the deterministic id
/// `'${profileId}_${localMidnight.toIso8601String()}'` (exactly the
/// generator's historical format — sessions already reference it) plus an
/// integer `revision`.
///
/// Two folds live here:
/// - [PlanDerivation.reconcileClaims]: offline `planGenerated` claims
///   reconcile highest-revision-wins per `(profileId, date)`; ties go to
///   the incumbent (server) copy. No work is ever lost — completion rides
///   on session facts, not on the plan.
/// - [PlanDerivation.foldSessions]: applying a session fact marks the
///   current revision completed (the client's `completePlan()` after a
///   session, session_screen.dart:1234) and regenerates the NEXT revision
///   with the same `PlanGenerator.generate` the client runs — progress
///   promotion is applied first so sabaq/verse carry-over matches the
///   client's regenerate-after-session behavior.
///
/// Ordering rule: session facts sort by (`recordedAtUtc` asc, `id` asc);
/// claims sort by (`revision` asc, `id` asc). Duplicate fact ids fold once.
library;

import 'dart:math' as math;

import '../dto/facts.dart';
import '../models/hifz_models.dart';
import '../planning/plan_generator.dart';
import 'progress_derivation.dart';

/// Canonical deterministic plan identity.
final class PlanIdentity {
  PlanIdentity._();

  /// `'${profileId}_${localMidnight.toIso8601String()}'` for a client-local
  /// `YYYY-MM-DD` date — byte-identical to `PlanGenerator.generate`'s
  /// historical id format (e.g. `p1_2026-06-10T00:00:00.000`).
  static String idFor(String profileId, String localDate) {
    final day = DateTime.parse(localDate);
    final midnight = DateTime(day.year, day.month, day.day);
    return '${profileId}_${midnight.toIso8601String()}';
  }
}

/// One canonical plan revision for a `(profileId, date)`.
final class PlanRevisionState {
  final DailyPlan plan;
  final int revision;
  final bool isCompleted;

  const PlanRevisionState({
    required this.plan,
    required this.revision,
    this.isCompleted = false,
  });

  PlanRevisionState copyWith({bool? isCompleted}) => PlanRevisionState(
    plan: plan,
    revision: revision,
    isCompleted: isCompleted ?? this.isCompleted,
  );
}

/// Result of folding session facts into plan + progress state.
final class SessionPlanFoldResult {
  /// Canonical latest revision per plan id — what `derived.plans` carries.
  final Map<String, PlanRevisionState> plans;

  /// Page progress after all promotions (input to each regeneration).
  final Map<int, PageProgress> progress;

  /// The revisions each applied session fact completed, in fold order
  /// (revision history; not part of the canonical map, which the
  /// regenerated plan supersedes — matching the device, where a completed
  /// session immediately replaces today's plan with a fresh, uncompleted
  /// one).
  final List<PlanRevisionState> completedRevisions;

  const SessionPlanFoldResult({
    required this.plans,
    required this.progress,
    required this.completedRevisions,
  });
}

/// Pure derivation of canonical plan state.
final class PlanDerivation {
  PlanDerivation._();

  /// Reconciles offline plan claims into [current]
  /// (plan id → state). Highest-revision-wins per `(profileId, date)`;
  /// ties keep the incumbent. Returns a new map.
  static Map<String, PlanRevisionState> reconcileClaims({
    required Map<String, PlanRevisionState> current,
    required Iterable<PlanGeneratedFact> claims,
  }) {
    final result = Map<String, PlanRevisionState>.of(current);
    final ordered = claims.toList()
      ..sort((a, b) {
        final byRevision = a.revision.compareTo(b.revision);
        if (byRevision != 0) return byRevision;
        return a.id.compareTo(b.id);
      });

    for (final claim in ordered) {
      final key = PlanIdentity.idFor(claim.profileId, claim.date);
      final incumbent = result[key];
      if (incumbent == null || claim.revision > incumbent.revision) {
        result[key] = PlanRevisionState(
          plan: claim.plan,
          revision: claim.revision,
        );
      }
      // revision <= incumbent.revision → incumbent (server copy) wins.
    }
    return result;
  }

  /// Folds session facts for ONE profile: marks the current revision of the
  /// fact's plan completed, applies the fact's progress promotion, then
  /// regenerates the next revision exactly as the client does after a
  /// session (`PlanProvider.regeneratePlan`).
  ///
  /// Facts whose `profileId` differs from [profile]`.id` are ignored —
  /// callers fold per profile (facts already carry `profileId`, §8 Phase 4
  /// multi-profile semantics).
  ///
  /// Each regeneration calls `PlanGenerator.generate` with
  /// `now: fact.recordedAtUtc` (exact instant comparisons for the sabqi
  /// window/future-date guard — host-timezone independent) and
  /// `localToday: fact.date` (client-local plan keying, §5 date semantics).
  /// The regenerated revision is
  /// `max(storedRevision, fact.planRevision) + 1`.
  static SessionPlanFoldResult foldSessions({
    required Map<String, PlanRevisionState> priorPlans,
    required Map<int, PageProgress> priorProgress,
    required Iterable<SessionFact> facts,
    required MemoryProfile profile,
    required List<int> rotationJuz,
    Set<String> alreadyAppliedFactIds = const {},
    PlanLog? log,
  }) {
    final plans = Map<String, PlanRevisionState>.of(priorPlans);
    var progress = priorProgress;
    final completed = <PlanRevisionState>[];
    final seen = Set<String>.of(alreadyAppliedFactIds);

    for (final fact in ProgressDerivation.sortSessionFacts(facts)) {
      if (fact.profileId != profile.id) continue;
      if (!seen.add(fact.id)) continue;

      final planId = PlanIdentity.idFor(fact.profileId, fact.date);
      final current = plans[planId];

      // 1. The session completes the plan revision it ran against.
      if (current != null) {
        completed.add(current.copyWith(isCompleted: true));
      }

      // 2. Progress promotion happens before regeneration — carry-over
      //    (next sabaq page/verse) reads the promoted state, like the
      //    client completing a session before `regeneratePlan`.
      progress = ProgressDerivation.applySessionFact(
        prior: progress,
        fact: fact,
      );

      // 3. Regenerate the next revision.
      final day = DateTime.parse(fact.date);
      final regenerated = PlanGenerator.generate(
        profile: profile,
        progress: progress,
        rotationJuz: rotationJuz,
        previousPlan: current?.plan,
        now: fact.recordedAtUtc.toUtc(),
        localToday: DateTime(day.year, day.month, day.day),
        log: log,
      );
      final nextRevision =
          math.max(current?.revision ?? 0, fact.planRevision) + 1;
      plans[planId] = PlanRevisionState(
        plan: regenerated,
        revision: nextRevision,
      );
    }

    return SessionPlanFoldResult(
      plans: plans,
      progress: progress,
      completedRevisions: completed,
    );
  }
}
