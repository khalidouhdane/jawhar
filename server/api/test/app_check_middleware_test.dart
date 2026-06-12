// LOG-ONLY App Check middleware (roadmap §8 Phase 8 task 3 / §9): the
// verdict (verified / invalid / absent / unverifiable) is attached to the
// structured request log, and NO verdict ever rejects a request — that is
// the contract this suite pins down before any enforcement runbook exists.

import 'dart:async';
import 'dart:convert';

import 'package:jawhar_api/middleware/app_check.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/test_app.dart';

/// Simulates a JWKS fetch that hangs forever (cold start / key expiry with
/// an unresponsive googleapis endpoint — the un-timeouted HTTP path inside
/// the Admin SDK).
class _HangingVerifier implements AppCheckVerifier {
  @override
  Future<String> verifyToken(String token) => Completer<String>().future;
}

void main() {
  late List<String> logLines;

  Map<String, dynamic> singleLogEntry() {
    expect(logLines, hasLength(1));
    return jsonDecode(logLines.single) as Map<String, dynamic>;
  }

  setUp(() {
    logLines = [];
  });

  Handler handlerWith({FakeAppCheckVerifier? verifier}) => buildTestHandler(
        logSink: logLines.add,
        appCheckVerifier: verifier,
      );

  Request whoami({String? appCheckToken}) => Request(
        'GET',
        Uri.parse('http://localhost/v1/me/whoami'),
        headers: {
          'authorization': 'Bearer $testToken',
          'x-firebase-appcheck': ?appCheckToken,
        },
      );

  test('no X-Firebase-AppCheck header -> 200, verdict "absent"', () async {
    final verifier = FakeAppCheckVerifier({'ac-token': 'app-1'});
    final response = await handlerWith(verifier: verifier)(whoami());

    expect(response.statusCode, 200);
    expect(singleLogEntry()['appCheck'], 'absent');
    expect(verifier.seenTokens, isEmpty,
        reason: 'nothing to verify without a header');
  });

  test('valid token -> 200, verdict "verified"', () async {
    final verifier = FakeAppCheckVerifier({'ac-token': 'app-1'});
    final response =
        await handlerWith(verifier: verifier)(whoami(appCheckToken: 'ac-token'));

    expect(response.statusCode, 200);
    expect(singleLogEntry()['appCheck'], 'verified');
    expect(verifier.seenTokens, ['ac-token']);
  });

  test('INVALID token -> STILL 200 (log-only, never rejects), '
      'verdict "invalid"', () async {
    final verifier = FakeAppCheckVerifier({'ac-token': 'app-1'});
    final response = await handlerWith(verifier: verifier)(
      whoami(appCheckToken: 'forged-garbage'),
    );

    expect(response.statusCode, 200,
        reason: 'enforcement is a post-soak runbook step — the middleware '
            'must never turn a verdict into a rejection');
    final entry = singleLogEntry();
    expect(entry['appCheck'], 'invalid');
    expect(entry['uid'], testUid,
        reason: 'auth still ran normally; the uid reaches the log');
  });

  test('header present but no verifier wired -> 200, "unverifiable"',
      () async {
    final response =
        await handlerWith(verifier: null)(whoami(appCheckToken: 'ac-token'));

    expect(response.statusCode, 200);
    expect(singleLogEntry()['appCheck'], 'unverifiable');
  });

  test('verdict is logged even on 401s (middleware sits before auth)',
      () async {
    final verifier = FakeAppCheckVerifier({'ac-token': 'app-1'});
    final response = await handlerWith(verifier: verifier)(
      Request(
        'GET',
        Uri.parse('http://localhost/v1/me/whoami'),
        headers: {'x-firebase-appcheck': 'ac-token'}, // no Authorization
      ),
    );

    expect(response.statusCode, 401);
    final entry = singleLogEntry();
    expect(entry['appCheck'], 'verified');
    expect(entry.containsKey('uid'), isFalse);
  });

  test('verified uid now reaches the request log via the response context',
      () async {
    final response = await handlerWith()(whoami());
    expect(response.statusCode, 200);
    expect(singleLogEntry()['uid'], testUid);
  });

  test('a HANGING verifier cannot stall the request: bounded by the verify '
      'timeout, verdict "unverifiable"', () async {
    // Verification is local crypto only while the JWKS cache is warm; on
    // cold start / 6-hourly expiry it is an un-timeouted HTTP fetch. A
    // log-only middleware must never add unbounded latency to the hot path.
    final middleware = appCheckLogOnly(
      _HangingVerifier(),
      verifyTimeout: const Duration(milliseconds: 50),
    );
    final handler = middleware((request) async => Response.ok('inner ran'));

    final watch = Stopwatch()..start();
    final response = await handler(Request(
      'GET',
      Uri.parse('http://localhost/v1/me/whoami'),
      headers: {'x-firebase-appcheck': 'ac-token'},
    ));
    watch.stop();

    expect(response.statusCode, 200);
    expect(await response.readAsString(), 'inner ran');
    expect(response.context[appCheckContextKey], 'unverifiable',
        reason: 'timeout means "no verdict produced", not "invalid"');
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)),
        reason: 'the hanging verifier must not block the request');
  });
}
