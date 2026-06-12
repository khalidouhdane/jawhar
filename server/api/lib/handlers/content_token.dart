import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../content/content_token_service.dart';

/// `POST /v1/content/token` (authenticated) — roadmap §5 #12 / §8 Phase 7
/// task 1: returns a short-lived QF Content API token the client caches,
/// replacing the compiled-in `QURAN_API_CLIENT_SECRET` Basic-auth exchange
/// on every platform.
///
/// 200 body: `{"token": "...", "expiresAt": "ISO-8601 UTC",
/// "expiresIn": REMAINING-seconds, "clientId": "..."}` — `clientId`
/// rides along because the Content API requires it as the `x-client-id`
/// header next to the token (it is an identifier, not a secret).
/// `expiresIn` is the REMAINING lifetime of the server-cached QF token
/// (which can be as little as ~60s near the cache's refresh edge), NOT the
/// upstream-issued 3600 — clients caching by `expires_in` convention stay
/// correct without parsing ISO instants.
///
/// Sits behind the standard `/v1` pipeline: Firebase ID token required
/// (401 otherwise), per-uid rate limit applies. The QF token itself is
/// cached server-side until expiry, so this endpoint costs QF one exchange
/// per hour per instance regardless of client traffic.
Handler contentTokenHandler(
  ContentTokenService service, {
  DateTime Function()? nowUtc,
}) {
  final now = nowUtc ?? (() => DateTime.now().toUtc());
  return (Request request) async {
    if (!service.isConfigured) {
      return _error(
        503,
        'unavailable',
        'Content token exchange is not configured on this deployment.',
      );
    }
    final ContentToken token;
    try {
      token = await service.getToken();
    } on ContentTokenException catch (e) {
      return _error(502, 'upstream-error', e.message, retryable: true);
    }
    final remaining = token.expiresAtUtc.difference(now()).inSeconds;
    return Response.ok(
      jsonEncode({
        'token': token.token,
        'expiresAt': token.expiresAtUtc.toIso8601String(),
        'expiresIn': remaining < 0 ? 0 : remaining,
        'clientId': service.clientId,
      }),
      headers: const {'content-type': 'application/json'},
    );
  };
}

Response _error(
  int status,
  String code,
  String message, {
  bool retryable = false,
}) {
  return Response(
    status,
    body: jsonEncode({
      'error': {'code': code, 'message': message, 'retryable': retryable},
    }),
    headers: const {'content-type': 'application/json'},
  );
}
