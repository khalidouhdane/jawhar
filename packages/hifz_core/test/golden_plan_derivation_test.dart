import 'dart:convert';
import 'dart:io';

import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

/// Golden plan-derivation suite (roadmap §5 plan identity & revision
/// semantics, §10 regenerate-after-session carry-over):
/// - `claims_*` fixtures: highest-revision-wins per (profileId, date),
///   ties to the incumbent server copy;
/// - `session_fold_*` fixtures: a session fact completes the current
///   revision and regenerates the next one through the same
///   `PlanGenerator.generate` the client runs, keyed by the CLIENT-LOCAL
///   date (non-UTC case included).
void main() {
  final fixtureDir = Directory('test/fixtures/plan_derivation');
  final fixtureFiles =
      fixtureDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('plan-derivation fixture directory is populated', () {
    expect(fixtureFiles, isNotEmpty);
  });

  Map<String, PlanRevisionState> parsePlans(Map<String, dynamic> json) => {
    for (final entry in json.entries)
      entry.key: PlanRevisionState(
        plan: DailyPlan.fromMap(
          ((entry.value as Map)['plan'] as Map).cast<String, dynamic>(),
        ),
        revision: (entry.value as Map)['revision'] as int,
        isCompleted: (entry.value as Map)['isCompleted'] as bool? ?? false,
      ),
  };

  void expectPlanSubset(
    PlanRevisionState got,
    Map<String, dynamic> want,
    String reason,
  ) {
    expect(got.revision, want['revision'], reason: '$reason revision');
    if (want.containsKey('isCompleted')) {
      expect(
        got.isCompleted,
        want['isCompleted'],
        reason: '$reason isCompleted',
      );
    }
    final planWant =
        (want['plan'] as Map?)?.cast<String, dynamic>() ??
        {if (want.containsKey('sabaqPage')) 'sabaqPage': want['sabaqPage']};
    final planMap = got.plan.toMap();
    for (final field in planWant.entries) {
      expect(
        planMap[field.key],
        field.value,
        reason: '$reason plan.${field.key}',
      );
    }
  }

  for (final file in fixtureFiles) {
    final fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final name = file.uri.pathSegments.last;

    if (fixture.containsKey('claims')) {
      test('golden claim reconciliation: $name', () {
        final current = parsePlans(
          (fixture['currentPlans'] as Map).cast<String, dynamic>(),
        );
        final claims = [
          for (final raw in fixture['claims'] as List)
            Fact.fromJson((raw as Map).cast<String, dynamic>())
                as PlanGeneratedFact,
        ];

        final result = PlanDerivation.reconcileClaims(
          current: current,
          claims: claims,
        );

        final expected = (fixture['expected'] as Map).cast<String, dynamic>();
        expect(result.keys.toSet(), expected.keys.toSet());
        for (final entry in expected.entries) {
          expectPlanSubset(
            result[entry.key]!,
            (entry.value as Map).cast<String, dynamic>(),
            entry.key,
          );
        }

        // Order independence.
        final reversed = PlanDerivation.reconcileClaims(
          current: current,
          claims: claims.reversed.toList(),
        );
        for (final key in result.keys) {
          expect(reversed[key]!.revision, result[key]!.revision);
          expect(reversed[key]!.plan.toMap(), result[key]!.plan.toMap());
        }
      });
      continue;
    }

    test('golden session plan fold: $name', () {
      final profile = MemoryProfile.fromMap(
        (fixture['profile'] as Map).cast<String, dynamic>(),
      );
      final rotationJuz = (fixture['rotationJuz'] as List).cast<int>();
      final priorProgress = <int, PageProgress>{
        for (final raw in fixture['priorProgress'] as List)
          (raw as Map)['pageNumber'] as int: PageProgress.fromMap(
            raw.cast<String, dynamic>(),
          ),
      };
      final priorPlans = parsePlans(
        (fixture['priorPlans'] as Map).cast<String, dynamic>(),
      );
      final facts = [
        for (final raw in fixture['sessionFacts'] as List)
          Fact.fromJson((raw as Map).cast<String, dynamic>()) as SessionFact,
      ];

      final result = PlanDerivation.foldSessions(
        priorPlans: priorPlans,
        priorProgress: priorProgress,
        facts: facts,
        profile: profile,
        rotationJuz: rotationJuz,
      );

      final expectedPlans = (fixture['expectedPlans'] as Map)
          .cast<String, dynamic>();
      for (final entry in expectedPlans.entries) {
        final got = result.plans[entry.key];
        expect(got, isNotNull, reason: 'plan ${entry.key} missing');
        expectPlanSubset(
          got!,
          (entry.value as Map).cast<String, dynamic>(),
          entry.key,
        );
      }

      final expectedCompleted = [
        for (final raw in fixture['expectedCompletedRevisions'] as List)
          (raw as Map).cast<String, dynamic>(),
      ];
      expect(
        result.completedRevisions.length,
        expectedCompleted.length,
        reason: 'completed revision count',
      );
      for (var i = 0; i < expectedCompleted.length; i++) {
        expect(
          result.completedRevisions[i].revision,
          expectedCompleted[i]['revision'],
          reason: 'completedRevisions[$i].revision',
        );
        expect(
          result.completedRevisions[i].isCompleted,
          expectedCompleted[i]['isCompleted'],
          reason: 'completedRevisions[$i].isCompleted',
        );
      }

      for (final raw in fixture['expectedProgress'] as List) {
        final want = (raw as Map).cast<String, dynamic>();
        final page = want['pageNumber'] as int;
        expect(
          result.progress[page]!.toMap(),
          want,
          reason: 'derived progress page $page',
        );
      }

      // Order independence (the fold sorts internally).
      final reversed = PlanDerivation.foldSessions(
        priorPlans: priorPlans,
        priorProgress: priorProgress,
        facts: facts.reversed.toList(),
        profile: profile,
        rotationJuz: rotationJuz,
      );
      for (final key in result.plans.keys) {
        expect(
          reversed.plans[key]!.plan.toMap(),
          result.plans[key]!.plan.toMap(),
          reason: 'plan $key must be input-order independent',
        );
      }

      // Replayed fact ids are skipped entirely.
      final replay = PlanDerivation.foldSessions(
        priorPlans: result.plans,
        priorProgress: result.progress,
        facts: facts,
        profile: profile,
        rotationJuz: rotationJuz,
        alreadyAppliedFactIds: {for (final f in facts) f.id},
      );
      expect(replay.completedRevisions, isEmpty);
      for (final key in result.plans.keys) {
        expect(
          replay.plans[key]!.plan.toMap(),
          result.plans[key]!.plan.toMap(),
          reason: 'replay must not change canonical plan $key',
        );
      }
    });
  }

  test('facts from other profiles are ignored by the session fold', () {
    final profile = MemoryProfile(
      id: 'p1',
      name: 'Test',
      createdAt: DateTime(2026, 1, 1),
      startDate: DateTime(2026, 1, 1),
    );
    final foreign = SessionFact(
      id: '99999999-9999-4999-8999-999999999999',
      coreVersion: hifzCoreVersion,
      profileId: 'p2',
      date: '2026-06-10',
      tzOffsetMinutes: 0,
      durationMinutes: 10,
      repCount: 1,
      sabaq: const SabaqOutcome(completed: true, page: 1),
      sabqi: const PhaseOutcome(completed: false),
      manzil: const PhaseOutcome(completed: false),
      planId: 'p2_2026-06-10T00:00:00.000',
      planRevision: 0,
      planOrigin: PlanOrigin.client,
      recordedAtUtc: DateTime.utc(2026, 6, 10, 12),
    );
    final result = PlanDerivation.foldSessions(
      priorPlans: const {},
      priorProgress: const {},
      facts: [foreign],
      profile: profile,
      rotationJuz: const [],
    );
    expect(result.plans, isEmpty);
    expect(result.completedRevisions, isEmpty);
    expect(result.progress, isEmpty);
  });

  test('PlanIdentity matches the generator id format exactly', () {
    expect(
      PlanIdentity.idFor('p1', '2026-06-10'),
      'p1_2026-06-10T00:00:00.000',
    );
    final generated = PlanGenerator.generate(
      profile: MemoryProfile(
        id: 'p1',
        name: 'Test',
        createdAt: DateTime(2026, 1, 1),
        startDate: DateTime(2026, 1, 1),
      ),
      progress: const {},
      rotationJuz: const [],
      now: DateTime.utc(2026, 6, 10, 22, 30),
      localToday: DateTime(2026, 6, 11), // UTC+x user past local midnight
    );
    expect(generated.id, PlanIdentity.idFor('p1', '2026-06-11'));
    expect(generated.date, DateTime(2026, 6, 11));
  });
}
