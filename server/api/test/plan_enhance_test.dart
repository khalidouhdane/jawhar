import 'dart:convert';

import 'package:jawhar_api/ai/prompts.dart';
import 'package:jawhar_api/ai/vertex_client.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/fakes.dart';
import 'support/test_app.dart';

void main() {
  const route = 'http://localhost/v1/me/plan:enhance';

  Request post(Object? body, {String? token = testToken}) => Request(
        'POST',
        Uri.parse(route),
        headers: {
          'content-type': 'application/json',
          if (token != null) 'authorization': 'Bearer $token',
        },
        body: body is String ? body : jsonEncode(body),
      );

  Map<String, dynamic> contextOf({String date = '2026-06-11'}) => {
        'profile': {'dailyTimeMinutes': 30},
        'progress': {'memorizedPages': 12},
        'recentSessions': <Object?>[],
        'temporal': {'date': date},
      };

  Future<Map<String, dynamic>> bodyOf(Response response) async =>
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;

  test('without token -> 401, Vertex and quota never touched', () async {
    final vertex = FakeVertexClient();
    final quota = FakeAiQuota();
    final handler = buildTestHandler(vertex: vertex, aiQuota: quota);
    final response =
        await handler(post({'context': contextOf()}, token: null));
    expect(response.statusCode, 401);
    expect(vertex.calls, isEmpty);
    expect(quota.calls, isEmpty);
  });

  test('success: returns exactly the JSON the model produced', () async {
    final vertex = FakeVertexClient(
      textToReturn:
          '{"sabaq":{"page":134},"recipes":[{"step":1}],"guidance":"go"}',
    );
    final handler = buildTestHandler(vertex: vertex);
    final response = await handler(post({'context': contextOf()}));
    expect(response.statusCode, 200);
    expect(response.headers['content-type'], contains('application/json'));
    expect(await bodyOf(response), {
      'sabaq': {'page': 134},
      'recipes': [
        {'step': 1},
      ],
      'guidance': 'go',
    });
  });

  test('ports the exact legacy prompt construction (normal mode)', () async {
    final vertex = FakeVertexClient();
    final handler = buildTestHandler(vertex: vertex);
    final context = contextOf();
    await handler(post({'context': context}));

    expect(vertex.calls, hasLength(1));
    final call = vertex.calls.single;
    final contextJson = const JsonEncoder.withIndent('  ').convert(context);
    expect(
      call.userText,
      'Generate today\'s memorization plan based on this user context:'
      '\n\n$contextJson\n\nGenerate the daily plan as JSON.',
    );
    expect(call.systemInstruction, defaultPlanSystemInstruction);
    expect(call.temperature, 0.3);
    expect(call.responseMimeType, 'application/json');
    expect(call.model, 'gemini-3.5-flash');
  });

  test('recovery mode switches the preamble exactly as the callable did',
      () async {
    final vertex = FakeVertexClient();
    final handler = buildTestHandler(vertex: vertex);
    final context = contextOf();
    await handler(post({'context': context, 'isRecoveryMode': true}));

    final contextJson = const JsonEncoder.withIndent('  ').convert(context);
    expect(
      vertex.calls.single.userText,
      'RECOVERY MODE: The user has returned after missed days.\n'
      'Generate a lighter, review-focused plan to ease them back in.\n\n'
      'User Context:\n$contextJson\n\nGenerate the daily plan as JSON.',
    );
  });

  test('caller systemPrompt overrides the default; empty falls back',
      () async {
    final vertex = FakeVertexClient();
    final handler = buildTestHandler(vertex: vertex);

    await handler(
      post({'context': contextOf(), 'systemPrompt': 'You are a test.'}),
    );
    expect(vertex.calls.last.systemInstruction, 'You are a test.');

    await handler(post({'context': contextOf(), 'systemPrompt': ''}));
    expect(
      vertex.calls.last.systemInstruction,
      defaultPlanSystemInstruction,
      reason: 'legacy `systemPrompt || default` treats empty as absent',
    );
  });

  test('missing context -> 400 with the verbatim legacy message', () async {
    final vertex = FakeVertexClient();
    final quota = FakeAiQuota();
    final handler = buildTestHandler(vertex: vertex, aiQuota: quota);
    final response = await handler(post({'isRecoveryMode': true}));
    expect(response.statusCode, 400);
    final error = (await bodyOf(response))['error'] as Map<String, dynamic>;
    expect(error['code'], 'invalid-argument');
    expect(error['message'], 'Missing "context" in request data.');
    expect(error['retryable'], false);
    expect(vertex.calls, isEmpty);
    expect(quota.calls, isEmpty, reason: 'invalid requests must not consume quota');
  });

  test('malformed (non-JSON) body -> 400', () async {
    final handler = buildTestHandler();
    final response = await handler(post('this is not json'));
    expect(response.statusCode, 400);
    final error = (await bodyOf(response))['error'] as Map<String, dynamic>;
    expect(error['code'], 'invalid-argument');
  });

  test('JSON-but-not-object body -> 400', () async {
    final handler = buildTestHandler();
    final response = await handler(post('[1,2,3]'));
    expect(response.statusCode, 400);
  });

  test('quota exhausted -> 429 resource-exhausted, Vertex never called',
      () async {
    final vertex = FakeVertexClient();
    final quota = FakeAiQuota(exhausted: true, limit: 10);
    final handler = buildTestHandler(vertex: vertex, aiQuota: quota);
    final response = await handler(post({'context': contextOf()}));
    expect(response.statusCode, 429);
    final error = (await bodyOf(response))['error'] as Map<String, dynamic>;
    expect(error['code'], 'resource-exhausted');
    expect(error['message'], contains('10'));
    expect(error['retryable'], true);
    expect(vertex.calls, isEmpty, reason: 'no Vertex spend past the quota');
  });

  test('quota is keyed by the client-local context.temporal.date', () async {
    final quota = FakeAiQuota();
    final handler = buildTestHandler(aiQuota: quota);
    await handler(post({'context': contextOf(date: '2026-06-10')}));
    expect(quota.calls.single.uid, testUid);
    expect(quota.calls.single.localDate, '2026-06-10');
  });

  test('quota date falls back to server UTC date when context has none',
      () async {
    final quota = FakeAiQuota();
    final handler = buildTestHandler(aiQuota: quota);
    await handler(post({
      'context': {'profile': <String, Object?>{}},
    }));
    final utcToday = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    expect(quota.calls.single.localDate, utcToday);
  });

  test('Vertex error -> 500 internal with "AI generation failed: <message>"',
      () async {
    final vertex = FakeVertexClient(
      errorToThrow: VertexException(
        'Vertex AI HTTP 429: Quota exceeded for model.',
        statusCode: 429,
      ),
    );
    final handler = buildTestHandler(vertex: vertex);
    final response = await handler(post({'context': contextOf()}));
    expect(response.statusCode, 500);
    final error = (await bodyOf(response))['error'] as Map<String, dynamic>;
    expect(error['code'], 'internal');
    expect(
      error['message'],
      'AI generation failed: Vertex AI HTTP 429: Quota exceeded for model.',
    );
    expect(error['retryable'], true);
  });

  test('empty model text -> 500 with the verbatim legacy message', () async {
    final vertex = FakeVertexClient(textToReturn: '   ');
    final handler = buildTestHandler(vertex: vertex);
    final response = await handler(post({'context': contextOf()}));
    expect(response.statusCode, 500);
    final error = (await bodyOf(response))['error'] as Map<String, dynamic>;
    expect(error['message'], 'AI generation failed: AI returned empty response.');
  });

  test('non-JSON model text -> 500 internal (parse failure mapped)', () async {
    final vertex = FakeVertexClient(textToReturn: 'Sure! Here is your plan:');
    final handler = buildTestHandler(vertex: vertex);
    final response = await handler(post({'context': contextOf()}));
    expect(response.statusCode, 500);
    final error = (await bodyOf(response))['error'] as Map<String, dynamic>;
    expect(error['code'], 'internal');
    expect(error['message'], startsWith('AI generation failed: '));
  });
}
