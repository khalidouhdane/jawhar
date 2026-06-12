import 'dart:convert';
import 'dart:io';

import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

/// Golden progress-promotion suite — the roadmap §10 mandatory parity case:
/// the server's derived progress from a session fact must be byte-identical
/// to the client's `completeSession` promotion
/// (session_provider.dart:459–546), including multi-page
/// `actualPagesCovered`, verse fields on the last covered page only,
/// memorizedAt drop/carry rules, and the documented
/// (`recordedAtUtc`, `id`) fold ordering.
void main() {
  final fixtureDir = Directory('test/fixtures/progress_promotion');
  final fixtureFiles =
      fixtureDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('progress-promotion fixture directory is populated', () {
    expect(fixtureFiles, isNotEmpty);
  });

  for (final file in fixtureFiles) {
    final fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final name = file.uri.pathSegments.last;

    test('golden progress promotion: $name', () {
      final prior = <int, PageProgress>{
        for (final raw in fixture['priorProgress'] as List)
          (raw as Map)['pageNumber'] as int: PageProgress.fromMap(
            raw.cast<String, dynamic>(),
          ),
      };
      final facts = [
        for (final raw in fixture['sessionFacts'] as List)
          Fact.fromJson((raw as Map).cast<String, dynamic>()) as SessionFact,
      ];

      final result = ProgressDerivation.foldSessionFacts(
        prior: prior,
        facts: facts,
      );

      final expectedRows = [
        for (final raw in fixture['expected'] as List)
          (raw as Map).cast<String, dynamic>(),
      ];
      expect(result.length, expectedRows.length, reason: 'derived page count');
      for (final want in expectedRows) {
        final page = want['pageNumber'] as int;
        final got = result[page];
        expect(got, isNotNull, reason: 'page $page missing');
        expect(got!.toMap(), want, reason: 'page $page (byte-identical map)');
      }

      // Order independence (the fold sorts internally).
      final reversed = ProgressDerivation.foldSessionFacts(
        prior: prior,
        facts: facts.reversed.toList(),
      );
      for (final page in result.keys) {
        expect(
          reversed[page]!.toMap(),
          result[page]!.toMap(),
          reason: 'page $page must be input-order independent',
        );
      }

      // Already-applied fact ids are skipped entirely.
      final skipped = ProgressDerivation.foldSessionFacts(
        prior: prior,
        facts: facts,
        alreadyAppliedFactIds: {for (final f in facts) f.id},
      );
      expect(
        {for (final e in skipped.entries) e.key: e.value.toMap()},
        {for (final e in prior.entries) e.key: e.value.toMap()},
        reason: 'fully-replayed batch must not change prior state',
      );
    });
  }
}
