import 'dart:convert';
import 'dart:io';

import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

/// Golden SRS-fold suite (roadmap §5/§10): review facts + prior card state
/// → new card state. Covers the documented ordering rule (sort by
/// `reviewedAtUtc` then `id` before folding — array order must not
/// matter), in-batch duplicate dedup, the future-timestamp clamp, and the
/// unknown-card placeholder with a non-UTC day boundary. The server suite
/// executes these same fixtures.
void main() {
  final fixtureDir = Directory('test/fixtures/srs_fold');
  final fixtureFiles =
      fixtureDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('SRS-fold fixture directory is populated', () {
    expect(fixtureFiles, isNotEmpty);
  });

  for (final file in fixtureFiles) {
    final fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final name = file.uri.pathSegments.last;

    test('golden SRS fold: $name', () {
      final priorCards = <String, Flashcard>{
        for (final entry
            in (fixture['priorCards'] as Map<String, dynamic>).entries)
          entry.key: Flashcard.fromMap(
            (entry.value as Map).cast<String, dynamic>(),
          ),
      };
      final reviews = [
        for (final raw in fixture['reviewFacts'] as List)
          Fact.fromJson((raw as Map).cast<String, dynamic>()) as ReviewFact,
      ];
      final nowUtc = fixture['nowUtc'] == null
          ? null
          : DateTime.parse(fixture['nowUtc'] as String);

      SrsFoldResult run(Iterable<ReviewFact> input) =>
          SrsFold.fold(priorCards: priorCards, reviews: input, nowUtc: nowUtc);

      final result = run(reviews);

      final expected = fixture['expected'] as Map<String, dynamic>;
      final expectedCards = expected['cards'] as Map<String, dynamic>;
      for (final entry in expectedCards.entries) {
        final card = result.cards[entry.key];
        expect(card, isNotNull, reason: 'card ${entry.key} missing');
        final want = (entry.value as Map).cast<String, dynamic>();
        expect(
          card!.interval,
          (want['interval'] as num).toDouble(),
          reason: '${entry.key} interval',
        );
        expect(
          card.easeFactor,
          closeTo((want['easeFactor'] as num).toDouble(), 1e-12),
          reason: '${entry.key} easeFactor',
        );
        expect(
          card.dueDate.toIso8601String(),
          want['dueDate'],
          reason: '${entry.key} dueDate',
        );
        expect(
          card.lastReviewedAt!.toIso8601String(),
          want['lastReviewedAtUtc'],
          reason: '${entry.key} lastReviewedAt',
        );
        expect(
          card.reviewCount,
          want['reviewCount'],
          reason: '${entry.key} reviewCount',
        );
      }
      expect(
        result.placeholderCardIds,
        (expected['placeholderCardIds'] as List).cast<String>().toSet(),
      );
      expect(
        result.appliedFactIds,
        (expected['appliedFactIds'] as List).cast<String>(),
        reason: 'applied fact ids in fold order',
      );

      // Order independence: reversing the input array changes nothing.
      final reversed = run(reviews.reversed.toList());
      for (final id in result.cards.keys) {
        expect(
          reversed.cards[id]!.toMap(),
          result.cards[id]!.toMap(),
          reason: 'fold must be input-order independent ($id)',
        );
      }

      // Replay idempotency: ids already applied are skipped entirely.
      final replay = SrsFold.fold(
        priorCards: result.cards,
        reviews: reviews,
        priorPlaceholderIds: result.placeholderCardIds,
        alreadyAppliedFactIds: result.appliedFactIds.toSet(),
        nowUtc: nowUtc,
      );
      expect(
        replay.appliedFactIds,
        isEmpty,
        reason: 'replayed batch must apply nothing',
      );
      for (final id in result.cards.keys) {
        expect(
          replay.cards[id]!.toMap(),
          result.cards[id]!.toMap(),
          reason: 'replay must not change canonical state ($id)',
        );
      }
    });
  }

  test('placeholder identity attaches from a late cardCreated fact', () {
    final created = CardCreatedFact(
      id: '9e107d9d-372b-4cde-8a3e-1a9b6c2d4e5f',
      coreVersion: hifzCoreVersion,
      profileId: 'p1',
      type: FlashcardType.surahDetective,
      verseKey: '3:21',
      questionData: '{}',
      answerData: '{}',
      createdAtUtc: DateTime.utc(2026, 6, 10, 12),
    );
    final placeholder = SrsFold.placeholderCard(
      cardId: created.id,
      firstSeenUtc: DateTime.utc(2026, 6, 10, 21, 30),
      tzOffsetMinutes: 180,
    );
    final folded = SrsEngine.processReview(
      placeholder,
      FlashcardRating.strong,
      clock: () => DateTime.utc(2026, 6, 10, 21, 30),
      localDayBoundary: SrsEngine.dayBoundaryForOffset(180),
    );

    final attached = SrsFold.attachIdentity(folded, created);
    expect(attached.profileId, 'p1');
    expect(attached.verseKey, '3:21');
    expect(attached.type, FlashcardType.surahDetective);
    // SRS state survives — the reviews already happened.
    expect(attached.interval, folded.interval);
    expect(attached.easeFactor, folded.easeFactor);
    expect(attached.dueDate, folded.dueDate);
    expect(attached.reviewCount, folded.reviewCount);

    expect(
      () => SrsFold.attachIdentity(
        folded,
        CardCreatedFact(
          id: '11111111-1111-4111-8111-111111111111',
          coreVersion: hifzCoreVersion,
          profileId: 'p1',
          type: FlashcardType.nextVerse,
          verseKey: '1:1',
          questionData: '{}',
          answerData: '{}',
          createdAtUtc: DateTime.utc(2026, 6, 10),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('fromCardCreated builds a fresh, immediately-due card', () {
    final created = CardCreatedFact(
      id: '9e107d9d-372b-4cde-8a3e-1a9b6c2d4e5f',
      coreVersion: hifzCoreVersion,
      profileId: 'p1',
      type: FlashcardType.nextVerse,
      verseKey: '2:255',
      questionData: '{"q":1}',
      answerData: '{"a":1}',
      createdAtUtc: DateTime.utc(2026, 6, 10, 12),
    );
    final card = SrsFold.fromCardCreated(created);
    expect(card.id, created.id);
    expect(card.interval, 1.0);
    expect(card.easeFactor, 2.5);
    expect(card.reviewCount, 0);
    expect(card.dueDate, created.createdAtUtc);
  });
}
