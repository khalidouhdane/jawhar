import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../gateway/firestore_gateway.dart';
import '../middleware/auth.dart';
import '../store/legacy_docs.dart';

/// Deletes the caller's Firebase Auth user. Implementations MUST treat a
/// missing user as success (idempotent — a retry after a half-completed
/// delete must not fail) and throw on any other failure.
typedef AuthUserDeleter = Future<void> Function(String uid);

/// `DELETE /v1/me` (authenticated) — roadmap §5 #11, §8 Phase 8 task 2.
///
/// Full account deletion, replacing the client-side cascade at
/// `cloud_sync_service.dart` (which dies with the Phase 8 rules flip):
/// 1. recursively deletes the caller's whole Firestore tree
///    (`users/{uid}` + every nested subcollection, [FirestoreGateway.deleteTree]);
/// 2. deletes the Firebase Auth user via [deleteAuthUser] (the R1 spike
///    verified Admin-SDK `auth.deleteUser` works server-side).
///
/// Semantics:
/// - The uid comes from the verified token only — a caller can delete
///   exactly themself, nothing else.
/// - **Idempotent**: deleting an already-empty tree / already-deleted auth
///   user is a success, so retries after partial failures converge.
/// - **Order**: Firestore first, then Auth. If the auth deletion fails the
///   data is already gone and the response is a retryable 502 — the client
///   falls back to its own `user.delete()` (requires-recent-login flow),
///   which is exactly the §5 #11 fallback split.
/// - With no [deleteAuthUser] wired (Firestore-data-only deployment) the
///   response reports `authUserDeleted: false` and the client's
///   `user.delete()` remains step two.
Handler accountDeleteHandler({
  required FirestoreGateway gateway,
  AuthUserDeleter? deleteAuthUser,
}) {
  return (Request request) async {
    final uid = request.uid;

    final int docsDeleted;
    try {
      docsDeleted = await gateway.deleteTree(UserPaths.userDoc(uid));
    } on DeleteTreeIncompleteException catch (e) {
      // The tree walk could not prove completion (pass cap). Whatever was
      // deleted stays deleted and a retry resumes idempotently — but the
      // auth user MUST survive: deleting it now would orphan the remainder
      // forever (no client could ever authenticate as this uid again).
      return Response(
        502,
        body: jsonEncode({
          'error': {
            'code': 'delete-incomplete',
            'message':
                'Account data deletion did not complete: $e. Retry — the '
                'deletion resumes where it stopped.',
            'retryable': true,
          },
        }),
        headers: const {'content-type': 'application/json'},
      );
    }

    var authUserDeleted = false;
    if (deleteAuthUser != null) {
      try {
        await deleteAuthUser(uid);
        authUserDeleted = true;
      } on Object catch (e) {
        // Firestore tree is already gone; only the auth half failed.
        return Response(
          502,
          body: jsonEncode({
            'error': {
              'code': 'auth-delete-failed',
              'message':
                  'User data was deleted but the Firebase Auth user could '
                  'not be: $e. Retry, or delete the account from the device.',
              'retryable': true,
            },
            'docsDeleted': docsDeleted,
          }),
          headers: const {'content-type': 'application/json'},
        );
      }
    }

    return Response.ok(
      jsonEncode({
        'deleted': true,
        'uid': uid,
        'docsDeleted': docsDeleted,
        'authUserDeleted': authUserDeleted,
      }),
      headers: const {'content-type': 'application/json'},
    );
  };
}
