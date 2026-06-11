import 'dart:convert';
import 'dart:io';

import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

/// Golden SRS parity suite (roadmap §10 — the migration's keystone).
///
/// Each fixture in `test/fixtures/srs/` folds a starting [Flashcard] through
/// a sequence of reviews with an injected clock and an injected
/// tz-offset-derived day boundary, and asserts the EXACT resulting SRS state
/// after every review. The jawhar-api server suite executes these same
/// fixtures, so any divergence between the client fold and the server fold
/// fails CI on either side.
///
/// `dueDate` expectations are local-naive ISO strings produced by
/// `SrsEngine.dayBoundaryForOffset` + day addition. Day addition is exact
/// wall-clock arithmetic only when the *host* timezone has no DST transition
/// between the review and its due date; all fixture horizons avoid DST
/// windows for UTC (CI) and Morocco (dev machine).
void main() {
  final fixtureDir = Directory('test/fixtures/srs');
  final fixtureFiles =
      fixtureDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('SRS fixture directory is populated', () {
    expect(fixtureFiles, isNotEmpty);
  });

  for (final file in fixtureFiles) {
    final fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final name = file.uri.pathSegments.last;

    test('golden SRS fold: $name', () {
      var card = Flashcard.fromMap(
        (fixture['card'] as Map<String, dynamic>).cast<String, dynamic>(),
      );

      final reviews = (fixture['reviews'] as List).cast<Map<String, dynamic>>();
      for (var i = 0; i < reviews.length; i++) {
        final review = reviews[i];
        final rating = FlashcardRating.values.byName(
          review['rating'] as String,
        );
        final clockUtc = DateTime.parse(review['clockUtc'] as String);
        expect(clockUtc.isUtc, isTrue, reason: 'review $i clock must be UTC');
        final tzOffsetMinutes = review['tzOffsetMinutes'] as int;
        final boundary = SrsEngine.dayBoundaryForOffset(tzOffsetMinutes);

        final cardBefore = card;
        card = SrsEngine.processReview(
          card,
          rating,
          clock: () => clockUtc,
          localDayBoundary: boundary,
        );

        final expected = review['expected'] as Map<String, dynamic>;
        expect(
          card.interval,
          (expected['interval'] as num).toDouble(),
          reason: 'review $i interval',
        );
        expect(
          card.easeFactor,
          closeTo((expected['easeFactor'] as num).toDouble(), 1e-12),
          reason: 'review $i easeFactor',
        );
        expect(
          card.reviewCount,
          expected['reviewCount'],
          reason: 'review $i reviewCount',
        );
        expect(
          card.dueDate.toIso8601String(),
          expected['dueDate'],
          reason: 'review $i dueDate (tz-aware local-day boundary)',
        );
        expect(
          card.lastReviewedAt!.toIso8601String(),
          expected['lastReviewedAtUtc'],
          reason: 'review $i lastReviewedAt (always stored as UTC)',
        );

        // Where the fixture records what a UTC-day fold would have produced,
        // prove the tz-aware boundary actually diverges from it — this is
        // the assertion that makes injected-clock goldens meaningful for
        // non-UTC users (roadmap §10).
        final utcFoldDueDate = review['utcFoldDueDate'] as String?;
        if (utcFoldDueDate != null) {
          final utcFolded = SrsEngine.processReview(
            cardBefore,
            rating,
            clock: () => clockUtc,
            localDayBoundary: SrsEngine.dayBoundaryForOffset(0),
          );
          expect(
            utcFolded.dueDate.toIso8601String(),
            utcFoldDueDate,
            reason: 'review $i UTC-fold control value',
          );
          expect(
            utcFolded.dueDate.toIso8601String(),
            isNot(card.dueDate.toIso8601String()),
            reason:
                'review $i: UTC folding must produce a DIFFERENT due date — '
                'otherwise this fixture no longer proves the tz boundary matters',
          );
        }
      }
    });
  }
}
