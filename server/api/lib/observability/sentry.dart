import 'package:sentry/sentry.dart';
import 'package:shelf/shelf.dart';

bool _sentryEnabled = false;

/// Initializes Sentry when [dsn] is set; a strict no-op when it is null
/// (roadmap §4.11: DSN from env, no-op when unset).
Future<void> initSentry(
  String? dsn, {
  required String gitSha,
  String environment = 'production',
}) async {
  if (dsn == null || dsn.isEmpty) {
    _sentryEnabled = false;
    return;
  }
  await Sentry.init((options) {
    options.dsn = dsn;
    options.release = 'jawhar-api@$gitSha';
    options.environment = environment;
    options.tracesSampleRate = 0;
  });
  _sentryEnabled = true;
}

/// Reports [error] to Sentry when initialized; no-op otherwise.
Future<void> reportError(Object error, StackTrace stackTrace) async {
  if (!_sentryEnabled) return;
  await Sentry.captureException(error, stackTrace: stackTrace);
}

/// Captures one synthetic canary exception and returns its Sentry event id
/// (the empty id `00000000000000000000000000000000` when Sentry is disabled
/// or the send failed). Backs the SENTRY_CANARY startup hook in
/// `bin/server.dart` — proves the Sentry pipeline end-to-end against the
/// LIVE service (roadmap §8 Phase 2 task 4 exit criterion).
Future<String> captureCanaryException(String label) async {
  if (!_sentryEnabled) return SentryId.empty().toString();
  final id = await Sentry.captureException(
    StateError('jawhar-api Sentry canary: $label'),
    stackTrace: StackTrace.current,
  );
  return id.toString();
}

/// Flushes and closes Sentry (call on shutdown). No-op when disabled.
Future<void> closeSentry() async {
  if (!_sentryEnabled) return;
  await Sentry.close();
  _sentryEnabled = false;
}

/// Middleware that reports any uncaught handler exception to Sentry and
/// rethrows so shelf still produces the 500 (and the JSON logger logs it).
Middleware sentryMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      try {
        return await inner(request);
      } catch (e, st) {
        await reportError(e, st);
        rethrow;
      }
    };
  };
}
