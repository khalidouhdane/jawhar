import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// A QF Content API access token with its expiry instant (UTC).
class ContentToken {
  const ContentToken({required this.token, required this.expiresAtUtc});

  final String token;
  final DateTime expiresAtUtc;
}

/// Thrown when the upstream QF token exchange fails. [message] is safe to
/// surface (status code + generic phrasing — never the upstream body, which
/// could echo credentials-adjacent details, and never the secret).
class ContentTokenException implements Exception {
  ContentTokenException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Server-side QF Content API client-credentials exchange (roadmap §5 #12 /
/// §8 Phase 7 task 1) — the move that evicts `QURAN_API_CLIENT_SECRET` from
/// every client binary.
///
/// Mirrors the client's `QuranAuthService` semantics exactly:
/// `grant_type=client_credentials&scope=content` with HTTP Basic auth
/// against `Config.quranAuthUrl`; the token is cached until 60s before
/// expiry and concurrent callers share one in-flight fetch (no stampede —
/// QF tokens live ~3600s, one exchange per hour per instance).
///
/// The secret only ever exists as a process env var injected from Secret
/// Manager (`--update-secrets`); it is never logged and never appears in
/// any error message.
class ContentTokenService {
  ContentTokenService({
    required Config config,
    http.Client? httpClient,
    DateTime Function()? nowUtc,
  })  : _clientId = config.quranClientId,
        _clientSecret = config.quranClientSecret,
        _authUrl = config.quranAuthUrl,
        _injectedClient = httpClient,
        _now = nowUtc ?? _utcNow;

  final String? _clientId;
  final String? _clientSecret;
  final String _authUrl;
  final http.Client? _injectedClient;
  final DateTime Function() _now;

  http.Client? _ownedClient;
  ContentToken? _cached;
  Future<ContentToken>? _inFlight;

  /// Whether the deployment carries QF credentials at all. When false the
  /// handler answers 503 — the endpoint is configured out, not broken.
  bool get isConfigured =>
      _clientId != null &&
      _clientId.isNotEmpty &&
      _clientSecret != null &&
      _clientSecret.isNotEmpty;

  /// The public client id (the Content API requires it as `x-client-id`
  /// alongside the token; it is an identifier, not a secret).
  String? get clientId => _clientId;

  http.Client get _client => _injectedClient ?? (_ownedClient ??= http.Client());

  /// Returns a valid token, from cache when it has >60s of life left.
  Future<ContentToken> getToken() {
    final cached = _cached;
    if (cached != null &&
        _now().isBefore(
          cached.expiresAtUtc.subtract(const Duration(seconds: 60)),
        )) {
      return Future.value(cached);
    }
    // Single-flight: concurrent expiries share one exchange.
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  Future<ContentToken> _fetch() async {
    if (!isConfigured) {
      throw ContentTokenException('QF content credentials are not configured.');
    }
    final basic = base64Encode(utf8.encode('$_clientId:$_clientSecret'));

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_authUrl),
            headers: {
              'content-type': 'application/x-www-form-urlencoded',
              'authorization': 'Basic $basic',
            },
            body: 'grant_type=client_credentials&scope=content',
          )
          .timeout(const Duration(seconds: 10));
    } on ContentTokenException {
      rethrow;
    } on Object catch (e) {
      // Transport failure: e's text never contains the secret (it is not
      // part of the URL and httplib exceptions carry the URI, not headers).
      throw ContentTokenException('QF token exchange failed: $e');
    }

    if (response.statusCode != 200) {
      throw ContentTokenException(
        'QF token endpoint answered HTTP ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw ContentTokenException('QF token endpoint returned non-JSON.');
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['access_token'] is! String) {
      throw ContentTokenException(
        'QF token endpoint returned an unexpected shape.',
      );
    }
    final expiresIn = decoded['expires_in'];
    final seconds = expiresIn is int ? expiresIn : 3600;
    final token = ContentToken(
      token: decoded['access_token'] as String,
      expiresAtUtc: _now().add(Duration(seconds: seconds)),
    );
    _cached = token;
    return token;
  }

  /// Closes the lazily-created HTTP client (injected clients belong to the
  /// caller).
  void close() {
    _ownedClient?.close();
    _ownedClient = null;
  }
}

DateTime _utcNow() => DateTime.now().toUtc();
