import 'dart:io';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:jawhar_api/ai/vertex_client.dart';
import 'package:jawhar_api/app.dart';
import 'package:jawhar_api/auth/admin_sdk_app_check_verifier.dart';
import 'package:jawhar_api/auth/admin_sdk_token_verifier.dart';
import 'package:jawhar_api/auth/admin_sdk_user_deleter.dart';
import 'package:jawhar_api/config.dart';
import 'package:jawhar_api/content/content_token_service.dart';
import 'package:jawhar_api/gateway/firestore_gateway.dart';
import 'package:jawhar_api/observability/sentry.dart';
import 'package:jawhar_api/quota/ai_quota.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final config = Config.fromEnvironment();

  await initSentry(config.sentryDsn, gitSha: config.gitSha);

  // One-shot observability canary: when SENTRY_CANARY is set, capture a
  // single synthetic exception at startup, log its Sentry event id, and
  // serve normally. Operate via
  //   gcloud run services update jawhar-api \
  //     --update-env-vars SENTRY_CANARY=<label>
  // and REMOVE the var (--remove-env-vars SENTRY_CANARY) once the event is
  // verified in Sentry — each instance start fires one event while set.
  final canaryLabel = Platform.environment['SENTRY_CANARY'];
  if (canaryLabel != null && canaryLabel.isNotEmpty) {
    final canaryEventId = await captureCanaryException(canaryLabel);
    stdout.writeln(
      '{"severity":"WARNING","message":"SENTRY_CANARY fired: '
      'label=$canaryLabel eventId=$canaryEventId"}',
    );
  }

  // On Cloud Run the SDK uses Application Default Credentials (metadata
  // server); against the local emulator no credentials are needed.
  final app = FirebaseApp.initializeApp(
    options: AppOptions(projectId: config.projectId),
  );

  // Production verifier, pinned: Google-published certs, aud == projectId.
  // No code path in this entrypoint can swap in a test verifier.
  final verifier = AdminSdkTokenVerifier(
    app,
    expectedProjectId: config.projectId,
  );
  final gateway = FirestoreGateway.forApp(app);

  // Vertex AI on the global endpoint via the runtime service account (ADC) —
  // no API key anywhere (roadmap §4.4).
  final vertex = VertexClient(projectId: config.projectId);
  final aiQuota = FirestoreAiQuota(gateway, dailyLimit: config.aiDailyQuota);

  // QF content-token exchange (§5 #12): credentials come from env /
  // Secret Manager; without them the endpoint answers 503.
  final contentTokens = ContentTokenService(config: config);

  // LOG-ONLY App Check (§8 Phase 8 task 3): verdicts go to the request log,
  // nothing is ever rejected. Enforcement is a post-soak runbook step.
  final appCheckVerifier = AdminSdkAppCheckVerifier(app);

  // DELETE /v1/me auth half (§5 #11) — idempotent Admin-SDK user deletion.
  final userDeleter = AdminSdkUserDeleter(app);

  final handler = buildHandler(
    config: config,
    verifier: verifier,
    vertex: vertex,
    aiQuota: aiQuota,
    gateway: gateway,
    contentTokens: contentTokens,
    appCheckVerifier: appCheckVerifier,
    deleteAuthUser: userDeleter.call,
  );

  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4,
    config.port,
  );
  server.autoCompress = true;

  stdout.writeln(
    '{"severity":"INFO","message":"jawhar-api listening on '
    ':${config.port} (gitSha=${config.gitSha}, model=${config.modelId}, '
    'emulator=${FirestoreGateway.isUsingEmulator})"}',
  );

  // Graceful shutdown so Sentry can flush.
  ProcessSignal.sigterm.watch().listen((_) async {
    await server.close();
    vertex.close();
    contentTokens.close();
    await closeSentry();
    await app.close();
    exit(0);
  });
}
