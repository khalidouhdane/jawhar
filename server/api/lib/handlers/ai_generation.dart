import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../ai/prompts.dart';
import '../ai/vertex_client.dart';
import '../config.dart';
import '../middleware/auth.dart';
import '../observability/sentry.dart';
import '../quota/ai_quota.dart';

/// Shared request flow for the two AI endpoints — an exact port of the
/// legacy callables' semantics (`functions/src/index.ts`, the reference
/// implementation):
///
/// 1. body must be a JSON object mirroring the callable data shape
///    `{context, isRecoveryMode?, systemPrompt?}` — anything else is 400;
/// 2. missing `context` -> 400 `invalid-argument`,
///    message `Missing "context" in request data.` (verbatim);
/// 3. per-uid DAILY AI quota consumed BEFORE Vertex (429 when exhausted) —
///    the server-enforced quota the callables never had (roadmap §5 #4/#9);
/// 4. Vertex `generateContent` with `responseMimeType: application/json`,
///    `temperature: 0.3`, caller system instruction or the legacy default;
/// 5. empty model text or any Vertex/parse failure -> 500 `internal` with
///    `AI generation failed: <message>` (verbatim mapping, including the
///    empty-response case which the legacy code rethrew through its own
///    catch block);
/// 6. success -> 200 whose body is EXACTLY the JSON the model returned
///    (what `result.data` held for the callable client).
Handler aiGenerationHandler({
  required Config config,
  required VertexClient vertex,
  required AiQuota quota,
  required String defaultSystemInstruction,
  required String Function(String contextJson, Map<String, dynamic> body)
      buildUserMessage,
}) {
  return (Request request) async {
    final Object? parsed;
    try {
      parsed = jsonDecode(await request.readAsString());
    } on FormatException {
      return _error(400, 'invalid-argument', 'Request body must be JSON.');
    }
    if (parsed is! Map<String, dynamic>) {
      return _error(
        400,
        'invalid-argument',
        'Request body must be a JSON object.',
      );
    }
    final body = parsed;

    final context = body['context'];
    if (context == null) {
      return _error(
        400,
        'invalid-argument',
        'Missing "context" in request data.',
      );
    }

    final decision = await quota.tryConsume(
      uid: request.uid,
      localDate: quotaDateFor(body),
    );
    if (!decision.allowed) {
      return _error(
        429,
        'resource-exhausted',
        'Daily AI quota of ${decision.limit} calls reached. '
        'Try again tomorrow.',
        retryable: true,
      );
    }

    final contextJson = contextToJson(context);
    final userMessage = buildUserMessage(contextJson, body);
    final systemPromptRaw = body['systemPrompt'];
    // `systemPrompt || default` in the legacy code: null/empty -> default.
    final systemInstruction =
        (systemPromptRaw is String && systemPromptRaw.isNotEmpty)
            ? systemPromptRaw
            : defaultSystemInstruction;

    try {
      final text = await vertex.generateContent(
        model: config.modelId,
        userText: userMessage,
        systemInstruction: systemInstruction,
        temperature: 0.3,
        responseMimeType: 'application/json',
      );
      if (text.trim().isEmpty) {
        throw VertexException('AI returned empty response.');
      }
      final result = jsonDecode(text);
      return Response.ok(
        jsonEncode(result),
        headers: const {'content-type': 'application/json'},
      );
    } catch (e, st) {
      await reportError(e, st);
      return _error(
        500,
        'internal',
        'AI generation failed: ${_messageOf(e)}',
        retryable: true,
      );
    }
  };
}

/// Quota bucketing date: the client-local `date` the plan context already
/// carries (`context.temporal.date`, the §5 canonical client-local date),
/// falling back to the server's UTC date when absent (e.g. calibration
/// contexts carry no date). Worst case for the fallback is a ±1-day bucket
/// shift around midnight — accepted at tester scale (roadmap R5).
String quotaDateFor(Map<String, dynamic> body) {
  final context = body['context'];
  if (context is Map<String, dynamic>) {
    final temporal = context['temporal'];
    if (temporal is Map<String, dynamic>) {
      final date = temporal['date'];
      if (date is String && _isoDate.hasMatch(date)) return date;
    }
  }
  return DateTime.now().toUtc().toIso8601String().substring(0, 10);
}

final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

String _messageOf(Object e) {
  if (e is VertexException) return e.message;
  if (e is FormatException) return e.message;
  return e.toString();
}

Response _error(
  int status,
  String code,
  String message, {
  bool retryable = false,
}) {
  return Response(
    status,
    body: jsonEncode({
      'error': {'code': code, 'message': message, 'retryable': retryable},
    }),
    headers: const {'content-type': 'application/json'},
  );
}
