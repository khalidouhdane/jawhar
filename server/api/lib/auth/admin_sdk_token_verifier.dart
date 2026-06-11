import 'dart:io';

import 'package:firebase_admin_sdk/auth.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';

import '../middleware/auth.dart';

/// Production [TokenVerifier]: verifies Firebase ID tokens through the
/// official Firebase Admin SDK for Dart (`firebase_admin_sdk`, R1 subject).
///
/// The SDK verifies the RS256 signature against Google's published public
/// certs (securetoken@system.gserviceaccount.com), and checks
/// `aud == <projectId>`, `iss == https://securetoken.google.com/<projectId>`,
/// `exp`/`iat`. This class additionally re-pins the audience as defense in
/// depth and refuses to construct when the Auth-emulator env var is set
/// (in emulator mode the SDK skips signature verification — that path must be
/// impossible to reach in a production image; tests inject their own
/// [TokenVerifier] instead, so production never needs `allowEmulator`).
class AdminSdkTokenVerifier implements TokenVerifier {
  AdminSdkTokenVerifier(
    FirebaseApp app, {
    required this.expectedProjectId,
    bool allowEmulator = false,
  }) : _auth = app.auth() {
    if (!allowEmulator &&
        Platform.environment.containsKey('FIREBASE_AUTH_EMULATOR_HOST')) {
      throw StateError(
        'FIREBASE_AUTH_EMULATOR_HOST is set but AdminSdkTokenVerifier was '
        'constructed for production. Refusing to start: emulator mode skips '
        'ID-token signature verification.',
      );
    }
    final appProjectId = app.projectId;
    if (appProjectId != expectedProjectId) {
      throw StateError(
        'FirebaseApp projectId "$appProjectId" does not match the expected '
        'token audience "$expectedProjectId".',
      );
    }
  }

  /// The only accepted token audience (Firebase project id).
  final String expectedProjectId;

  final Auth _auth;

  @override
  Future<VerifiedToken> verify(String idToken) async {
    final DecodedIdToken decoded;
    try {
      decoded = await _auth.verifyIdToken(idToken);
    } on FirebaseAuthAdminException catch (e) {
      throw TokenVerificationException(
        'ID token rejected: ${e.errorCode.code}',
        e,
      );
    } catch (e) {
      throw TokenVerificationException('ID token rejected.', e);
    }

    // Defense in depth — the SDK has already enforced these.
    if (decoded.aud != expectedProjectId) {
      throw TokenVerificationException(
        'ID token audience "${decoded.aud}" != "$expectedProjectId".',
      );
    }
    if (decoded.uid.isEmpty) {
      throw TokenVerificationException('ID token has an empty subject.');
    }
    return VerifiedToken(uid: decoded.uid, claims: decoded.claims);
  }
}
