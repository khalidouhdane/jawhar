import 'package:firebase_admin_sdk/app_check.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';

import '../middleware/app_check.dart';

/// Production [AppCheckVerifier]: verifies App Check tokens through the
/// Firebase Admin SDK (`app.appCheck().verifyToken`) — RS256 signature
/// against the App Check JWKS (cached ~6h by the SDK), `aud` contains
/// `projects/<projectId>`, issuer, expiry. No replay-protection consume:
/// this wave is LOG-ONLY (§8 Phase 8 task 3), so tokens are observed, never
/// burned.
class AdminSdkAppCheckVerifier implements AppCheckVerifier {
  AdminSdkAppCheckVerifier(FirebaseApp app) : _appCheck = app.appCheck();

  final AppCheck _appCheck;

  @override
  Future<String> verifyToken(String token) async {
    final response = await _appCheck.verifyToken(token);
    return response.appId;
  }
}
