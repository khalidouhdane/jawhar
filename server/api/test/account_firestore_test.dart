// Contract tests for `DELETE /v1/me` (roadmap §5 #11 / §8 Phase 8 task 2)
// against the FIRESTORE EMULATOR: the caller's whole tree — including
// transitively nested subcollections and "missing" parent docs — is deleted,
// the injected auth-user deleter runs, other users are untouched, and the
// operation is idempotent.
//
// Run with:
//   firebase emulators:exec --only firestore --project quran-app-e5e86 ^
//     "cd server/api && dart test test/account_firestore_test.dart"
//
// Without the emulator the suite is SKIPPED, not silently green.

import 'dart:convert';
import 'dart:io';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
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

  group('DELETE /v1/me (emulator)', () {
    late FirebaseApp app;
    late FirestoreGateway gateway;
    var run = 0;

    setUpAll(() {
      app = FirebaseApp.initializeApp(
        options: const AppOptions(projectId: 'demo-jawhar-account-test'),
      );
      gateway = FirestoreGateway(app.firestore());
    });

    tearDownAll(() async {
      await app.close();
    });

    late String uid;
    late String token;
    setUp(() {
      uid = 'acct-uid-${DateTime.now().microsecondsSinceEpoch}-${run++}';
      token = 'tok-$uid';
    });

    Handler handler({Future<void> Function(String uid)? deleteAuthUser}) =>
        buildTestHandler(
          gateway: gateway,
          deleteAuthUser: deleteAuthUser,
          verifiedTokens: {token: VerifiedToken(uid: uid)},
        );

    Future<Response> sendDelete(Handler h) async => h(Request(
          'DELETE',
          Uri.parse('http://localhost/v1/me'),
          headers: {'authorization': 'Bearer $token'},
        ));

    Future<Map<String, dynamic>> body(Response response) async =>
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;

    /// Seeds a representative legacy + plural tree for [forUid]:
    /// root doc, flat subcollections, a DOUBLY-nested subcollection
    /// (profiles/p2/progress/5 — the §5 #7 plural keyspace), and a
    /// "missing" parent (`profiles/ghost` has NO doc, only a child) —
    /// the case a naive listDocuments-without-showMissing walk strands.
    Future<void> seedTree(String forUid) async {
      await gateway.setDoc('users/$forUid', {'id': 'p1', 'name': 'Root'});
      await gateway.setDoc('users/$forUid/progress/134', {'status': 2});
      await gateway.setDoc('users/$forUid/sessions/s1', {'date': '2026-06-10'});
      await gateway.setDoc('users/$forUid/plans/p1_2026-06-10', {'rev': 1});
      await gateway.setDoc('users/$forUid/meta/streak', {'totalActiveDays': 4});
      await gateway.setDoc('users/$forUid/profiles/p2', {'id': 'p2'});
      await gateway
          .setDoc('users/$forUid/profiles/p2/progress/5', {'status': 1});
      // Missing parent: child exists, parent doc was never written.
      await gateway
          .setDoc('users/$forUid/profiles/ghost/progress/9', {'status': 3});
    }

    Future<void> expectTreeGone(String forUid) async {
      expect(await gateway.getDoc('users/$forUid'), isNull);
      expect(await gateway.getDoc('users/$forUid/progress/134'), isNull);
      expect(await gateway.getDoc('users/$forUid/sessions/s1'), isNull);
      expect(await gateway.getDoc('users/$forUid/plans/p1_2026-06-10'), isNull);
      expect(await gateway.getDoc('users/$forUid/meta/streak'), isNull);
      expect(await gateway.getDoc('users/$forUid/profiles/p2'), isNull);
      expect(
        await gateway.getDoc('users/$forUid/profiles/p2/progress/5'),
        isNull,
      );
      expect(
        await gateway.getDoc('users/$forUid/profiles/ghost/progress/9'),
        isNull,
      );
    }

    test('deletes the whole tree (nested + missing-parent docs), deletes '
        'the auth user, and reports counts', () async {
      await seedTree(uid);
      final deletedUids = <String>[];
      final response = await sendDelete(
        handler(deleteAuthUser: (u) async => deletedUids.add(u)),
      );

      expect(response.statusCode, 200);
      final decoded = await body(response);
      expect(decoded['deleted'], isTrue);
      expect(decoded['uid'], uid);
      expect(decoded['authUserDeleted'], isTrue);
      // 8 real docs + the ghost "missing" parent location = 9 deletions.
      expect(decoded['docsDeleted'], 9);
      expect(deletedUids, [uid]);

      await expectTreeGone(uid);
    });

    test('scopes deletion to the CALLER: another user\'s tree is untouched',
        () async {
      final otherUid = '$uid-other';
      await seedTree(uid);
      await seedTree(otherUid);

      final response =
          await sendDelete(handler(deleteAuthUser: (_) async {}));
      expect(response.statusCode, 200);

      await expectTreeGone(uid);
      expect(await gateway.getDoc('users/$otherUid'), isNotNull);
      expect(
        await gateway.getDoc('users/$otherUid/profiles/p2/progress/5'),
        isNotNull,
      );
    });

    test('idempotent: a replay (nothing left to delete) is a 200, not an '
        'error', () async {
      await seedTree(uid);
      final h = handler(deleteAuthUser: (_) async {});

      final first = await sendDelete(h);
      expect(first.statusCode, 200);
      expect((await body(first))['docsDeleted'], 9);

      final replay = await sendDelete(h);
      expect(replay.statusCode, 200);
      final decoded = await body(replay);
      expect(decoded['deleted'], isTrue);
      // The walk issues a blind delete for the root LOCATION without
      // reading it first (deleting a missing doc is a success), so a
      // replay counts exactly that one location and nothing else.
      expect(decoded['docsDeleted'], 1);
    });

    test('auth-deleter failure -> 502 retryable envelope; Firestore data is '
        'already gone (retry converges)', () async {
      await seedTree(uid);
      final response = await sendDelete(
        handler(deleteAuthUser: (_) async => throw Exception('auth down')),
      );

      expect(response.statusCode, 502);
      final decoded = await body(response);
      final error = decoded['error'] as Map<String, dynamic>;
      expect(error['code'], 'auth-delete-failed');
      expect(error['retryable'], isTrue);
      await expectTreeGone(uid);
    });

    test('no deleter wired -> Firestore-only deletion, '
        'authUserDeleted:false (client user.delete() stays step two)',
        () async {
      await seedTree(uid);
      final response = await sendDelete(handler(deleteAuthUser: null));

      expect(response.statusCode, 200);
      final decoded = await body(response);
      expect(decoded['deleted'], isTrue);
      expect(decoded['authUserDeleted'], isFalse);
      await expectTreeGone(uid);
    });

    test(
        'a subcollection larger than one backend list page (>300 docs) is '
        'deleted COMPLETELY — not just the first page', () async {
      // google_cloud_firestore 0.5.2's listDocuments() issues ONE
      // ListDocumentsRequest and never follows nextPageToken; production
      // caps a page at ~300 documents. deleteTree's delete-then-relist
      // loop must therefore drain every page — a months-of-history facts
      // log is exactly this shape, and a partial delete behind a 200
      // would orphan the remainder forever once the auth user is gone.
      const factCount = 350;
      await gateway.setDoc('users/$uid', {'id': 'p1', 'name': 'Root'});
      for (var start = 0; start < factCount; start += 50) {
        await Future.wait([
          for (var i = start; i < start + 50 && i < factCount; i++)
            gateway.setDoc(
              'users/$uid/facts/fact-${i.toString().padLeft(4, '0')}',
              {'kind': 'session', 'n': i},
            ),
        ]);
      }

      final response = await sendDelete(handler(deleteAuthUser: (_) async {}));
      expect(response.statusCode, 200);
      final decoded = await body(response);
      expect(decoded['deleted'], isTrue);
      expect(
        decoded['docsDeleted'],
        factCount + 1,
        reason: 'every facts doc plus the root location',
      );

      // A follow-up read finds nothing: first page, last doc, and a full
      // collection scan (the "bootstrap finds nothing" half of §5 #11).
      expect(await gateway.getDoc('users/$uid'), isNull);
      expect(await gateway.getDoc('users/$uid/facts/fact-0000'), isNull);
      expect(await gateway.getDoc('users/$uid/facts/fact-0349'), isNull);
      expect(await gateway.query('users/$uid/facts'), isEmpty);
    });

    test('401 without a token; the deleter never runs', () async {
      var deleterRan = false;
      final response = await handler(
        deleteAuthUser: (_) async => deleterRan = true,
      )(Request('DELETE', Uri.parse('http://localhost/v1/me')));

      expect(response.statusCode, 401);
      expect(deleterRan, isFalse);
    });
  }, skip: skip);
}
