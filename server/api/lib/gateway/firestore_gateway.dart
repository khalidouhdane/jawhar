import 'dart:io';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart' as fs;

/// The single class through which ALL Firestore access flows (roadmap §4.2).
///
/// Wraps the official Firebase Admin SDK for Dart (`firebase_admin_sdk`,
/// which delegates to `google_cloud_firestore`) and exposes only what
/// handlers need: document get/set and transactions. If the experimental SDK
/// has to be swapped for Firestore v1 REST via `googleapis` (R1 fallback),
/// this file is the only one that changes.
///
/// Emulator support: `google_cloud_firestore` reads FIRESTORE_EMULATOR_HOST
/// from the process environment itself and switches to an unauthenticated
/// `Bearer owner` client — no credentials required (verified in the Phase 2
/// spike, see tool/spike/).
class FirestoreGateway {
  /// Wraps an already-constructed Firestore instance (tests/spikes).
  FirestoreGateway(this._db);

  /// Obtains Firestore from an initialized [FirebaseApp].
  FirestoreGateway.forApp(FirebaseApp app) : _db = app.firestore();

  final fs.Firestore _db;

  /// Whether FIRESTORE_EMULATOR_HOST is in effect for this process —
  /// the same env var `google_cloud_firestore` switches on internally.
  static bool get isUsingEmulator =>
      (Platform.environment['FIRESTORE_EMULATOR_HOST'] ?? '').isNotEmpty;

  /// Reads the document at [path] (e.g. `users/{uid}`).
  /// Returns null when it does not exist.
  Future<Map<String, dynamic>?> getDoc(String path) async {
    final snapshot = await _db.doc(path).get();
    return snapshot.data();
  }

  /// Writes [data] to the document at [path]; with [merge] true performs a
  /// merge-set instead of a full overwrite.
  Future<void> setDoc(
    String path,
    Map<String, dynamic> data, {
    bool merge = false,
  }) async {
    await _db
        .doc(path)
        .set(data, options: merge ? const fs.SetOptions.merge() : null);
  }

  /// Runs a query against the collection at [collectionPath]: equality
  /// filters from [whereEquals] (ANDed), optional [orderBy]/[descending],
  /// optional [limit]. Returns `(id, data)` per matching document.
  ///
  /// Index reality check (roadmap §8 Phase 2 task 7): combining equality
  /// filters with an orderBy needs a COMPOSITE index in production
  /// (firestore.indexes.json — e.g. plans `(profileId, date, revision DESC)`)
  /// while the emulator executes the same query without one, so a green
  /// emulator suite proves nothing about indexes. Keep every such query shape
  /// mirrored in firestore.indexes.json.
  ///
  /// Note Firestore orderBy semantics: documents MISSING the orderBy field
  /// are excluded from results entirely (relevant for legacy revision-less
  /// plan docs — handlers that care must fall back to a direct [getDoc]).
  Future<List<({String id, Map<String, dynamic> data})>> query(
    String collectionPath, {
    Map<String, Object?> whereEquals = const {},
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    fs.Query<fs.DocumentData> q = _db.collection(collectionPath);
    for (final entry in whereEquals.entries) {
      q = q.where(entry.key, fs.WhereFilter.equal, entry.value);
    }
    if (orderBy != null) q = q.orderBy(orderBy, descending: descending);
    if (limit != null) q = q.limit(limit);
    final snapshot = await q.get();
    return [
      for (final doc in snapshot.docs) (id: doc.id, data: doc.data()),
    ];
  }

  /// Runs [updateFunction] inside a Firestore transaction. All reads must
  /// happen before writes (Firestore semantics). Retries are handled by the
  /// underlying SDK, EXCEPT for one verified 0.5.x defect we patch here:
  ///
  /// When a transaction's COMMIT fails (observed deterministically on the
  /// first-ever RPC of a process against the emulator), the SDK's
  /// `_runTransactionOnce` rollback also throws — and that rollback error
  /// ("Transaction is invalid or expired", invalid_argument) REPLACES the
  /// original retryable error, defeating the SDK's own retry loop (its
  /// retryable check looks for the production phrasing "transaction has
  /// expired", which this is not). Probed evidence (tool/probe_tx_first.dart,
  /// 2026-06-11): callback and reads complete, commit fails, NO writes are
  /// applied — so retrying the whole transaction is safe and is exactly what
  /// the SDK would do if the rollback didn't mask the error. The residual
  /// commit-response-lost double-apply risk is the same one the SDK's own
  /// retry accepts.
  Future<T> runTransaction<T>(
    Future<T> Function(GatewayTransaction tx) updateFunction,
  ) async {
    const maxAttempts = 3;
    Object? lastError;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await _db.runTransaction<T>(
          (transaction) =>
              updateFunction(GatewayTransaction._(_db, transaction)),
        );
      } catch (e) {
        lastError = e;
        if (!_isMaskedRetryableTransactionError(e)) rethrow;
      }
    }
    throw lastError!;
  }

  /// Matches both observed variants of the same defect: "Transaction is
  /// invalid or expired" (when the failed rollback masks the commit error)
  /// and "Transaction is invalid or closed" (when the commit error surfaces
  /// directly).
  static bool _isMaskedRetryableTransactionError(Object e) =>
      e.toString().toLowerCase().contains('transaction is invalid');

  /// Recursively deletes the document at [docPath] and every document in
  /// every (transitively) nested subcollection — `DELETE /v1/me` (§5 #11).
  /// Returns the number of document locations deleted.
  ///
  /// Implementation note: deliberately NOT the library's
  /// `Firestore.recursiveDelete` — that builds a kindless all-descendants
  /// query, an API surface the Firestore EMULATOR does not reliably support,
  /// and our contract tests live on the emulator. Manual recursion via
  /// `listCollections()` + `listDocuments()` (`showMissing: true` is
  /// hardcoded inside the package, so "missing" parents whose only existence
  /// is a nested subcollection are still traversed) is emulator-safe.
  /// Deletes are committed in [_deleteBatchSize]-document `WriteBatch`es,
  /// children before parents, so an interrupted run never strands an
  /// orphaned subcollection under an already-deleted parent: re-running
  /// resumes idempotently (deleting a missing doc is a success).
  ///
  /// ⚠ Pagination: `google_cloud_firestore` 0.5.2's
  /// `CollectionReference.listDocuments()` issues a SINGLE
  /// `ListDocumentsRequest` and never follows `nextPageToken` — the
  /// production backend caps one page at ~300 documents (the package's own
  /// comment). Each collection is therefore looped DELETE-THEN-RELIST to
  /// exhaustion: the flush before every relist makes the listing shrink
  /// monotonically (deleted docs and emptied "missing" parents drop out of
  /// the next page), so the loop converges on every tree size. A paranoid
  /// pass cap turns a non-converging walk into a thrown
  /// [DeleteTreeIncompleteException] (handler maps it to a retryable 502)
  /// instead of a silent partial delete behind a 200.
  Future<int> deleteTree(String docPath) async {
    final pending = <fs.DocumentReference<fs.DocumentData>>[];
    var deleted = 0;

    Future<void> flush() async {
      if (pending.isEmpty) return;
      final batch = _db.batch();
      for (final ref in pending) {
        batch.delete(ref);
      }
      await batch.commit();
      deleted += pending.length;
      pending.clear();
    }

    Future<void> visit(fs.DocumentReference<fs.DocumentData> ref) async {
      for (final collection in await ref.listCollections()) {
        var passes = 0;
        while (true) {
          final children = await collection.listDocuments();
          if (children.isEmpty) break;
          if (++passes > _maxDeletePassesPerCollection) {
            throw DeleteTreeIncompleteException(
              'deleteTree did not converge for "${collection.path}" after '
              '$_maxDeletePassesPerCollection delete-and-relist passes '
              '($deleted docs deleted so far) — aborting instead of '
              'reporting a partial delete as success.',
            );
          }
          for (final child in children) {
            await visit(child);
          }
          // Commit before relisting so the next page excludes what this
          // pass already deleted (this is what makes the loop converge).
          await flush();
        }
      }
      pending.add(ref);
      if (pending.length >= _deleteBatchSize) await flush();
    }

    await visit(_db.doc(docPath));
    await flush();
    return deleted;
  }

  /// Documents per delete batch (Firestore caps a commit at 500 writes).
  static const int _deleteBatchSize = 400;

  /// Delete-and-relist passes allowed per collection before [deleteTree]
  /// gives up. Each pass clears one backend page (~300 docs), so this caps
  /// a single collection at ~60k documents — orders of magnitude above
  /// tester scale, while still bounding a pathological non-converging loop.
  static const int _maxDeletePassesPerCollection = 200;
}

/// [FirestoreGateway.deleteTree] could not prove the tree is fully gone
/// (pass cap hit). The data already deleted STAYS deleted; retrying the
/// operation resumes idempotently — so callers must surface this as a
/// retryable failure, never as success.
class DeleteTreeIncompleteException implements Exception {
  DeleteTreeIncompleteException(this.message);

  final String message;

  @override
  String toString() => 'DeleteTreeIncompleteException: $message';
}

/// Narrow transactional surface handed to [FirestoreGateway.runTransaction]
/// callbacks — same get/set vocabulary as the gateway itself.
class GatewayTransaction {
  GatewayTransaction._(this._db, this._transaction);

  final fs.Firestore _db;
  final fs.Transaction _transaction;

  /// Transactional read of the document at [path]; null when missing.
  Future<Map<String, dynamic>?> get(String path) async {
    final snapshot = await _transaction.get(_db.doc(path));
    return snapshot.data();
  }

  /// Transactional equality-filtered read of a whole collection — same
  /// semantics as [FirestoreGateway.query] minus orderBy/limit (the facts
  /// handler needs full progress maps, not ordered slices). Firestore
  /// transaction rules apply: ALL reads (including these) before any write.
  Future<List<({String id, Map<String, dynamic> data})>> query(
    String collectionPath, {
    Map<String, Object?> whereEquals = const {},
  }) async {
    fs.Query<fs.DocumentData> q = _db.collection(collectionPath);
    for (final entry in whereEquals.entries) {
      q = q.where(entry.key, fs.WhereFilter.equal, entry.value);
    }
    final snapshot = await _transaction.getQuery(q);
    return [
      for (final doc in snapshot.docs) (id: doc.id, data: doc.data()),
    ];
  }

  /// Transactional write of the document at [path].
  void set(String path, Map<String, dynamic> data, {bool merge = false}) {
    _transaction.set(
      _db.doc(path),
      data,
      options: merge ? const fs.SetOptions.merge() : null,
    );
  }

  /// Transactional delete of the document at [path] (used when a
  /// `cardCreated` fact attaches identity to an SRS placeholder and the
  /// placeholder doc moves into `flashcards/`).
  void delete(String path) {
    _transaction.delete(_db.doc(path));
  }
}
