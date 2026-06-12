import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'ai/vertex_client.dart';
import 'config.dart';
import 'content/content_token_service.dart';
import 'gateway/firestore_gateway.dart';
import 'handlers/account.dart';
import 'handlers/admin.dart';
import 'handlers/analytics.dart';
import 'handlers/bootstrap.dart';
import 'handlers/calibration.dart';
import 'handlers/content_token.dart';
import 'handlers/facts.dart';
import 'handlers/healthz.dart';
import 'handlers/plan_enhance.dart';
import 'handlers/plan_get.dart';
import 'handlers/profiles.dart';
import 'middleware/app_check.dart';
import 'middleware/auth.dart';
import 'middleware/body_limit.dart';
import 'middleware/cors.dart';
import 'middleware/rate_limit.dart';
import 'middleware/request_logging.dart';
import 'observability/sentry.dart';
import 'quota/ai_quota.dart';

/// Builds the full shelf handler for jawhar-api.
///
/// Pipeline (outermost first): JSON request logging -> Sentry capture ->
/// CORS -> router. CORS sits OUTSIDE the router on purpose: browser
/// preflights carry no Authorization header, so they must be answered before
/// the `/v1` auth pipeline can 401 them. `/healthz` is public; everything
/// under `/v1/` sits behind [firebaseAuthMiddleware] with the injected
/// [TokenVerifier], then the per-uid token-bucket [perUidRateLimit].
///
/// [vertex] and [aiQuota] are injectable so handler tests run with fakes;
/// [rateLimiter] defaults to one built from [config] (tests inject a tiny or
/// pre-drained one). [gateway] backs the Firestore-reading routes (plan,
/// facts, backfill, analytics, admin, account deletion, per-user bootstrap
/// flag — and the Firestore-backed [AiQuota] constructed from it in
/// `bin/server.dart`); when null — Firestore-less unit-test composition —
/// those routes are not registered and answer 404 (still 401 without a
/// token: auth wraps the whole `/v1` mount). [contentTokens] defaults to a
/// service built from [config] (tests inject one with a fake HTTP client).
/// [nowUtc] is the plan/facts/analytics clock, injectable for date-boundary
/// and cache-TTL contract tests.
///
/// [appCheckVerifier] backs the LOG-ONLY App Check middleware (§8 Phase 8
/// task 3): verdicts are attached to the request log and never reject; a
/// null verifier logs header-carrying requests as `unverifiable`.
/// [deleteAuthUser] is the Admin-SDK auth half of `DELETE /v1/me` (§5 #11);
/// when null the endpoint deletes Firestore data only and reports
/// `authUserDeleted: false` (client `user.delete()` stays step two).
Handler buildHandler({
  required Config config,
  required TokenVerifier verifier,
  required VertexClient vertex,
  required AiQuota aiQuota,
  FirestoreGateway? gateway,
  ContentTokenService? contentTokens,
  TokenBucketRateLimiter? rateLimiter,
  LogSink? logSink,
  DateTime Function()? nowUtc,
  AppCheckVerifier? appCheckVerifier,
  AuthUserDeleter? deleteAuthUser,
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
  final contentToken = contentTokenHandler(
    contentTokens ?? ContentTokenService(config: config),
    nowUtc: nowUtc,
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
    ..get('/me/bootstrap', bootstrapHandler(config, gateway: gateway))
    ..post('/me/plan:enhance', planEnhance)
    // Canonical roadmap route (§5 #9) plus the bare alias.
    ..post('/me/calibration:run', calibration)
    ..post('/me/calibration', calibration)
    // §5 #12 — server-side QF content-token exchange (Phase 7 task 1).
    ..post('/content/token', contentToken);
  if (gateway != null) {
    // §5 #3 — get-or-create deterministic daily plan (no inline AI).
    v1.get('/me/plan', planGetHandler(gateway: gateway, nowUtc: nowUtc));
    // §5 #5 — THE single write path; backfill is the same machinery (§7.3).
    final facts = factsHandler(gateway: gateway, config: config, nowUtc: nowUtc);
    v1.post('/me/facts', facts);
    v1.post('/me/backfill', facts);
    // §5 #7 — plural-keyed MemoryProfile upsert (LWW on updatedAt); what
    // lets a second profile's facts derive (Phase 5 plural-safe contract).
    v1.put(
      '/me/profiles/<profileId>',
      profilePutHandler(gateway: gateway, nowUtc: nowUtc),
    );
    // §5 #10 — weekly analytics snapshot (canonical path + bare alias).
    final analytics = analyticsHandler(gateway: gateway, nowUtc: nowUtc);
    v1.get('/me/analytics/snapshot', analytics);
    v1.get('/me/analytics', analytics);
    // Phase 4 per-user writePath flip (admin-guarded, R2 rollback lever)
    // + the flip-to-facts reconcile pass (§8 Phase 4b task 3).
    v1.post(
      '/admin/users/<targetUid>/writePath',
      adminWritePathHandler(gateway: gateway, config: config, nowUtc: nowUtc),
    );
    // §5 #11 — account + cascade delete (Firestore tree + Auth user).
    v1.delete(
      '/me',
      accountDeleteHandler(gateway: gateway, deleteAuthUser: deleteAuthUser),
    );
  }

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
      Pipeline()
          // App Check verdict BEFORE auth so the log-only soak also sees
          // 401-bound traffic (JWKS is cached ~6h by the SDK, so verifying
          // pre-auth is cheap). NEVER rejects — §8 Phase 8 task 3 ceiling.
          .addMiddleware(appCheckLogOnly(appCheckVerifier))
          .addMiddleware(firebaseAuthMiddleware(verifier))
          .addMiddleware(perUidRateLimit(limiter))
          // After auth + rate limit: junk traffic never makes us buffer a
          // body; oversized authenticated bodies are 413'd before handlers.
          .addMiddleware(bodySizeLimit())
          .addHandler(v1.call),
    );

  return const Pipeline()
      .addMiddleware(jsonRequestLogger(sink: logSink))
      .addMiddleware(sentryMiddleware())
      .addMiddleware(corsMiddleware(CorsPolicy(config.corsAllowedOrigins)))
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
