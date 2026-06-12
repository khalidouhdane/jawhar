import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Result of a successfully verified Firebase ID token.
class VerifiedToken {
  const VerifiedToken({required this.uid, this.claims = const {}});

  /// The Firebase Auth uid (the token's `sub`). This — and only this — is the
  /// caller identity. The uid is NEVER taken from a request body (roadmap §4.3).
  final String uid;

  /// Custom claims carried by the token (informational).
  final Map<String, Object?> claims;
}

/// Thrown by a [TokenVerifier] when a token is invalid for any reason
/// (bad signature, wrong audience/issuer, expired, malformed, ...).
class TokenVerificationException implements Exception {
  TokenVerificationException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'TokenVerificationException: $message';
}

/// Injectable verifier interface (roadmap §4.3 / §8 Phase 2 task 2).
///
/// Production pins [AdminSdkTokenVerifier] (Google JWKS/X.509 certs,
/// aud == quran-app-e5e86, exp). Tests inject a deterministic implementation
/// so contract tests never need Google JWKS. The production entrypoint
/// (`bin/server.dart`) constructs the production verifier unconditionally —
/// there is no env flag that swaps in a test verifier in the shipped image.
abstract interface class TokenVerifier {
  /// Returns the verified identity, or throws [TokenVerificationException].
  Future<VerifiedToken> verify(String idToken);
}

/// Request-context key under which the verified uid is stored.
const String uidContextKey = 'jawhar.uid';

/// Typed accessor for the uid placed in the request context by
/// [firebaseAuthMiddleware]. Throws if the middleware did not run.
extension AuthenticatedRequest on Request {
  String get uid =>
      context[uidContextKey] as String? ??
      (throw StateError(
        'Request has no verified uid — is firebaseAuthMiddleware installed?',
      ));
}

/// Shelf middleware enforcing `Authorization: Bearer <Firebase ID token>` on
/// every request it wraps. On success the verified uid is stored in the
/// request context under [uidContextKey]; on failure a 401 with the §5 error
/// envelope is returned and the inner handler never runs.
Middleware firebaseAuthMiddleware(TokenVerifier verifier) {
  return (Handler inner) {
    return (Request request) async {
      final header = request.headers['authorization'];
      if (header == null || !header.startsWith('Bearer ')) {
        return _unauthorized('Missing Authorization: Bearer <ID token>.');
      }
      final token = header.substring('Bearer '.length).trim();
      if (token.isEmpty) {
        return _unauthorized('Empty bearer token.');
      }

      final VerifiedToken verified;
      try {
        verified = await verifier.verify(token);
      } on TokenVerificationException catch (e) {
        return _unauthorized(e.message);
      }
      if (verified.uid.isEmpty) {
        return _unauthorized('Token subject (uid) is empty.');
      }

      final response = await inner(
        request.change(context: {
          ...request.context,
          uidContextKey: verified.uid,
        }),
      );
      // Also surface the uid on the response: the outermost request logger
      // only holds the ORIGINAL request, so inner-middleware context is
      // visible to it exclusively through the response on the way out.
      return response.change(context: {
        ...response.context,
        uidContextKey: verified.uid,
      });
    };
  };
}

Response _unauthorized(String message) {
  return Response(
    401,
    body: jsonEncode({
      'error': {
        'code': 'unauthenticated',
        'message': message,
        'retryable': false,
      },
    }),
    headers: const {'content-type': 'application/json'},
  );
}
