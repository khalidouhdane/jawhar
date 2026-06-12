import 'package:jawhar_api/app.dart';
import 'package:jawhar_api/config.dart';
import 'package:jawhar_api/content/content_token_service.dart';
import 'package:jawhar_api/gateway/firestore_gateway.dart';
import 'package:jawhar_api/handlers/account.dart';
import 'package:jawhar_api/middleware/app_check.dart';
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
/// scriptable Vertex + quota, optional rate limiter / log sink. [gateway]
/// (emulator-backed, contract tests) enables `GET /v1/me/plan`; [nowUtc]
/// pins that handler's clock for date-boundary cases. [verifiedTokens]
/// extends the accepted-token map (extra uids for multi-user tests).
/// [appCheckVerifier] scripts the log-only App Check middleware;
/// [deleteAuthUser] scripts the auth half of `DELETE /v1/me`.
Handler buildTestHandler({
  Config config = testConfig,
  FakeVertexClient? vertex,
  FakeAiQuota? aiQuota,
  FirestoreGateway? gateway,
  ContentTokenService? contentTokens,
  TokenBucketRateLimiter? rateLimiter,
  LogSink? logSink,
  DateTime Function()? nowUtc,
  Map<String, VerifiedToken> verifiedTokens = const {},
  AppCheckVerifier? appCheckVerifier,
  AuthUserDeleter? deleteAuthUser,
}) {
  return buildHandler(
    config: config,
    verifier: StaticTokenVerifier({
      testToken: const VerifiedToken(uid: testUid),
      ...verifiedTokens,
    }),
    vertex: vertex ?? FakeVertexClient(),
    aiQuota: aiQuota ?? FakeAiQuota(),
    gateway: gateway,
    contentTokens: contentTokens,
    rateLimiter: rateLimiter,
    logSink: logSink,
    nowUtc: nowUtc,
    appCheckVerifier: appCheckVerifier,
    deleteAuthUser: deleteAuthUser,
  );
}

/// Scriptable [AppCheckVerifier]: accepts exactly the tokens in
/// [validTokens] (mapping token -> appId), throws on everything else.
class FakeAppCheckVerifier implements AppCheckVerifier {
  FakeAppCheckVerifier(this.validTokens);

  final Map<String, String> validTokens;

  /// Tokens this verifier was asked to check, in order.
  final List<String> seenTokens = [];

  @override
  Future<String> verifyToken(String token) async {
    seenTokens.add(token);
    final appId = validTokens[token];
    if (appId == null) {
      throw Exception('FakeAppCheckVerifier: unknown App Check token.');
    }
    return appId;
  }
}
