// Contract tests for the Phase 5 manzil-rotation persistence (roadmap §8
// Phase 5 task 4) against the FIRESTORE EMULATOR:
// - `rotationChanged` facts fold LWW per profile into
//   `users/{uid}/meta/manzil_rotation`;
// - the facts-fold plan regeneration consumes the persisted rotation;
// - `GET /v1/me/plan` consumes the persisted rotation.
//
// Run with:
//   firebase emulators:exec --only firestore --project quran-app-e5e86 ^
//     "cd server/api && dart test test/rotation_firestore_test.dart"
//
// Without the emulator the suite is SKIPPED, not silently green.

import 'dart:convert';
import 'dart:io';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:hifz_core/hifz_core.dart';
import 'package:jawhar_api/gateway/firestore_gateway.dart';
import 'package:jawhar_api/middleware/auth.dart';
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

  group('manzil rotation (emulator)', () {
    late FirebaseApp app;
    late FirestoreGateway gateway;
    var run = 0;

    setUpAll(() {
      app = FirebaseApp.initializeApp(
        options: const AppOptions(projectId: 'demo-jawhar-rotation-test'),
      );
      gateway = FirestoreGateway(app.firestore());
    });

    tearDownAll(() async {
      await app.close();
    });

    late String uid;
    late String token;
    setUp(() {
      uid = 'rot-uid-${DateTime.now().microsecondsSinceEpoch}-${run++}';
      token = 'tok-$uid';
    });

    final fixedNowUtc = DateTime.utc(2026, 6, 16, 12);

    Handler handler() => buildTestHandler(
          gateway: gateway,
          nowUtc: () => fixedNowUtc,
          verifiedTokens: {token: VerifiedToken(uid: uid)},
        );

    Future<Response> post(String path, Map<String, dynamic> body) async =>
        handler()(Request(
          'POST',
          Uri.parse('http://localhost$path'),
          headers: {
            'authorization': 'Bearer $token',
            'content-type': 'application/json',
          },
          body: jsonEncode(body),
        ));

    Future<Response> get(String path) async => handler()(Request(
          'GET',
          Uri.parse('http://localhost$path'),
          headers: {'authorization': 'Bearer $token'},
        ));

    Future<Map<String, dynamic>> body(Response response) async =>
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

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

    Map<String, dynamic> rotationFact({
      required String id,
      required List<int> juz,
      required String changedAtUtc,
      String profileId = 'p1',
    }) =>
        {
          'kind': 'rotationChanged',
          'id': id,
          'coreVersion': hifzCoreVersion,
          'profileId': profileId,
          'juz': juz,
          'changedAtUtc': changedAtUtc,
        };

    Map<String, dynamic> sessionFact({
      required String id,
      required String date,
      required int sabaqPage,
      required String recordedAtUtc,
    }) =>
        {
          'kind': 'session',
          'id': id,
          'coreVersion': hifzCoreVersion,
          'profileId': 'p1',
          'date': date,
          'tzOffsetMinutes': 60,
          'durationMinutes': 30,
          'repCount': 20,
          'sabaq': {'completed': true, 'assessment': 2, 'page': sabaqPage},
          'sabqi': {'completed': false, 'assessment': null, 'pages': <int>[]},
          'manzil': {'completed': false, 'assessment': null, 'pages': <int>[]},
          'actualPagesCovered': <int>[],
          'lastVerseLearned': null,
          'totalVersesOnPage': null,
          'planId': 'p1_${date}T00:00:00.000',
          'planRevision': 0,
          'planOrigin': 'server',
          'recordedAtUtc': recordedAtUtc,
        };

    const r1 = 'd1111111-1111-4111-8111-111111111111';
    const r2 = 'd2222222-2222-4222-8222-222222222222';
    const r3 = 'd3333333-3333-4333-8333-333333333333';
    const s1 = 'd4444444-4444-4444-8444-444444444444';

    test('rotationChanged applies into users/{uid}/meta/manzil_rotation and '
        'replays byte-identically', () async {
      await seedProfile();
      final batch = {
        'facts': [
          rotationFact(
            id: r1,
            juz: [29, 30],
            changedAtUtc: '2026-06-14T10:00:00.000Z',
          ),
        ],
      };

      final first = await post('/v1/me/facts', batch);
      expect(first.statusCode, 200);
      final firstBody = await body(first);
      expect(((firstBody['results'] as List).single as Map)['applied'], true);
      final rotations =
          (firstBody['derived'] as Map)['rotations'] as List<dynamic>;
      expect(rotations, hasLength(1));
      expect((rotations.single as Map)['profileId'], 'p1');
      expect((rotations.single as Map)['juz'], [29, 30]);
      expect(
        (rotations.single as Map)['changedAtUtc'],
        '2026-06-14T10:00:00.000Z',
      );

      // Server-owned doc shape (roadmap: users/{uid}/meta + reset protocol).
      final doc = await gateway.getDoc('users/$uid/meta/manzil_rotation');
      final p1 = ((doc!['profiles'] as Map)['p1'] as Map);
      expect(p1['juz'], [29, 30]);
      expect(p1['factId'], r1);
      expect(p1['changedAtUtc'], '2026-06-14T10:00:00.000Z');
      expect(doc['updatedAt'], '2026-06-14T10:00:00.000Z',
          reason: 'updatedAt is the max winning changedAtUtc, never the '
              'wall clock');

      // §5: a replay is never an error and changes nothing.
      final replay = await post('/v1/me/facts', batch);
      expect(replay.statusCode, 200);
      final replayBody = await body(replay);
      expect(
          ((replayBody['results'] as List).single as Map)['applied'], false);
      expect(replayBody['derived'], firstBody['derived']);
    });

    test('an older offline edit is consumed but loses LWW; the response '
        'carries the canonical rotation for adoption', () async {
      await seedProfile();
      expect(
        (await post('/v1/me/facts', {
          'facts': [
            rotationFact(
              id: r1,
              juz: [29, 30],
              changedAtUtc: '2026-06-14T10:00:00.000Z',
            ),
          ],
        }))
            .statusCode,
        200,
      );

      // A second device's OLDER edit drains later (offline queue).
      final stale = await post('/v1/me/facts', {
        'facts': [
          rotationFact(
            id: r2,
            juz: [1],
            changedAtUtc: '2026-06-13T08:00:00.000Z',
          ),
        ],
      });
      final staleBody = await body(stale);
      expect(((staleBody['results'] as List).single as Map)['applied'], true,
          reason: 'consumed — it will never retry');
      final rotations =
          (staleBody['derived'] as Map)['rotations'] as List<dynamic>;
      expect((rotations.single as Map)['juz'], [29, 30],
          reason: 'canonical (newer) rotation rides back');

      final doc = await gateway.getDoc('users/$uid/meta/manzil_rotation');
      expect(((doc!['profiles'] as Map)['p1'] as Map)['factId'], r1);
    });

    test('a far-future changedAtUtc is clamped to the server clock so the '
        'rotation can never get stuck', () async {
      await seedProfile();
      final response = await post('/v1/me/facts', {
        'facts': [
          rotationFact(
            id: r3,
            juz: [5],
            changedAtUtc: '2027-01-01T00:00:00.000Z',
          ),
        ],
      });
      expect(response.statusCode, 200);
      final doc = await gateway.getDoc('users/$uid/meta/manzil_rotation');
      expect(
        ((doc!['profiles'] as Map)['p1'] as Map)['changedAtUtc'],
        fixedNowUtc.toIso8601String(),
      );
    });

    test('duplicate juz entries poison that item only', () async {
      await seedProfile();
      final response = await post('/v1/me/facts', {
        'facts': [
          rotationFact(
            id: r1,
            juz: [3, 3],
            changedAtUtc: '2026-06-14T10:00:00.000Z',
          ),
          rotationFact(
            id: r2,
            juz: [3],
            changedAtUtc: '2026-06-14T11:00:00.000Z',
          ),
        ],
      });
      expect(response.statusCode, 200);
      final results = (await body(response))['results'] as List<dynamic>;
      expect((results[0] as Map)['applied'], false);
      expect(((results[0] as Map)['error'] as Map)['retryable'], false);
      expect((results[1] as Map)['applied'], true);
    });

    test('session-fact regeneration consumes the persisted rotation '
        '(2026-06-15 = day 896 since 2024-01-01, 896 % 2 = 0 -> juz 29)',
        () async {
      await seedProfile();
      // Same batch: rotation edits apply BEFORE sessions (application
      // order), so the regeneration sees the new rotation.
      final response = await post('/v1/me/facts', {
        'facts': [
          sessionFact(
            id: s1,
            date: '2026-06-15',
            sabaqPage: 582,
            recordedAtUtc: '2026-06-15T10:00:00.000Z',
          ),
          rotationFact(
            id: r1,
            juz: [29, 30],
            changedAtUtc: '2026-06-14T10:00:00.000Z',
          ),
        ],
      });
      expect(response.statusCode, 200);
      final responseBody = await body(response);
      final plans = (responseBody['derived'] as Map)['plans'] as List<dynamic>;
      expect(plans, hasLength(1));
      final plan = (plans.single as Map)['plan'] as Map;
      expect((plans.single as Map)['revision'], 1);
      expect(plan['manzilJuz'], 29);
      expect(plan['manzilPages'], '562,563,564,565,566',
          reason: 'juz 29 starts at page 562; manzilPagesPerDay 5 for '
              'moderate retention');

      // The stored plan doc carries the same regenerated manzil phase.
      final planDoc = await gateway
          .getDoc('users/$uid/plans/p1_2026-06-15T00:00:00.000');
      expect(planDoc!['manzilJuz'], 29);
      expect(planDoc['revision'], 1);
    });

    test('GET /v1/me/plan consumes the persisted rotation '
        '(2026-06-16 = day 897, 897 % 2 = 1 -> juz 30)', () async {
      await seedProfile();
      expect(
        (await post('/v1/me/facts', {
          'facts': [
            rotationFact(
              id: r1,
              juz: [29, 30],
              changedAtUtc: '2026-06-14T10:00:00.000Z',
            ),
          ],
        }))
            .statusCode,
        200,
      );

      final response = await get('/v1/me/plan?date=2026-06-16');
      expect(response.statusCode, 200);
      final planBody = await body(response);
      expect(planBody['source'], 'server-deterministic');
      final plan = planBody['plan'] as Map<String, dynamic>;
      expect(plan['manzilJuz'], 30);
      expect(plan['manzilPages'], '582,583,584,585,586');
      expect(plan['manzilTargetMinutes'], greaterThan(0));
    });

    test('GET /v1/me/plan without any persisted rotation still serves an '
        'empty manzil phase (regression: the old hard-coded [])', () async {
      await seedProfile();
      final response = await get('/v1/me/plan?date=2026-06-16');
      expect(response.statusCode, 200);
      final plan = (await body(response))['plan'] as Map<String, dynamic>;
      expect(plan['manzilJuz'], 0);
      expect(plan['manzilPages'], '');
    });
  }, skip: skip);
}
