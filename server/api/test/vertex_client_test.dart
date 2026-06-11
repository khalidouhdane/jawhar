import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jawhar_api/ai/vertex_client.dart';
import 'package:test/test.dart';

void main() {
  http.Request? captured;

  VertexClient clientReturning(
    String body, {
    int status = 200,
    String location = 'global',
  }) {
    return VertexClient(
      projectId: 'quran-app-e5e86',
      location: location,
      httpClient: MockClient((request) async {
        captured = request;
        return http.Response(
          body,
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  }

  String candidateBody(String text) => jsonEncode({
        'candidates': [
          {
            'content': {
              'role': 'model',
              'parts': [
                {'text': text},
              ],
            },
          },
        ],
      });

  setUp(() => captured = null);

  test('POSTs to the GLOBAL endpoint with the documented URL shape', () async {
    final client = clientReturning(candidateBody('{"ok":true}'));
    await client.generateContent(
      model: 'gemini-3.5-flash',
      userText: 'hello',
    );
    expect(captured!.method, 'POST');
    expect(
      captured!.url.toString(),
      'https://aiplatform.googleapis.com/v1/projects/quran-app-e5e86'
      '/locations/global/publishers/google/models'
      '/gemini-3.5-flash:generateContent',
    );
  });

  test('non-global location uses the regional host', () async {
    final client = clientReturning(
      candidateBody('x'),
      location: 'europe-west1',
    );
    await client.generateContent(model: 'm', userText: 'u');
    expect(captured!.url.host, 'europe-west1-aiplatform.googleapis.com');
    expect(captured!.url.path, contains('/locations/europe-west1/'));
  });

  test('payload carries contents, systemInstruction and generationConfig',
      () async {
    final client = clientReturning(candidateBody('{}'));
    await client.generateContent(
      model: 'gemini-3.5-flash',
      userText: 'the user message',
      systemInstruction: 'the system prompt',
    );
    final payload =
        jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(payload['contents'], [
      {
        'role': 'user',
        'parts': [
          {'text': 'the user message'},
        ],
      },
    ]);
    expect(payload['systemInstruction'], {
      'parts': [
        {'text': 'the system prompt'},
      ],
    });
    expect(payload['generationConfig'], {
      'responseMimeType': 'application/json',
      'temperature': 0.3,
    });
  });

  test('omits systemInstruction when absent', () async {
    final client = clientReturning(candidateBody('{}'));
    await client.generateContent(model: 'm', userText: 'u');
    final payload = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(payload.containsKey('systemInstruction'), isFalse);
  });

  test('joins multiple text parts like the genai SDK response.text', () async {
    final client = clientReturning(jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': '{"a":'},
              {'text': '1}'},
            ],
          },
        },
      ],
    }));
    final text = await client.generateContent(model: 'm', userText: 'u');
    expect(text, '{"a":1}');
  });

  test('no candidates -> empty string (caller maps to empty-response error)',
      () async {
    final client = clientReturning(jsonEncode({'candidates': <Object?>[]}));
    final text = await client.generateContent(model: 'm', userText: 'u');
    expect(text, '');
  });

  test('HTTP error -> VertexException with status and extracted message',
      () async {
    final client = clientReturning(
      jsonEncode({
        'error': {'code': 429, 'message': 'Quota exceeded.', 'status': 'RESOURCE_EXHAUSTED'},
      }),
      status: 429,
    );
    try {
      await client.generateContent(model: 'm', userText: 'u');
      fail('expected VertexException');
    } on VertexException catch (e) {
      expect(e.statusCode, 429);
      expect(e.message, 'Vertex AI HTTP 429: Quota exceeded.');
    }
  });

  test('HTTP error with non-JSON body still produces a bounded message',
      () async {
    final client = clientReturning('upstream exploded', status: 500);
    try {
      await client.generateContent(model: 'm', userText: 'u');
      fail('expected VertexException');
    } on VertexException catch (e) {
      expect(e.statusCode, 500);
      expect(e.message, 'Vertex AI HTTP 500: upstream exploded');
    }
  });

  test('transport failure -> VertexException, not a raw socket error',
      () async {
    final client = VertexClient(
      projectId: 'p',
      httpClient: MockClient((_) async => throw http.ClientException('boom')),
    );
    expect(
      () => client.generateContent(model: 'm', userText: 'u'),
      throwsA(isA<VertexException>()),
    );
  });
}
