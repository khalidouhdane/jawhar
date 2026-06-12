import 'dart:convert';

import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

/// Wire-contract tests for the `/v1` fact DTOs and reply types (roadmap
/// §5): JSON round-trips through real `jsonEncode`/`jsonDecode`, plus
/// strict bounds-checked rejection of malformed input ([FormatException] →
/// poisoned outbox row / 422, never silent coercion).
void main() {
  Map<String, dynamic> roundTrip(Map<String, dynamic> json) =>
      jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

  final sessionJson = <String, dynamic>{
    'kind': 'session',
    'id': '11111111-1111-4111-8111-111111111111',
    'coreVersion': '1.0.0',
    'profileId': 'p1',
    'date': '2026-06-10',
    'tzOffsetMinutes': 60,
    'durationMinutes': 38,
    'repCount': 14,
    'sabaq': {'completed': true, 'assessment': 2, 'page': 134},
    'sabqi': {
      'completed': true,
      'assessment': 1,
      'pages': [130, 131, 132, 133],
    },
    'manzil': {
      'completed': false,
      'assessment': null,
      'pages': [22, 23, 24],
    },
    'actualPagesCovered': [134, 135],
    'lastVerseLearned': 12,
    'totalVersesOnPage': 15,
    'planId': 'p1_2026-06-10T00:00:00.000',
    'planRevision': 1,
    'planOrigin': 'server',
    'recordedAtUtc': '2026-06-10T19:04:11.000Z',
  };

  group('SessionFact', () {
    test('round-trips the §5 wire shape', () {
      final fact = Fact.fromJson(roundTrip(sessionJson)) as SessionFact;
      expect(fact.id, sessionJson['id']);
      expect(fact.date, '2026-06-10');
      expect(fact.tzOffsetMinutes, 60);
      expect(fact.sabaq.assessment, SelfAssessment.needsWork);
      expect(fact.sabaq.page, 134);
      expect(fact.sabqi.pages, [130, 131, 132, 133]);
      expect(fact.manzil.completed, isFalse);
      expect(fact.manzil.assessment, isNull);
      expect(fact.actualPagesCovered, [134, 135]);
      expect(fact.planOrigin, PlanOrigin.server);
      expect(fact.recordedAtUtc, DateTime.utc(2026, 6, 10, 19, 4, 11));
      expect(fact.recordedAtUtc.isUtc, isTrue);

      expect(roundTrip(fact.toJson()), sessionJson);
    });

    test('rejects malformed input strictly', () {
      Map<String, dynamic> mutated(String key, Object? value) => {
        ...sessionJson,
        key: value,
      };

      // Page bounds (1–604, same as firestore.rules).
      expect(
        () => Fact.fromJson(mutated('actualPagesCovered', [134, 605])),
        throwsFormatException,
      );
      expect(
        () => Fact.fromJson(mutated('sabaq', {'completed': true, 'page': 0})),
        throwsFormatException,
      );
      // Assessment index bounds.
      expect(
        () => Fact.fromJson(
          mutated('sabaq', {'completed': true, 'assessment': 3, 'page': 1}),
        ),
        throwsFormatException,
      );
      // Naive timestamp on a *Utc field.
      expect(
        () =>
            Fact.fromJson(mutated('recordedAtUtc', '2026-06-10T19:04:11.000')),
        throwsFormatException,
      );
      // Local date must be a real calendar date in YYYY-MM-DD.
      expect(
        () => Fact.fromJson(mutated('date', '2026-02-31')),
        throwsFormatException,
      );
      expect(
        () => Fact.fromJson(mutated('date', '2026-6-1')),
        throwsFormatException,
      );
      // tz offset outside UTC-12..UTC+14.
      expect(
        () => Fact.fromJson(mutated('tzOffsetMinutes', 900)),
        throwsFormatException,
      );
      // Non-UUID idempotency key.
      expect(
        () => Fact.fromJson(mutated('id', 'not-a-uuid')),
        throwsFormatException,
      );
      // Unknown planOrigin.
      expect(
        () => Fact.fromJson(mutated('planOrigin', 'cloud')),
        throwsFormatException,
      );
      // Negative duration.
      expect(
        () => Fact.fromJson(mutated('durationMinutes', -1)),
        throwsFormatException,
      );
      // Unknown kind.
      expect(
        () => Fact.fromJson(mutated('kind', 'sessionV2')),
        throwsFormatException,
      );
      // Path-unsafe profileId (becomes a Firestore doc-path filter and a
      // progress-doc field server-side).
      expect(
        () => Fact.fromJson(mutated('profileId', 'a/b')),
        throwsFormatException,
      );
      expect(
        () => Fact.fromJson(mutated('profileId', 'x' * 65)),
        throwsFormatException,
      );
    });

    test('page LISTS are length-capped (Firestore 500-write commit limit)',
        () {
      final oversize = List<int>.generate(
        FactBounds.maxPagesPerList + 1,
        (i) => (i % FactBounds.maxPage) + 1,
      );
      final atCap = oversize.sublist(0, FactBounds.maxPagesPerList);

      expect(
        () => Fact.fromJson({...sessionJson, 'actualPagesCovered': oversize}),
        throwsFormatException,
      );
      expect(
        () => Fact.fromJson({
          ...sessionJson,
          'sabqi': {'completed': true, 'assessment': 1, 'pages': oversize},
        }),
        throwsFormatException,
      );
      expect(
        () => Fact.fromJson({
          ...sessionJson,
          'manzil': {'completed': true, 'assessment': 1, 'pages': oversize},
        }),
        throwsFormatException,
      );
      // The cap itself is fine.
      expect(
        Fact.fromJson({...sessionJson, 'actualPagesCovered': atCap}),
        isA<SessionFact>(),
      );
    });
  });

  group('ReviewFact', () {
    final reviewJson = <String, dynamic>{
      'kind': 'review',
      'id': '22222222-2222-4222-8222-222222222222',
      'coreVersion': '1.0.0',
      'cardId': '9e107d9d-372b-4cde-8a3e-1a9b6c2d4e5f',
      'rating': 2,
      'reviewedAtUtc': '2026-06-10T19:20:00.000Z',
      'tzOffsetMinutes': 60,
      'clientComputed': {'interval': 1.0, 'easeFactor': 2.0},
    };

    test('round-trips, clientComputed is optional advisory telemetry', () {
      final fact = Fact.fromJson(roundTrip(reviewJson)) as ReviewFact;
      expect(fact.rating, FlashcardRating.weak);
      expect(fact.clientComputed!.interval, 1.0);
      expect(fact.clientComputed!.easeFactor, 2.0);
      expect(roundTrip(fact.toJson()), reviewJson);

      final bare =
          Fact.fromJson({...reviewJson}..remove('clientComputed'))
              as ReviewFact;
      expect(bare.clientComputed, isNull);
      expect(bare.toJson().containsKey('clientComputed'), isFalse);
    });

    test('rejects out-of-range rating (rules bound 0–3)', () {
      expect(
        () => Fact.fromJson({...reviewJson, 'rating': 4}),
        throwsFormatException,
      );
      expect(
        () => Fact.fromJson({...reviewJson, 'rating': -1}),
        throwsFormatException,
      );
    });

    test('cardId is charset-whitelisted (Firestore doc-path segment): '
        'UUIDs and legacy deterministic ids pass, `/` is rejected', () {
      expect(
        (Fact.fromJson({...reviewJson, 'cardId': 'p1_nv_3_21'}) as ReviewFact)
            .cardId,
        'p1_nv_3_21',
      );
      expect(
        () => Fact.fromJson({...reviewJson, 'cardId': 'a/b'}),
        throwsFormatException,
      );
      expect(
        () => Fact.fromJson({...reviewJson, 'cardId': 'x' * 65}),
        throwsFormatException,
      );
      expect(
        () => Fact.fromJson({...reviewJson, 'cardId': ''}),
        throwsFormatException,
      );
    });
  });

  group('CardCreatedFact', () {
    final cardJson = <String, dynamic>{
      'kind': 'cardCreated',
      'id': '9e107d9d-372b-4cde-8a3e-1a9b6c2d4e5f',
      'coreVersion': '1.0.0',
      'profileId': 'p1',
      'type': 3,
      'verseKey': '3:21',
      'questionData': '{"prompt":"…"}',
      'answerData': '{"answer":"…"}',
      'createdAtUtc': '2026-06-10T19:00:00.000Z',
    };

    test('round-trips with JSON-string blobs', () {
      final fact = Fact.fromJson(roundTrip(cardJson)) as CardCreatedFact;
      expect(fact.type, FlashcardType.verseCompletion);
      expect(fact.verseKey, '3:21');
      expect(roundTrip(fact.toJson()), cardJson);
    });

    test('rejects bad verse keys, types, and non-JSON blobs', () {
      expect(
        () => Fact.fromJson({...cardJson, 'verseKey': 'x'}),
        throwsFormatException,
      );
      expect(
        () => Fact.fromJson({...cardJson, 'type': 6}),
        throwsFormatException,
      );
      expect(
        () => Fact.fromJson({...cardJson, 'questionData': '{not json'}),
        throwsFormatException,
      );
    });

    test('blobs are length-capped (Firestore ~1 MiB doc limit must poison, '
        'not retry forever)', () {
      final oversize = '"${'x' * (FactBounds.maxCardBlobLength + 1)}"';
      expect(
        () => Fact.fromJson({...cardJson, 'questionData': oversize}),
        throwsFormatException,
      );
      expect(
        () => Fact.fromJson({...cardJson, 'answerData': oversize}),
        throwsFormatException,
      );
    });
  });

  group('PlanGeneratedFact', () {
    final planFactJson = <String, dynamic>{
      'kind': 'planGenerated',
      'id': '33333333-3333-4333-8333-333333333333',
      'coreVersion': '1.0.0',
      'profileId': 'p1',
      'date': '2026-06-10',
      'revision': 2,
      'plan': {
        'id': 'p1_2026-06-10T00:00:00.000',
        'profileId': 'p1',
        'date': '2026-06-10T00:00:00.000',
        'sabaqPage': 134,
        'sabaqLineStart': 5,
        'sabaqLineEnd': 8,
        'sabqiPages': '130,131',
        'manzilJuz': 29,
        'manzilPages': '562,563',
      },
    };

    test('round-trips; the plan payload never carries completion flags', () {
      final fact = Fact.fromJson(roundTrip(planFactJson)) as PlanGeneratedFact;
      expect(fact.revision, 2);
      expect(fact.plan.sabaqPage, 134);
      expect(fact.plan.sabqiPages, [130, 131]);

      final wire = fact.toJson();
      final planPayload = wire['plan'] as Map<String, dynamic>;
      expect(planPayload.containsKey('sabaqDoneOffline'), isFalse);
      expect(planPayload.containsKey('sabqiDoneOffline'), isFalse);
      expect(planPayload.containsKey('manzilDoneOffline'), isFalse);
      expect(planPayload.containsKey('isCompleted'), isFalse);

      // Round-trip through the stripped payload is lossless for plan
      // content (completion state intentionally excluded).
      final reparsed = Fact.fromJson(roundTrip(wire)) as PlanGeneratedFact;
      expect(
        PlanGeneratedFact.encodePlanPayload(reparsed.plan),
        PlanGeneratedFact.encodePlanPayload(fact.plan),
      );
    });

    test('rejects a negative revision and a broken plan payload', () {
      expect(
        () => Fact.fromJson({...planFactJson, 'revision': -1}),
        throwsFormatException,
      );
      expect(
        () => Fact.fromJson({
          ...planFactJson,
          'plan': {'id': 'x'}, // missing required profileId/date
        }),
        throwsFormatException,
      );
    });

    test('rejects an oversize aiReasoning blob and a path-unsafe profileId',
        () {
      expect(
        () => Fact.fromJson({
          ...planFactJson,
          'plan': {
            ...planFactJson['plan'] as Map<String, dynamic>,
            'aiReasoning': 'r' * (FactBounds.maxAiReasoningLength + 1),
          },
        }),
        throwsFormatException,
      );
      expect(
        () => Fact.fromJson({...planFactJson, 'profileId': 'a/b'}),
        throwsFormatException,
      );
    });
  });

  test('FactBatch round-trips a mixed batch in order', () {
    final batch = FactBatch.fromJson({
      'facts': [
        sessionJson,
        {
          'kind': 'review',
          'id': '22222222-2222-4222-8222-222222222222',
          'coreVersion': '1.0.0',
          'cardId': 'c1',
          'rating': 0,
          'reviewedAtUtc': '2026-06-10T19:20:00.000Z',
          'tzOffsetMinutes': 0,
        },
      ],
    });
    expect(batch.facts, hasLength(2));
    expect(batch.facts.first, isA<SessionFact>());
    expect(batch.facts.last, isA<ReviewFact>());
    final wire = roundTrip(batch.toJson());
    expect((wire['facts'] as List).first['kind'], 'session');
    expect((wire['facts'] as List).last['kind'], 'review');

    expect(() => FactBatch.fromJson({'facts': 'nope'}), throwsFormatException);
  });

  group('reply types', () {
    test('DatasetEpoch is a strict non-empty value type', () {
      expect(DatasetEpoch.parse('e1'), const DatasetEpoch('e1'));
      expect(const DatasetEpoch('e1') == const DatasetEpoch('e2'), isFalse);
      expect(const DatasetEpoch('e1').toJson(), 'e1');
      expect(() => DatasetEpoch.parse(''), throwsFormatException);
      expect(() => DatasetEpoch.parse(null), throwsFormatException);
      expect(() => DatasetEpoch.parse(7), throwsFormatException);
    });

    test('ApiError envelope matches the §5 error body', () {
      final envelope = ApiErrorEnvelope.fromJson({
        'error': {
          'code': 'validation',
          'message': 'page out of range',
          'retryable': false,
        },
      });
      expect(envelope.error.code, 'validation');
      expect(envelope.error.retryable, isFalse);
      expect(roundTrip(envelope.toJson()), {
        'error': {
          'code': 'validation',
          'message': 'page out of range',
          'retryable': false,
        },
      });
      expect(
        () => ApiErrorEnvelope.fromJson({
          'error': {'code': 'x'},
        }),
        throwsFormatException,
      );
    });

    test('FactsResponse round-trips the §5 reply shape', () {
      final responseJson = <String, dynamic>{
        'datasetEpoch': 'e1',
        'results': [
          {'id': '11111111-1111-4111-8111-111111111111', 'applied': true},
          {
            'id': '22222222-2222-4222-8222-222222222222',
            'applied': false,
            'error': {
              'code': 'validation',
              'message': 'bad page',
              'retryable': false,
            },
          },
        ],
        'derived': {
          'progress': [
            {
              'profileId': 'p1',
              'pageNumber': 134,
              'status': 2,
              'reviewCount': 1,
              'lastVerseLearned': 12,
              'totalVersesOnPage': null,
              'lastReviewedAt': '2026-06-10T19:04:11.000Z',
              'memorizedAt': null,
              'updatedAt': '2026-06-10T19:04:12.000Z',
            },
          ],
          'cards': [
            {
              'id': 'c1',
              'interval': 1.0,
              'easeFactor': 2.0,
              'dueDate': '2026-06-11T00:00:00.000',
              'reviewCount': 7,
              'lastReviewedAt': '2026-06-10T19:20:00.000Z',
              'isPlaceholder': true,
            },
          ],
          'streak': {'totalActiveDays': 41, 'lastActiveDate': '2026-06-10'},
          'plans': [
            {
              'id': 'p1_2026-06-10T00:00:00.000',
              'revision': 2,
              'isCompleted': false,
              'plan': {
                'id': 'p1_2026-06-10T00:00:00.000',
                'profileId': 'p1',
                'date': '2026-06-10T00:00:00.000',
                'sabaqPage': 135,
              },
            },
          ],
        },
      };

      final response = FactsResponse.fromJson(roundTrip(responseJson));
      expect(response.datasetEpoch, const DatasetEpoch('e1'));
      expect(response.results, hasLength(2));
      expect(response.results.first.applied, isTrue);
      expect(response.results.last.error!.code, 'validation');

      final progress = response.derived.progress.single;
      expect(progress.status, PageStatus.reviewing);
      expect(progress.toPageProgress().pageNumber, 134);
      expect(progress.toPageProgress().lastVerseLearned, 12);

      final card = response.derived.cards.single;
      expect(card.isPlaceholder, isTrue);
      expect(card.dueDate, DateTime(2026, 6, 11));
      expect(
        card.dueDate.isUtc,
        isFalse,
        reason: 'dueDate is a local-day concept, not an instant',
      );

      final streak = response.derived.streak!;
      expect(streak.toStreakData().totalActiveDays, 41);
      expect(streak.toStreakData().lastActiveDate, DateTime(2026, 6, 10));

      expect(response.derived.plans.single.plan.sabaqPage, 135);

      // Lossless round-trip back to the wire.
      final reencoded = roundTrip(response.toJson());
      expect(FactsResponse.fromJson(reencoded).toJson(), response.toJson());
      expect(reencoded['datasetEpoch'], 'e1');

      // ProgressDelta.fromPageProgress is the server-side constructor.
      final delta = ProgressDelta.fromPageProgress(
        progress.toPageProgress(),
        updatedAtUtc: DateTime.utc(2026, 6, 10, 19, 4, 12),
      );
      expect(delta.toJson(), progress.toJson());
    });

    test('FactsResponse rejects a missing datasetEpoch or bad results', () {
      expect(
        () => FactsResponse.fromJson({'results': []}),
        throwsFormatException,
      );
      expect(
        () => FactsResponse.fromJson({'datasetEpoch': 'e1', 'results': 'x'}),
        throwsFormatException,
      );
    });
  });
}
