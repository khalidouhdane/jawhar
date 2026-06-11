import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'ai/vertex_client.dart';
import 'config.dart';
import 'gateway/firestore_gateway.dart';
import 'handlers/bootstrap.dart';
import 'handlers/calibration.dart';
import 'handlers/healthz.dart';
import 'handlers/plan_enhance.dart';
import 'middleware/auth.dart';
import 'middleware/rate_limit.dart';
import 'middleware/request_logging.dart';
import 'observability/sentry.dart';
import 'quota/ai_quota.dart';

/// Builds the full shelf handler for jawhar-api.
///
/// Pipeline (outermost first): JSON request logging -> Sentry capture ->
/// router. `/healthz` is public; everything under `/v1/` sits behind
/// [firebaseAuthMiddleware] with the injected [TokenVerifier], then the
/// per-uid token-bucket [perUidRateLimit].
///
/// [vertex] and [aiQuota] are injectable so handler tests run with fakes;
/// [rateLimiter] defaults to one built from [config] (tests inject a tiny or
/// pre-drained one). [gateway] is accepted so the composition root is in
/// place for the Phase 4+ handlers; the current routes do not read Firestore
/// directly (the Firestore-backed [AiQuota] is constructed from it in
/// `bin/server.dart`).
Handler buildHandler({
  required Config config,
  required TokenVerifier verifier,
  required VertexClient vertex,
  required AiQuota aiQuota,
  FirestoreGateway? gateway,
  TokenBucketRateLimiter? rateLimiter,
  LogSink? logSink,
}) {
  final planEnhance = planEnhanceHandler(
    config: config,
    vertex: vertex,
    quota: aiQuota,
  );
  final calibration = calibrationHandler(
    config: config,
    vertex: vertex,
    quota: aiQuota,
  );

  final v1 = Router(notFoundHandler: _notFound)
    // Minimal authenticated probe: proves the token middleware end-to-end
    // (used by the R1 spike and, later, the hidden debug screen).
    ..get('/me/whoami', (Request request) {
      return Response.ok(
        jsonEncode({'uid': request.uid}),
        headers: const {'content-type': 'application/json'},
      );
    })
    ..get('/me/bootstrap', bootstrapHandler(config))
    ..post('/me/plan:enhance', planEnhance)
    // Canonical roadmap route (§5 #9) plus the bare alias.
    ..post('/me/calibration:run', calibration)
    ..post('/me/calibration', calibration);

  final limiter = rateLimiter ??
      TokenBucketRateLimiter(
        capacity: config.rateLimitBurst,
        refillPerMinute: config.rateLimitPerMinute,
      );

  // `/health` is the canonical public liveness path: Google's frontend
  // intercepts the literal path `/healthz` on *.run.app hosts and answers
  // its own 404 without ever forwarding to the container (verified live
  // 2026-06-12 — every other path reaches the app). `/healthz` stays
  // registered for local/emulator use where no GFE sits in front.
  final root = Router(notFoundHandler: _notFound)
    ..get('/health', healthzHandler(config))
    ..get('/healthz', healthzHandler(config))
    ..mount(
      '/v1',
      const Pipeline()
          .addMiddleware(firebaseAuthMiddleware(verifier))
          .addMiddleware(perUidRateLimit(limiter))
          .addHandler(v1.call),
    );

  return const Pipeline()
      .addMiddleware(jsonRequestLogger(sink: logSink))
      .addMiddleware(sentryMiddleware())
      .addHandler(root.call);
}

Response _notFound(Request request) {
  return Response.notFound(
    jsonEncode({
      'error': {
        'code': 'not-found',
        'message': 'No such route.',
        'retryable': false,
      },
    }),
    headers: const {'content-type': 'application/json'},
  );
}
