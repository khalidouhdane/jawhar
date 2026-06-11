// Contract tests for GET /v1/me/plan against the FIRESTORE EMULATOR
// (roadmap §8 Phase 3 task 2 / §10 local dev loop). Run with the emulator up:
//
//   firebase emulators:exec --only firestore --project quran-app-e5e86 ^
//     "dart test test/plan_get_firestore_test.dart"
//
// (emulators:exec sets FIRESTORE_EMULATOR_HOST for the child process.)
// Without the emulator the suite is SKIPPED, not silently green.
//
// ⚠ The emulator does NOT enforce composite indexes: the highest-revision
// query here is only proven index-backed by firestore.indexes.json's
// plans `(profileId ASC, date ASC, revision DESC)` entry, which is deployed
// and READY in production.

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
          'quran-app-e5e86 "dart test test/plan_get_firestore_test.dart")'
      : null;

  group('GET /v1/me/plan (emulator)', () {
    late FirebaseApp app;
    late FirestoreGateway gateway;
    var run = 0;

    setUpAll(() {
      // demo- prefix = offline-only project by Firebase convention.
      app = FirebaseApp.initializeApp(
        options: const AppOptions(projectId: 'demo-jawhar-plan-test'),
      );
      gateway = FirestoreGateway(app.firestore());
    });

    tearDownAll(() async {
      await app.close();
    });

    // Fresh uid (and bearer token) per test so tests never share docs.
    late String uid;
    late String token;
    setUp(() {
      uid = 'plan-uid-${DateTime.now().microsecondsSinceEpoch}-${run++}';
      token = 'tok-$uid';
    });

    // Fixed clock late in the UTC day so tz offsets cross the boundary.
    final fixedNowUtc = DateTime.utc(2026, 6, 10, 23, 30);

    Handler handler() => buildTestHandler(
          gateway: gateway,
          nowUtc: () => fixedNowUtc,
          verifiedTokens: {token: VerifiedToken(uid: uid)},
        );

    Future<Response> get(String query) async => handler()(Request(
          'GET',
          Uri.parse('http://localhost/v1/me/plan$query'),
          headers: {'authorization': 'Bearer $token'},
        ));

    Future<Map<String, dynamic>> body(Response response) async =>
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    // Profile mirror fixture: moderate/moderate, 30 min/day, steady ->
    // linesPerSession 4, minReps 20, starting page 582 (juz 30).
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

    Future<void> seedProgress(PageProgress page) => gateway.setDoc(
          'users/$uid/progress/${page.pageNumber}',
          {...page.toMap(), 'updatedAt': fixedNowUtc.toIso8601String()},
        );

    test('404 with the §5 envelope when no profile mirror exists', () async {
      final response = await get('?date=2026-06-15');
      expect(response.statusCode, 404);
      final error = (await body(response))['error'] as Map<String, dynamic>;
      expect(error['code'], 'not-found');
      expect(error['retryable'], false);
      expect(error['message'], isA<String>());
    });

    test('404 for a profileId that is not the mirrored one', () async {
      await seedProfile();
      final response = await get('?profileId=p2&date=2026-06-15');
      expect(response.statusCode, 404);
      final error = (await body(response))['error'] as Map<String, dynamic>;
      expect(error['code'], 'not-found');
    });

    test('400 invalid-argument for a malformed date', () async {
      await seedProfile();
      final response = await get('?date=2026-2-31');
      expect(response.statusCode, 400);
      final error = (await body(response))['error'] as Map<String, dynamic>;
      expect(error['code'], 'invalid-argument');
    });

    test('create-on-first-get: generates from the legacy mirror and persists',
        () async {
      await seedProfile();
      // Page 582 already being learned (reviewed yesterday): sabaq must
      // advance to 583 and 582 must come back as sabqi review — proves the
      // generator really consumed the progress mirror.
      await seedProgress(PageProgress(
        pageNumber: 582,
        profileId: 'p1',
        status: PageStatus.learning,
        lastReviewedAt: DateTime(2026, 6, 14, 10),
        reviewCount: 1,
      ));

      final response = await get('?date=2026-06-15&profileId=p1');
      expect(response.statusCode, 200);
      final payload = await body(response);
      expect(payload['id'], 'p1_2026-06-15T00:00:00.000');
      expect(payload['profileId'], 'p1');
      expect(payload['date'], '2026-06-15');
      expect(payload['revision'], 0);
      expect(payload['source'], 'server-deterministic');

      final plan = payload['plan'] as Map<String, dynamic>;
      expect(plan['sabaqPage'], 583);
      expect(plan['sabaqLineStart'], 1);
      expect(plan['sabaqLineEnd'], 4);
      expect(plan['sabqiPages'], '582'); // legacy toMap comma-string shape
      expect(plan['manzilPages'], ''); // rotation is device-local until P5
      expect(plan['isAiGenerated'], 0);

      // Recipes travel with the plan: sabaq + sabqi (manzil empty -> none).
      final recipes = payload['sessionRecipes'] as List<dynamic>;
      expect(recipes, hasLength(2));
      final phases = [
        for (final r in recipes) (r as Map<String, dynamic>)['phase'],
      ];
      expect(phases, ['sabaq', 'sabqi']);

      // Persisted at the deterministic id, with the server fields.
      final doc =
          await gateway.getDoc('users/$uid/plans/p1_2026-06-15T00:00:00.000');
      expect(doc, isNotNull);
      expect(doc!['revision'], 0);
      expect(doc['source'], 'server-deterministic');
      expect(doc['sabaqPage'], 583);
      expect(doc['recipes'], hasLength(2));
    });

    test('second get is idempotent: same revision, read not regenerated',
        () async {
      await seedProfile();
      final first = await get('?date=2026-06-15');
      expect(first.statusCode, 200);
      final firstPayload = await body(first);

      final second = await get('?date=2026-06-15');
      expect(second.statusCode, 200);
      expect(await body(second), firstPayload,
          reason: 'a replayed GET must return the identical payload '
              '(Firestore does not guarantee field order, so compare '
              'decoded JSON rather than bytes)');

      // Sentinel mutation: if a third get still returns the stored copy,
      // the endpoint reads rather than regenerate-and-overwrite.
      await gateway.setDoc(
        'users/$uid/plans/p1_2026-06-15T00:00:00.000',
        {'sabaqPage': 99},
        merge: true,
      );
      final third = await get('?date=2026-06-15');
      final payload = await body(third);
      expect(payload['revision'], 0);
      expect((payload['plan'] as Map<String, dynamic>)['sabaqPage'], 99);
    });

    test('highest revision wins for (profileId, date) — §5 plan semantics',
        () async {
      await seedProfile();
      const dateIso = '2026-06-15T00:00:00.000';
      final base = DailyPlan(
        id: 'p1_$dateIso',
        profileId: 'p1',
        date: DateTime(2026, 6, 15),
        sabaqPage: 582,
      );
      await gateway.setDoc('users/$uid/plans/p1_$dateIso', {
        ...base.toMap(),
        'revision': 0,
        'source': 'server-deterministic',
        'recipes': <Map<String, dynamic>>[],
      });
      // A higher revision stored under a DIFFERENT doc id (the Phase 4+
      // shape for revision history) must win via the composite query.
      await gateway.setDoc('users/$uid/plans/p1_${dateIso}_r2', {
        ...base.toMap(),
        'sabaqPage': 600,
        'revision': 2,
        'source': 'server-ai',
        'recipes': <Map<String, dynamic>>[],
      });

      final payload = await body(await get('?date=2026-06-15'));
      expect(payload['revision'], 2);
      expect(payload['source'], 'server-ai');
      expect((payload['plan'] as Map<String, dynamic>)['sabaqPage'], 600);
    });

    test('legacy revision-less client plan is returned as-is, never clobbered',
        () async {
      await seedProfile();
      const dateIso = '2026-06-20T00:00:00.000';
      final clientPlan = DailyPlan(
        id: 'p1_$dateIso',
        profileId: 'p1',
        date: DateTime(2026, 6, 20),
        sabaqPage: 100,
        isAiGenerated: true,
        aiReasoning: 'client AI plan',
      );
      // Exactly what CloudSyncService.syncPlan writes (minus the server
      // timestamp): plan.toMap() with no revision/source/recipes.
      await gateway.setDoc('users/$uid/plans/p1_$dateIso', clientPlan.toMap());

      final payload = await body(await get('?date=2026-06-20'));
      expect(payload['revision'], 0);
      expect(payload['source'], 'client-legacy');
      expect(payload['sessionRecipes'], isEmpty);
      final plan = payload['plan'] as Map<String, dynamic>;
      expect(plan['sabaqPage'], 100);
      expect(plan['isAiGenerated'], 1);

      // The mirror doc was not overwritten by a fresh generation.
      final doc = await gateway.getDoc('users/$uid/plans/p1_$dateIso');
      expect(doc!['sabaqPage'], 100);
      expect(doc.containsKey('source'), isFalse);
    });

    test('non-UTC day boundary: tzOffsetMinutes keys the client-local date',
        () async {
      await seedProfile();
      // Server clock is 2026-06-10T23:30Z. A UTC+2 client is already on
      // 2026-06-11; a UTC-5 client is still on 2026-06-10.
      final ahead = await body(await get('?tzOffsetMinutes=120'));
      expect(ahead['date'], '2026-06-11');
      expect(ahead['id'], 'p1_2026-06-11T00:00:00.000');

      final behind = await body(await get('?tzOffsetMinutes=-300'));
      expect(behind['date'], '2026-06-10');
      expect(behind['id'], 'p1_2026-06-10T00:00:00.000');

      // Two distinct plan docs were persisted — one per client-local day.
      expect(
        await gateway.getDoc('users/$uid/plans/p1_2026-06-11T00:00:00.000'),
        isNotNull,
      );
      expect(
        await gateway.getDoc('users/$uid/plans/p1_2026-06-10T00:00:00.000'),
        isNotNull,
      );

      // Documented caveat: no date and no offset falls back to the UTC day.
      final fallback = await body(await get(''));
      expect(fallback['date'], '2026-06-10');
    });
  }, skip: skip);
}
