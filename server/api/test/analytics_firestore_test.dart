// Contract tests for GET /v1/me/analytics[/snapshot] against the FIRESTORE
// EMULATOR (roadmap §5 #10 / §8 Phase 6 task 1). Run with:
//
//   firebase emulators:exec --only firestore --project quran-app-e5e86 ^
//     "cd server/api && dart test test/analytics_firestore_test.dart"

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
      ? 'FIRESTORE_EMULATOR_HOST not set — start the Firestore emulator'
      : null;

  group('GET /v1/me/analytics (emulator)', () {
    late FirebaseApp app;
    late FirestoreGateway gateway;
    var run = 0;

    setUpAll(() {
      app = FirebaseApp.initializeApp(
        options: const AppOptions(projectId: 'demo-jawhar-analytics-test'),
      );
      gateway = FirestoreGateway(app.firestore());
    });

    tearDownAll(() async {
      await app.close();
    });

    late String uid;
    late String token;
    setUp(() {
      uid = 'ana-uid-${DateTime.now().microsecondsSinceEpoch}-${run++}';
      token = 'tok-$uid';
    });

    var nowUtc = DateTime.utc(2026, 6, 16, 12);

    Handler handler() => buildTestHandler(
          gateway: gateway,
          nowUtc: () => nowUtc,
          verifiedTokens: {token: VerifiedToken(uid: uid)},
        );

    Future<Response> get(String query) async => handler()(Request(
          'GET',
          Uri.parse('http://localhost/v1/me/analytics/snapshot$query'),
          headers: {'authorization': 'Bearer $token'},
        ));

    Future<Map<String, dynamic>> body(Response response) async =>
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    Future<void> seedProfile() => gateway.setDoc('users/$uid', {
          ...MemoryProfile(
            id: 'p1',
            name: 'Tester',
            createdAt: DateTime(2026, 1, 1),
            startDate: DateTime(2026, 1, 1),
          ).toMap(),
          'updatedAt': nowUtc.toIso8601String(),
        });

    Future<void> seedSession(
      String id,
      DateTime date, {
      int duration = 30,
    }) =>
        gateway.setDoc('users/$uid/sessions/$id', {
          ...SessionRecord(
            id: id,
            profileId: 'p1',
            date: date,
            durationMinutes: duration,
            sabaqCompleted: true,
            sabaqAssessment: SelfAssessment.strong,
            sabaqPage: 582,
          ).toMap(),
          'createdAt': date.toIso8601String(),
        });

    test('404 without a profile mirror; 400 for malformed dates', () async {
      expect((await get('?start=2026-06-08')).statusCode, 404);
      await seedProfile();
      expect((await get('?start=2026-13-08')).statusCode, 400);
      expect(
        (await get('?start=2026-06-10&end=2026-06-08')).statusCode,
        400,
        reason: 'end before start',
      );
    });

    test('profileId with path-unsafe characters -> 400 (it is interpolated '
        'into the cache doc path)', () async {
      await seedProfile();
      final response = await get('?start=2026-06-08&profileId=a%2Fb');
      expect(response.statusCode, 400);
      final error = (await body(response))['error'] as Map<String, dynamic>;
      expect(error['code'], 'invalid-argument');
    });

    test('weekly snapshot over the legacy mirror (facts-written docs share '
        'the same collections — dual window)', () async {
      await seedProfile();
      // Two sessions inside [06-08 .. 06-14], one outside.
      await seedSession('s1', DateTime.utc(2026, 6, 9, 10), duration: 20);
      await seedSession('s2', DateTime.utc(2026, 6, 11, 10), duration: 40);
      await seedSession('s3', DateTime.utc(2026, 6, 1, 10), duration: 99);
      // One plan in range, completed.
      await gateway.setDoc('users/$uid/plans/p1_2026-06-09T00:00:00.000', {
        ...DailyPlan(
          id: 'p1_2026-06-09T00:00:00.000',
          profileId: 'p1',
          date: DateTime(2026, 6, 9),
          sabaqPage: 582,
          isCompleted: true,
        ).toMap(),
      });
      // Progress: one page memorized in range, one reviewed in range.
      await gateway.setDoc('users/$uid/progress/582', {
        ...PageProgress(
          pageNumber: 582,
          profileId: 'p1',
          status: PageStatus.memorized,
          lastReviewedAt: DateTime.utc(2026, 6, 11, 10),
          reviewCount: 5,
          memorizedAt: DateTime.utc(2026, 6, 11, 10),
        ).toMap(),
        'updatedAt': nowUtc.toIso8601String(),
      });
      await gateway.setDoc('users/$uid/progress/581', {
        ...PageProgress(
          pageNumber: 581,
          profileId: 'p1',
          status: PageStatus.reviewing,
          lastReviewedAt: DateTime.utc(2026, 6, 9, 10),
          reviewCount: 3,
        ).toMap(),
        'updatedAt': nowUtc.toIso8601String(),
      });

      final response = await get('?start=2026-06-08&end=2026-06-14');
      expect(response.statusCode, 200);
      final payload = await body(response);
      expect(payload['profileId'], 'p1');
      expect(payload['startDate'], '2026-06-08');
      expect(payload['endDate'], '2026-06-14');

      final snapshot = payload['snapshot'] as Map<String, dynamic>;
      expect(snapshot['totalSessions'], 2);
      expect(snapshot['totalDurationMinutes'], 60);
      expect(snapshot['avgDurationMinutes'], 30.0);
      expect(snapshot['plannedDays'], 1);
      expect(snapshot['completedDays'], 1);
      expect(snapshot['completionRate'], 1.0);
      expect(snapshot['strongCount'], 2);
      expect(snapshot['pagesMemorized'], 1);
      expect(snapshot['pagesReviewed'], 2);
      // 2026-06-09 = Tuesday(2), 2026-06-11 = Thursday(4).
      expect(snapshot['sessionsPerDay'], {'2': 1, '4': 1});
    });

    test('24h cache: a second call returns the cached payload; the cache '
        'expires after 24h', () async {
      await seedProfile();
      await seedSession('s1', DateTime.utc(2026, 6, 9, 10));

      final first = await body(await get('?start=2026-06-08&end=2026-06-14'));
      expect((first['snapshot'] as Map)['totalSessions'], 1);

      // Sentinel mutation: a fresh computation would now see 2 sessions.
      await seedSession('s2', DateTime.utc(2026, 6, 10, 10));

      final cached = await body(await get('?start=2026-06-08&end=2026-06-14'));
      expect(cached, first, reason: 'served from the 24h cache doc');

      // The cache doc is server-only state.
      final cacheDoc = await gateway.getDoc(
        'users/$uid/analytics/p1_2026-06-08_2026-06-14',
      );
      expect(cacheDoc, isNotNull);

      // 25h later the snapshot recomputes.
      nowUtc = DateTime.utc(2026, 6, 17, 13);
      final fresh = await body(await get('?start=2026-06-08&end=2026-06-14'));
      expect((fresh['snapshot'] as Map)['totalSessions'], 2);
      nowUtc = DateTime.utc(2026, 6, 16, 12); // restore for later tests
    });

    test('bare /v1/me/analytics alias serves the same handler; trailing '
        '7-day window defaults from tzOffsetMinutes', () async {
      await seedProfile();
      await seedSession('s1', DateTime.utc(2026, 6, 15, 10));
      final response = await handler()(Request(
        'GET',
        // Server clock 2026-06-16T12:00Z; UTC+14 client is on 2026-06-17.
        Uri.parse('http://localhost/v1/me/analytics?tzOffsetMinutes=840'),
        headers: {'authorization': 'Bearer $token'},
      ));
      expect(response.statusCode, 200);
      final payload = await body(response);
      expect(payload['startDate'], '2026-06-11');
      expect(payload['endDate'], '2026-06-17');
      expect((payload['snapshot'] as Map)['totalSessions'], 1);
    });
  }, skip: skip);
}
