import 'dart:async';

import 'package:shelf/shelf.dart';

/// Header App Check tokens travel in (set by the client next to the
/// Authorization header; same name the Firebase SDKs use).
const String appCheckHeader = 'x-firebase-appcheck';

/// Request/response-context key carrying the App Check verdict for the
/// request logger (`middleware/request_logging.dart`).
const String appCheckContextKey = 'jawhar.appCheck';

/// App Check verdicts attached to the request log (roadmap §8 Phase 8
/// task 3 — log-only soak; §9 platform matrix).
abstract final class AppCheckVerdict {
  /// No `X-Firebase-AppCheck` header on the request: every pre-App-Check
  /// client build, all of iOS/web (activation deferred per §8), and the
  /// permanent Windows exemption (no attestation provider exists, §9).
  static const String absent = 'absent';

  /// Header present and the token verified (signature against the App Check
  /// JWKS, `aud` contains this project, issuer, expiry).
  static const String verified = 'verified';

  /// Header present but the token failed verification.
  static const String invalid = 'invalid';

  /// Header present but no verdict could be produced: no verifier is wired
  /// (composition without an initialized Admin app — should not happen in
  /// production), or verification timed out (cold-start / 6-hourly JWKS
  /// refetch hanging — see [appCheckLogOnly]'s timeout).
  static const String unverifiable = 'unverifiable';
}

/// Verifies a Firebase App Check token; returns the verified Firebase app id
/// or throws. Injectable so middleware tests run without Google JWKS
/// (production pins [AdminSdkAppCheckVerifier] in `bin/server.dart`).
abstract interface class AppCheckVerifier {
  Future<String> verifyToken(String token);
}

/// LOG-ONLY App Check middleware (roadmap §8 Phase 8 task 3 ceiling for this
/// wave): reads `X-Firebase-AppCheck` when present, verifies it via the
/// Admin SDK, and attaches the verdict (verified / invalid / absent) to the
/// request log — and **NEVER rejects**. Enforcement is a post-soak runbook
/// step, deliberately not expressible through this middleware.
///
/// The verdict is attached to the forwarded request context AND to the
/// response context: shelf middleware sees the ORIGINAL request object, so
/// the outermost JSON request logger can only observe inner-middleware
/// findings through the response as it propagates back out.
///
/// [verifyTimeout]: verification is normally local crypto (the SDK caches
/// the App Check JWKS ~6h), but on cold start or key expiry it performs an
/// un-timeouted HTTP fetch of the JWKS — without a bound here, a hanging
/// googleapis endpoint would stall EVERY header-carrying request on the hot
/// path of a middleware whose whole contract is "observability only". A
/// timeout is mapped to the `unverifiable` verdict (we could not produce a
/// verdict; the token was not proven invalid).
Middleware appCheckLogOnly(
  AppCheckVerifier? verifier, {
  Duration verifyTimeout = const Duration(seconds: 2),
}) {
  return (Handler inner) {
    return (Request request) async {
      final token = request.headers[appCheckHeader];

      String verdict;
      if (token == null || token.isEmpty) {
        verdict = AppCheckVerdict.absent;
      } else if (verifier == null) {
        verdict = AppCheckVerdict.unverifiable;
      } else {
        try {
          await verifier.verifyToken(token).timeout(verifyTimeout);
          verdict = AppCheckVerdict.verified;
        } on TimeoutException {
          // No verdict could be produced in time — a log-only middleware
          // must never become an availability dependency.
          verdict = AppCheckVerdict.unverifiable;
        } on Object {
          // Log-only: ANY verification failure is a verdict, never a 4xx.
          verdict = AppCheckVerdict.invalid;
        }
      }

      final response = await inner(
        request.change(
          context: {...request.context, appCheckContextKey: verdict},
        ),
      );
      return response.change(
        context: {...response.context, appCheckContextKey: verdict},
      );
    };
  };
}
