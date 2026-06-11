import 'dart:convert';

import 'package:jawhar_api/middleware/auth.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/static_token_verifier.dart';

void main() {
  late StaticTokenVerifier verifier;
  late Handler guarded;
  late List<String> uidsSeenByInner;

  setUp(() {
    verifier = StaticTokenVerifier({
      'good-token': const VerifiedToken(uid: 'uid-123'),
      'empty-uid-token': const VerifiedToken(uid: ''),
    });
    uidsSeenByInner = [];
    guarded = const Pipeline()
        .addMiddleware(firebaseAuthMiddleware(verifier))
        .addHandler((request) {
      uidsSeenByInner.add(request.uid);
      return Response.ok('inner:${request.uid}');
    });
  });

  Request req({String? authorization}) => Request(
        'GET',
        Uri.parse('http://localhost/v1/me/whoami'),
        headers: {'authorization': ?authorization},
      );

  Map<String, dynamic> errorBody(String body) =>
      (jsonDecode(body) as Map<String, dynamic>)['error']
          as Map<String, dynamic>;

  test('missing Authorization header -> 401, inner never runs', () async {
    final response = await guarded(req());
    expect(response.statusCode, 401);
    final error = errorBody(await response.readAsString());
    expect(error['code'], 'unauthenticated');
    expect(error['retryable'], false);
    expect(uidsSeenByInner, isEmpty);
    expect(verifier.seenTokens, isEmpty);
  });

  test('non-Bearer scheme -> 401 without calling the verifier', () async {
    final response = await guarded(req(authorization: 'Basic abc'));
    expect(response.statusCode, 401);
    expect(verifier.seenTokens, isEmpty);
    expect(uidsSeenByInner, isEmpty);
  });

  test('empty bearer token -> 401 without calling the verifier', () async {
    final response = await guarded(req(authorization: 'Bearer '));
    expect(response.statusCode, 401);
    expect(verifier.seenTokens, isEmpty);
  });

  test('rejected token -> 401 with error envelope', () async {
    final response = await guarded(req(authorization: 'Bearer forged'));
    expect(response.statusCode, 401);
    expect(verifier.seenTokens, ['forged']);
    final error = errorBody(await response.readAsString());
    expect(error['code'], 'unauthenticated');
    expect(uidsSeenByInner, isEmpty);
  });

  test('valid token -> inner runs with uid from the token only', () async {
    final response = await guarded(req(authorization: 'Bearer good-token'));
    expect(response.statusCode, 200);
    expect(await response.readAsString(), 'inner:uid-123');
    expect(uidsSeenByInner, ['uid-123']);
  });

  test('verified-but-empty uid -> 401 (uid is load-bearing)', () async {
    final response =
        await guarded(req(authorization: 'Bearer empty-uid-token'));
    expect(response.statusCode, 401);
    expect(uidsSeenByInner, isEmpty);
  });

  test('request.uid throws when middleware did not run', () {
    final bare = Request('GET', Uri.parse('http://localhost/x'));
    expect(() => bare.uid, throwsStateError);
  });
}
