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
  /// underlying SDK.
  Future<T> runTransaction<T>(
    Future<T> Function(GatewayTransaction tx) updateFunction,
  ) {
    return _db.runTransaction<T>(
      (transaction) => updateFunction(GatewayTransaction._(_db, transaction)),
    );
  }
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
