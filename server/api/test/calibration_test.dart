import 'dart:convert';

import 'package:jawhar_api/ai/prompts.dart';
import 'package:jawhar_api/ai/vertex_client.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';
import 'support/test_app.dart';

void main() {
  Request post(String path, Object? body, {String? token = testToken}) =>
      Request(
        'POST',
        Uri.parse('http://localhost$path'),
        headers: {
          'content-type': 'application/json',
          if (token != null) 'authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

  // Mirrors AICalibrationService._buildCalibrationContext (no temporal.date).
  Map<String, dynamic> calibrationContext() => {
        'totalSessionsCompleted': 14,
        'currentWeek': {'totalSessions': 5, 'completionRate': '80'},
        'profile': {'dailyTimeMinutes': 30, 'pacePreference': 'steady'},
      };

  Future<Map<String, dynamic>> bodyOf(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;

  test('without token -> 401', () async {
    final handler = buildTestHandler();
    final response = await handler(
      post('/v1/me/calibration', {'context': calibrationContext()},
          token: null),
    );
    expect(response.statusCode, 401);
  });

  for (final path in ['/v1/me/calibration', '/v1/me/calibration:run']) {
    test('success on $path returns the model JSON (suggestions shape)',
        () async {
      final vertex = FakeVertexClient(
        textToReturn: '{"suggestions":[{"type":"pace","reasoning":"ok"}]}',
      );
      final handler = buildTestHandler(vertex: vertex);
      final response =
          await handler(post(path, {'context': calibrationContext()}));
      expect(response.statusCode, 200);
      expect(await bodyOf(response), {
        'suggestions': [
          {'type': 'pace', 'reasoning': 'ok'},
        ],
      });
    });
  }

  test('ports the exact legacy calibration prompt construction', () async {
    final vertex = FakeVertexClient();
    final handler = buildTestHandler(vertex: vertex);
    final context = calibrationContext();
    await handler(post('/v1/me/calibration', {'context': context}));

    final call = vertex.calls.single;
    final contextJson = const JsonEncoder.withIndent('  ').convert(context);
    expect(
      call.userText,
      // The legacy generateCalibration reuses the plan wording verbatim.
      'Generate today\'s memorization plan based on this user context:'
      '\n\n$contextJson\n\nGenerate the daily plan as JSON.',
    );
    expect(call.systemInstruction, defaultCalibrationSystemInstruction);
    expect(call.temperature, 0.3);
    expect(call.responseMimeType, 'application/json');
  });

  test('caller systemPrompt (the client always sends one) wins', () async {
    final vertex = FakeVertexClient();
    final handler = buildTestHandler(vertex: vertex);
    await handler(post('/v1/me/calibration', {
      'context': calibrationContext(),
      'systemPrompt': 'calibration prompt from client',
    }));
    expect(
      vertex.calls.single.systemInstruction,
      'calibration prompt from client',
    );
  });

  test('missing context -> 400 verbatim legacy message', () async {
    final handler = buildTestHandler();
    final response = await handler(post('/v1/me/calibration', {}));
    expect(response.statusCode, 400);
    final error = (await bodyOf(response))['error'] as Map<String, dynamic>;
    expect(error['message'], 'Missing "context" in request data.');
  });

  test('quota exhausted -> 429 (shared daily AI quota)', () async {
    final handler = buildTestHandler(aiQuota: FakeAiQuota(exhausted: true));
    final response = await handler(
      post('/v1/me/calibration', {'context': calibrationContext()}),
    );
    expect(response.statusCode, 429);
  });

  test('Vertex error -> 500 internal with mapped message', () async {
    final vertex = FakeVertexClient(
      errorToThrow: VertexException('Vertex AI request failed: socket closed'),
    );
    final handler = buildTestHandler(vertex: vertex);
    final response = await handler(
      post('/v1/me/calibration', {'context': calibrationContext()}),
    );
    expect(response.statusCode, 500);
    final error = (await bodyOf(response))['error'] as Map<String, dynamic>;
    expect(
      error['message'],
      'AI generation failed: Vertex AI request failed: socket closed',
    );
  });
}
