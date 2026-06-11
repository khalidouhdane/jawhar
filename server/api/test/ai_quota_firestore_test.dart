// Contract tests for FirestoreAiQuota against the FIRESTORE EMULATOR
// (roadmap §10 local dev loop). Run with the emulator up:
//
//   firebase emulators:exec --only firestore --project quran-app-e5e86 ^
//     "dart test test/ai_quota_firestore_test.dart"
//
// (emulators:exec sets FIRESTORE_EMULATOR_HOST for the child process.)
// Without the emulator the suite is SKIPPED, not silently green: each test
// reports the skip reason, and plain `dart test` stays runnable offline.

import 'dart:io';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:jawhar_api/gateway/firestore_gateway.dart';
import 'package:jawhar_api/quota/ai_quota.dart';
import 'package:test/test.dart';

void main() {
  final emulatorHost = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  final skip = (emulatorHost == null || emulatorHost.isEmpty)
      ? 'FIRESTORE_EMULATOR_HOST not set — start the Firestore emulator '
          '(firebase emulators:exec --only firestore --project '
          'quran-app-e5e86 "dart test test/ai_quota_firestore_test.dart")'
      : null;

  group('FirestoreAiQuota (emulator)', () {
    late FirebaseApp app;
    late FirestoreGateway gateway;
    var run = 0;

    setUpAll(() {
      // demo- prefix = offline-only project by Firebase convention.
      app = FirebaseApp.initializeApp(
        options: const AppOptions(projectId: 'demo-jawhar-quota-test'),
      );
      gateway = FirestoreGateway(app.firestore());
    });

    tearDownAll(() async {
      await app.close();
    });

    // Fresh uid per test so tests never share quota docs.
    late String uid;
    setUp(() => uid = 'quota-uid-${DateTime.now().microsecondsSinceEpoch}-${run++}');

    test('allows up to the daily limit, then denies', () async {
      final quota = FirestoreAiQuota(gateway, dailyLimit: 3);
      for (var i = 0; i < 3; i++) {
        final d = await quota.tryConsume(uid: uid, localDate: '2026-06-11');
        expect(d.allowed, isTrue, reason: 'call ${i + 1} of 3 should pass');
        expect(d.remaining, 3 - i - 1);
      }
      final denied =
          await quota.tryConsume(uid: uid, localDate: '2026-06-11');
      expect(denied.allowed, isFalse);
      expect(denied.remaining, 0);
      expect(denied.limit, 3);

      final doc = await gateway.getDoc(FirestoreAiQuota.docPath(uid));
      expect(doc!['date'], '2026-06-11');
      expect(doc['count'], 3, reason: 'denied attempt must not increment');
    });

    test('a new client-local date resets the counter', () async {
      final quota = FirestoreAiQuota(gateway, dailyLimit: 1);
      expect(
        (await quota.tryConsume(uid: uid, localDate: '2026-06-10')).allowed,
        isTrue,
      );
      expect(
        (await quota.tryConsume(uid: uid, localDate: '2026-06-10')).allowed,
        isFalse,
      );
      // Next local day: fresh allowance, doc rolls over in place.
      final nextDay =
          await quota.tryConsume(uid: uid, localDate: '2026-06-11');
      expect(nextDay.allowed, isTrue);
      final doc = await gateway.getDoc(FirestoreAiQuota.docPath(uid));
      expect(doc!['date'], '2026-06-11');
      expect(doc['count'], 1);
    });

    test('quotas are per uid', () async {
      final quota = FirestoreAiQuota(gateway, dailyLimit: 1);
      expect(
        (await quota.tryConsume(uid: '$uid-a', localDate: '2026-06-11'))
            .allowed,
        isTrue,
      );
      expect(
        (await quota.tryConsume(uid: '$uid-a', localDate: '2026-06-11'))
            .allowed,
        isFalse,
      );
      expect(
        (await quota.tryConsume(uid: '$uid-b', localDate: '2026-06-11'))
            .allowed,
        isTrue,
        reason: 'a different uid has its own daily bucket',
      );
    });

    test('concurrent consumption never exceeds the limit (transactional)',
        () async {
      final quota = FirestoreAiQuota(gateway, dailyLimit: 5);
      final decisions = await Future.wait(List.generate(
        10,
        (_) => quota.tryConsume(uid: uid, localDate: '2026-06-11'),
      ));
      final allowed = decisions.where((d) => d.allowed).length;
      expect(allowed, 5,
          reason: '10 concurrent attempts against limit 5 must yield '
              'exactly 5 allowed — anything else means the transaction '
              'is not actually transactional');
      final doc = await gateway.getDoc(FirestoreAiQuota.docPath(uid));
      expect(doc!['count'], 5);
    });
  }, skip: skip);
}
