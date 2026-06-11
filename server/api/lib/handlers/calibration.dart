import 'package:shelf/shelf.dart';

import '../ai/prompts.dart';
import '../ai/vertex_client.dart';
import '../config.dart';
import '../quota/ai_quota.dart';
import 'ai_generation.dart';

/// `POST /v1/me/calibration` (also routed as the roadmap-canonical
/// `POST /v1/me/calibration:run`, §5 #9) — exact port of the legacy
/// `generateCalibration` callable: body mirrors the callable data shape
/// `{context, systemPrompt?}` and the 200 body is the JSON the callable
/// returned (the client parses `suggestions` out of it).
///
/// The server-persisted 7-day calibration gate is Phase 4+ state; today the
/// gate stays client-side (as with the callables) and this endpoint is
/// quota-gated like plan:enhance.
Handler calibrationHandler({
  required Config config,
  required VertexClient vertex,
  required AiQuota quota,
}) {
  return aiGenerationHandler(
    config: config,
    vertex: vertex,
    quota: quota,
    defaultSystemInstruction: defaultCalibrationSystemInstruction,
    buildUserMessage: (contextJson, body) =>
        buildCalibrationUserMessage(contextJson),
  );
}
