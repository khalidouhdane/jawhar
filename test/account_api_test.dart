// `DELETE /v1/me` client (§5 #11): API-first account deletion with a
// null-result contract — every "API not available" condition returns null so
// CloudSyncService.deleteAccount falls back to the legacy client-side
// cascade, and a 200 reports whether the server also deleted the Auth user.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quran_app/services/account_api.dart';

void main() {
  late List<http.Request> requests;

  AccountApi api({
    required Future<http.Response> Function(http.Request) handler,
    Future<String?> Function({bool forceRefresh})? idTokenProvider,
  }) {
    return AccountApi(
      idTokenProvider:
          idTokenProvider ??
          ({bool forceRefresh = false}) async =>
              forceRefresh ? 'fresh-token' : 'stale-token',
      apiBaseUrl: 'https://api.test',
      httpClient: MockClient((request) async {
        requests.add(request);
        return handler(request);
      }),
    );
  }

  http.Response ok({bool authUserDeleted = true}) => http.Response(
    jsonEncode({
      'deleted': true,
      'uid': 'u1',
      'docsDeleted': 9,
      'authUserDeleted': authUserDeleted,
    }),
    200,
    headers: {'content-type': 'application/json'},
  );

  setUp(() {
    requests = [];
  });

  test('200 -> outcome with deleted + authUserDeleted parsed', () async {
    final outcome = await api(handler: (_) async => ok()).deleteAccount();

    expect(outcome, isNotNull);
    expect(outcome!.deleted, isTrue);
    expect(outcome.authUserDeleted, isTrue);
    expect(requests, hasLength(1));
    expect(requests.single.method, 'DELETE');
    expect(requests.single.url.path, '/v1/me');
    expect(requests.single.headers['Authorization'], 'Bearer stale-token');
  });

  test('200 with authUserDeleted:false survives the parse (client keeps '
      'user.delete() as step two)', () async {
    final outcome = await api(
      handler: (_) async => ok(authUserDeleted: false),
    ).deleteAccount();

    expect(outcome!.deleted, isTrue);
    expect(outcome.authUserDeleted, isFalse);
  });

  test('401 -> force-refreshed token, retried exactly once (§5 error rules)',
      () async {
    final outcome = await api(
      handler: (request) async =>
          request.headers['Authorization'] == 'Bearer fresh-token'
              ? ok()
              : http.Response('{"error":{"code":"unauthenticated"}}', 401),
    ).deleteAccount();

    expect(outcome, isNotNull);
    expect(requests, hasLength(2));
    expect(requests.last.headers['Authorization'], 'Bearer fresh-token');
  });

  test('persistent 401 -> null (fallback), no infinite retry', () async {
    final outcome = await api(
      handler: (_) async => http.Response('nope', 401),
    ).deleteAccount();

    expect(outcome, isNull);
    expect(requests, hasLength(2));
  });

  test('5xx -> null (caller falls back to client-side cascade)', () async {
    final outcome = await api(
      handler: (_) async => http.Response('boom', 502),
    ).deleteAccount();
    expect(outcome, isNull);
  });

  test('network error -> null, never throws', () async {
    final outcome = await api(
      handler: (_) async => throw http.ClientException('no route to host'),
    ).deleteAccount();
    expect(outcome, isNull);
  });

  test('unparseable 200 body -> null (treated as unreachable)', () async {
    final outcome = await api(
      handler: (_) async => http.Response('not json', 200),
    ).deleteAccount();
    expect(outcome, isNull);
  });

  test('no ID token (signed out / auth gone) -> null without any request',
      () async {
    final outcome = await api(
      handler: (_) async => ok(),
      idTokenProvider: ({bool forceRefresh = false}) async => null,
    ).deleteAccount();

    expect(outcome, isNull);
    expect(requests, isEmpty);
  });
}
