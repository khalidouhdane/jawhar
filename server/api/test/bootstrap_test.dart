import 'dart:convert';

import 'package:jawhar_api/config.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/test_app.dart';

void main() {
  Request get({String? token}) => Request(
        'GET',
        Uri.parse('http://localhost/v1/me/bootstrap'),
        headers: {if (token != null) 'authorization': 'Bearer $token'},
      );

  test('without token -> 401 with error envelope', () async {
    final handler = buildTestHandler();
    final response = await handler(get());
    expect(response.statusCode, 401);
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect((body['error'] as Map<String, dynamic>)['code'], 'unauthenticated');
  });

  test('with injected verifier -> 200 with the Wave 2 §5 shape', () async {
    final before = DateTime.now().toUtc();
    final handler = buildTestHandler();
    final response = await handler(get(token: testToken));
    expect(response.statusCode, 200);
    expect(response.headers['content-type'], contains('application/json'));

    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect(
      body.keys,
      unorderedEquals([
        'minSupportedBuild',
        'datasetEpoch',
        'writePath',
        'modelId',
        'serverTime',
      ]),
    );
    expect(body['minSupportedBuild'], 1);
    expect(body['datasetEpoch'], 'e1');
    expect(body['writePath'], 'legacy', reason: 'Phase 4 flag default');
    expect(body['modelId'], 'gemini-3.5-flash');

    final serverTime = DateTime.parse(body['serverTime'] as String);
    expect(serverTime.isUtc, isTrue);
    final after = DateTime.now().toUtc();
    expect(
      serverTime.isAfter(before.subtract(const Duration(seconds: 1))) &&
          serverTime.isBefore(after.add(const Duration(seconds: 1))),
      isTrue,
      reason: 'serverTime should be "now" in UTC',
    );
  });

  test('env-overridden config flows through', () async {
    const config = Config(
      gitSha: 'abc1234',
      modelId: 'gemini-x',
      projectId: 'quran-app-e5e86',
      port: 8080,
      minSupportedBuild: 23,
      datasetEpoch: 'e2',
      writePath: 'facts',
    );
    final handler = buildTestHandler(config: config);
    final response = await handler(get(token: testToken));
    expect(response.statusCode, 200);
    final body =
        jsonDecode(await response.readAsString()) as Map<String, dynamic>;
    expect(body['minSupportedBuild'], 23);
    expect(body['datasetEpoch'], 'e2');
    expect(body['writePath'], 'facts');
    expect(body['modelId'], 'gemini-x');
  });
}
