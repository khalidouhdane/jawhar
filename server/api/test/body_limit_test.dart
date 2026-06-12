import 'dart:async';
import 'dart:convert';

import 'package:jawhar_api/middleware/body_limit.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/test_app.dart';

/// Request-body size cap (no unbounded authenticated payloads — an
/// oversize batch must die with a non-retryable 413, never loop as a
/// permanently-failing "internal" row).
void main() {
  Future<Map<String, dynamic>> body(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;

  group('bodySizeLimit middleware', () {
    final handler = const Pipeline()
        .addMiddleware(bodySizeLimit(maxBytes: 100))
        .addHandler(
          (request) async => Response.ok(await request.readAsString()),
        );

    test('declared Content-Length over the cap -> 413 without reading',
        () async {
      final response = await handler(Request(
        'POST',
        Uri.parse('http://localhost/x'),
        body: 'x' * 101,
      ));
      expect(response.statusCode, 413);
      final error = (await body(response))['error'] as Map<String, dynamic>;
      expect(error['code'], 'payload-too-large');
      expect(error['retryable'], false,
          reason: 'a too-large body never shrinks on retry');
    });

    test('chunked (undeclared-length) body over the cap -> 413', () async {
      final chunks = StreamController<List<int>>();
      chunks.add(List.filled(60, 0x61));
      chunks.add(List.filled(60, 0x62));
      unawaited(chunks.close());
      final response = await handler(Request(
        'POST',
        Uri.parse('http://localhost/x'),
        body: chunks.stream,
      ));
      expect(response.statusCode, 413);
    });

    test('bodies at or under the cap pass through unchanged', () async {
      final payload = 'y' * 100;
      final response = await handler(Request(
        'POST',
        Uri.parse('http://localhost/x'),
        body: payload,
      ));
      expect(response.statusCode, 200);
      expect(await response.readAsString(), payload);
    });
  });

  test('the /v1 pipeline rejects oversized authenticated bodies with 413',
      () async {
    final handler = buildTestHandler();
    final response = await handler(Request(
      'POST',
      Uri.parse('http://localhost/v1/me/calibration'),
      headers: {
        'authorization': 'Bearer $testToken',
        'content-type': 'application/json',
      },
      body: '{"pad": "${'x' * (5 * 1024 * 1024 + 1)}"}',
    ));
    expect(response.statusCode, 413);
    final error = (await body(response))['error'] as Map<String, dynamic>;
    expect(error['code'], 'payload-too-large');
  });
}
