import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jawhar_api/config.dart';
import 'package:jawhar_api/content/content_token_service.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/test_app.dart';

/// `POST /v1/content/token` (roadmap §5 #12 / §8 Phase 7 task 1) with a
/// scripted QF endpoint — never touches the network or real credentials.
void main() {
  const configured = Config(
    gitSha: 'abc1234',
    modelId: 'gemini-3.5-flash',
    projectId: 'quran-app-e5e86',
    port: 8080,
    quranClientId: 'qf-client-id',
    quranClientSecret: 'qf-client-secret',
    quranAuthUrl: 'https://oauth2.example.test/oauth2/token',
  );

  Request post({String? token}) => Request(
        'POST',
        Uri.parse('http://localhost/v1/content/token'),
        headers: {if (token != null) 'authorization': 'Bearer $token'},
      );

  Future<Map<String, dynamic>> body(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;

  test('without a Firebase ID token -> 401 (the endpoint is authenticated)',
      () async {
    final handler = buildTestHandler(config: configured);
    final response = await handler(post());
    expect(response.statusCode, 401);
    final error = (await body(response))['error'] as Map<String, dynamic>;
    expect(error['code'], 'unauthenticated');
  });

  test('unconfigured deployment -> 503 with the §5 envelope', () async {
    final handler = buildTestHandler(); // testConfig has no QF credentials
    final response = await handler(post(token: testToken));
    expect(response.statusCode, 503);
    final error = (await body(response))['error'] as Map<String, dynamic>;
    expect(error['code'], 'unavailable');
    expect(error['retryable'], false);
  });

  test(
      'exchange: Basic auth from id:secret, form body, scope=content; '
      '200 {token, expiresAt, expiresIn, clientId}', () async {
    final requests = <http.Request>[];
    final service = ContentTokenService(
      config: configured,
      nowUtc: () => DateTime.utc(2026, 6, 12, 10),
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({'access_token': 'qf-token-1', 'expires_in': 3600}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    final handler = buildTestHandler(
      config: configured,
      contentTokens: service,
      // Late in the cache window: the response's expiresIn must be the
      // REMAINING life of the cached QF token, not the upstream 3600 — a
      // client caching by seconds-convention would otherwise hold a
      // ~5-minute token for an hour.
      nowUtc: () => DateTime.utc(2026, 6, 12, 10, 55),
    );

    final response = await handler(post(token: testToken));
    expect(response.statusCode, 200);
    final payload = await body(response);
    expect(payload['token'], 'qf-token-1');
    expect(payload['clientId'], 'qf-client-id');
    expect(
      DateTime.parse(payload['expiresAt'] as String),
      DateTime.utc(2026, 6, 12, 11),
    );
    expect(payload['expiresIn'], 5 * 60,
        reason: 'remaining seconds, not the upstream-issued lifetime');

    expect(requests, hasLength(1));
    final upstream = requests.single;
    expect(upstream.url.toString(), configured.quranAuthUrl);
    expect(
      upstream.headers['authorization'],
      'Basic ${base64Encode(utf8.encode('qf-client-id:qf-client-secret'))}',
    );
    expect(upstream.headers['content-type'], contains('x-www-form-urlencoded'));
    expect(upstream.body, 'grant_type=client_credentials&scope=content');
  });

  test('token is cached server-side until expiry (one upstream exchange)',
      () async {
    var calls = 0;
    var now = DateTime.utc(2026, 6, 12, 10);
    final service = ContentTokenService(
      config: configured,
      nowUtc: () => now,
      httpClient: MockClient((request) async {
        calls++;
        return http.Response(
          jsonEncode({'access_token': 'qf-token-$calls', 'expires_in': 3600}),
          200,
        );
      }),
    );
    final handler =
        buildTestHandler(config: configured, contentTokens: service);

    final first = await body(await handler(post(token: testToken)));
    final second = await body(await handler(post(token: testToken)));
    expect(calls, 1, reason: 'second call must hit the server-side cache');
    expect(second['token'], first['token']);

    // Within 60s of expiry the cache is stale -> a fresh exchange.
    now = DateTime.utc(2026, 6, 12, 10, 59, 30);
    final third = await body(await handler(post(token: testToken)));
    expect(calls, 2);
    expect(third['token'], 'qf-token-2');
  });

  test('upstream non-200 -> 502 retryable, message carries no body/secret',
      () async {
    final service = ContentTokenService(
      config: configured,
      httpClient: MockClient(
        (request) async =>
            http.Response('{"error":"invalid_client SECRETLEAK"}', 401),
      ),
    );
    final handler =
        buildTestHandler(config: configured, contentTokens: service);

    final response = await handler(post(token: testToken));
    expect(response.statusCode, 502);
    final error = (await body(response))['error'] as Map<String, dynamic>;
    expect(error['code'], 'upstream-error');
    expect(error['retryable'], true);
    expect(error['message'], isNot(contains('SECRETLEAK')),
        reason: 'upstream bodies are never echoed');
    expect(error['message'], isNot(contains('qf-client-secret')));
  });

  test('concurrent first calls share one exchange (single-flight)', () async {
    var calls = 0;
    final service = ContentTokenService(
      config: configured,
      httpClient: MockClient((request) async {
        calls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response(
          jsonEncode({'access_token': 'qf-token', 'expires_in': 3600}),
          200,
        );
      }),
    );
    final results = await Future.wait([
      service.getToken(),
      service.getToken(),
      service.getToken(),
    ]);
    expect(calls, 1);
    expect({for (final r in results) r.token}, {'qf-token'});
  });
}
