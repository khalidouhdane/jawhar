import 'package:shelf/shelf.dart';

import '../ai/prompts.dart';
import '../ai/vertex_client.dart';
import '../config.dart';
import '../quota/ai_quota.dart';
import 'ai_generation.dart';

/// `POST /v1/me/plan:enhance` (authenticated) — roadmap §5 #4.
///
/// Exact port of the legacy `generateDailyPlan` callable: request body
/// mirrors the callable data shape `{context, isRecoveryMode?, systemPrompt?}`
/// and the 200 body is the same JSON the callable returned, so the client
/// transport swaps 1:1. Recovery mode switches the user-message preamble
/// exactly as `functions/src/index.ts` did.
Handler planEnhanceHandler({
  required Config config,
  required VertexClient vertex,
  required AiQuota quota,
}) {
  return aiGenerationHandler(
    config: config,
    vertex: vertex,
    quota: quota,
    defaultSystemInstruction: defaultPlanSystemInstruction,
    buildUserMessage: (contextJson, body) => buildPlanUserMessage(
      contextJson,
      isRecoveryMode: body['isRecoveryMode'] == true,
    ),
  );
}
