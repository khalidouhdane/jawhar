import 'dart:convert';
import 'dart:io';

import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

/// Golden streak-derivation suite (roadmap §5/§10): session facts + prior
/// streak → new streak, on CLIENT-LOCAL dates (ported from
/// `HifzDatabaseService.recordActiveDay`). Covers out-of-order facts,
/// same-day dedup, backdated-date skipping (idempotent fold), and the
/// non-UTC case where the local date differs from the UTC date of
/// `recordedAtUtc`.
void main() {
  final fixtureDir = Directory('test/fixtures/streak');
  final fixtureFiles =
      fixtureDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('streak fixture directory is populated', () {
    expect(fixtureFiles, isNotEmpty);
  });

  String? dateOnly(DateTime? value) {
    if (value == null) return null;
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  for (final file in fixtureFiles) {
    final fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final name = file.uri.pathSegments.last;

    test('golden streak fold: $name', () {
      final priorJson = fixture['prior'] as Map<String, dynamic>;
      final prior = StreakData(
        totalActiveDays: priorJson['totalActiveDays'] as int,
        lastActiveDate: priorJson['lastActiveDate'] == null
            ? null
            : DateTime.parse(priorJson['lastActiveDate'] as String),
      );
      final facts = [
        for (final raw in fixture['sessionFacts'] as List)
          Fact.fromJson((raw as Map).cast<String, dynamic>()) as SessionFact,
      ];

      final result = StreakDerivation.fold(prior: prior, sessions: facts);

      final expected = fixture['expected'] as Map<String, dynamic>;
      expect(result.totalActiveDays, expected['totalActiveDays']);
      expect(dateOnly(result.lastActiveDate), expected['lastActiveDate']);

      // Order independence.
      final reversed = StreakDerivation.fold(
        prior: prior,
        sessions: facts.reversed.toList(),
      );
      expect(reversed.totalActiveDays, result.totalActiveDays);
      expect(reversed.lastActiveDate, result.lastActiveDate);

      // Replay idempotency: folding the same batch over the result changes
      // nothing (every date is now <= lastActiveDate).
      final replay = StreakDerivation.fold(prior: result, sessions: facts);
      expect(replay.totalActiveDays, result.totalActiveDays);
      expect(replay.lastActiveDate, result.lastActiveDate);
    });
  }
}
