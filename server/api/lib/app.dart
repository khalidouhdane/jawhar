import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config.dart';
import 'gateway/firestore_gateway.dart';
import 'handlers/healthz.dart';
import 'middleware/auth.dart';
import 'middleware/request_logging.dart';
import 'observability/sentry.dart';

/// Builds the full shelf handler for jawhar-api.
///
/// Pipeline (outermost first): JSON request logging -> Sentry capture ->
/// router. `/healthz` is public; everything under `/v1/` sits behind
/// [firebaseAuthMiddleware] with the injected [TokenVerifier].
///
/// [gateway] is accepted now so the composition root is in place for the
/// Wave 2 handlers; the Wave 1 routes do not read Firestore yet.
Handler buildHandler({
  required Config config,
  required TokenVerifier verifier,
  FirestoreGateway? gateway,
  LogSink? logSink,
}) {
  final v1 = Router(notFoundHandler: _notFound)
    // Minimal authenticated probe: proves the token middleware end-to-end
    // (used by the R1 spike and, later, the hidden debug screen).
    ..get('/me/whoami', (Request request) {
      return Response.ok(
        jsonEncode({'uid': request.uid}),
        headers: const {'content-type': 'application/json'},
      );
    });

  final root = Router(notFoundHandler: _notFound)
    ..get('/healthz', healthzHandler(config))
    ..mount(
      '/v1',
      const Pipeline()
          .addMiddleware(firebaseAuthMiddleware(verifier))
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
