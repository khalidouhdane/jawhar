import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quran_app/services/quran_auth_service.dart';

void main() {
  setUp(QuranAuthService.resetForTest);
  tearDown(QuranAuthService.resetForTest);

  group('QuranAuthService content token via jawhar-api (Phase 7)', () {
    test('signed-in: POST /v1/content/token with the Firebase ID token; '
        'the returned token is cached', () async {
      var calls = 0;
      QuranAuthService.apiBaseUrlOverride = 'https://api.test';
      QuranAuthService.idTokenProviderOverride = () async => 'firebase-id';
      QuranAuthService.httpClientOverride = MockClient((request) async {
        calls++;
        expect(request.method, 'POST');
        expect(request.url.toString(), 'https://api.test/v1/content/token');
        expect(request.headers['Authorization'], 'Bearer firebase-id');
        return http.Response(
          jsonEncode({'access_token': 'content-token-1', 'expires_in': 3600}),
          200,
        );
      });

      expect(await QuranAuthService.getValidToken(), 'content-token-1');
      // Second call is served from cache — no extra HTTP round-trip.
      expect(await QuranAuthService.getValidToken(), 'content-token-1');
      expect(calls, 1);
    });

    test(
      'lenient response field names: {token, expiresIn} also accepted',
      () async {
        QuranAuthService.apiBaseUrlOverride = 'https://api.test';
        QuranAuthService.idTokenProviderOverride = () async => 'firebase-id';
        QuranAuthService.httpClientOverride = MockClient((request) async {
          return http.Response(
            jsonEncode({'token': 'content-token-2', 'expiresIn': 600}),
            200,
          );
        });

        expect(await QuranAuthService.getValidToken(), 'content-token-2');
      },
    );

    test(
      'setTestToken short-circuits fetching (existing seam preserved)',
      () async {
        QuranAuthService.setTestToken('manual-token');
        expect(await QuranAuthService.getValidToken(), 'manual-token');
      },
    );

    test('SERVER wire shape {token, expiresAt, expiresIn, clientId}: '
        'expiresAt is the primary expiry source', () async {
      // A token with ~30s of real life (the server cache near its refresh
      // edge). Parsing expiresAt correctly puts it inside the 60s pre-expiry
      // buffer, so the SECOND call must refetch; the pre-fix behavior
      // (default 3600s) would have served the nearly-dead token from cache
      // for ~59 minutes.
      var calls = 0;
      QuranAuthService.apiBaseUrlOverride = 'https://api.test';
      QuranAuthService.idTokenProviderOverride = () async => 'firebase-id';
      QuranAuthService.httpClientOverride = MockClient((request) async {
        calls++;
        return http.Response(
          jsonEncode({
            'token': 'short-lived-$calls',
            'expiresAt': DateTime.now()
                .toUtc()
                .add(const Duration(seconds: 30))
                .toIso8601String(),
            'expiresIn': 30,
            'clientId': 'qf-client-id',
          }),
          200,
        );
      });

      expect(await QuranAuthService.getValidToken(), 'short-lived-1');
      expect(await QuranAuthService.getValidToken(), 'short-lived-2');
      expect(calls, 2,
          reason: 'a ~30s token must not be cached as if it had 3600s');
    });

    test('SERVER wire shape with a long-lived expiresAt is cached', () async {
      var calls = 0;
      QuranAuthService.apiBaseUrlOverride = 'https://api.test';
      QuranAuthService.idTokenProviderOverride = () async => 'firebase-id';
      QuranAuthService.httpClientOverride = MockClient((request) async {
        calls++;
        return http.Response(
          jsonEncode({
            'token': 'long-lived',
            'expiresAt': DateTime.now()
                .toUtc()
                .add(const Duration(hours: 1))
                .toIso8601String(),
            'expiresIn': 3600,
            'clientId': 'qf-client-id',
          }),
          200,
        );
      });

      expect(await QuranAuthService.getValidToken(), 'long-lived');
      expect(await QuranAuthService.getValidToken(), 'long-lived');
      expect(calls, 1);
    });

    test('invalidateToken drops the cache so the next call refetches '
        '(401-recovery seam)', () async {
      var calls = 0;
      QuranAuthService.apiBaseUrlOverride = 'https://api.test';
      QuranAuthService.idTokenProviderOverride = () async => 'firebase-id';
      QuranAuthService.httpClientOverride = MockClient((request) async {
        calls++;
        return http.Response(
          jsonEncode({'access_token': 'token-$calls', 'expires_in': 3600}),
          200,
        );
      });

      expect(await QuranAuthService.getValidToken(), 'token-1');
      QuranAuthService.invalidateToken();
      expect(await QuranAuthService.getValidToken(), 'token-2');
      expect(calls, 2);
    });
  });
}
