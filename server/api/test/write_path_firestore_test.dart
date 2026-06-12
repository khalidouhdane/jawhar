// Contract tests for the Phase 4 per-user writePath flag (roadmap §8
// Phase 4 task 4 / R2 rollback lever): GET /v1/me/bootstrap resolution +
// the admin flip endpoint. Run against the FIRESTORE EMULATOR:
//
//   firebase emulators:exec --only firestore --project quran-app-e5e86 ^
//     "cd server/api && dart test test/write_path_firestore_test.dart"

import 'dart:convert';
import 'dart:io';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:hifz_core/hifz_core.dart';
import 'package:jawhar_api/config.dart';
import 'package:jawhar_api/gateway/firestore_gateway.dart';
import 'package:jawhar_api/middleware/auth.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/test_app.dart';

void main() {
  final emulatorHost = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  final skip = (emulatorHost == null || emulatorHost.isEmpty)
      ? 'FIRESTORE_EMULATOR_HOST not set — start the Firestore emulator'
      : null;

  group('per-user writePath (emulator)', () {
    late FirebaseApp app;
    late FirestoreGateway gateway;
    var run = 0;

    setUpAll(() {
      app = FirebaseApp.initializeApp(
        options: const AppOptions(projectId: 'demo-jawhar-writepath-test'),
      );
      gateway = FirestoreGateway(app.firestore());
    });

    tearDownAll(() async {
      await app.close();
    });

    late String uid;
    late String token;
    setUp(() {
      uid = 'wp-uid-${DateTime.now().microsecondsSinceEpoch}-${run++}';
      token = 'tok-$uid';
    });

    const adminUid = 'admin-uid-1';
    const adminToken = 'admin-token';

    const config = Config(
      gitSha: 'abc1234',
      modelId: 'gemini-3.5-flash',
      projectId: 'quran-app-e5e86',
      port: 8080,
      adminUids: [adminUid],
    );

    final fixedNowUtc = DateTime.utc(2026, 6, 16, 12);

    Handler handler() => buildTestHandler(
          config: config,
          gateway: gateway,
          nowUtc: () => fixedNowUtc,
          verifiedTokens: {
            token: VerifiedToken(uid: uid),
            adminToken: const VerifiedToken(uid: adminUid),
          },
        );

    Future<Map<String, dynamic>> body(Response response) async =>
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    Future<Map<String, dynamic>> bootstrap() async {
      final response = await handler()(Request(
        'GET',
        Uri.parse('http://localhost/v1/me/bootstrap'),
        headers: {'authorization': 'Bearer $token'},
      ));
      expect(response.statusCode, 200);
      return body(response);
    }

    Future<Response> flip(
      String target,
      Object? payload, {
      String asToken = adminToken,
    }) async =>
        handler()(Request(
          'POST',
          Uri.parse('http://localhost/v1/admin/users/$target/writePath'),
          headers: {
            'authorization': 'Bearer $asToken',
            'content-type': 'application/json',
          },
          body: jsonEncode(payload),
        ));

    test('default: env fleet default (legacy) when no per-user doc exists',
        () async {
      expect((await bootstrap())['writePath'], 'legacy');
    });

    test('per-user doc overrides the fleet default', () async {
      await gateway.setDoc('users/$uid/meta/server', {'writePath': 'facts'});
      expect((await bootstrap())['writePath'], 'facts');
    });

    test('garbage per-user value falls back to the fleet default', () async {
      await gateway.setDoc('users/$uid/meta/server', {'writePath': 'wat'});
      expect((await bootstrap())['writePath'], 'legacy');
    });

    test('admin flip: facts -> bootstrap serves it; flip back to legacy '
        '(the R2 instant per-user rollback)', () async {
      final response = await flip(uid, {'writePath': 'facts'});
      expect(response.statusCode, 200);
      final payload = await body(response);
      expect(payload['uid'], uid);
      expect(payload['writePath'], 'facts');
      // Flip-to-facts runs the reconcile pass; empty log = no-op summary.
      expect((payload['reconciled'] as Map)['sessionFacts'], 0);
      expect((await bootstrap())['writePath'], 'facts');

      // Rollback lever: one call, instant, per-user.
      await flip(uid, {'writePath': 'legacy'});
      expect((await bootstrap())['writePath'], 'legacy');

      final doc = await gateway.getDoc('users/$uid/meta/server');
      expect(doc!['writePath'], 'legacy');
      expect(doc['updatedBy'], adminUid);
    });

    test('non-admin callers get 403 (uid allow-list, default empty)',
        () async {
      final response = await flip(uid, {'writePath': 'facts'}, asToken: token);
      expect(response.statusCode, 403);
      final error = (await body(response))['error'] as Map<String, dynamic>;
      expect(error['code'], 'permission-denied');
      expect(await gateway.getDoc('users/$uid/meta/server'), isNull);
    });

    test('invalid body -> 400', () async {
      expect((await flip(uid, {'writePath': 'wat'})).statusCode, 400);
      expect((await flip(uid, {'nope': 1})).statusCode, 400);
    });

    // ── Flip-to-facts reconcile pass (roadmap §8 Phase 4b task 3) ────────

    Map<String, dynamic> sessionFactJson({
      required String id,
      required String date,
      required int page,
      required String recordedAtUtc,
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
          'sabaq': {'completed': true, 'assessment': 2, 'page': page},
          'sabqi': {'completed': false, 'assessment': null, 'pages': <int>[]},
          'manzil': {'completed': false, 'assessment': null, 'pages': <int>[]},
          'actualPagesCovered': [page],
          'planId': 'p1_${date}T00:00:00.000',
          'planRevision': 0,
          'planOrigin': 'client',
          'recordedAtUtc': recordedAtUtc,
        };

    Future<void> seedFactLog(Map<String, dynamic> fact) =>
        gateway.setDoc('users/$uid/facts/${fact['id']}', {
          'kind': fact['kind'],
          'coreVersion': hifzCoreVersion,
          'appliedAtUtc': '2026-06-15T12:00:00.000Z',
          'fact': fact,
        });

    test('flip to facts re-derives progress + streak from the facts log '
        '(dual-window reviewCount drift + misordered-backfill streak heal); '
        'legacy-only docs survive', () async {
      await gateway.setDoc('users/$uid', {
        ...MemoryProfile(
          id: 'p1',
          name: 'Tester',
          createdAt: DateTime(2026, 1, 1),
          startDate: DateTime(2026, 1, 1),
        ).toMap(),
        'updatedAt': '2026-06-15T12:00:00.000Z',
      });

      // The durable facts log: two sessions touching page 582, two days.
      await seedFactLog(sessionFactJson(
        id: 'a1111111-1111-4111-8111-111111111111',
        date: '2026-06-14',
        page: 582,
        recordedAtUtc: '2026-06-14T10:00:00Z',
      ));
      await seedFactLog(sessionFactJson(
        id: 'a2222222-2222-4222-8222-222222222222',
        date: '2026-06-15',
        page: 582,
        recordedAtUtc: '2026-06-15T10:00:00Z',
      ));
      // A foreign profile's fact must NOT contribute (keyspace guard).
      await seedFactLog(sessionFactJson(
        id: 'a3333333-3333-4333-8333-333333333333',
        date: '2026-06-15',
        page: 582,
        recordedAtUtc: '2026-06-15T11:00:00Z',
        profileId: 'p2',
      ));

      // Drifted derived docs: reviewCount inflated by the dual-writer
      // window; streak corrupted by a misordered pre-fix backfill.
      await gateway.setDoc('users/$uid/progress/582', {
        ...PageProgress(
          pageNumber: 582,
          profileId: 'p1',
          status: PageStatus.learning,
          lastReviewedAt: DateTime.utc(2026, 6, 15, 10),
          reviewCount: 7,
        ).toMap(),
        'updatedAt': '2026-06-15T10:00:00.000Z',
      });
      await gateway.setDoc('users/$uid/meta/streak', {
        'totalActiveDays': 1,
        'lastActiveDate': '2026-06-15T00:00:00.000',
        'updatedAt': '2026-06-15T10:00:00.000Z',
      });
      // Legacy-only page (history that never became a fact) — untouched.
      await gateway.setDoc('users/$uid/progress/300', {
        ...PageProgress(
          pageNumber: 300,
          profileId: 'p1',
          status: PageStatus.memorized,
          reviewCount: 9,
        ).toMap(),
        'updatedAt': '2026-05-01T10:00:00.000Z',
      });

      final response = await flip(uid, {'writePath': 'facts'});
      expect(response.statusCode, 200);
      final payload = await body(response);
      expect(payload['writePath'], 'facts');
      final reconciled = payload['reconciled'] as Map<String, dynamic>;
      expect(reconciled['sessionFacts'], 2,
          reason: 'root-profile facts only');

      final progressDoc = await gateway.getDoc('users/$uid/progress/582');
      expect(progressDoc!['reviewCount'], 2,
          reason: 're-derived from the 2 root facts, not the drifted 7');
      expect(progressDoc['profileId'], 'p1');

      final streakDoc = await gateway.getDoc('users/$uid/meta/streak');
      expect(streakDoc!['totalActiveDays'], 2,
          reason: 'order-independent fold from zero over the full set');

      final untouched = await gateway.getDoc('users/$uid/progress/300');
      expect(untouched!['reviewCount'], 9,
          reason: 'legacy-only progress is never deleted by the reconcile');
    });

    test('flip to facts with an empty facts log never zeroes legacy state',
        () async {
      await gateway.setDoc('users/$uid/meta/streak', {
        'totalActiveDays': 41,
        'lastActiveDate': '2026-06-14T00:00:00.000',
        'updatedAt': '2026-06-14T09:00:00.000Z',
      });

      final response = await flip(uid, {'writePath': 'facts'});
      expect(response.statusCode, 200);
      final payload = await body(response);
      expect((payload['reconciled'] as Map)['sessionFacts'], 0);

      final streakDoc = await gateway.getDoc('users/$uid/meta/streak');
      expect(streakDoc!['totalActiveDays'], 41);
      expect((await bootstrap())['writePath'], 'facts');
    });
  }, skip: skip);
}
