import 'dart:convert';
import 'dart:io';

import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

/// Golden plan-generation parity suite (roadmap §10 — the migration's
/// keystone).
///
/// Each fixture in `test/fixtures/plan_generation/` is
/// (profile + progress + rotation + optional previous plan + fixed `now`)
/// → the EXACT expected [DailyPlan], compared field-for-field via `toMap()`.
/// The jawhar-api server suite executes these same fixtures, so the
/// deterministic offline plan and the server's authoritative plan can never
/// drift (identical inputs ⇒ identical plan, including the deterministic
/// `${profileId}_${isoDate}` id).
///
/// The regenerate-after-session fixture pins the sabaq carry-over semantics
/// the server must reproduce when it regenerates the next plan revision in
/// response to a session fact (§5 plan revision semantics).
void main() {
  final fixtureDir = Directory('test/fixtures/plan_generation');
  final fixtureFiles =
      fixtureDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('plan-generation fixture directory is populated', () {
    expect(fixtureFiles, isNotEmpty);
    expect(
      fixtureFiles.map((f) => f.uri.pathSegments.last),
      contains('regenerate_after_session_carry_over.json'),
      reason: 'the mandatory carry-over fixture must exist (roadmap §10)',
    );
  });

  for (final file in fixtureFiles) {
    final fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final name = file.uri.pathSegments.last;

    test('golden plan: $name', () {
      final profile = MemoryProfile.fromMap(
        (fixture['profile'] as Map<String, dynamic>).cast<String, dynamic>(),
      );
      final progress = <int, PageProgress>{
        for (final row in (fixture['progress'] as List))
          (row as Map<String, dynamic>)['pageNumber'] as int:
              PageProgress.fromMap(row.cast<String, dynamic>()),
      };
      final rotationJuz = (fixture['rotationJuz'] as List).cast<int>();
      final previousPlanMap = fixture['previousPlan'] as Map<String, dynamic>?;
      final previousPlan = previousPlanMap == null
          ? null
          : DailyPlan.fromMap(previousPlanMap.cast<String, dynamic>());
      final now = DateTime.parse(fixture['now'] as String);

      final plan = PlanGenerator.generate(
        profile: profile,
        progress: progress,
        rotationJuz: rotationJuz,
        previousPlan: previousPlan,
        now: now,
      );

      expect(
        plan.toMap(),
        equals(fixture['expectedPlan'] as Map<String, dynamic>),
        reason:
            'plan output must be byte-identical to the golden fixture — '
            'any diff here means client/server plan divergence',
      );
    });
  }
}
