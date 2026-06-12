// Contract tests for POST /v1/me/facts + /v1/me/backfill against the
// FIRESTORE EMULATOR — the roadmap §10 mandatory list. Run with:
//
//   firebase emulators:exec --only firestore --project quran-app-e5e86 ^
//     "cd server/api && dart test test/facts_firestore_test.dart"
//
// Without the emulator the suite is SKIPPED, not silently green.

import 'dart:convert';
import 'dart:io';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:hifz_core/hifz_core.dart';
import 'package:jawhar_api/gateway/firestore_gateway.dart';
import 'package:jawhar_api/middleware/auth.dart';
import 'package:jawhar_api/middleware/rate_limit.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/test_app.dart';

void main() {
  final emulatorHost = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  final skip = (emulatorHost == null || emulatorHost.isEmpty)
      ? 'FIRESTORE_EMULATOR_HOST not set — start the Firestore emulator '
          '(firebase emulators:exec --only firestore --project '
          'quran-app-e5e86 "cd server/api && dart test")'
      : null;

  group('POST /v1/me/facts (emulator)', () {
    late FirebaseApp app;
    late FirestoreGateway gateway;
    var run = 0;

    setUpAll(() {
      app = FirebaseApp.initializeApp(
        options: const AppOptions(projectId: 'demo-jawhar-facts-test'),
      );
      gateway = FirestoreGateway(app.firestore());
    });

    tearDownAll(() async {
      await app.close();
    });

    late String uid;
    late String token;
    setUp(() {
      uid = 'facts-uid-${DateTime.now().microsecondsSinceEpoch}-${run++}';
      token = 'tok-$uid';
    });

    final fixedNowUtc = DateTime.utc(2026, 6, 16, 12);

    Handler handler({TokenBucketRateLimiter? rateLimiter}) => buildTestHandler(
          gateway: gateway,
          nowUtc: () => fixedNowUtc,
          rateLimiter: rateLimiter,
          verifiedTokens: {
            token: VerifiedToken(uid: uid),
            'tok-b-$uid': VerifiedToken(uid: 'b-$uid'),
          },
        );

    Future<Response> post(
      String path,
      Map<String, dynamic> body, {
      String? asToken,
      Map<String, String> extraHeaders = const {},
      Handler? via,
    }) async =>
        (via ?? handler())(Request(
          'POST',
          Uri.parse('http://localhost$path'),
          headers: {
            'authorization': 'Bearer ${asToken ?? token}',
            'content-type': 'application/json',
            ...extraHeaders,
          },
          body: jsonEncode(body),
        ));

    Future<Response> get(String path, {String? asToken}) async =>
        handler()(Request(
          'GET',
          Uri.parse('http://localhost$path'),
          headers: {'authorization': 'Bearer ${asToken ?? token}'},
        ));

    Future<Map<String, dynamic>> body(Response response) async =>
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    // Same profile fixture as the plan contract tests: moderate/moderate ->
    // linesPerSession 4, starting page 582 (juz 30).
    MemoryProfile profile() => MemoryProfile(
          id: 'p1',
          name: 'Tester',
          createdAt: DateTime(2026, 1, 1),
          startDate: DateTime(2026, 1, 1),
        );

    Future<void> seedProfile() => gateway.setDoc('users/$uid', {
          ...profile().toMap(),
          'updatedAt': fixedNowUtc.toIso8601String(),
        });

    Map<String, dynamic> sessionFact({
      required String id,
      required String date,
      int? sabaqPage,
      List<int> covered = const [],
      List<int> sabqiPages = const [],
      List<int> manzilPages = const [],
      int? manzilAssessment,
      int planRevision = 0,
      required String recordedAtUtc,
      int? lastVerseLearned,
      int? totalVersesOnPage,
      String profileId = 'p1',
    }) =>
        {
          'kind': 'session',
          'id': id,
          'coreVersion': hifzCoreVersion,
          'profileId': profileId,
          'date': date,
          'tzOffsetMinutes': 60,
          'durationMinutes': 30,
          'repCount': 20,
          'sabaq': {
            'completed': sabaqPage != null,
            'assessment': sabaqPage != null ? 2 : null,
            'page': sabaqPage,
          },
          'sabqi': {
            'completed': sabqiPages.isNotEmpty,
            'assessment': sabqiPages.isNotEmpty ? 1 : null,
            'pages': sabqiPages,
          },
          'manzil': {
            'completed': manzilPages.isNotEmpty,
            'assessment': manzilPages.isNotEmpty ? (manzilAssessment ?? 0) : null,
            'pages': manzilPages,
          },
          'actualPagesCovered': covered,
          'lastVerseLearned': lastVerseLearned,
          'totalVersesOnPage': totalVersesOnPage,
          'planId': 'p1_${date}T00:00:00.000',
          'planRevision': planRevision,
          'planOrigin': 'server',
          'recordedAtUtc': recordedAtUtc,
        };

    const u1 = 'a1111111-1111-4111-8111-111111111111';
    const u2 = 'a2222222-2222-4222-8222-222222222222';
    const u3 = 'a3333333-3333-4333-8333-333333333333';
    const u4 = 'a4444444-4444-4444-8444-444444444444';
    const cardId = 'cc111111-1111-4111-8111-111111111111';

    // ── §10: byte-identical replay ───────────────────────────────────────

    test('byte-identical replay: same batch twice -> applied:false, '
        'identical derived state, no double-counting', () async {
      await seedProfile();
      final batch = {
        'facts': [
          sessionFact(
            id: u1,
            date: '2026-06-15',
            sabaqPage: 582,
            covered: [582],
            recordedAtUtc: '2026-06-15T10:00:00Z',
            lastVerseLearned: 4,
            totalVersesOnPage: 9,
          ),
        ],
      };

      final first = await post('/v1/me/facts', batch);
      expect(first.statusCode, 200);
      final firstBody = await body(first);
      expect(firstBody['datasetEpoch'], 'e1');
      final firstResults = firstBody['results'] as List<dynamic>;
      expect(firstResults, hasLength(1));
      expect((firstResults.single as Map)['applied'], true);

      final second = await post('/v1/me/facts', batch);
      expect(second.statusCode, 200);
      final secondBody = await body(second);
      final secondResults = secondBody['results'] as List<dynamic>;
      expect((secondResults.single as Map)['applied'], false);
      expect((secondResults.single as Map).containsKey('error'), isFalse,
          reason: 'a replay is never an error');

      // Byte-identical apart from the applied flag: derived state matches
      // exactly (decoded JSON — Firestore guarantees no field order).
      expect(secondBody['derived'], firstBody['derived']);
      expect(secondBody['datasetEpoch'], firstBody['datasetEpoch']);

      // No double-counting in storage.
      final progressDoc = await gateway.getDoc('users/$uid/progress/582');
      expect(progressDoc!['reviewCount'], 1);
      expect(progressDoc['status'], 1 /* learning */);
      expect(progressDoc['lastVerseLearned'], 4);
      final streakDoc = await gateway.getDoc('users/$uid/meta/streak');
      expect(streakDoc!['totalActiveDays'], 1);
    });

    // ── §10: kill-mid-drain double flush ─────────────────────────────────

    test('kill-mid-drain: overlapping second flush re-sends applied facts '
        'without double-counting, applies the new ones', () async {
      await seedProfile();
      final f1 = sessionFact(
        id: u1,
        date: '2026-06-15',
        sabaqPage: 582,
        covered: [582],
        recordedAtUtc: '2026-06-15T10:00:00Z',
      );
      final f2 = sessionFact(
        id: u2,
        date: '2026-06-16',
        sabaqPage: 582,
        covered: [582],
        planRevision: 1,
        recordedAtUtc: '2026-06-16T10:00:00Z',
      );

      // First drain delivers f1, then the app dies before marking it sent.
      expect((await post('/v1/me/facts', {'facts': [f1]})).statusCode, 200);

      // Relaunch flushes the whole outbox again: f1 (replay) + f2 (new).
      final response = await post('/v1/me/facts', {'facts': [f1, f2]});
      expect(response.statusCode, 200);
      final results = (await body(response))['results'] as List<dynamic>;
      expect((results[0] as Map)['id'], u1);
      expect((results[0] as Map)['applied'], false);
      expect((results[1] as Map)['id'], u2);
      expect((results[1] as Map)['applied'], true);

      // One increment per DISTINCT fact: two sessions touched page 582.
      final progressDoc = await gateway.getDoc('users/$uid/progress/582');
      expect(progressDoc!['reviewCount'], 2, reason: 'f1 once + f2 once');
      final streakDoc = await gateway.getDoc('users/$uid/meta/streak');
      expect(streakDoc!['totalActiveDays'], 2, reason: 'two distinct days');
      // Both session docs exist exactly once.
      expect(await gateway.getDoc('users/$uid/sessions/$u1'), isNotNull);
      expect(await gateway.getDoc('users/$uid/sessions/$u2'), isNotNull);
    });

    // ── §10: enqueue-under-A / flush-under-B isolation ───────────────────

    test('uid comes from the token, never the body: a batch flushed under '
        'B lands entirely under B', () async {
      await seedProfile(); // profile for A only
      final fact = sessionFact(
        id: u3,
        date: '2026-06-15',
        sabaqPage: 582,
        covered: [582],
        recordedAtUtc: '2026-06-15T10:00:00Z',
      );

      // The outbox rows were enqueued under A but the device switched to B
      // before the flush: the server attributes them to B, full stop.
      final response =
          await post('/v1/me/facts', {'facts': [fact]}, asToken: 'tok-b-$uid');
      expect(response.statusCode, 200);
      final results = (await body(response))['results'] as List<dynamic>;
      expect((results.single as Map)['applied'], true);

      // Everything under users/b-...; NOTHING under users/A.
      expect(await gateway.getDoc('users/b-$uid/sessions/$u3'), isNotNull);
      expect(await gateway.getDoc('users/b-$uid/progress/582'), isNotNull);
      expect(await gateway.getDoc('users/$uid/sessions/$u3'), isNull);
      expect(await gateway.getDoc('users/$uid/progress/582'), isNull);
      expect(await gateway.getDoc('users/$uid/meta/streak'), isNull);

      // Dedup memory is partitioned per uid: the same fact id still applies
      // under A afterwards (it is A's own fact).
      final replayUnderA = await post('/v1/me/facts', {'facts': [fact]});
      final aResults = (await body(replayUnderA))['results'] as List<dynamic>;
      expect((aResults.single as Map)['applied'], true,
          reason: 'the (uid, fact.id) upsert key includes the uid');
      expect(await gateway.getDoc('users/$uid/sessions/$u3'), isNotNull);
    });

    // ── §10: unknown-card review placeholder + late identity attach ──────

    test('review for an unknown card creates placeholder SRS state; the '
        'late cardCreated attaches identity and keeps the folded state',
        () async {
      final review = {
        'kind': 'review',
        'id': u1,
        'coreVersion': hifzCoreVersion,
        'cardId': cardId,
        'rating': 0 /* strong */,
        'reviewedAtUtc': '2026-06-15T20:00:00Z',
        'tzOffsetMinutes': 120,
      };

      final response = await post('/v1/me/facts', {'facts': [review]});
      expect(response.statusCode, 200);
      final derived = (await body(response))['derived'] as Map<String, dynamic>;
      final card = (derived['cards'] as List).single as Map<String, dynamic>;
      expect(card['id'], cardId);
      expect(card['isPlaceholder'], true);
      expect(card['reviewCount'], 1);

      // Placeholder lives OUTSIDE flashcards/ (legacy pull never sees it);
      // the legacy review-event doc exists.
      expect(await gateway.getDoc('users/$uid/flashcards/$cardId'), isNull);
      final placeholder =
          await gateway.getDoc('users/$uid/srs_placeholders/$cardId');
      expect(placeholder, isNotNull);
      expect(placeholder!['isPlaceholder'], true);
      final reviewDoc =
          await gateway.getDoc('users/$uid/flashcard_reviews/$u1');
      expect(reviewDoc, isNotNull);
      expect(reviewDoc!['card_id'], cardId);
      expect(reviewDoc['rating'], 0);

      // The cardCreated fact arrives late (fact id IS the card id).
      final created = {
        'kind': 'cardCreated',
        'id': cardId,
        'coreVersion': hifzCoreVersion,
        'profileId': 'p1',
        'type': 0,
        'verseKey': '2:255',
        'questionData': '{"verse":"..."}',
        'answerData': '{"answer":"..."}',
        'createdAtUtc': '2026-06-15T19:00:00Z',
      };
      final attach = await post('/v1/me/facts', {'facts': [created]});
      expect(attach.statusCode, 200);
      final attachedDerived =
          (await body(attach))['derived'] as Map<String, dynamic>;
      final attachedCard =
          (attachedDerived['cards'] as List).single as Map<String, dynamic>;
      expect(attachedCard['isPlaceholder'], anyOf(isNull, false));
      expect(attachedCard['reviewCount'], 1,
          reason: 'the folded SRS state survives the identity attach');

      final cardDoc = await gateway.getDoc('users/$uid/flashcards/$cardId');
      expect(cardDoc, isNotNull);
      expect(cardDoc!['verse_key'], '2:255');
      expect(cardDoc['review_count'], 1);
      expect(cardDoc['question_data'], '{"verse":"..."}');
      expect(
        await gateway.getDoc('users/$uid/srs_placeholders/$cardId'),
        isNull,
        reason: 'placeholder is consumed by the identity attach',
      );
    });

    // ── §10: plan revision conflict (offline claim vs regeneration) ──────

    test('plan revision conflict: lower/tied offline claim loses to the '
        'server regeneration, higher claim wins', () async {
      await seedProfile();

      // Server regenerates revision 1 after a session fact.
      final session = sessionFact(
        id: u1,
        date: '2026-06-15',
        sabaqPage: 582,
        covered: [582],
        recordedAtUtc: '2026-06-15T10:00:00Z',
      );
      final sessionResponse = await post('/v1/me/facts', {'facts': [session]});
      final sessionDerived =
          (await body(sessionResponse))['derived'] as Map<String, dynamic>;
      final regenerated =
          (sessionDerived['plans'] as List).single as Map<String, dynamic>;
      expect(regenerated['revision'], 1);
      final serverSabaqPage =
          (regenerated['plan'] as Map<String, dynamic>)['sabaqPage'];

      Map<String, dynamic> claim(String id, int revision) => {
            'kind': 'planGenerated',
            'id': id,
            'coreVersion': hifzCoreVersion,
            'profileId': 'p1',
            'date': '2026-06-15',
            'revision': revision,
            'plan': DailyPlan(
              id: 'p1_2026-06-15T00:00:00.000',
              profileId: 'p1',
              date: DateTime(2026, 6, 15),
              sabaqPage: 600,
            ).toMap()
              ..remove('sabaqDoneOffline')
              ..remove('sabqiDoneOffline')
              ..remove('manzilDoneOffline')
              ..remove('isCompleted'),
          };

      // Tie (revision 1): incumbent server copy wins; the claim is still
      // CONSUMED and the canonical plan is returned for adoption.
      final tie = await post('/v1/me/facts', {'facts': [claim(u2, 1)]});
      final tieBody = await body(tie);
      expect(((tieBody['results'] as List).single as Map)['applied'], true);
      final tiePlan = (tieBody['derived'] as Map<String, dynamic>)['plans']
          as List<dynamic>;
      final tieCanonical = tiePlan.single as Map<String, dynamic>;
      expect(tieCanonical['revision'], 1);
      expect((tieCanonical['plan'] as Map<String, dynamic>)['sabaqPage'],
          serverSabaqPage,
          reason: 'ties go to the incumbent server copy');
      final storedAfterTie = await gateway
          .getDoc('users/$uid/plans/p1_2026-06-15T00:00:00.000');
      expect(storedAfterTie!['sabaqPage'], serverSabaqPage);
      expect(storedAfterTie['source'], 'server-deterministic');

      // Higher revision: the offline claim is adopted.
      final win = await post('/v1/me/facts', {'facts': [claim(u3, 5)]});
      final winBody = await body(win);
      final winCanonical = ((winBody['derived']
              as Map<String, dynamic>)['plans'] as List<dynamic>)
          .single as Map<String, dynamic>;
      expect(winCanonical['revision'], 5);
      expect((winCanonical['plan'] as Map<String, dynamic>)['sabaqPage'], 600);
      final storedAfterWin = await gateway
          .getDoc('users/$uid/plans/p1_2026-06-15T00:00:00.000');
      expect(storedAfterWin!['revision'], 5);
      expect(storedAfterWin['sabaqPage'], 600);
      expect(storedAfterWin['source'], 'client-offline');

      // GET /v1/me/plan serves the highest revision (§5 end-to-end).
      final plan = await body(await get('/v1/me/plan?date=2026-06-15'));
      expect(plan['revision'], 5);
      expect((plan['plan'] as Map<String, dynamic>)['sabaqPage'], 600);
    });

    // ── §5 plan semantics: regenerate-after-session carry-over ───────────

    test('session fact regenerates the next-revision plan with sabaq '
        'carry-over; GET /v1/me/plan serves it', () async {
      await seedProfile();

      // Get-or-create revision 0: fresh user -> sabaq 582 lines 1-4.
      final initial = await body(await get('/v1/me/plan?date=2026-06-15'));
      expect(initial['revision'], 0);
      final initialPlan = initial['plan'] as Map<String, dynamic>;
      expect(initialPlan['sabaqPage'], 582);
      expect(initialPlan['sabaqLineStart'], 1);
      expect(initialPlan['sabaqLineEnd'], 4);

      final response = await post('/v1/me/facts', {
        'facts': [
          sessionFact(
            id: u4,
            date: '2026-06-15',
            sabaqPage: 582,
            covered: [582],
            recordedAtUtc: '2026-06-15T10:00:00Z',
          ),
        ],
      });
      expect(response.statusCode, 200);
      final derived = (await body(response))['derived'] as Map<String, dynamic>;

      final planDelta = (derived['plans'] as List).single as Map<String, dynamic>;
      expect(planDelta['id'], 'p1_2026-06-15T00:00:00.000');
      expect(planDelta['revision'], 1);
      expect(planDelta['isCompleted'], false,
          reason: 'canonical latest is the fresh uncompleted next revision');
      final nextPlan = planDelta['plan'] as Map<String, dynamic>;
      expect(nextPlan['sabaqPage'], 582);
      expect(nextPlan['sabaqLineStart'], 5,
          reason: 'sabaq line carry-over from the completed revision');
      expect(nextPlan['sabaqLineEnd'], 8);

      // Derived progress and streak ride the same response.
      final progressDelta =
          (derived['progress'] as List).single as Map<String, dynamic>;
      expect(progressDelta['pageNumber'], 582);
      expect(progressDelta['status'], 1 /* learning */);
      expect(progressDelta['reviewCount'], 1);
      final streak = derived['streak'] as Map<String, dynamic>;
      expect(streak['totalActiveDays'], 1);
      expect(streak['lastActiveDate'], '2026-06-15');

      // The plan read path returns the regenerated revision, recipes included.
      final after = await body(await get('/v1/me/plan?date=2026-06-15'));
      expect(after['revision'], 1);
      expect(after['source'], 'server-deterministic');
      expect((after['plan'] as Map<String, dynamic>)['sabaqLineStart'], 5);
      expect(after['sessionRecipes'], isNotEmpty);
    });

    // ── §10: datasetEpoch mismatch ───────────────────────────────────────

    test('datasetEpoch mismatch: stale X-Dataset-Epoch is refused with 409 '
        'before any write; matching epoch proceeds', () async {
      await seedProfile();
      final batch = {
        'facts': [
          sessionFact(
            id: u1,
            date: '2026-06-15',
            sabaqPage: 582,
            covered: [582],
            recordedAtUtc: '2026-06-15T10:00:00Z',
          ),
        ],
      };

      final stale = await post(
        '/v1/me/facts',
        batch,
        extraHeaders: {'x-dataset-epoch': 'e0'},
      );
      expect(stale.statusCode, 409);
      final staleBody = await body(stale);
      final error = staleBody['error'] as Map<String, dynamic>;
      expect(error['code'], 'dataset-epoch-mismatch');
      expect(error['retryable'], false);
      expect(staleBody['datasetEpoch'], 'e1',
          reason: 'the 409 carries the CURRENT epoch so the refused client '
              'can adopt it while executing the reset policy');
      expect(await gateway.getDoc('users/$uid/sessions/$u1'), isNull,
          reason: 'a stale outbox must not flush into a new data generation');

      final fresh = await post(
        '/v1/me/facts',
        batch,
        extraHeaders: {'x-dataset-epoch': 'e1'},
      );
      expect(fresh.statusCode, 200);
      expect((await body(fresh))['datasetEpoch'], 'e1');
    });

    // ── §10 extra: dual-window derivation over the legacy mirror ─────────

    test('dual-window: derivations fold ON TOP of legacy-writer mirror docs '
        '(progress counts, streak, plan carry-over)', () async {
      await seedProfile();
      // A legacy device blind-wrote these (CloudSyncService shapes).
      await gateway.setDoc('users/$uid/progress/582', {
        ...PageProgress(
          pageNumber: 582,
          profileId: 'p1',
          status: PageStatus.learning,
          lastReviewedAt: DateTime.utc(2026, 6, 14, 9),
          reviewCount: 2,
        ).toMap(),
        'updatedAt': '2026-06-14T09:00:00.000Z',
      });
      await gateway.setDoc('users/$uid/meta/streak', {
        'totalActiveDays': 41,
        'lastActiveDate': '2026-06-14T00:00:00.000',
        'updatedAt': '2026-06-14T09:00:00.000Z',
      });
      // Legacy revision-less client plan for the day (today's mirror shape).
      await gateway.setDoc(
        'users/$uid/plans/p1_2026-06-15T00:00:00.000',
        DailyPlan(
          id: 'p1_2026-06-15T00:00:00.000',
          profileId: 'p1',
          date: DateTime(2026, 6, 15),
          sabaqPage: 582,
          sabaqLineStart: 5,
          sabaqLineEnd: 8,
        ).toMap(),
      );

      final response = await post('/v1/me/facts', {
        'facts': [
          sessionFact(
            id: u2,
            date: '2026-06-15',
            sabaqPage: 582,
            covered: [582],
            recordedAtUtc: '2026-06-15T10:00:00Z',
          ),
        ],
      });
      expect(response.statusCode, 200);
      final derived = (await body(response))['derived'] as Map<String, dynamic>;

      final progress =
          (derived['progress'] as List).single as Map<String, dynamic>;
      expect(progress['reviewCount'], 3,
          reason: 'increments the LEGACY doc count (2), not from zero');

      final streak = derived['streak'] as Map<String, dynamic>;
      expect(streak['totalActiveDays'], 42,
          reason: 'extends the legacy streak, never restarts it');
      expect(streak['lastActiveDate'], '2026-06-15');

      final plan = (derived['plans'] as List).single as Map<String, dynamic>;
      expect(plan['revision'], 1,
          reason: 'legacy revision-less doc counts as revision 0');
      expect((plan['plan'] as Map<String, dynamic>)['sabaqLineStart'], 9,
          reason: 'carry-over continues from the LEGACY plan (lines 5-8)');
    });

    // ── Multi-profile keyspace guard ─────────────────────────────────────

    test('two profiles, same page number: a foreign-profile session is '
        'logged + mirrored but never clobbers the root profile\'s '
        'page-keyed progress or singleton streak', () async {
      await seedProfile(); // root mirror = p1

      // Root profile learns page 590.
      final rootResponse = await post('/v1/me/facts', {
        'facts': [
          sessionFact(
            id: u1,
            date: '2026-06-15',
            sabaqPage: 590,
            covered: [590],
            recordedAtUtc: '2026-06-15T10:00:00Z',
          ),
        ],
      });
      expect(rootResponse.statusCode, 200);

      // A second local profile on the same device covers the SAME page.
      final foreignFact = sessionFact(
        id: u2,
        date: '2026-06-16',
        sabaqPage: 590,
        covered: [590],
        profileId: 'p2',
        recordedAtUtc: '2026-06-16T08:00:00Z',
      );
      final foreign = await post('/v1/me/facts', {'facts': [foreignFact]});
      expect(foreign.statusCode, 200);
      final foreignBody = await body(foreign);
      expect(((foreignBody['results'] as List).single as Map)['applied'], true,
          reason: 'the fact is consumed (logged + session doc), not refused');
      final derived = foreignBody['derived'] as Map<String, dynamic>;
      expect(derived['progress'], isEmpty);
      expect(derived['streak'], isNull);
      expect(derived['plans'], isEmpty);

      // p1's progress doc untouched (NOT overwritten with p2 prior=empty).
      final progressDoc = await gateway.getDoc('users/$uid/progress/590');
      expect(progressDoc!['profileId'], 'p1');
      expect(progressDoc['reviewCount'], 1);
      // The singleton streak still counts only the root profile's day.
      final streakDoc = await gateway.getDoc('users/$uid/meta/streak');
      expect(streakDoc!['totalActiveDays'], 1);

      // Nothing lost: fact logged (re-derivable later) + session doc.
      expect(await gateway.getDoc('users/$uid/facts/$u2'), isNotNull);
      expect(await gateway.getDoc('users/$uid/sessions/$u2'), isNotNull);

      // Replay answers applied:false with the SAME (empty) delta set.
      final replay = await post('/v1/me/facts', {'facts': [foreignFact]});
      final replayBody = await body(replay);
      expect(
          ((replayBody['results'] as List).single as Map)['applied'], false);
      expect(replayBody['derived'], foreignBody['derived']);
    });

    // ── Clock-skew guards (f342e80 class, session-dated facts) ───────────

    test('far-future date is rejected as poison; tomorrow-in-UTC+14 is '
        'accepted; future recordedAtUtc is clamped before derivation',
        () async {
      await seedProfile();
      // fixedNowUtc = 2026-06-16T12:00Z.

      // +1 year: one such fact would freeze the streak fold for years.
      final farFuture = sessionFact(
        id: u1,
        date: '2027-06-16',
        sabaqPage: 582,
        covered: [582],
        recordedAtUtc: '2027-06-16T10:00:00Z',
      );
      final rejected = await post('/v1/me/facts', {'facts': [farFuture]});
      expect(rejected.statusCode, 200);
      final result =
          ((await body(rejected))['results'] as List).single as Map;
      expect(result['applied'], false);
      expect((result['error'] as Map)['code'], 'invalid-argument');
      expect((result['error'] as Map)['retryable'], false,
          reason: 'poison, visible in the debug screen — never retried');
      expect(await gateway.getDoc('users/$uid/sessions/$u1'), isNull);
      expect(await gateway.getDoc('users/$uid/facts/$u1'), isNull);
      expect(await gateway.getDoc('users/$uid/meta/streak'), isNull);

      // UTC+14 (Kiribati): client-local now is 2026-06-17T02:00 — a fact
      // dated "tomorrow in UTC" is TODAY on the client's own clock.
      final kiribati = {
        ...sessionFact(
          id: u2,
          date: '2026-06-17',
          sabaqPage: 582,
          covered: [582],
          recordedAtUtc: '2026-06-16T11:00:00Z',
        ),
        'tzOffsetMinutes': 840,
      };
      final accepted = await post('/v1/me/facts', {'facts': [kiribati]});
      expect(
          (((await body(accepted))['results'] as List).single
              as Map)['applied'],
          true);

      // Future planGenerated claims are guarded the same way.
      final futureClaim = {
        'kind': 'planGenerated',
        'id': u3,
        'coreVersion': hifzCoreVersion,
        'profileId': 'p1',
        'date': '2027-01-01',
        'revision': 1,
        'plan': DailyPlan(
          id: 'p1_2027-01-01T00:00:00.000',
          profileId: 'p1',
          date: DateTime(2027, 1, 1),
          sabaqPage: 600,
        ).toMap()
          ..remove('sabaqDoneOffline')
          ..remove('sabqiDoneOffline')
          ..remove('manzilDoneOffline')
          ..remove('isCompleted'),
      };
      final claimRejected =
          await post('/v1/me/facts', {'facts': [futureClaim]});
      final claimResult =
          ((await body(claimRejected))['results'] as List).single as Map;
      expect(claimResult['applied'], false);
      expect((claimResult['error'] as Map)['retryable'], false);

      // Valid date but recordedAtUtc an hour ahead: clamped to server now
      // so derived `updatedAt` stamps never sit in the future (Phase 5
      // `?since=` delta pulls).
      final skewed = sessionFact(
        id: u4,
        date: '2026-06-16',
        sabaqPage: 583,
        covered: [583],
        recordedAtUtc: '2026-06-16T13:00:00Z',
      );
      await post('/v1/me/facts', {'facts': [skewed]});
      final progressDoc = await gateway.getDoc('users/$uid/progress/583');
      expect(progressDoc!['updatedAt'], fixedNowUtc.toIso8601String(),
          reason: 'future recordedAtUtc clamped to the server clock');
      // The dedup log keeps the client's ORIGINAL (unclamped) instant —
      // re-encoded through the wire codec, hence the .000 millis.
      final log = await gateway.getDoc('users/$uid/facts/$u4');
      expect(
        (log!['fact'] as Map)['recordedAtUtc'],
        '2026-06-16T13:00:00.000Z',
      );
    });

    // ── §10 extra: quota/rate-limit still enforced on facts ──────────────

    test('per-uid rate limit applies to the facts route', () async {
      final limited = handler(
        rateLimiter: TokenBucketRateLimiter(
          capacity: 1,
          refillPerMinute: 0.0001,
        ),
      );
      final first =
          await post('/v1/me/facts', {'facts': <Object>[]}, via: limited);
      expect(first.statusCode, 200);
      final second =
          await post('/v1/me/facts', {'facts': <Object>[]}, via: limited);
      expect(second.statusCode, 429);
      final error = (await body(second))['error'] as Map<String, dynamic>;
      expect(error['code'], 'rate-limited');
      expect(error['retryable'], true);
    });

    // ── Poison isolation ─────────────────────────────────────────────────

    test('one poisoned item never blocks the queue: per-item 422-class '
        'errors, the rest of the batch applies', () async {
      await seedProfile();
      final response = await post('/v1/me/facts', {
        'facts': [
          sessionFact(
            id: u1,
            date: '2026-06-15',
            sabaqPage: 582,
            covered: [582],
            recordedAtUtc: '2026-06-15T10:00:00Z',
          ),
          // page out of the 1-604 rules bounds -> typed validator rejects
          sessionFact(
            id: u2,
            date: '2026-06-15',
            sabaqPage: 9999,
            recordedAtUtc: '2026-06-15T11:00:00Z',
          ),
          {'kind': 'bogus', 'id': u3},
          'not-even-an-object',
        ],
      });
      expect(response.statusCode, 200);
      final results = (await body(response))['results'] as List<dynamic>;
      expect(results, hasLength(4));

      final byId = {
        for (final r in results.cast<Map<String, dynamic>>()) r['id']: r,
      };
      expect(byId[u1]!['applied'], true);

      for (final poisoned in [byId[u2]!, byId[u3]!, byId['#3']!]) {
        expect(poisoned['applied'], false);
        final error = poisoned['error'] as Map<String, dynamic>;
        expect(error['code'], 'invalid-argument');
        expect(error['retryable'], false,
            reason: 'validation failures poison the outbox row, no retry');
      }

      // The valid fact really applied.
      expect(await gateway.getDoc('users/$uid/sessions/$u1'), isNotNull);
      expect(await gateway.getDoc('users/$uid/sessions/$u2'), isNull);
    });

    // ── §10: multi-page actualPagesCovered parity (shared golden) ────────

    test('multi-page completeSession parity: derived progress docs are '
        'byte-identical to the hifz_core golden fixture', () async {
      await seedProfile();
      final fixture = jsonDecode(
        File(
          '../../packages/hifz_core/test/fixtures/progress_promotion/'
          'multi_page_session_parity.json',
        ).readAsStringSync(),
      ) as Map<String, dynamic>;

      for (final raw in fixture['priorProgress'] as List<dynamic>) {
        final doc = (raw as Map).cast<String, dynamic>();
        await gateway.setDoc(
          'users/$uid/progress/${doc['pageNumber']}',
          {...doc, 'updatedAt': '2026-06-09T10:00:00.000Z'},
        );
      }

      final response = await post(
        '/v1/me/facts',
        {'facts': fixture['sessionFacts']},
      );
      expect(response.statusCode, 200);
      for (final result
          in ((await body(response))['results'] as List<dynamic>)) {
        expect((result as Map)['applied'], true);
      }

      for (final raw in fixture['expected'] as List<dynamic>) {
        final expected = (raw as Map).cast<String, dynamic>();
        final stored = await gateway
            .getDoc('users/$uid/progress/${expected['pageNumber']}');
        expect(stored, isNotNull);
        expect(
          {...stored!}..remove('updatedAt'),
          expected,
          reason: 'page ${expected['pageNumber']} must match completeSession '
              'byte-for-byte (PageProgress.toMap shape)',
        );
      }
    });

    // ── Backfill ─────────────────────────────────────────────────────────

    test('backfill: chronological history in one batch counts every day; '
        're-running the backfill is a no-op', () async {
      await seedProfile();
      final history = {
        'facts': [
          for (final (i, date) in ['2026-06-10', '2026-06-11', '2026-06-12'].indexed)
            sessionFact(
              id: 'b${i}111111-1111-4111-8111-111111111111',
              date: date,
              sabaqPage: 582,
              covered: [582],
              planRevision: i,
              recordedAtUtc: '${date}T10:00:00Z',
            ),
        ],
      };

      final first = await post('/v1/me/backfill', history);
      expect(first.statusCode, 200);
      final firstBody = await body(first);
      for (final result in firstBody['results'] as List<dynamic>) {
        expect((result as Map)['applied'], true);
      }
      final streak = (firstBody['derived'] as Map<String, dynamic>)['streak']
          as Map<String, dynamic>;
      expect(streak['totalActiveDays'], 3);
      expect(streak['lastActiveDate'], '2026-06-12');

      // Safe to re-run (the §7.3 guarantee): nothing double-counts.
      final second = await post('/v1/me/backfill', history);
      final secondBody = await body(second);
      for (final result in secondBody['results'] as List<dynamic>) {
        expect((result as Map)['applied'], false);
      }
      expect(secondBody['derived'], firstBody['derived'],
          reason: 'replayed backfill returns the same canonical state');
      final progressDoc = await gateway.getDoc('users/$uid/progress/582');
      expect(progressDoc!['reviewCount'], 3, reason: '3 sessions, 3 counts');
    });

    // ── Batch hygiene ────────────────────────────────────────────────────

    test('malformed body / missing facts array -> 400 envelope', () async {
      final notJson = await handler()(Request(
        'POST',
        Uri.parse('http://localhost/v1/me/facts'),
        headers: {'authorization': 'Bearer $token'},
        body: 'not-json',
      ));
      expect(notJson.statusCode, 400);

      final noFacts = await post('/v1/me/facts', {'nope': true});
      expect(noFacts.statusCode, 400);
      final error = (await body(noFacts))['error'] as Map<String, dynamic>;
      expect(error['code'], 'invalid-argument');
    });

    test('in-batch duplicate ids fold once; both positions report the '
        'single outcome', () async {
      await seedProfile();
      final fact = sessionFact(
        id: u1,
        date: '2026-06-15',
        sabaqPage: 582,
        covered: [582],
        recordedAtUtc: '2026-06-15T10:00:00Z',
      );
      final response = await post('/v1/me/facts', {'facts': [fact, fact]});
      expect(response.statusCode, 200);
      final results = (await body(response))['results'] as List<dynamic>;
      expect(results, hasLength(2));
      expect((results[0] as Map)['applied'], true);
      expect((results[1] as Map)['applied'], true,
          reason: 'same fact, same single application, reported twice');
      final progressDoc = await gateway.getDoc('users/$uid/progress/582');
      expect(progressDoc!['reviewCount'], 1, reason: 'folded exactly once');
    });

    test('facts log doc stores the full fact for re-derivation (R2)',
        () async {
      await seedProfile();
      final fact = sessionFact(
        id: u1,
        date: '2026-06-15',
        sabaqPage: 582,
        covered: [582],
        recordedAtUtc: '2026-06-15T10:00:00Z',
      );
      await post('/v1/me/facts', {'facts': [fact]});
      final log = await gateway.getDoc('users/$uid/facts/$u1');
      expect(log, isNotNull);
      expect(log!['kind'], 'session');
      final stored = (log['fact'] as Map).cast<String, dynamic>();
      expect(stored['date'], '2026-06-15');
      expect(stored['profileId'], 'p1');
      // The stored fact round-trips through the strict wire parser.
      expect(() => Fact.fromJson(stored), returnsNormally);
    });
  }, skip: skip);
}
