// R1 spike, items (a) and (d) — run manually, not part of `dart test`.
//
// (a) ID-token verification through firebase_admin_sdk (the production
//     AdminSdkTokenVerifier): positive path with a real token minted via
//     identitytoolkit signUp, plus tampered-token negative paths, plus a
//     Google public-cert (JWKS-equivalent) fetch proof.
// (d) auth.deleteUser called for real against the user created in (a),
//     authenticated by a gcloud access token injected via AppOptions.httpClient.
//
// Inputs (env vars; values are never printed):
//   JAWHAR_WEB_API_KEY   - Firebase web API key (lib/firebase_options.dart)
//   GCLOUD_ACCESS_TOKEN  - optional; enables the real deleteUser call
//
// The created throwaway user is always cleaned up: deleteUser when possible,
// else self-delete via accounts:delete with its own idToken.

import 'dart:convert';
import 'dart:io';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gauth;
import 'package:http/http.dart' as http;
import 'package:jawhar_api/auth/admin_sdk_token_verifier.dart';
import 'package:jawhar_api/middleware/auth.dart';

const projectId = 'quran-app-e5e86';
const certUrl =
    'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';

final results = <String, String>{};

void record(String item, bool pass, String evidence) {
  results[item] = pass ? 'PASS' : 'FAIL';
  stdout.writeln('[${pass ? 'PASS' : 'FAIL'}] $item — $evidence');
}

Future<void> main() async {
  final apiKey = Platform.environment['JAWHAR_WEB_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('JAWHAR_WEB_API_KEY is required.');
    exitCode = 2;
    return;
  }
  final accessToken = Platform.environment['GCLOUD_ACCESS_TOKEN'];

  // --- Cert/JWKS fetch proof (part of item a) -----------------------------
  final certResponse = await http.get(Uri.parse(certUrl));
  final kids = certResponse.statusCode == 200
      ? (jsonDecode(certResponse.body) as Map<String, dynamic>).keys.toList()
      : const <String>[];
  record(
    'a0-cert-fetch',
    certResponse.statusCode == 200 && kids.isNotEmpty,
    'GET securetoken certs -> HTTP ${certResponse.statusCode}, '
    '${kids.length} key id(s)',
  );

  // --- Mint a real ID token via identitytoolkit signUp --------------------
  String? idToken;
  String? localId;
  var signUpMode = 'anonymous';
  var signUp = await http.post(
    Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
    ),
    headers: {'content-type': 'application/json'},
    body: jsonEncode({'returnSecureToken': true}),
  );
  if (signUp.statusCode != 200) {
    // Anonymous provider may be disabled; try a throwaway email/password.
    signUpMode = 'email-password';
    final nonce = DateTime.now().millisecondsSinceEpoch;
    signUp = await http.post(
      Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey',
      ),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'email': 'jawhar.spike.$nonce@example.com',
        'password': 'Spike-$nonce-pw',
        'returnSecureToken': true,
      }),
    );
  }
  if (signUp.statusCode == 200) {
    final body = jsonDecode(signUp.body) as Map<String, dynamic>;
    idToken = body['idToken'] as String?;
    localId = body['localId'] as String?;
    stdout.writeln(
      '[info] minted ID token ($signUpMode) for throwaway uid=$localId',
    );
  } else {
    stdout.writeln(
      '[info] signUp failed (HTTP ${signUp.statusCode}): ${signUp.body}',
    );
  }

  // --- Initialize the Admin SDK app ---------------------------------------
  gauth.AuthClient? adminClient;
  if (accessToken != null && accessToken.isNotEmpty) {
    adminClient = gauth.authenticatedClient(
      http.Client(),
      gauth.AccessCredentials(
        gauth.AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(const Duration(minutes: 50)),
        ),
        null,
        const ['https://www.googleapis.com/auth/cloud-platform'],
      ),
    );
  }
  final app = FirebaseApp.initializeApp(
    options: AppOptions(projectId: projectId, httpClient: adminClient),
  );
  final verifier = AdminSdkTokenVerifier(app, expectedProjectId: projectId);

  // --- (a) positive + negative verification -------------------------------
  if (idToken != null && localId != null) {
    try {
      final verified = await verifier.verify(idToken);
      record(
        'a1-verify-positive',
        verified.uid == localId,
        'verifyIdToken returned uid=${verified.uid}, '
        'signUp localId=$localId (must match)',
      );
    } catch (e) {
      record('a1-verify-positive', false, 'threw: $e');
    }

    // Tampered payload (claims edited, signature now stale).
    final parts = idToken.split('.');
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    ) as Map<String, dynamic>;
    payload['sub'] = 'attacker-uid';
    final tamperedPayload =
        base64Url.encode(utf8.encode(jsonEncode(payload))).replaceAll('=', '');
    await _expectRejected(
      'a2-verify-tampered-payload',
      verifier,
      '${parts[0]}.$tamperedPayload.${parts[2]}',
    );

    // Tampered signature.
    final sig = parts[2];
    final flipped = sig.endsWith('A') ? '${sig.substring(0, sig.length - 1)}B'
        : '${sig.substring(0, sig.length - 1)}A';
    await _expectRejected(
      'a3-verify-tampered-signature',
      verifier,
      '${parts[0]}.${parts[1]}.$flipped',
    );

    // Garbage token.
    await _expectRejected('a4-verify-garbage', verifier, 'not-a-jwt');
  } else {
    stdout.writeln(
      '[info] positive path unavailable (no mintable token) — running the '
      'sanctioned negative-path fallback instead',
    );

    // Forged-but-well-formed RS256 JWT: correct iss/aud/exp/iat/sub claim
    // shape for this project, but a kid Google never published and a bogus
    // signature. Rejection proves the verifier resolves the kid against the
    // fetched Google certs and checks the signature — it does not merely
    // decode the payload.
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    String b64(Map<String, Object?> m) =>
        base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
    final forged = [
      b64({'alg': 'RS256', 'kid': 'deadbeef-no-such-kid', 'typ': 'JWT'}),
      b64({
        'iss': 'https://securetoken.google.com/$projectId',
        'aud': projectId,
        'sub': 'forged-uid',
        'user_id': 'forged-uid',
        'auth_time': nowSec - 60,
        'iat': nowSec - 60,
        'exp': nowSec + 3600,
      }),
      base64Url.encode(List<int>.generate(256, (i) => (i * 37) % 256))
          .replaceAll('=', ''),
    ].join('.');
    await _expectRejected('a2-verify-forged-wellformed-jwt', verifier, forged);

    // Garbage token.
    await _expectRejected('a4-verify-garbage', verifier, 'not-a-jwt');
  }

  // --- (d) auth.deleteUser -------------------------------------------------
  var deletedViaAdmin = false;
  if (localId == null || adminClient == null) {
    // No throwaway user and/or no admin credential: the task accepts an
    // API-surface check for item (d).
    _recordDeleteUserSurfaceCheck(app);
  }
  if (localId != null) {
    if (adminClient != null) {
      try {
        await app.auth().deleteUser(localId);
        deletedViaAdmin = true;
        // Prove deletion: the old idToken must no longer resolve.
        final lookup = await http.post(
          Uri.parse(
            'https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=$apiKey',
          ),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({'idToken': idToken}),
        );
        record(
          'd1-deleteUser',
          lookup.statusCode != 200,
          'auth.deleteUser($localId) succeeded; accounts:lookup with the old '
          'token -> HTTP ${lookup.statusCode} (non-200 proves the user is gone)',
        );
      } catch (e) {
        record('d1-deleteUser', false, 'auth.deleteUser threw: $e');
      }
    }

    // Cleanup fallback: self-delete with the user's own idToken.
    if (!deletedViaAdmin && idToken != null) {
      final del = await http.post(
        Uri.parse(
          'https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$apiKey',
        ),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );
      stdout.writeln(
        '[info] cleanup self-delete of throwaway user -> HTTP ${del.statusCode}',
      );
    }
  }

  await app.close();
  adminClient?.close();

  final failed = results.values.where((v) => v == 'FAIL').length;
  stdout.writeln('---');
  stdout.writeln(
    'spike_token_verify: ${results.length} checks, $failed FAIL '
    '(${results.entries.map((e) => '${e.key}=${e.value}').join(', ')})',
  );
  exitCode = failed == 0 ? 0 : 1;
}

/// Item (d) fallback, sanctioned by the task: prove `auth.deleteUser` exists
/// with the expected signature via a compile-time typed tear-off (this file
/// does not compile if the API surface is absent or shaped differently).
void _recordDeleteUserSurfaceCheck(FirebaseApp app) {
  final Future<void> Function(String uid) deleteUser = app.auth().deleteUser;
  record(
    'd1-deleteUser-surface',
    true,
    'compile-time tear-off Auth.deleteUser: $deleteUser '
    '(Future<void> Function(String uid)) — REAL call not made: no usable '
    'admin credential on this machine (gcloud/firebase reauth required)',
  );
}

Future<void> _expectRejected(
  String item,
  TokenVerifier verifier,
  String token,
) async {
  try {
    final verified = await verifier.verify(token);
    record(item, false,
        'token was ACCEPTED (uid=${verified.uid}) but must be rejected');
  } on TokenVerificationException catch (e) {
    record(
      item,
      true,
      'rejected as expected: ${e.message}'
      '${e.cause != null ? ' | cause: ${e.cause}' : ''}',
    );
  } catch (e) {
    record(item, false, 'rejected with unexpected exception type: $e');
  }
}
