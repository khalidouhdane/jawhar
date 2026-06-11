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

  /// Transactional write of the document at [path].
  void set(String path, Map<String, dynamic> data, {bool merge = false}) {
    _transaction.set(
      _db.doc(path),
      data,
      options: merge ? const fs.SetOptions.merge() : null,
    );
  }
}
