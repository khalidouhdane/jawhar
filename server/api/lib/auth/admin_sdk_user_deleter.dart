import 'package:firebase_admin_sdk/auth.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';

/// Production [`AuthUserDeleter`] (handlers/account.dart): deletes a Firebase
/// Auth user through the Admin SDK, treating "user not found" as success so
/// `DELETE /v1/me` stays idempotent (a retry after a half-completed delete —
/// Firestore gone, auth user gone, response lost — must converge, not 502).
class AdminSdkUserDeleter {
  AdminSdkUserDeleter(FirebaseApp app) : _auth = app.auth();

  final Auth _auth;

  Future<void> call(String uid) async {
    try {
      await _auth.deleteUser(uid);
    } on FirebaseAuthAdminException catch (e) {
      if (e.errorCode == AuthClientErrorCode.userNotFound) return;
      rethrow;
    }
  }
}
