import 'dart:convert';

import 'package:jawhar_api/app.dart';
import 'package:jawhar_api/config.dart';
import 'package:jawhar_api/middleware/auth.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/static_token_verifier.dart';

void main() {
  const config = Config(
    gitSha: 'abc1234',
    modelId: 'gemini-3.5-flash',
    projectId: 'quran-app-e5e86',
    port: 8080,
  );

  late List<String> logLines;
  late Handler handler;

  setUp(() {
    logLines = [];
    handler = buildHandler(
      config: config,
      verifier: StaticTokenVerifier({
        'good-token': const VerifiedToken(uid: 'uid-123'),
      }),
      logSink: logLines.add,
    );
  });

  test('GET /healthz is public and returns status/gitSha/modelId', () async {
    final response =
        await handler(Request('GET', Uri.parse('http://localhost/healthz')));
    expect(response.statusCode, 200);
    expect(response.headers['content-type'], contains('application/json'));
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect(body, {
      'status': 'ok',
      'gitSha': 'abc1234',
      'modelId': 'gemini-3.5-flash',
    });
  });

  test('GET /v1/me/whoami without token -> 401', () async {
    final response = await handler(
      Request('GET', Uri.parse('http://localhost/v1/me/whoami')),
    );
    expect(response.statusCode, 401);
  });

  test('GET /v1/me/whoami with valid token -> uid from token', () async {
    final response = await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/me/whoami'),
        headers: {'authorization': 'Bearer good-token'},
      ),
    );
    expect(response.statusCode, 200);
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect(body, {'uid': 'uid-123'});
  });

  test('unknown route -> 404 error envelope', () async {
    final response =
        await handler(Request('GET', Uri.parse('http://localhost/nope')));
    expect(response.statusCode, 404);
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect((body['error'] as Map<String, dynamic>)['code'], 'not-found');
  });

  test('requests are logged as structured JSON without auth headers',
      () async {
    await handler(
      Request(
        'GET',
        Uri.parse('http://localhost/healthz'),
        headers: {'authorization': 'Bearer super-secret'},
      ),
    );
    expect(logLines, hasLength(1));
    final entry = jsonDecode(logLines.single) as Map<String, dynamic>;
    expect(entry['severity'], 'INFO');
    final httpRequest = entry['httpRequest'] as Map<String, dynamic>;
    expect(httpRequest['requestMethod'], 'GET');
    expect(httpRequest['requestUrl'], '/healthz');
    expect(httpRequest['status'], 200);
    expect(logLines.single, isNot(contains('super-secret')));
  });

  test('Config.fromEnvironment applies defaults', () {
    final fromEmpty = Config.fromEnvironment(const {});
    expect(fromEmpty.gitSha, 'unknown');
    expect(fromEmpty.modelId, kDefaultGeminiModel);
    expect(fromEmpty.projectId, 'quran-app-e5e86');
    expect(fromEmpty.port, 8080);
    expect(fromEmpty.sentryDsn, isNull);

    final fromSet = Config.fromEnvironment(const {
      'GIT_SHA': 'deadbeef',
      'GEMINI_MODEL': 'gemini-x',
      'PORT': '9090',
      'SENTRY_DSN': 'https://k@o.ingest.sentry.io/1',
    });
    expect(fromSet.gitSha, 'deadbeef');
    expect(fromSet.modelId, 'gemini-x');
    expect(fromSet.port, 9090);
    expect(fromSet.sentryDsn, isNotNull);
  });
}
