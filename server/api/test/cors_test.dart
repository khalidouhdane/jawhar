import 'dart:convert';

import 'package:jawhar_api/config.dart';
import 'package:jawhar_api/middleware/cors.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/test_app.dart';

const vercelOrigin = 'https://website-lilac-phi-50.vercel.app';

void main() {
  group('CorsPolicy', () {
    final policy = CorsPolicy(kDefaultCorsAllowedOrigins);

    test('allows the default Vercel origin exactly', () {
      expect(policy.isAllowed(vercelOrigin), isTrue);
      // Origins are scheme-sensitive; http != https.
      expect(
        policy.isAllowed('http://website-lilac-phi-50.vercel.app'),
        isFalse,
      );
    });

    test('allows any localhost/127.0.0.1 port (Flutter web debug)', () {
      expect(policy.isAllowed('http://localhost:51737'), isTrue);
      expect(policy.isAllowed('http://localhost:3000'), isTrue);
      expect(policy.isAllowed('http://127.0.0.1:8081'), isTrue);
      // Default port 80 — browsers omit it from the Origin header.
      expect(policy.isAllowed('http://localhost'), isTrue);
    });

    test('wildcard never bleeds into other hosts or schemes', () {
      expect(policy.isAllowed('http://localhost.evil.com'), isFalse);
      expect(policy.isAllowed('http://localhost:80.evil.com'), isFalse);
      expect(policy.isAllowed('http://localhost:'), isFalse);
      expect(policy.isAllowed('https://evil.example'), isFalse);
      expect(policy.isAllowed('null'), isFalse);
    });

    test('CORS_ALLOWED_ORIGINS env REPLACES the default list', () {
      final config = Config.fromEnvironment(const {
        'CORS_ALLOWED_ORIGINS':
            'https://staging.example , https://app.example',
      });
      expect(
        config.corsAllowedOrigins,
        ['https://staging.example', 'https://app.example'],
      );
      final custom = CorsPolicy(config.corsAllowedOrigins);
      expect(custom.isAllowed('https://staging.example'), isTrue);
      expect(custom.isAllowed(vercelOrigin), isFalse);
      expect(custom.isAllowed('http://localhost:3000'), isFalse);

      // Unset/empty env keeps the default allow-list.
      expect(
        Config.fromEnvironment(const {}).corsAllowedOrigins,
        kDefaultCorsAllowedOrigins,
      );
    });
  });

  group('corsMiddleware in the full app pipeline', () {
    late Handler handler;

    setUp(() => handler = buildTestHandler());

    Request preflight(String path, {required String origin}) => Request(
          'OPTIONS',
          Uri.parse('http://localhost$path'),
          headers: {
            'origin': origin,
            'access-control-request-method': 'GET',
            'access-control-request-headers': 'authorization,content-type',
          },
        );

    test('preflight from an allowed origin succeeds WITHOUT a token',
        () async {
      final response = await handler(preflight('/v1/me/plan',
          origin: vercelOrigin)); // no Authorization header anywhere
      expect(response.statusCode, 204);
      expect(response.headers['access-control-allow-origin'], vercelOrigin);
      expect(
        response.headers['access-control-allow-methods'],
        'GET, POST, PUT, DELETE',
      );
      expect(
        response.headers['access-control-allow-headers'],
        'Authorization, Content-Type',
      );
      expect(response.headers['access-control-max-age'], '3600');
      expect(response.headers['vary'], 'Origin');
    });

    test('preflight from a random localhost port succeeds', () async {
      final response = await handler(
        preflight('/v1/me/plan:enhance', origin: 'http://localhost:51737'),
      );
      expect(response.statusCode, 204);
      expect(
        response.headers['access-control-allow-origin'],
        'http://localhost:51737',
      );
    });

    test('preflight from a disallowed origin carries NO CORS headers',
        () async {
      final response = await handler(
        preflight('/v1/me/plan', origin: 'https://evil.example'),
      );
      expect(response.statusCode, 403);
      expect(response.headers.keys.map((k) => k.toLowerCase()),
          isNot(contains('access-control-allow-origin')));
      expect(response.headers.keys.map((k) => k.toLowerCase()),
          isNot(contains('access-control-allow-methods')));
      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(
        (body['error'] as Map<String, dynamic>)['code'],
        'cors-origin-denied',
      );
    });

    test('authenticated GET from an allowed origin carries the CORS header',
        () async {
      final response = await handler(Request(
        'GET',
        Uri.parse('http://localhost/v1/me/whoami'),
        headers: {
          'authorization': 'Bearer $testToken',
          'origin': vercelOrigin,
        },
      ));
      expect(response.statusCode, 200);
      expect(response.headers['access-control-allow-origin'], vercelOrigin);
      expect(response.headers['vary'], 'Origin');
    });

    test('401s also carry the CORS header so web JS can read the error',
        () async {
      final response = await handler(Request(
        'GET',
        Uri.parse('http://localhost/v1/me/whoami'),
        headers: {'origin': vercelOrigin}, // no token
      ));
      expect(response.statusCode, 401);
      expect(response.headers['access-control-allow-origin'], vercelOrigin);
    });

    test('responses to disallowed or absent origins get no CORS headers',
        () async {
      final fromEvil = await handler(Request(
        'GET',
        Uri.parse('http://localhost/v1/me/whoami'),
        headers: {
          'authorization': 'Bearer $testToken',
          'origin': 'https://evil.example',
        },
      ));
      expect(fromEvil.statusCode, 200);
      expect(fromEvil.headers.keys.map((k) => k.toLowerCase()),
          isNot(contains('access-control-allow-origin')));

      final native = await handler(Request(
        'GET',
        Uri.parse('http://localhost/health'), // no Origin (native client)
      ));
      expect(native.statusCode, 200);
      expect(native.headers.keys.map((k) => k.toLowerCase()),
          isNot(contains('access-control-allow-origin')));
    });

    test('plain OPTIONS (no Access-Control-Request-Method) is NOT a preflight',
        () async {
      final response = await handler(Request(
        'OPTIONS',
        Uri.parse('http://localhost/v1/me/plan'),
        headers: {'origin': vercelOrigin},
      ));
      // Falls through to the router (404 here) instead of being answered
      // as a preflight — but still gets the allow-origin echo.
      expect(response.statusCode, isNot(204));
      expect(response.headers['access-control-allow-origin'], vercelOrigin);
    });
  });
}
