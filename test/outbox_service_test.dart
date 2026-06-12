import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_core/hifz_core.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/services/outbox_service.dart';

ReviewFact _reviewFact({String? id, String cardId = 'card-1'}) => ReviewFact(
  id: id ?? IdGenerator.uuidV4(),
  coreVersion: hifzCoreVersion,
  cardId: cardId,
  rating: FlashcardRating.ok,
  reviewedAtUtc: DateTime.utc(2026, 6, 10, 19, 20),
  tzOffsetMinutes: 60,
);

Future<void> _insertProfile(Database db, String id) => db.insert('profiles', {
  'id': id,
  'name': 'Test',
  'createdAt': DateTime(2026, 1, 1).toIso8601String(),
  'startDate': DateTime(2026, 1, 1).toIso8601String(),
  'isActive': 1,
});

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Directory tempDir;
  late HifzDatabaseService dbService;
  late OutboxService outbox;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('outbox_test_');
    await databaseFactory.setDatabasesPath(tempDir.path);
    dbService = HifzDatabaseService();
    outbox = OutboxService(dbService);
  });

  tearDown(() async {
    outbox.dispose();
    try {
      final db = await dbService.database;
      await db.close();
    } catch (_) {}
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('schema migration v7 → v8', () {
    test('upgrade creates sync_outbox and preserves legacy data', () async {
      // Pre-create a v7 database with a minimal legacy schema + data.
      final path = '${tempDir.path}/hifz_data.db';
      final v7 = await databaseFactory.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 7,
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE session_history (id TEXT PRIMARY KEY, '
              'profileId TEXT NOT NULL, date TEXT NOT NULL, '
              'durationMinutes INTEGER DEFAULT 0)',
            );
            await db.insert('session_history', {
              'id': 'legacy-row',
              'profileId': 'p1',
              'date': DateTime.utc(2026, 6, 1).toIso8601String(),
              'durationMinutes': 10,
            });
          },
        ),
      );
      await v7.close();

      // Opening through the service runs _onUpgrade(7 → 8).
      final db = await dbService.database;
      expect(await db.getVersion(), 8);

      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name='sync_outbox'",
      );
      expect(tables, hasLength(1), reason: 'v8 must add sync_outbox');

      final legacy = await db.query('session_history');
      expect(legacy, hasLength(1));
      expect(legacy.single['id'], 'legacy-row');
    });

    test('fresh install (onCreate) also has sync_outbox', () async {
      final db = await dbService.database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name='sync_outbox'",
      );
      expect(tables, hasLength(1));
    });
  });

  group('uid partitioning + NULL-uid adoption (§7.2)', () {
    test('rows enqueued signed-out are adopted by the FIRST sign-in, '
        'exactly once', () async {
      await outbox.enqueue(_reviewFact(), uid: null);

      // First sign-in adopts.
      expect(await outbox.adoptOrphanRows('uid-A'), 1);
      expect(await outbox.pendingForUid('uid-A'), hasLength(1));

      // Second adoption attempt (same or different uid) gets nothing.
      expect(await outbox.adoptOrphanRows('uid-A'), 0);
      expect(await outbox.adoptOrphanRows('uid-B'), 0);
      expect(await outbox.pendingForUid('uid-B'), isEmpty);
    });

    test('A → B switch isolation: rows owned by A are never drained '
        'under B', () async {
      await outbox.enqueue(_reviewFact(), uid: 'uid-A');
      // B signs in afterwards and enqueues their own work.
      await outbox.enqueue(_reviewFact(), uid: 'uid-B');

      final forB = await outbox.pendingForUid('uid-B');
      expect(forB, hasLength(1));
      expect(forB.single.uid, 'uid-B');

      final forA = await outbox.pendingForUid('uid-A');
      expect(forA, hasLength(1));
      expect(forA.single.uid, 'uid-A');
    });

    test('rows enqueued while signed out AFTER an A session belong to the '
        'next sign-in (B), not to A', () async {
      await outbox.enqueue(_reviewFact(), uid: 'uid-A');
      // A signs out; user keeps reviewing offline.
      await outbox.enqueue(_reviewFact(), uid: null);
      // B signs in → adopts only the orphan row.
      expect(await outbox.adoptOrphanRows('uid-B'), 1);
      expect(await outbox.pendingForUid('uid-A'), hasLength(1));
      expect(await outbox.pendingForUid('uid-B'), hasLength(1));
    });

    test('adoption survives UNIQUE(uid, entity_id) collisions: duplicate '
        '(NULL, X) rows + an existing (uid, X) row never stall the drain',
        () async {
      final fact = _reviewFact();
      // The uid already owns X (e.g. a previous backfill enqueued it)...
      await outbox.enqueue(fact, uid: 'uid-A');
      // ...and TWO orphan rows carry the same entity id (SQLite UNIQUE
      // indexes treat NULLs as distinct, so both can exist).
      await outbox.enqueue(fact, uid: null);
      final db = await dbService.database;
      await db.insert('sync_outbox', {
        'uid': null,
        'kind': fact.kind,
        'entity_id': fact.id,
        'payload': jsonEncode(fact.toJson()),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'attempts': 0,
        'status': 'pending',
      });
      // Plus one legitimately adoptable orphan.
      final other = _reviewFact();
      await outbox.enqueue(other, uid: null);

      // A plain UPDATE would throw here — adoption must complete.
      final adopted = await outbox.adoptOrphanRows('uid-A');
      expect(adopted, 1, reason: 'only the non-colliding orphan adopts');

      final rows = await outbox.pendingForUid('uid-A', limit: 100);
      expect({for (final r in rows) r.entityId}, {fact.id, other.id});
      // The colliding duplicates are gone; nothing remains unowned.
      expect((await outbox.stats()).pending, 2);

      // And the very next adoption is a clean no-op.
      expect(await outbox.adoptOrphanRows('uid-A'), 0);
    });
  });

  group('chronological re-sequencing (first-drain ordering)', () {
    test('resequencePendingForUid orders rows by the payload instant, '
        'preserving row contents', () async {
      // Enqueued newest-first — the broken order a pre-backfill live fact
      // produces (low seq = today, high seqs = history).
      final newest = ReviewFact(
        id: IdGenerator.uuidV4(),
        coreVersion: hifzCoreVersion,
        cardId: 'card-1',
        rating: FlashcardRating.ok,
        reviewedAtUtc: DateTime.utc(2026, 6, 10, 19),
        tzOffsetMinutes: 60,
      );
      final oldest = ReviewFact(
        id: IdGenerator.uuidV4(),
        coreVersion: hifzCoreVersion,
        cardId: 'card-1',
        rating: FlashcardRating.strong,
        reviewedAtUtc: DateTime.utc(2026, 6, 1, 9),
        tzOffsetMinutes: 60,
      );
      final middle = SessionFact(
        id: IdGenerator.uuidV4(),
        coreVersion: hifzCoreVersion,
        profileId: 'p1',
        date: '2026-06-05',
        tzOffsetMinutes: 60,
        durationMinutes: 20,
        repCount: 5,
        sabaq: const SabaqOutcome(completed: true, page: 134),
        sabqi: const PhaseOutcome(completed: false),
        manzil: const PhaseOutcome(completed: false),
        planId: 'p1_2026-06-05T00:00:00.000',
        planRevision: 0,
        planOrigin: PlanOrigin.client,
        recordedAtUtc: DateTime.utc(2026, 6, 5, 18),
      );
      await outbox.enqueue(newest, uid: 'u');
      await outbox.enqueue(oldest, uid: 'u');
      await outbox.enqueue(middle, uid: 'u');
      // Another uid's rows must be untouched.
      final foreign = _reviewFact();
      await outbox.enqueue(foreign, uid: 'other');

      await outbox.resequencePendingForUid('u');

      final rows = await outbox.pendingForUid('u', limit: 100);
      expect(
        [for (final r in rows) r.entityId],
        [oldest.id, middle.id, newest.id],
        reason: 'seq order must now encode fact chronology',
      );
      // Payloads still round-trip through the strict codec.
      for (final row in rows) {
        Fact.fromJson(jsonDecode(row.payload) as Map<String, dynamic>);
      }
      expect((await outbox.pendingForUid('other')).single.entityId, foreign.id);

      // Idempotent: a second pass changes nothing.
      await outbox.resequencePendingForUid('u');
      expect(
        [for (final r in await outbox.pendingForUid('u', limit: 100)) r.entityId],
        [oldest.id, middle.id, newest.id],
      );
    });
  });

  group('idempotent enqueue', () {
    test('same fact id under the same uid inserts once', () async {
      final fact = _reviewFact();
      await outbox.enqueue(fact, uid: 'uid-A');
      await outbox.enqueue(fact, uid: 'uid-A');
      expect(await outbox.pendingForUid('uid-A'), hasLength(1));
    });

    test('same fact id under different uids is allowed (device history '
        'goes to every first-sign-in, §7.3)', () async {
      final fact = _reviewFact();
      await outbox.enqueue(fact, uid: 'uid-A');
      await outbox.enqueue(fact, uid: 'uid-B');
      expect(await outbox.pendingForUid('uid-A'), hasLength(1));
      expect(await outbox.pendingForUid('uid-B'), hasLength(1));
    });
  });

  group('row lifecycle', () {
    test('deleteRows removes acked rows; poisonRow keeps the row out of '
        'pendingForUid; bumpAttempts increments', () async {
      final f1 = _reviewFact();
      final f2 = _reviewFact();
      final f3 = _reviewFact();
      await outbox.enqueue(f1, uid: 'u');
      await outbox.enqueue(f2, uid: 'u');
      await outbox.enqueue(f3, uid: 'u');

      var rows = await outbox.pendingForUid('u');
      expect(rows, hasLength(3));

      await outbox.deleteRows([rows[0].seq]);
      await outbox.poisonRow(rows[1].seq, 'validation: bad page');
      await outbox.bumpAttempts([rows[2].seq], 'HTTP 503');

      rows = await outbox.pendingForUid('u');
      expect(rows, hasLength(1));
      expect(rows.single.entityId, f3.id);
      expect(rows.single.attempts, 1);
      expect(rows.single.lastError, 'HTTP 503');

      final stats = await outbox.stats(uid: 'u');
      expect(stats.pending, 1);
      expect(stats.poisoned, 1);
    });

    test('clearAll wipes everything (epoch-mismatch policy)', () async {
      await outbox.enqueue(_reviewFact(), uid: 'u');
      await outbox.enqueue(_reviewFact(), uid: null);
      await outbox.clearAll();
      final stats = await outbox.stats();
      expect(stats.pending, 0);
      expect(stats.poisoned, 0);
    });
  });

  group('transactional enqueue', () {
    test('saveSessionRecordAndEnqueue writes session + outbox row '
        'atomically', () async {
      final db = await dbService.database;
      await _insertProfile(db, 'p1');

      final record = SessionRecord(
        id: IdGenerator.uuidV4(),
        profileId: 'p1',
        date: DateTime.utc(2026, 6, 10, 19, 4),
        durationMinutes: 38,
        sabaqCompleted: true,
        sabaqAssessment: SelfAssessment.okay,
        sabaqPage: 134,
        repCount: 14,
      );
      final fact = SessionFact(
        id: record.id,
        coreVersion: hifzCoreVersion,
        profileId: 'p1',
        date: '2026-06-10',
        tzOffsetMinutes: 60,
        durationMinutes: 38,
        repCount: 14,
        sabaq: const SabaqOutcome(
          completed: true,
          assessment: SelfAssessment.okay,
          page: 134,
        ),
        sabqi: const PhaseOutcome(completed: false),
        manzil: const PhaseOutcome(completed: false),
        planId: 'p1_2026-06-10T00:00:00.000',
        planRevision: 0,
        planOrigin: PlanOrigin.client,
        recordedAtUtc: DateTime.utc(2026, 6, 10, 19, 4),
      );

      await outbox.saveSessionRecordAndEnqueue(record, fact, uid: 'u');

      expect(await db.query('session_history'), hasLength(1));
      final rows = await outbox.pendingForUid('u');
      expect(rows, hasLength(1));
      expect(rows.single.kind, 'session');
      // The payload round-trips through the strict wire codec.
      final parsed = Fact.fromJson(
        jsonDecode(rows.single.payload) as Map<String, dynamic>,
      );
      expect(parsed, isA<SessionFact>());
      expect((parsed as SessionFact).actualPagesCovered, isEmpty);
      expect(parsed.planRevision, 0);
    });
  });

  group('backfill (§7.3)', () {
    test('enqueues sessions chronologically + reviews; skips non-UUID '
        'card ids; re-run is a no-op', () async {
      final db = await dbService.database;
      await _insertProfile(db, 'p1');

      // Two sessions inserted OUT of chronological order.
      final later = IdGenerator.uuidV4();
      final earlier = IdGenerator.uuidV4();
      await db.insert('session_history', {
        'id': later,
        'profileId': 'p1',
        'date': DateTime.utc(2026, 6, 9, 18).toIso8601String(),
        'durationMinutes': 20,
        'sabaqCompleted': 1,
        'sabaqPage': 135,
      });
      await db.insert('session_history', {
        'id': earlier,
        'profileId': 'p1',
        'date': DateTime.utc(2026, 6, 8, 18).toIso8601String(),
        'durationMinutes': 25,
        'sabaqCompleted': 1,
        'sabaqPage': 134,
      });

      // A card with today's deterministic (non-UUID) id + a review of it.
      await db.insert('flashcards', {
        'id': 'p1_nv_3_21',
        'type': 0,
        'profile_id': 'p1',
        'verse_key': '3:21',
        'due_date': DateTime.utc(2026, 6, 9).toIso8601String(),
      });
      final reviewId = IdGenerator.uuidV4();
      await db.insert('flashcard_reviews', {
        'id': reviewId,
        'card_id': 'p1_nv_3_21',
        'rating': 1,
        'reviewed_at': DateTime.utc(2026, 6, 9, 19).toIso8601String(),
      });

      final enqueued = await outbox.enqueueBackfillForUid('u');
      // 2 sessions + 1 review; the non-UUID card id cannot travel as a
      // cardCreated fact under the frozen DTO (reported gap) — its REVIEW
      // still syncs and creates placeholder SRS state server-side.
      expect(enqueued, 3);

      final rows = await outbox.pendingForUid('u', limit: 100);
      expect(rows, hasLength(3));
      // Sessions first, in chronological order (streak fold requirement).
      expect(rows[0].kind, 'session');
      expect(rows[0].entityId, earlier);
      expect(rows[1].kind, 'session');
      expect(rows[1].entityId, later);
      expect(rows[2].kind, 'review');
      expect(rows[2].entityId, reviewId);

      // Every payload parses through the strict wire codec.
      for (final row in rows) {
        Fact.fromJson(jsonDecode(row.payload) as Map<String, dynamic>);
      }
      final review =
          Fact.fromJson(jsonDecode(rows[2].payload) as Map<String, dynamic>)
              as ReviewFact;
      expect(review.cardId, 'p1_nv_3_21');

      // Idempotent: a re-run enqueues nothing new.
      expect(await outbox.enqueueBackfillForUid('u'), 0);
      expect(await outbox.pendingForUid('u', limit: 100), hasLength(3));
    });

    test('backfill for a second uid re-enqueues the same fact ids under '
        'that uid (first-sign-in semantics)', () async {
      final db = await dbService.database;
      await _insertProfile(db, 'p1');
      final id = IdGenerator.uuidV4();
      await db.insert('session_history', {
        'id': id,
        'profileId': 'p1',
        'date': DateTime.utc(2026, 6, 8, 18).toIso8601String(),
        'durationMinutes': 25,
        'sabaqCompleted': 1,
        'sabaqPage': 134,
      });

      expect(await outbox.enqueueBackfillForUid('uid-A'), 1);
      expect(await outbox.enqueueBackfillForUid('uid-B'), 1);
      // SAME idempotency key both times — the server's (uid, fact.id)
      // upsert keeps replays free.
      expect((await outbox.pendingForUid('uid-A')).single.entityId, id);
      expect((await outbox.pendingForUid('uid-B')).single.entityId, id);
    });
  });
}
