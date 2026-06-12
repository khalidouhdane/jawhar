import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:hifz_core/hifz_core.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/utils/app_logger.dart';

/// One pending (or poisoned) row of the `sync_outbox` table.
class OutboxRow {
  final int seq;
  final String? uid;
  final String kind;
  final String entityId;
  final String payload;
  final DateTime createdAt;
  final int attempts;
  final String status;
  final String? lastError;

  const OutboxRow({
    required this.seq,
    required this.uid,
    required this.kind,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    required this.attempts,
    required this.status,
    this.lastError,
  });

  factory OutboxRow.fromMap(Map<String, dynamic> map) => OutboxRow(
    seq: map['seq'] as int,
    uid: map['uid'] as String?,
    kind: map['kind'] as String,
    entityId: map['entity_id'] as String,
    payload: map['payload'] as String,
    createdAt:
        DateTime.tryParse(map['created_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    attempts: map['attempts'] as int? ?? 0,
    status: map['status'] as String? ?? 'pending',
    lastError: map['last_error'] as String?,
  );
}

/// Aggregate outbox state for the debug screen.
class OutboxStats {
  final int pending;
  final int poisoned;
  final DateTime? oldestPendingCreatedAt;

  const OutboxStats({
    required this.pending,
    required this.poisoned,
    this.oldestPendingCreatedAt,
  });

  Duration? oldestAge(DateTime nowUtc) => oldestPendingCreatedAt == null
      ? null
      : nowUtc.difference(oldestPendingCreatedAt!);
}

/// The client half of the facts write path (roadmap §7.2): a durable,
/// uid-partitioned queue of `Fact`s in SQLite.
///
/// Rules implemented here:
/// - **uid stamping**: rows carry the uid that was signed in at enqueue
///   time, or NULL when signed out. Rows are only ever drained under their
///   own uid (A→B switch isolation).
/// - **NULL-uid adoption**: [adoptOrphanRows] assigns all NULL rows to the
///   first uid that signs in afterwards — exactly once, because adopted
///   rows are no longer NULL.
/// - **Idempotency**: `entity_id` is the fact's UUID; a UNIQUE(uid,
///   entity_id) index + INSERT OR IGNORE make over-enqueueing (backfill
///   re-runs) free. SQLite UNIQUE indexes treat NULLs as distinct, so
///   duplicate (NULL, entity_id) rows can exist — [adoptOrphanRows] is
///   hardened against the resulting collisions (UPDATE OR IGNORE +
///   duplicate cleanup) so adoption can never stall the drain.
/// - **Transactional enqueue**: the session/review save paths write the
///   domain row and the outbox row in ONE SQLite transaction, so a crash
///   can never separate "user saw it saved" from "it will sync".
///
/// Notifies listeners on every enqueue so the [SyncWorker] can schedule a
/// drain without the providers knowing about the worker.
class OutboxService extends ChangeNotifier {
  static const String statusPending = 'pending';
  static const String statusPoisoned = 'poisoned';

  final HifzDatabaseService _db;

  OutboxService(this._db);

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Map<String, dynamic> _rowFor(Fact fact, String? uid) => {
    'uid': uid,
    'kind': fact.kind,
    'entity_id': fact.id,
    'payload': jsonEncode(fact.toJson()),
    'created_at': DateTime.now().toUtc().toIso8601String(),
    'attempts': 0,
    'status': statusPending,
  };

  /// Enqueue a single fact (outside any other write).
  Future<void> enqueue(Fact fact, {String? uid}) async {
    final db = await _db.database;
    await db.insert(
      'sync_outbox',
      _rowFor(fact, uid),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    notifyListeners();
  }

  /// Save a completed session AND its fact in one transaction
  /// (roadmap §8 Phase 4a task 3).
  Future<void> saveSessionRecordAndEnqueue(
    SessionRecord record,
    SessionFact fact, {
    String? uid,
  }) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.insert('session_history', record.toMap());
      await txn.insert(
        'sync_outbox',
        _rowFor(fact, uid),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });
    notifyListeners();
  }

  /// Persist a flashcard review (updated SRS state + review event) AND its
  /// fact in one transaction.
  Future<void> saveReviewAndEnqueue(
    Flashcard updatedCard,
    FlashcardReview review,
    ReviewFact fact, {
    String? uid,
  }) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update(
        'flashcards',
        updatedCard.toMap(),
        where: 'id = ?',
        whereArgs: [updatedCard.id],
      );
      await txn.insert('flashcard_reviews', review.toMap());
      await txn.insert(
        'sync_outbox',
        _rowFor(fact, uid),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    });
    notifyListeners();
  }

  /// NULL-uid adoption rule (§7.2): the first uid that signs in adopts all
  /// rows enqueued while signed out — exactly once. Returns the number of
  /// adopted rows.
  ///
  /// Hardened against UNIQUE(uid, entity_id) collisions: SQLite UNIQUE
  /// indexes treat NULLs as distinct, so duplicate (NULL, X) rows can
  /// exist, and an orphan's entity_id may already exist under the adopting
  /// uid. A plain UPDATE would throw here — at the top of EVERY drain —
  /// permanently stalling sync for the device. `UPDATE OR IGNORE` skips
  /// the colliding rows; whatever stays NULL afterwards is an exact
  /// duplicate of a row the uid already owns and is dropped, all in one
  /// transaction.
  Future<int> adoptOrphanRows(String uid) async {
    final db = await _db.database;
    var adopted = 0;
    await db.transaction((txn) async {
      adopted = await txn.rawUpdate(
        'UPDATE OR IGNORE sync_outbox SET uid = ? WHERE uid IS NULL',
        [uid],
      );
      await txn.rawDelete(
        'DELETE FROM sync_outbox WHERE uid IS NULL AND entity_id IN '
        '(SELECT entity_id FROM sync_outbox WHERE uid = ?)',
        [uid],
      );
    });
    if (adopted > 0) {
      AppLogger.info('Outbox', 'Adopted $adopted signed-out rows for $uid');
    }
    return adopted;
  }

  /// Re-sequences ALL of [uid]'s pending rows into fact-chronological order
  /// in ONE transaction — run once per uid, right after the first-drain
  /// backfill enqueue (and after [adoptOrphanRows], which must go first to
  /// avoid UNIQUE collisions with backfill inserts).
  ///
  /// Why: adopted orphan rows and live facts enqueued before the first
  /// drain keep LOW seqs while the §7.3 backfill enqueues months of history
  /// at HIGHER seqs. The drain flushes in seq order, so TODAY's session
  /// would reach the server before the history — and the server streak fold
  /// counts only dates strictly after `lastActiveDate` (deliberately, for
  /// replay safety), so every historical day would be skipped forever.
  /// The SRS fold similarly only sorts WITHIN a batch. Fresh AUTOINCREMENT
  /// seqs assigned by the delete + re-insert encode chronology.
  ///
  /// Ordering key: the payload's own instant (`recordedAtUtc` /
  /// `reviewedAtUtc` / `createdAtUtc`), falling back to the row's
  /// `created_at` (planGenerated facts carry no instant), with the original
  /// seq as a stable tiebreak.
  Future<void> resequencePendingForUid(String uid) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'sync_outbox',
        where: 'uid = ? AND status = ?',
        whereArgs: [uid, statusPending],
        orderBy: 'seq ASC',
      );
      if (rows.length < 2) return;

      DateTime instantOf(Map<String, dynamic> row) {
        try {
          final decoded = jsonDecode(row['payload'] as String);
          if (decoded is Map<String, dynamic>) {
            final raw =
                decoded['recordedAtUtc'] ??
                decoded['reviewedAtUtc'] ??
                decoded['createdAtUtc'];
            if (raw is String) {
              final parsed = DateTime.tryParse(raw);
              if (parsed != null) return parsed.toUtc();
            }
          }
        } catch (_) {
          // Unparseable payloads keep their enqueue time below.
        }
        return DateTime.tryParse(row['created_at'] as String? ?? '')
                ?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      }

      final ordered = [...rows]
        ..sort((a, b) {
          final byInstant = instantOf(a).compareTo(instantOf(b));
          if (byInstant != 0) return byInstant;
          return (a['seq'] as int).compareTo(b['seq'] as int);
        });
      var alreadyOrdered = true;
      for (var i = 0; i < rows.length; i++) {
        if (ordered[i]['seq'] != rows[i]['seq']) {
          alreadyOrdered = false;
          break;
        }
      }
      if (alreadyOrdered) return;

      await txn.delete(
        'sync_outbox',
        where: 'uid = ? AND status = ?',
        whereArgs: [uid, statusPending],
      );
      for (final row in ordered) {
        await txn.insert('sync_outbox', {
          'uid': row['uid'],
          'kind': row['kind'],
          'entity_id': row['entity_id'],
          'payload': row['payload'],
          'created_at': row['created_at'],
          'attempts': row['attempts'],
          'status': row['status'],
          'last_error': row['last_error'],
        });
      }
      AppLogger.info(
        'Outbox',
        'Re-sequenced ${ordered.length} pending rows chronologically for $uid',
      );
    });
  }

  /// Pending rows for [uid] only, in seq (enqueue) order.
  Future<List<OutboxRow>> pendingForUid(String uid, {int limit = 50}) async {
    final db = await _db.database;
    final rows = await db.query(
      'sync_outbox',
      where: 'uid = ? AND status = ?',
      whereArgs: [uid, statusPending],
      orderBy: 'seq ASC',
      limit: limit,
    );
    return rows.map(OutboxRow.fromMap).toList();
  }

  /// Delete rows acknowledged by the server (applied OR idempotent-skip).
  Future<void> deleteRows(List<int> seqs) async {
    if (seqs.isEmpty) return;
    final db = await _db.database;
    final placeholders = List.filled(seqs.length, '?').join(',');
    await db.delete(
      'sync_outbox',
      where: 'seq IN ($placeholders)',
      whereArgs: seqs,
    );
  }

  /// Mark a row poisoned (non-retryable 422-class rejection). Kept for
  /// diagnostics, never retried — replaces today's silent drops (§5).
  Future<void> poisonRow(int seq, String error) async {
    final db = await _db.database;
    await db.update(
      'sync_outbox',
      {'status': statusPoisoned, 'last_error': _truncate(error), 'attempts': 0},
      where: 'seq = ?',
      whereArgs: [seq],
    );
    AppLogger.warn('Outbox', 'Poisoned outbox row $seq: $error');
  }

  /// Debug-screen recovery (§5 errors note): re-mark poisoned rows pending
  /// so the next drain retries them — e.g. after a transient server-side
  /// 403 condition (App Check rollout, middleware misconfig) has cleared.
  /// Returns the number of revived rows.
  Future<int> retryPoisonedRows({String? uid}) async {
    final db = await _db.database;
    final revived = await db.update(
      'sync_outbox',
      {'status': statusPending, 'attempts': 0, 'last_error': null},
      where: uid == null ? 'status = ?' : 'status = ? AND uid = ?',
      whereArgs: uid == null ? [statusPoisoned] : [statusPoisoned, uid],
    );
    if (revived > 0) {
      AppLogger.info('Outbox', 'Revived $revived poisoned rows');
      notifyListeners();
    }
    return revived;
  }

  /// Record a retryable failure on the given rows.
  Future<void> bumpAttempts(List<int> seqs, String error) async {
    if (seqs.isEmpty) return;
    final db = await _db.database;
    final placeholders = List.filled(seqs.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE sync_outbox SET attempts = attempts + 1, last_error = ? '
      'WHERE seq IN ($placeholders)',
      [_truncate(error), ...seqs],
    );
  }

  /// Wipe the whole outbox — datasetEpoch-mismatch policy (§5): the server
  /// announced a data-generation reset, so queued facts target a dead
  /// epoch; local history stays intact and is re-enqueued by the backfill.
  Future<void> clearAll() async {
    final db = await _db.database;
    final removed = await db.delete('sync_outbox');
    AppLogger.warn('Outbox', 'Cleared outbox ($removed rows) on epoch reset');
    notifyListeners();
  }

  /// Aggregate state for the debug screen. [uid] = null aggregates over
  /// every row (incl. NULL-uid rows).
  Future<OutboxStats> stats({String? uid}) async {
    final db = await _db.database;
    final where = uid == null ? '' : 'WHERE uid = ?';
    final args = uid == null ? <Object>[] : <Object>[uid];
    final rows = await db.rawQuery('''
      SELECT status, COUNT(*) AS n, MIN(created_at) AS oldest
      FROM sync_outbox $where GROUP BY status
    ''', args);
    var pending = 0;
    var poisoned = 0;
    DateTime? oldest;
    for (final row in rows) {
      final n = row['n'] as int? ?? 0;
      if (row['status'] == statusPending) {
        pending = n;
        oldest = DateTime.tryParse(row['oldest'] as String? ?? '');
      } else if (row['status'] == statusPoisoned) {
        poisoned = n;
      }
    }
    return OutboxStats(
      pending: pending,
      poisoned: poisoned,
      oldestPendingCreatedAt: oldest,
    );
  }

  // ════════════════════════════════════════════
  // BACKFILL (§7.3)
  // ════════════════════════════════════════════

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}'
    r'-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static String _ymd(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';

  /// Enqueue ALL local history as facts for [uid] (roadmap §7.3).
  ///
  /// Idempotent at two levels: re-running it re-derives the SAME fact ids
  /// (the local row ids, which are RFC-4122 UUIDs for sessions/reviews), so
  /// the UNIQUE(uid, entity_id) INSERT OR IGNORE skips rows already queued
  /// and the server's (uid, fact.id) upsert skips rows already applied.
  ///
  /// Sessions are enqueued in chronological order — the server's streak
  /// fold skips dates <= lastActiveDate, so out-of-order backfill would
  /// undercount historical days (Stream A contract note).
  ///
  /// Known gaps (deliberate, reported):
  /// - cardCreated facts are only emitted for UUID-shaped card ids; today's
  ///   generator uses deterministic ids (`p1_nv_3_21`) which the frozen
  ///   CardCreatedFact DTO rejects (fact id must be the card id AND a
  ///   UUID). Reviews of those cards still sync — the server creates
  ///   placeholder SRS state keyed by cardId (§5 unknown-card tolerance).
  /// - Historical sessions carry no actualPagesCovered / verse fields
  ///   (never persisted locally pre-v8); the server falls back to
  ///   [sabaq.page], exactly like the client's own fallback.
  ///
  /// Returns the number of rows actually enqueued (ignored duplicates not
  /// counted).
  Future<int> enqueueBackfillForUid(String uid) async {
    final db = await _db.database;
    final tzOffsetMinutes = DateTime.now().timeZoneOffset.inMinutes.clamp(
      FactBounds.minTzOffsetMinutes,
      FactBounds.maxTzOffsetMinutes,
    );

    var enqueued = 0;

    // 1. Sessions — chronological for the streak fold.
    final sessionRows = await db.query('session_history', orderBy: 'date ASC');
    for (final row in sessionRows) {
      SessionRecord record;
      try {
        record = SessionRecord.fromMap(row);
      } catch (e) {
        AppLogger.warn('Outbox', 'Backfill skipping bad session row: $e');
        continue;
      }
      if (!_uuidPattern.hasMatch(record.id) || record.profileId.isEmpty) {
        continue;
      }
      final recordedAtUtc = record.date.toUtc();
      final local = record.date.toLocal();
      final dateStr = _ymd(local);
      final fact = SessionFact(
        id: record.id,
        coreVersion: hifzCoreVersion,
        profileId: record.profileId,
        date: dateStr,
        tzOffsetMinutes: tzOffsetMinutes,
        durationMinutes: record.durationMinutes.clamp(
          0,
          FactBounds.maxDurationMinutes,
        ),
        repCount: record.repCount.clamp(0, FactBounds.maxRepCount),
        sabaq: SabaqOutcome(
          completed: record.sabaqCompleted,
          assessment: record.sabaqAssessment,
          page: record.sabaqPage,
        ),
        sabqi: PhaseOutcome(
          completed: record.sabqiCompleted,
          assessment: record.sabqiAssessment,
          pages: record.sabqiPages,
        ),
        manzil: PhaseOutcome(
          completed: record.manzilCompleted,
          assessment: record.manzilAssessment,
          pages: record.manzilPages,
        ),
        // Pre-v8 history never stored coverage; server falls back to
        // [sabaq.page] exactly like completeSession does.
        actualPagesCovered: const [],
        planId: PlanIdentity.idFor(record.profileId, dateStr),
        planRevision: 0,
        planOrigin: PlanOrigin.client,
        recordedAtUtc: recordedAtUtc,
      );
      final inserted = await db.insert(
        'sync_outbox',
        _rowFor(fact, uid),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      if (inserted != 0) enqueued++;
    }

    // 2. Flashcard reviews — chronological.
    final reviewRows = await db.query(
      'flashcard_reviews',
      orderBy: 'reviewed_at ASC',
    );
    for (final row in reviewRows) {
      FlashcardReview review;
      try {
        review = FlashcardReview.fromMap(row);
      } catch (e) {
        AppLogger.warn('Outbox', 'Backfill skipping bad review row: $e');
        continue;
      }
      if (!_uuidPattern.hasMatch(review.id) || review.cardId.isEmpty) {
        continue;
      }
      final fact = ReviewFact(
        id: review.id,
        coreVersion: hifzCoreVersion,
        cardId: review.cardId,
        rating: review.rating,
        reviewedAtUtc: review.reviewedAt.toUtc(),
        tzOffsetMinutes: tzOffsetMinutes,
      );
      final inserted = await db.insert(
        'sync_outbox',
        _rowFor(fact, uid),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      if (inserted != 0) enqueued++;
    }

    // 3. Cards — only UUID-shaped ids can travel as cardCreated facts
    //    under the frozen DTO (fact id IS the card id and must be a UUID).
    final cardRows = await db.query('flashcards');
    for (final row in cardRows) {
      Flashcard card;
      try {
        card = Flashcard.fromMap(row);
      } catch (e) {
        AppLogger.warn('Outbox', 'Backfill skipping bad card row: $e');
        continue;
      }
      if (!_uuidPattern.hasMatch(card.id)) continue;
      final fact = CardCreatedFact(
        id: card.id,
        coreVersion: hifzCoreVersion,
        profileId: card.profileId,
        type: card.type,
        verseKey: card.verseKey,
        questionData: jsonEncode(card.questionData),
        answerData: jsonEncode(card.answerData),
        createdAtUtc: (card.lastReviewedAt ?? card.dueDate).toUtc(),
      );
      final inserted = await db.insert(
        'sync_outbox',
        _rowFor(fact, uid),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      if (inserted != 0) enqueued++;
    }

    if (enqueued > 0) {
      AppLogger.info('Outbox', 'Backfill enqueued $enqueued facts for $uid');
      notifyListeners();
    }
    return enqueued;
  }

  static String _truncate(String s, [int max = 500]) =>
      s.length <= max ? s : s.substring(0, max);
}
