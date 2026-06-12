// Contract tests for `PUT /v1/me/profiles/{profileId}` (roadmap §5 #7) and
// the Phase 5 foreign-profile derivation (a second profile's session facts
// regenerate ITS plan and promote ITS progress — never the root's) against
// the FIRESTORE EMULATOR.
//
// Run with:
//   firebase emulators:exec --only firestore --project quran-app-e5e86 ^
//     "cd server/api && dart test test/profiles_firestore_test.dart"
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

  group('profiles + foreign-profile derivation (emulator)', () {
    late FirebaseApp app;
    late FirestoreGateway gateway;
    var run = 0;

    setUpAll(() {
      app = FirebaseApp.initializeApp(
        options: const AppOptions(projectId: 'demo-jawhar-profiles-test'),
      );
      gateway = FirestoreGateway(app.firestore());
    });

    tearDownAll(() async {
      await app.close();
    });

    late String uid;
    late String token;
    setUp(() {
      uid = 'prof-uid-${DateTime.now().microsecondsSinceEpoch}-${run++}';
      token = 'tok-$uid';
    });

    final fixedNowUtc = DateTime.utc(2026, 6, 16, 12);

    Handler handler() => buildTestHandler(
          gateway: gateway,
          nowUtc: () => fixedNowUtc,
          verifiedTokens: {token: VerifiedToken(uid: uid)},
        );

    Future<Response> send(
      String method,
      String path, {
      Map<String, dynamic>? jsonBody,
    }) async =>
        handler()(Request(
          method,
          Uri.parse('http://localhost$path'),
          headers: {
            'authorization': 'Bearer $token',
            if (jsonBody != null) 'content-type': 'application/json',
          },
          body: jsonBody == null ? null : jsonEncode(jsonBody),
        ));

    Future<Map<String, dynamic>> body(Response response) async =>
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    MemoryProfile rootProfile() => MemoryProfile(
          id: 'p1',
          name: 'Root',
          createdAt: DateTime(2026, 1, 1),
          startDate: DateTime(2026, 1, 1),
        );

    MemoryProfile secondProfile({String name = 'Second'}) => MemoryProfile(
          id: 'p2',
          name: name,
          createdAt: DateTime(2026, 2, 1),
          startDate: DateTime(2026, 2, 1),
          startingPage: 1,
          isActive: false,
        );

    Future<void> seedRoot() => gateway.setDoc('users/$uid', {
          ...rootProfile().toMap(),
          'updatedAt': fixedNowUtc.toIso8601String(),
        });

    Map<String, dynamic> sessionFact({
      required String id,
      required String profileId,
      required int sabaqPage,
      String date = '2026-06-15',
      String recordedAtUtc = '2026-06-15T10:00:00.000Z',
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
          'sabaq': {'completed': true, 'assessment': 2, 'page': sabaqPage},
          'sabqi': {'completed': false, 'assessment': null, 'pages': <int>[]},
          'manzil': {'completed': false, 'assessment': null, 'pages': <int>[]},
          'actualPagesCovered': <int>[],
          'lastVerseLearned': null,
          'totalVersesOnPage': null,
          'planId': '${profileId}_${date}T00:00:00.000',
          'planRevision': 0,
          'planOrigin': 'server',
          'recordedAtUtc': recordedAtUtc,
        };

    const f1 = 'e1111111-1111-4111-8111-111111111111';
    const f2 = 'e2222222-2222-4222-8222-222222222222';

    // ── PUT /v1/me/profiles/{profileId} (§5 #7) ──────────────────────────

    test('upserts the plural profile doc and answers applied:true', () async {
      final response = await send(
        'PUT',
        '/v1/me/profiles/p2',
        jsonBody: {
          ...secondProfile().toMap(),
          'updatedAt': '2026-06-15T09:00:00.000Z',
        },
      );
      expect(response.statusCode, 200);
      final responseBody = await body(response);
      expect(responseBody['applied'], true);
      expect(responseBody['profileId'], 'p2');

      final doc = await gateway.getDoc('users/$uid/profiles/p2');
      expect(doc!['id'], 'p2');
      expect(doc['name'], 'Second');
      expect(doc['updatedAt'], '2026-06-15T09:00:00.000Z');
    });

    test('LWW on updatedAt: a stale snapshot loses and gets the canonical '
        'profile back', () async {
      expect(
        (await send('PUT', '/v1/me/profiles/p2', jsonBody: {
          ...secondProfile(name: 'Newer').toMap(),
          'updatedAt': '2026-06-15T09:00:00.000Z',
        }))
            .statusCode,
        200,
      );

      final stale = await send('PUT', '/v1/me/profiles/p2', jsonBody: {
        ...secondProfile(name: 'Older').toMap(),
        'updatedAt': '2026-06-14T09:00:00.000Z',
      });
      expect(stale.statusCode, 200);
      final staleBody = await body(stale);
      expect(staleBody['applied'], false);
      expect((staleBody['profile'] as Map)['name'], 'Newer');

      final doc = await gateway.getDoc('users/$uid/profiles/p2');
      expect(doc!['name'], 'Newer');
    });

    test('rejects a body id that does not match the path', () async {
      final response = await send(
        'PUT',
        '/v1/me/profiles/p9',
        jsonBody: secondProfile().toMap(),
      );
      expect(response.statusCode, 422);
    });

    test('rejects an unparseable profile payload', () async {
      final response = await send(
        'PUT',
        '/v1/me/profiles/p2',
        jsonBody: {'id': 'p2'}, // missing name/createdAt/startDate
      );
      expect(response.statusCode, 422);
    });

    test('updating the ROOT profile through the plural endpoint keeps the '
        'legacy root mirror coherent (dual window)', () async {
      await seedRoot();
      final response = await send('PUT', '/v1/me/profiles/p1', jsonBody: {
        ...rootProfile().toMap(),
        'dailyTimeMinutes': 60,
        'updatedAt': '2026-06-16T11:00:00.000Z',
      });
      expect(response.statusCode, 200);

      final root = await gateway.getDoc('users/$uid');
      expect(root!['dailyTimeMinutes'], 60,
          reason: 'root mirror updated in the same transaction');
      final plural = await gateway.getDoc('users/$uid/profiles/p1');
      expect(plural!['dailyTimeMinutes'], 60);
    });

    test('upserting a NON-root profile never touches the root mirror',
        () async {
      await seedRoot();
      expect(
        (await send('PUT', '/v1/me/profiles/p2',
                jsonBody: secondProfile().toMap()))
            .statusCode,
        200,
      );
      final root = await gateway.getDoc('users/$uid');
      expect(root!['id'], 'p1');
      expect(root['name'], 'Root');
    });

    // ── Foreign-profile fold (Phase 5 plural-safe derivation) ────────────

    test('a second profile\'s session fact regenerates ITS plan and promotes '
        'ITS progress in the plural keyspace — root state untouched',
        () async {
      await seedRoot();
      expect(
        (await send('PUT', '/v1/me/profiles/p2',
                jsonBody: secondProfile().toMap()))
            .statusCode,
        200,
      );

      final response = await send('POST', '/v1/me/facts', jsonBody: {
        'facts': [
          sessionFact(id: f1, profileId: 'p2', sabaqPage: 1),
        ],
      });
      expect(response.statusCode, 200);
      final responseBody = await body(response);
      expect(((responseBody['results'] as List).single as Map)['applied'],
          true);
      final derived = responseBody['derived'] as Map<String, dynamic>;

      // ITS progress, profile-keyed on the wire.
      final progress = (derived['progress'] as List).single as Map;
      expect(progress['profileId'], 'p2');
      expect(progress['pageNumber'], 1);
      expect(progress['status'], 1 /* learning */);

      // ITS plan — regenerated next revision under the plural-safe plan id.
      final plan = (derived['plans'] as List).single as Map;
      expect(plan['id'], 'p2_2026-06-15T00:00:00.000');
      expect(plan['revision'], 1);
      expect((plan['plan'] as Map)['profileId'], 'p2');

      // The singleton streak mirrors the ROOT profile — never derived from
      // a foreign-profile fact.
      expect(derived['streak'], isNull);
      expect(await gateway.getDoc('users/$uid/meta/streak'), isNull);

      // Plural keyspace holds the progress; the root page keyspace is
      // untouched (two profiles, same page number, no clobbering).
      expect(
          await gateway.getDoc('users/$uid/profiles/p2/progress/1'), isNotNull);
      expect(await gateway.getDoc('users/$uid/progress/1'), isNull);

      // Plan doc lives in the shared plans collection (ids are
      // profileId-keyed already).
      final planDoc =
          await gateway.getDoc('users/$uid/plans/p2_2026-06-15T00:00:00.000');
      expect(planDoc!['revision'], 1);
      expect(planDoc['profileId'], 'p2');

      // Session doc mirrored as usual (append-only UUID keyspace).
      expect(await gateway.getDoc('users/$uid/sessions/$f1'), isNotNull);

      // Replay answers applied:false with the same canonical deltas.
      final replay = await send('POST', '/v1/me/facts', jsonBody: {
        'facts': [
          sessionFact(id: f1, profileId: 'p2', sabaqPage: 1),
        ],
      });
      final replayBody = await body(replay);
      expect(
          ((replayBody['results'] as List).single as Map)['applied'], false);
      expect(replayBody['derived'], responseBody['derived']);
    });

    test('root and second profile fold independently on the same page '
        'number', () async {
      await seedRoot();
      expect(
        (await send('PUT', '/v1/me/profiles/p2',
                jsonBody: secondProfile().toMap()))
            .statusCode,
        200,
      );

      final response = await send('POST', '/v1/me/facts', jsonBody: {
        'facts': [
          sessionFact(id: f1, profileId: 'p2', sabaqPage: 5),
          sessionFact(
            id: f2,
            profileId: 'p1',
            sabaqPage: 5,
            recordedAtUtc: '2026-06-15T11:00:00.000Z',
          ),
        ],
      });
      expect(response.statusCode, 200);
      final results = (await body(response))['results'] as List<dynamic>;
      expect((results[0] as Map)['applied'], true);
      expect((results[1] as Map)['applied'], true);

      final rootDoc = await gateway.getDoc('users/$uid/progress/5');
      expect(rootDoc!['profileId'], 'p1');
      expect(rootDoc['reviewCount'], 1, reason: 'no cross-profile bleed');
      final pluralDoc =
          await gateway.getDoc('users/$uid/profiles/p2/progress/5');
      expect(pluralDoc!['profileId'], 'p2');
      expect(pluralDoc['reviewCount'], 1);

      // Each profile got ITS OWN regenerated plan.
      expect(
        (await gateway
            .getDoc('users/$uid/plans/p1_2026-06-15T00:00:00.000'))!['revision'],
        1,
      );
      expect(
        (await gateway
            .getDoc('users/$uid/plans/p2_2026-06-15T00:00:00.000'))!['revision'],
        1,
      );

      // The root fact drove the streak; the foreign one did not (one
      // active day, not two — both facts share the date anyway, but the
      // doc must exist now because a ROOT fact applied).
      final streakDoc = await gateway.getDoc('users/$uid/meta/streak');
      expect(streakDoc!['totalActiveDays'], 1);
    });

    test('a non-root profile with NO plural doc stays on the lossless path '
        '(logged + session doc, no derivation)', () async {
      await seedRoot();
      final response = await send('POST', '/v1/me/facts', jsonBody: {
        'facts': [
          sessionFact(id: f1, profileId: 'p3', sabaqPage: 7),
        ],
      });
      expect(response.statusCode, 200);
      final responseBody = await body(response);
      expect(((responseBody['results'] as List).single as Map)['applied'],
          true);
      final derived = responseBody['derived'] as Map<String, dynamic>;
      expect(derived['progress'], isEmpty);
      expect(derived['plans'], isEmpty);
      expect(derived['streak'], isNull);
      expect(await gateway.getDoc('users/$uid/sessions/$f1'), isNotNull);
      expect(await gateway.getDoc('users/$uid/profiles/p3/progress/7'),
          isNull);
    });

    // ── GET /v1/me/plan, plural-safe (§5 #3 + #7) ────────────────────────

    test('GET /v1/me/plan?profileId=p2 serves and generates for the second '
        'profile from ITS plural progress', () async {
      await seedRoot();
      expect(
        (await send('PUT', '/v1/me/profiles/p2',
                jsonBody: secondProfile().toMap()))
            .statusCode,
        200,
      );
      // Fold one p2 session so plural progress + a revision-1 plan exist.
      expect(
        (await send('POST', '/v1/me/facts', jsonBody: {
          'facts': [
            sessionFact(id: f1, profileId: 'p2', sabaqPage: 1),
          ],
        }))
            .statusCode,
        200,
      );

      // Stored plan (the regenerated revision 1) is served, not clobbered.
      final stored = await send(
          'GET', '/v1/me/plan?profileId=p2&date=2026-06-15');
      expect(stored.statusCode, 200);
      final storedBody = await body(stored);
      expect(storedBody['profileId'], 'p2');
      expect(storedBody['revision'], 1);
      expect(storedBody['source'], 'server-deterministic');

      // A fresh day generates from p2's OWN progress subcollection.
      final fresh = await send(
          'GET', '/v1/me/plan?profileId=p2&date=2026-06-16');
      expect(fresh.statusCode, 200);
      final freshBody = await body(fresh);
      expect(freshBody['profileId'], 'p2');
      expect(freshBody['revision'], 0);
      expect((freshBody['plan'] as Map)['profileId'], 'p2');

      // The root profile's plan space is independent.
      final root = await send('GET', '/v1/me/plan?date=2026-06-16');
      expect(root.statusCode, 200);
      expect((await body(root))['profileId'], 'p1');
    });

    test('GET /v1/me/plan?profileId=unknown is still 404', () async {
      await seedRoot();
      final response = await send('GET', '/v1/me/plan?profileId=p9');
      expect(response.statusCode, 404);
    });
  }, skip: skip);
}
