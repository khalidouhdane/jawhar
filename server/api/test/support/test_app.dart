import 'package:jawhar_api/app.dart';
import 'package:jawhar_api/config.dart';
import 'package:jawhar_api/middleware/auth.dart';
import 'package:jawhar_api/middleware/rate_limit.dart';
import 'package:jawhar_api/middleware/request_logging.dart';
import 'package:shelf/shelf.dart';

import 'fakes.dart';
import 'static_token_verifier.dart';

/// The config used by handler tests unless overridden.
const Config testConfig = Config(
  gitSha: 'abc1234',
  modelId: 'gemini-3.5-flash',
  projectId: 'quran-app-e5e86',
  port: 8080,
);

/// Bearer token [buildTestHandler]'s verifier accepts, mapping to [testUid].
const String testToken = 'good-token';
const String testUid = 'uid-123';

/// Full app handler wired with fakes: `Bearer good-token` -> uid-123,
/// scriptable Vertex + quota, optional rate limiter / log sink.
Handler buildTestHandler({
  Config config = testConfig,
  FakeVertexClient? vertex,
  FakeAiQuota? aiQuota,
  TokenBucketRateLimiter? rateLimiter,
  LogSink? logSink,
}) {
  return buildHandler(
    config: config,
    verifier: StaticTokenVerifier({
      testToken: const VerifiedToken(uid: testUid),
    }),
    vertex: vertex ?? FakeVertexClient(),
    aiQuota: aiQuota ?? FakeAiQuota(),
    rateLimiter: rateLimiter,
    logSink: logSink,
  );
}
