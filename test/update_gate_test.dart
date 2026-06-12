// §5 force-update gate: builds below the server's `minSupportedBuild` BLOCK
// SYNC ONLY — the outbox drain is skipped (facts stay queued locally, the
// offline core loop keeps enqueueing) and the gate is surfaced for the
// non-dismissable banner. At/above the threshold nothing changes; with the
// server unreachable nothing changes (fail-open). Same harness as
// sync_worker_test.dart.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_core/hifz_core.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/services/outbox_service.dart';
import 'package:quran_app/services/sync_worker.dart';
import 'package:quran_app/services/write_path_store.dart';

class FakeAuth extends ChangeNotifier {
  String? uid;
}

ReviewFact _reviewFact() => ReviewFact(
  id: IdGenerator.uuidV4(),
  coreVersion: hifzCoreVersion,
  cardId: 'card-1',
  rating: FlashcardRating.ok,
  reviewedAtUtc: DateTime.utc(2026, 6, 10, 19, 20),
  tzOffsetMinutes: 60,
);

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late HifzDatabaseService dbService;
  late OutboxService outbox;
  late WritePathStore store;
  late FakeAuth auth;
  SyncWorker? worker;

  late List<List<Map<String, dynamic>>> factsRequests;
  int? bootstrapMinSupportedBuild; // null -> bootstrap answers 500
  late int bootstrapCalls;

  MockClient client() => MockClient((request) async {
    if (request.url.path == '/v1/me/bootstrap') {
      bootstrapCalls++;
      final minBuild = bootstrapMinSupportedBuild;
      if (minBuild == null) return http.Response('outage', 500);
      return http.Response(
        jsonEncode({
          'minSupportedBuild': minBuild,
          'datasetEpoch': 'e1',
          'writePath': 'facts',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    if (request.url.path == '/v1/me/facts') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final facts = (body['facts'] as List).cast<Map<String, dynamic>>();
      factsRequests.add(facts);
      return http.Response(
        jsonEncode({
          'datasetEpoch': 'e1',
          'results': [
            for (final fact in facts) {'id': fact['id'], 'applied': true},
          ],
          'derived': {'progress': [], 'cards': [], 'streak': null, 'plans': []},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response('not found', 404);
  });

  SyncWorker buildWorker() => SyncWorker(
    outbox: outbox,
    store: store,
    authChanges: auth,
    uidProvider: () => auth.uid,
    idTokenProvider: ({bool forceRefresh = false}) async => 'test-token',
    apiBaseUrl: 'https://api.test',
    httpClient: client(),
    observeAppLifecycle: false,
  );

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('update_gate_test_');
    await databaseFactory.setDatabasesPath(tempDir.path);
    dbService = HifzDatabaseService();
    outbox = OutboxService(dbService);
    SharedPreferences.setMockInitialValues({});
    store = WritePathStore(await SharedPreferences.getInstance());
    auth = FakeAuth();
    factsRequests = [];
    bootstrapMinSupportedBuild = 1;
    bootstrapCalls = 0;
    worker = null;
  });

  tearDown(() async {
    worker?.dispose();
    outbox.dispose();
    try {
      final db = await dbService.database;
      await db.close();
    } catch (_) {}
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('WritePathStore.updateRequired (pure gate logic)', () {
    test('default: no server contact, no build number -> never blocked',
        () async {
      expect(store.minSupportedBuild, 0);
      expect(store.updateRequired, isFalse);
      store.currentBuildNumber = 24;
      expect(store.updateRequired, isFalse);
    });

    test('below min -> required; at min -> not; above min -> not', () async {
      await store.setMinSupportedBuild(25);
      store.currentBuildNumber = 24;
      expect(store.updateRequired, isTrue);
      store.currentBuildNumber = 25;
      expect(store.updateRequired, isFalse);
      store.currentBuildNumber = 26;
      expect(store.updateRequired, isFalse);
    });

    test('unknown build number (null) -> fail-open even with a stored min',
        () async {
      await store.setMinSupportedBuild(25);
      store.currentBuildNumber = null;
      expect(store.updateRequired, isFalse);
    });
  });

  group('below-min blocks the drain and shows the gate', () {
    test('bootstrap engages the gate; queued facts never leave; rows stay '
        'pending for the post-update drain', () async {
      auth.uid = 'u1';
      store.currentBuildNumber = 24;
      bootstrapMinSupportedBuild = 25;
      await store.markBackfillDone('u1');
      await outbox.enqueue(_reviewFact(), uid: 'u1');

      worker = buildWorker();
      await worker!.start(); // bootstrap refresh + drain attempt

      expect(worker!.updateRequired, isTrue, reason: 'gate is shown');
      expect(factsRequests, isEmpty, reason: 'sync is blocked');
      expect(
        worker!.lastDrainResult?.error,
        contains('update-required'),
        reason: 'debug screen sees why the drain did nothing',
      );
      final stats = await outbox.stats(uid: 'u1');
      expect(stats.pending, 1, reason: 'nothing dropped — offline loop data '
          'waits for the updated build');
    });

    test('enqueueing KEEPS WORKING while gated (offline core loop is never '
        'blocked)', () async {
      auth.uid = 'u1';
      store.currentBuildNumber = 24;
      await store.setMinSupportedBuild(25);
      await store.markBackfillDone('u1');

      worker = buildWorker();
      await outbox.enqueue(_reviewFact(), uid: 'u1');
      await outbox.enqueue(_reviewFact(), uid: 'u1');
      await worker!.requestDrain();

      expect(factsRequests, isEmpty);
      expect((await outbox.stats(uid: 'u1')).pending, 2);
    });

    test('gate persists offline: stored threshold still blocks when the '
        'server is unreachable', () async {
      auth.uid = 'u1';
      store.currentBuildNumber = 24;
      await store.setMinSupportedBuild(25); // learned on a previous run
      bootstrapMinSupportedBuild = null; // bootstrap now answers 500
      await store.markBackfillDone('u1');
      await outbox.enqueue(_reviewFact(), uid: 'u1');

      worker = buildWorker();
      await worker!.start();

      expect(worker!.updateRequired, isTrue);
      expect(factsRequests, isEmpty);
    });
  });

  group('at/above min unaffected', () {
    test('build == minSupportedBuild -> drain flushes normally', () async {
      auth.uid = 'u1';
      store.currentBuildNumber = 24;
      bootstrapMinSupportedBuild = 24;
      await store.markBackfillDone('u1');
      await outbox.enqueue(_reviewFact(), uid: 'u1');

      worker = buildWorker();
      await worker!.start();

      expect(worker!.updateRequired, isFalse);
      expect(factsRequests, hasLength(1));
      expect((await outbox.stats(uid: 'u1')).pending, 0);
    });

    test('the gate LIFTS when the server lowers minSupportedBuild (no app '
        'update needed) and the queue then drains', () async {
      auth.uid = 'u1';
      store.currentBuildNumber = 24;
      await store.setMinSupportedBuild(25); // gated from a previous contact
      await store.markBackfillDone('u1');
      await outbox.enqueue(_reviewFact(), uid: 'u1');

      worker = buildWorker();
      expect(worker!.updateRequired, isTrue);

      bootstrapMinSupportedBuild = 24; // server rolls the threshold back
      await worker!.start();

      expect(worker!.updateRequired, isFalse);
      expect(factsRequests, hasLength(1));
      expect((await outbox.stats(uid: 'u1')).pending, 0);
    });
  });

  group('gated refresh cadence (lift without restart)', () {
    // The gate schedules no backoff on purpose, so the foreground and
    // connectivity triggers must re-read the threshold themselves —
    // otherwise "server lowers minSupportedBuild -> gate lifts, queue
    // drains, no app update needed" only works on the next app restart.

    Future<void> settle() async {
      for (var i = 0; i < 40 && factsRequests.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    }

    test('connectivity regained while GATED -> threshold re-read; a lowered '
        'server threshold lifts the gate and drains, no restart', () async {
      auth.uid = 'u1';
      store.currentBuildNumber = 24;
      await store.setMinSupportedBuild(25); // gated from a previous contact
      await store.markBackfillDone('u1');
      await outbox.enqueue(_reviewFact(), uid: 'u1');

      final connectivity = StreamController<dynamic>.broadcast();
      addTearDown(connectivity.close);
      worker = SyncWorker(
        outbox: outbox,
        store: store,
        authChanges: auth,
        uidProvider: () => auth.uid,
        idTokenProvider: ({bool forceRefresh = false}) async => 'test-token',
        apiBaseUrl: 'https://api.test',
        httpClient: client(),
        connectivityChanges: connectivity.stream,
        observeAppLifecycle: false,
      );
      expect(worker!.updateRequired, isTrue);

      bootstrapMinSupportedBuild = 24; // server rolls the threshold back
      connectivity.add(['wifi']);
      await settle();

      expect(bootstrapCalls, 1, reason: 'gated trigger re-reads bootstrap');
      expect(worker!.updateRequired, isFalse, reason: 'gate lifted');
      expect(factsRequests, hasLength(1), reason: 'queue drained');
    });

    test('app foreground while GATED -> threshold re-read and gate lifts',
        () async {
      auth.uid = 'u1';
      store.currentBuildNumber = 24;
      await store.setMinSupportedBuild(25);
      await store.markBackfillDone('u1');
      await outbox.enqueue(_reviewFact(), uid: 'u1');

      worker = buildWorker();
      expect(worker!.updateRequired, isTrue);

      bootstrapMinSupportedBuild = 24;
      worker!.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle();

      expect(bootstrapCalls, 1);
      expect(worker!.updateRequired, isFalse);
      expect(factsRequests, hasLength(1));
    });

    test('NOT gated -> foreground/connectivity do not spam bootstrap '
        '(drain only)', () async {
      auth.uid = 'u1';
      store.currentBuildNumber = 24;
      await store.setMinSupportedBuild(24); // at min: not gated
      await store.markBackfillDone('u1');
      await outbox.enqueue(_reviewFact(), uid: 'u1');

      worker = buildWorker();
      worker!.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle();

      expect(factsRequests, hasLength(1));
      expect(bootstrapCalls, 0, reason: 'ungated triggers go straight to '
          'the drain — the refresh is gate-scoped on purpose');
    });
  });

  group('offline unaffected', () {
    test('no stored threshold + unreachable bootstrap -> gate stays off and '
        'the drain still attempts its POST', () async {
      auth.uid = 'u1';
      store.currentBuildNumber = 24;
      bootstrapMinSupportedBuild = null; // 500 on bootstrap
      await store.markBackfillDone('u1');
      await outbox.enqueue(_reviewFact(), uid: 'u1');

      worker = buildWorker();
      await worker!.start();

      expect(bootstrapCalls, 1);
      expect(worker!.updateRequired, isFalse, reason: 'fail-open');
      expect(factsRequests, hasLength(1), reason: 'sync proceeds normally');
    });
  });
}
