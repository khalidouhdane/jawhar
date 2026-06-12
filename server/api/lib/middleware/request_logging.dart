import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

import 'app_check.dart';
import 'auth.dart';

/// Sink for structured log lines; injectable for tests (defaults to stdout).
typedef LogSink = void Function(String line);

/// Structured JSON request logging in the Cloud Logging special-fields format
/// (`severity`, `message`, `httpRequest`, `time`) — one JSON object per line
/// on stdout, which Cloud Run forwards to Cloud Logging verbatim.
///
/// Never logs headers (so never the Authorization header). Logs the verified
/// uid and the App Check verdict when the inner middleware has populated
/// them — read from the RESPONSE context: this logger is outermost, so it
/// holds the original request object and can only see what inner middleware
/// attached via the response propagating back out (`request.change` produces
/// a new request the outer layers never observe).
Middleware jsonRequestLogger({LogSink? sink}) {
  final LogSink write = sink ?? stdout.writeln;
  return (Handler inner) {
    return (Request request) async {
      final watch = Stopwatch()..start();
      Response? response;
      Object? error;
      try {
        response = await inner(request);
        return response;
      } catch (e) {
        error = e;
        rethrow;
      } finally {
        watch.stop();
        final status = response?.statusCode ?? 500;
        final entry = <String, Object?>{
          'severity': error != null
              ? 'ERROR'
              : status >= 500
                  ? 'ERROR'
                  : status >= 400
                      ? 'WARNING'
                      : 'INFO',
          'message':
              '${request.method} /${request.url.path} -> $status '
              '(${watch.elapsedMilliseconds}ms)',
          'time': DateTime.now().toUtc().toIso8601String(),
          'httpRequest': {
            'requestMethod': request.method,
            'requestUrl': '/${request.url.path}',
            'status': status,
            'latency': '${(watch.elapsedMicroseconds / 1e6).toStringAsFixed(6)}s',
            if (request.headers['user-agent'] != null)
              'userAgent': request.headers['user-agent'],
          },
          if (response?.context[uidContextKey] != null)
            'uid': response?.context[uidContextKey]
          else if (request.context[uidContextKey] != null)
            'uid': request.context[uidContextKey],
          if (response?.context[appCheckContextKey] != null)
            'appCheck': response?.context[appCheckContextKey],
          if (error != null) 'error': error.toString(),
        };
        write(jsonEncode(entry));
      }
    };
  };
}
