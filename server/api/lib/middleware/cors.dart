import 'dart:convert';

import 'package:shelf/shelf.dart';

/// CORS for the web client (roadmap §8 Phase 2 exit criterion: "web
/// exercises CORS — set headers in shelf for the Vercel origin").
///
/// Policy, not transport: which `Origin` values may script against the API.
/// Entries come from `Config.corsAllowedOrigins` (env CORS_ALLOWED_ORIGINS):
///
/// - exact origins, e.g. `https://website-lilac-phi-50.vercel.app`;
/// - any-port wildcards, e.g. `http://localhost:*` — Flutter web debug binds
///   a RANDOM port per `flutter run`, so dev entries match every port on
///   that scheme+host (including the implicit default port, where browsers
///   omit `:80`/`:443` from the Origin header).
///
/// CORS is NOT an auth boundary here — every `/v1` route still requires a
/// Firebase ID token; this only controls which browser origins may make
/// credentialed fetches at all.
class CorsPolicy {
  CorsPolicy(List<String> allowedOrigins)
      : _exact = {
          for (final o in allowedOrigins)
            if (!o.endsWith(':*')) o.toLowerCase(),
        },
        _anyPortPrefixes = [
          for (final o in allowedOrigins)
            if (o.endsWith(':*'))
              o.substring(0, o.length - ':*'.length).toLowerCase(),
        ];

  /// Exact-match origins (scheme://host[:port], lowercased).
  final Set<String> _exact;

  /// `scheme://host` prefixes from `:*` entries — match any (or no) port.
  final List<String> _anyPortPrefixes;

  /// Whether [origin] (an `Origin` request-header value) is allowed.
  bool isAllowed(String origin) {
    final normalized = origin.toLowerCase();
    if (_exact.contains(normalized)) return true;
    for (final prefix in _anyPortPrefixes) {
      // Either the bare scheme+host (browser omitted the default port) or
      // scheme+host followed by `:<digits>` and nothing else — anything
      // beyond a pure numeric port (e.g. http://localhost.evil.com,
      // http://localhost:80.evil.com) must NOT match.
      if (normalized == prefix) return true;
      if (normalized.startsWith('$prefix:') &&
          _allDigits(normalized.substring(prefix.length + 1))) {
        return true;
      }
    }
    return false;
  }

  static bool _allDigits(String s) =>
      s.isNotEmpty && s.codeUnits.every((c) => c >= 0x30 && c <= 0x39);
}

/// Methods advertised on preflight — every verb the §5 contract uses
/// (GET reads, POST facts/AI, PUT upserts, DELETE /v1/me).
const String _allowMethods = 'GET, POST, PUT, DELETE';

/// Headers the client actually sends cross-origin: the Firebase ID token
/// and the JSON content type.
const String _allowHeaders = 'Authorization, Content-Type';

/// Preflight cache lifetime: 1h — long enough that the web client does not
/// re-preflight every call, short enough that an allow-list change rolls
/// out the same hour (Chromium caps at 2h anyway).
const String _maxAgeSeconds = '3600';

/// Shelf middleware implementing [policy]:
///
/// - **Preflights** (`OPTIONS` + `Access-Control-Request-Method`) are
///   answered HERE, before the router — and therefore before
///   `firebaseAuthMiddleware`, which only wraps the mounted `/v1` pipeline.
///   Browsers never attach `Authorization` to preflights, so a preflight
///   that required a token would permanently break the web client. Allowed
///   origin -> 204 with the full preflight header set; disallowed -> 403
///   §5 error envelope with NO CORS headers (the browser blocks the call).
/// - **Actual requests** pass through; when the `Origin` is allowed the
///   response gains `Access-Control-Allow-Origin: <that origin>` (echoed,
///   never `*`) + `Vary: Origin`. Disallowed or absent origins (native
///   clients) get no CORS headers at all.
Middleware corsMiddleware(CorsPolicy policy) {
  return (Handler inner) {
    return (Request request) async {
      final origin = request.headers['origin'];

      final isPreflight = request.method == 'OPTIONS' &&
          request.headers['access-control-request-method'] != null;
      if (isPreflight) {
        if (origin == null || !policy.isAllowed(origin)) {
          return Response(
            403,
            body: jsonEncode({
              'error': {
                'code': 'cors-origin-denied',
                'message': 'Origin is not allowed by CORS policy.',
                'retryable': false,
              },
            }),
            headers: const {'content-type': 'application/json'},
          );
        }
        return Response(
          204,
          headers: {
            'access-control-allow-origin': origin,
            'access-control-allow-methods': _allowMethods,
            'access-control-allow-headers': _allowHeaders,
            'access-control-max-age': _maxAgeSeconds,
            'vary': 'Origin',
          },
        );
      }

      final response = await inner(request);
      if (origin == null || !policy.isAllowed(origin)) return response;
      return response.change(headers: {
        'access-control-allow-origin': origin,
        'vary': 'Origin',
      });
    };
  };
}
