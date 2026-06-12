import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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

/// Minimal auth double: a [Listenable] + mutable uid.
class FakeAuth extends ChangeNotifier {
  String? uid;

  void signIn(String newUid) {
    uid = newUid;
    notifyListeners();
  }

  void signOut() {
    uid = null;
    notifyListeners();
  }
}

ReviewFact _reviewFact({String? id}) => ReviewFact(
  id: id ?? IdGenerator.uuidV4(),
  coreVersion: hifzCoreVersion,
  cardId: 'card-1',
  rating: FlashcardRating.ok,
  reviewedAtUtc: DateTime.utc(2026, 6, 10, 19, 20),
  tzOffsetMinutes: 60,
);

typedef FactsHandler =
    http.Response Function(List<Map<String, dynamic>> facts, int callIndex);

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late HifzDatabaseService dbService;
  late OutboxService outbox;
  late WritePathStore store;
  late FakeAuth auth;
  SyncWorker? worker;

  // Captured request log + pluggable handlers.
  late List<List<Map<String, dynamic>>> factsRequests;
  late List<Map<String, String>> factsRequestHeaders;
  late FactsHandler factsHandler;
  http.Response Function()? bootstrapHandler;

  http.Response okFacts(
    List<Map<String, dynamic>> facts, {
    String epoch = 'e1',
    Map<String, Map<String, dynamic>> overrides = const {},
  }) {
    final results = [
      for (final fact in facts)
        overrides[fact['id']] ?? {'id': fact['id'], 'applied': true},
    ];
    return http.Response(
      jsonEncode({
        'datasetEpoch': epoch,
        'results': results,
        'derived': {'progress': [], 'cards': [], 'streak': null, 'plans': []},
      }),
      200,
      headers: {'content-type': 'application/json'},
    );
  }

  MockClient client() => MockClient((request) async {
    if (request.url.path == '/v1/me/facts') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final facts = (body['facts'] as List).cast<Map<String, dynamic>>();
      factsRequests.add(facts);
      factsRequestHeaders.add(Map.of(request.headers));
      return factsHandler(facts, factsRequests.length - 1);
    }
    if (request.url.path == '/v1/me/bootstrap') {
      return bootstrapHandler?.call() ??
          http.Response(jsonEncode({'profiles': []}), 200);
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
    tempDir = Directory.systemTemp.createTempSync('sync_worker_test_');
    await databaseFactory.setDatabasesPath(tempDir.path);
    dbService = HifzDatabaseService();
    outbox = OutboxService(dbService);
    SharedPreferences.setMockInitialValues({});
    store = WritePathStore(await SharedPreferences.getInstance());
    auth = FakeAuth();
    factsRequests = [];
    factsRequestHeaders = [];
    factsHandler = (facts, _) => okFacts(facts);
    bootstrapHandler = null;
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

  group('drain acknowledgment handling', () {
    test('applied:true AND applied:false-without-error both delete the '
        'row (replay is never an error)', () async {
      auth.uid = 'u1';
      await store.markBackfillDone('u1');
      final f1 = _reviewFact();
      final f2 = _reviewFact();
      await outbox.enqueue(f1, uid: 'u1');
      await outbox.enqueue(f2, uid: 'u1');

      factsHandler = (facts, _) => okFacts(
        facts,
        overrides: {
          f2.id: {'id': f2.id, 'applied': false}, // idempotent replay
        },
      );

      worker = buildWorker();
      await worker!.requestDrain(trigger: 'test');

      expect(await outbox.pendingForUid('u1'), isEmpty);
      expect(worker!.lastDrainResult!.applied, 1);
      expect(worker!.lastDrainResult!.skipped, 1);
      expect(worker!.lastDrainResult!.ok, isTrue);
    });

    test('non-retryable per-item error poisons exactly that row; the rest '
        'of the batch still drains', () async {
      auth.uid = 'u1';
      await store.markBackfillDone('u1');
      final good = _reviewFact();
      final bad = _reviewFact();
      await outbox.enqueue(good, uid: 'u1');
      await outbox.enqueue(bad, uid: 'u1');

      factsHandler = (facts, _) => okFacts(
        facts,
        overrides: {
          bad.id: {
            'id': bad.id,
            'applied': false,
            'error': {
              'code': 'validation',
              'message': 'page out of bounds',
              'retryable': false,
            },
          },
        },
      );

      worker = buildWorker();
      await worker!.requestDrain(trigger: 'test');

      expect(await outbox.pendingForUid('u1'), isEmpty);
      final stats = await outbox.stats(uid: 'u1');
      expect(stats.poisoned, 1);
      expect(worker!.lastDrainResult!.poisoned, 1);
      expect(worker!.lastDrainResult!.applied, 1);
    });

    test('retryable per-item error keeps the row pending with attempts++ '
        'and stops the drain', () async {
      auth.uid = 'u1';
      await store.markBackfillDone('u1');
      final fact = _reviewFact();
      await outbox.enqueue(fact, uid: 'u1');

      factsHandler = (facts, _) => okFacts(
        facts,
        overrides: {
          fact.id: {
            'id': fact.id,
            'applied': false,
            'error': {
              'code': 'rate_limited',
              'message': 'slow down',
              'retryable': true,
            },
          },
        },
      );

      worker = buildWorker();
      await worker!.requestDrain(trigger: 'test');

      final rows = await outbox.pendingForUid('u1');
      expect(rows, hasLength(1));
      expect(rows.single.attempts, 1);
      expect(worker!.lastDrainResult!.ok, isFalse);
    });

    test('network failure keeps rows pending; recovery re-sends the SAME '
        'idempotency keys (kill-mid-drain safety)', () async {
      auth.uid = 'u1';
      await store.markBackfillDone('u1');
      final fact = _reviewFact();
      await outbox.enqueue(fact, uid: 'u1');

      // First attempt: the server applied the batch but the client never
      // saw the response (connection died — equivalent to kill-mid-drain).
      factsHandler = (facts, callIndex) {
        if (callIndex == 0) throw const SocketException('connection reset');
        // Second attempt: server answers the replay with applied:false.
        return okFacts(
          facts,
          overrides: {
            fact.id: {'id': fact.id, 'applied': false},
          },
        );
      };

      worker = buildWorker();
      await worker!.requestDrain(trigger: 'first');
      expect(
        await outbox.pendingForUid('u1'),
        hasLength(1),
        reason: 'no ack → row must survive',
      );

      await worker!.requestDrain(trigger: 'second');
      expect(await outbox.pendingForUid('u1'), isEmpty);

      expect(factsRequests, hasLength(2));
      expect(
        factsRequests[0].single['id'],
        factsRequests[1].single['id'],
        reason: 'replay must reuse the same fact id (idempotency key)',
      );
      expect(worker!.lastDrainResult!.skipped, 1);
    });

    test('HTTP 500 keeps rows pending (retryable)', () async {
      auth.uid = 'u1';
      await store.markBackfillDone('u1');
      await outbox.enqueue(_reviewFact(), uid: 'u1');

      factsHandler = (facts, _) => http.Response('boom', 500);

      worker = buildWorker();
      await worker!.requestDrain(trigger: 'test');

      final rows = await outbox.pendingForUid('u1');
      expect(rows, hasLength(1));
      expect(rows.single.attempts, 1);
    });

    test('batch-level 422 isolates the poison pill row-by-row', () async {
      auth.uid = 'u1';
      await store.markBackfillDone('u1');
      final f1 = _reviewFact();
      final f2 = _reviewFact();
      await outbox.enqueue(f1, uid: 'u1');
      await outbox.enqueue(f2, uid: 'u1');

      factsHandler = (facts, _) {
        if (facts.length > 1) {
          return http.Response(
            jsonEncode({
              'error': {
                'code': 'validation',
                'message': 'malformed batch',
                'retryable': false,
              },
            }),
            422,
          );
        }
        // One-by-one: first row poisoned, second applies.
        if (facts.single['id'] == f1.id) {
          return http.Response(
            jsonEncode({
              'error': {
                'code': 'validation',
                'message': 'bad fact',
                'retryable': false,
              },
            }),
            422,
          );
        }
        return okFacts(facts);
      };

      worker = buildWorker();
      await worker!.requestDrain(trigger: 'test');

      expect(await outbox.pendingForUid('u1'), isEmpty);
      final stats = await outbox.stats(uid: 'u1');
      expect(stats.poisoned, 1);
    });
  });

  group('A → B isolation at the drain level', () {
    test('enqueue under A, switch to B, flush — the server receives '
        'nothing of A\'s', () async {
      await store.markBackfillDone('uid-A');
      await store.markBackfillDone('uid-B');
      auth.uid = 'uid-A';
      await outbox.enqueue(_reviewFact(), uid: 'uid-A');

      // Switch to B before any flush.
      auth.uid = 'uid-B';
      worker = buildWorker();
      await worker!.requestDrain(trigger: 'test');

      expect(factsRequests, isEmpty, reason: 'B has nothing to flush');
      expect(
        await outbox.pendingForUid('uid-A'),
        hasLength(1),
        reason: "A's rows wait for A to sign back in",
      );
    });
  });

  group('datasetEpoch handling (§5)', () {
    test('first epoch is adopted without a reset', () async {
      auth.uid = 'u1';
      await store.markBackfillDone('u1');
      await outbox.enqueue(_reviewFact(), uid: 'u1');

      worker = buildWorker();
      await worker!.requestDrain(trigger: 'test');

      expect(store.datasetEpoch, 'e1');
      expect(await outbox.pendingForUid('u1'), isEmpty);
    });

    test('epoch mismatch clears the outbox + backfill markers and stores '
        'the new epoch (re-backfill policy)', () async {
      auth.uid = 'u1';
      await store.setDatasetEpoch('e1');
      await store.markBackfillDone('u1');
      await store.markBackfillDone('u2');
      await outbox.enqueue(_reviewFact(), uid: 'u1');
      await outbox.enqueue(_reviewFact(), uid: 'u1');

      factsHandler = (facts, _) => okFacts(facts, epoch: 'e2');

      worker = buildWorker();
      await worker!.requestDrain(trigger: 'test');
      // The epoch reset queues a follow-up drain; let it settle.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(store.datasetEpoch, 'e2');
      // The follow-up drain immediately re-ran u1's backfill against the
      // new epoch (and re-marked it done); the queued pre-reset rows are
      // gone for good.
      expect(store.backfillDoneFor('u1'), isTrue);
      expect((await outbox.stats()).pending, 0);
      // Other accounts re-backfill on their next sign-in.
      expect(
        store.backfillDoneFor('u2'),
        isFalse,
        reason: 'all other uids must re-backfill against the new epoch',
      );
    });
  });

  group('403 handling (retryable-with-cap)', () {
    test('a 403 bumps attempts instead of poisoning; the row is poisoned '
        'only at the cap', () async {
      auth.uid = 'u1';
      await store.markBackfillDone('u1');
      final fact = _reviewFact();
      await outbox.enqueue(fact, uid: 'u1');

      factsHandler = (facts, _) => http.Response(
        jsonEncode({
          'error': {
            'code': 'permission-denied',
            'message': 'app check enforcement',
            'retryable': false,
          },
        }),
        403,
      );

      worker = buildWorker();
      await worker!.requestDrain(trigger: 'test');

      var rows = await outbox.pendingForUid('u1');
      expect(
        rows,
        hasLength(1),
        reason: '403 can be transient/environmental — never instant poison',
      );
      expect(rows.single.attempts, 1);
      expect(worker!.lastDrainResult!.ok, isFalse);

      // Drive the row to the cap.
      for (var i = 1; i < SyncWorker.max403Attempts; i++) {
        await worker!.requestDrain(trigger: 'test');
      }
      expect(await outbox.pendingForUid('u1'), isEmpty);
      expect(
        (await outbox.stats(uid: 'u1')).poisoned,
        1,
        reason: 'poisoned only after ${SyncWorker.max403Attempts} attempts',
      );
    });

    test('retryPoisonedRows revives poisoned rows for another drain',
        () async {
      auth.uid = 'u1';
      await store.markBackfillDone('u1');
      final fact = _reviewFact();
      await outbox.enqueue(fact, uid: 'u1');
      final seq = (await outbox.pendingForUid('u1')).single.seq;
      await outbox.poisonRow(seq, 'HTTP 403: app check');
      expect((await outbox.stats(uid: 'u1')).poisoned, 1);

      expect(await outbox.retryPoisonedRows(), 1);
      final rows = await outbox.pendingForUid('u1');
      expect(rows, hasLength(1));
      expect(rows.single.attempts, 0);

      worker = buildWorker();
      await worker!.requestDrain(trigger: 'test');
      expect(await outbox.pendingForUid('u1'), isEmpty);
    });
  });

  group('X-Dataset-Epoch arbitration (§5)', () {
    String? headerOf(Map<String, String> headers, String name) {
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
      }
      return null;
    }

    test('the stored epoch rides every facts POST; a 409 refusal executes '
        'the reset policy and the re-backfill re-applies under the new '
        'epoch', () async {
      final db = await dbService.database;
      await db.insert('profiles', {
        'id': 'p1',
        'name': 'Test',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'startDate': DateTime(2026, 1, 1).toIso8601String(),
        'isActive': 1,
      });
      final sessionId = IdGenerator.uuidV4();
      await db.insert('session_history', {
        'id': sessionId,
        'profileId': 'p1',
        'date': DateTime.utc(2026, 6, 8, 18).toIso8601String(),
        'durationMinutes': 25,
        'sabaqCompleted': 1,
        'sabaqPage': 134,
      });

      auth.uid = 'u1';
      await store.setDatasetEpoch('e0'); // stale generation
      await store.markBackfillDone('u1'); // backfilled under e0 already
      final staleFact = _reviewFact();
      await outbox.enqueue(staleFact, uid: 'u1');

      factsHandler = (facts, _) {
        final claimed =
            headerOf(factsRequestHeaders.last, 'X-Dataset-Epoch');
        if (claimed != 'e1') {
          // Server-side guard: refused BEFORE any write.
          return http.Response(
            jsonEncode({
              'datasetEpoch': 'e1',
              'error': {
                'code': 'dataset-epoch-mismatch',
                'message': 'stale epoch',
                'retryable': false,
              },
            }),
            409,
          );
        }
        return okFacts(facts);
      };

      worker = buildWorker();
      await worker!.requestDrain(trigger: 'test');
      // The reset queues a follow-up drain (re-backfill); let it settle.
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        if (factsRequests.length >= 2 &&
            (await outbox.stats()).pending == 0) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }

      // First POST asserted the stale epoch (the server-side guard's input).
      expect(headerOf(factsRequestHeaders.first, 'X-Dataset-Epoch'), 'e0');
      // Reset executed: new epoch adopted, markers cleared then re-marked
      // by the follow-up backfill.
      expect(store.datasetEpoch, 'e1');
      expect(store.backfillDoneFor('u1'), isTrue);
      // The stale outbox row is gone for good; the re-backfill re-applied
      // local HISTORY under the new epoch.
      final lastIds = [for (final f in factsRequests.last) f['id']];
      expect(lastIds, isNot(contains(staleFact.id)));
      expect(lastIds, contains(sessionId));
      expect(headerOf(factsRequestHeaders.last, 'X-Dataset-Epoch'), 'e1');
      expect((await outbox.stats()).pending, 0);
    });
  });

  group('first-drain ordering (adopted rows vs backfill history)', () {
    test('a live fact enqueued signed-out drains AFTER the backfilled '
        'history — streak fold counts every historical day', () async {
      final db = await dbService.database;
      await db.insert('profiles', {
        'id': 'p1',
        'name': 'Test',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'startDate': DateTime(2026, 1, 1).toIso8601String(),
        'isActive': 1,
      });
      // Months of pre-v8 history (3 days).
      for (final day in [1, 2, 3]) {
        await db.insert('session_history', {
          'id': IdGenerator.uuidV4(),
          'profileId': 'p1',
          'date': DateTime.utc(2026, 6, day, 18).toIso8601String(),
          'durationMinutes': 20,
          'sabaqCompleted': 1,
          'sabaqPage': 130 + day,
        });
      }
      // TODAY's session, recorded signed-out BEFORE the first sign-in —
      // it holds the lowest outbox seq.
      final todayFact = SessionFact(
        id: IdGenerator.uuidV4(),
        coreVersion: hifzCoreVersion,
        profileId: 'p1',
        date: '2026-06-09',
        tzOffsetMinutes: 60,
        durationMinutes: 30,
        repCount: 10,
        sabaq: const SabaqOutcome(
          completed: true,
          assessment: SelfAssessment.okay,
          page: 140,
        ),
        sabqi: const PhaseOutcome(completed: false),
        manzil: const PhaseOutcome(completed: false),
        planId: 'p1_2026-06-09T00:00:00.000',
        planRevision: 0,
        planOrigin: PlanOrigin.client,
        recordedAtUtc: DateTime.utc(2026, 6, 9, 18),
      );
      await outbox.enqueue(todayFact, uid: null);

      worker = buildWorker();
      auth.signIn('u1');

      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        if (factsRequests.isNotEmpty &&
            (await outbox.pendingForUid('u1')).isEmpty) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }

      // Everything flushed in fact-chronological order: history FIRST.
      final sent = factsRequests.expand((batch) => batch).toList();
      final dates = [
        for (final raw in sent)
          if (raw['kind'] == 'session') raw['date'] as String,
      ];
      expect(dates, [
        '2026-06-01',
        '2026-06-02',
        '2026-06-03',
        '2026-06-09',
      ]);

      // The server folds per arrival order across batches — fold each fact
      // separately (worst case: one fact per batch) and assert no
      // historical day is swallowed by today's lastActiveDate.
      var streak = const StreakData();
      for (final raw in sent) {
        final fact = Fact.fromJson(raw);
        if (fact is SessionFact) {
          streak = StreakDerivation.fold(prior: streak, sessions: [fact]);
        }
      }
      expect(
        streak.totalActiveDays,
        4,
        reason: '3 history days + today — NOT 1 (the pre-fix corruption)',
      );
    });
  });

  group('backfill orchestration', () {
    test('first drain for a uid runs the one-time backfill, then marks it '
        'done', () async {
      final db = await dbService.database;
      await db.insert('profiles', {
        'id': 'p1',
        'name': 'Test',
        'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        'startDate': DateTime(2026, 1, 1).toIso8601String(),
        'isActive': 1,
      });
      final sessionId = IdGenerator.uuidV4();
      await db.insert('session_history', {
        'id': sessionId,
        'profileId': 'p1',
        'date': DateTime.utc(2026, 6, 8, 18).toIso8601String(),
        'durationMinutes': 25,
        'sabaqCompleted': 1,
        'sabaqPage': 134,
      });

      auth.uid = 'u1';
      expect(store.backfillDoneFor('u1'), isFalse);

      worker = buildWorker();
      await worker!.requestDrain(trigger: 'test');

      expect(store.backfillDoneFor('u1'), isTrue);
      expect(factsRequests, hasLength(1));
      expect(factsRequests.single.single['id'], sessionId);
      expect(await outbox.pendingForUid('u1'), isEmpty);
    });
  });

  group('writePath from bootstrap', () {
    test('bootstrap writePath=facts is cached per uid; missing field '
        'defaults to legacy', () async {
      auth.uid = 'u1';
      bootstrapHandler = () => http.Response(
        jsonEncode({
          'profiles': [],
          'writePath': 'facts',
          'datasetEpoch': 'e1',
        }),
        200,
      );

      worker = buildWorker();
      await worker!.refreshBootstrapMeta();

      expect(store.pathFor('u1'), WritePathStore.facts);
      expect(store.isFactsUser('u1'), isTrue);
      expect(store.isFactsUser('someone-else'), isFalse);
      expect(store.datasetEpoch, 'e1');
      expect(worker!.currentWritePath, WritePathStore.facts);

      // Unknown uid (offline default) stays legacy.
      expect(store.pathFor('u-unknown'), WritePathStore.legacy);
    });

    test('bootstrap failure leaves the cached value untouched', () async {
      auth.uid = 'u1';
      await store.setPathFor('u1', WritePathStore.facts);
      bootstrapHandler = () => http.Response('down', 503);

      worker = buildWorker();
      await worker!.refreshBootstrapMeta();

      expect(store.pathFor('u1'), WritePathStore.facts);
    });
  });

  group('sign-in trigger', () {
    test('a sign-in adopts NULL-uid rows and drains them', () async {
      await outbox.enqueue(_reviewFact(), uid: null);

      worker = buildWorker();
      auth.signIn('u1');

      // Sign-in flow is fire-and-forget; poll for completion.
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (DateTime.now().isBefore(deadline)) {
        if (factsRequests.isNotEmpty &&
            (await outbox.pendingForUid('u1')).isEmpty) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }

      expect(factsRequests, hasLength(1));
      expect(await outbox.pendingForUid('u1'), isEmpty);
      expect(store.backfillDoneFor('u1'), isTrue);
    });
  });

  group('account-deletion quiesce (§5 #11)', () {
    // A drain racing DELETE /v1/me recreates docs under the deleted uid —
    // permanently orphaned, because the ID token outlives auth.deleteUser
    // but no client can ever sign in as that uid again.

    test('quiesce refuses every new drain until resumed; queued rows stay',
        () async {
      auth.uid = 'u1';
      await store.markBackfillDone('u1');
      await outbox.enqueue(_reviewFact(), uid: 'u1');

      worker = buildWorker();
      await worker!.quiesceForAccountDeletion();
      expect(worker!.isQuiesced, isTrue);

      await worker!.requestDrain();
      expect(factsRequests, isEmpty, reason: 'no POST while quiesced');
      expect((await outbox.stats(uid: 'u1')).pending, 1);

      worker!.resumeAfterFailedAccountDeletion();
      await worker!.requestDrain();
      expect(factsRequests, hasLength(1),
          reason: 'a FAILED deletion restores normal sync');
    });

    test('quiesce AWAITS the in-flight drain — no POST completes after it '
        'returns', () async {
      auth.uid = 'u1';
      await store.markBackfillDone('u1');
      await outbox.enqueue(_reviewFact(), uid: 'u1');

      var postsStarted = 0;
      var postsFinished = 0;
      final slowClient = MockClient((request) async {
        if (request.url.path == '/v1/me/facts') {
          postsStarted++;
          await Future<void>.delayed(const Duration(milliseconds: 150));
          postsFinished++;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          return okFacts((body['facts'] as List).cast<Map<String, dynamic>>());
        }
        return http.Response(jsonEncode({'profiles': []}), 200);
      });
      worker = SyncWorker(
        outbox: outbox,
        store: store,
        authChanges: auth,
        uidProvider: () => auth.uid,
        idTokenProvider: ({bool forceRefresh = false}) async => 'test-token',
        apiBaseUrl: 'https://api.test',
        httpClient: slowClient,
        observeAppLifecycle: false,
      );

      final drain = worker!.requestDrain();
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (postsStarted == 0 && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(postsStarted, 1, reason: 'drain reached the slow POST');

      await worker!.quiesceForAccountDeletion();
      expect(postsFinished, 1,
          reason: 'quiesce returned only after the in-flight POST finished');
      expect(worker!.isDraining, isFalse);
      await drain;
    });

    test('sign-out lifts the quiesce: the next sign-in syncs normally',
        () async {
      auth.uid = 'u1';
      await store.markBackfillDone('u1');
      worker = buildWorker();
      await worker!.quiesceForAccountDeletion();

      auth.signOut();
      expect(worker!.isQuiesced, isFalse);

      await store.markBackfillDone('u2');
      await outbox.enqueue(_reviewFact(), uid: 'u2');
      auth.signIn('u2');
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (factsRequests.isEmpty && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      expect(factsRequests, hasLength(1));
    });
  });
}
