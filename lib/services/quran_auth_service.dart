import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:quran_app/config/api_config.dart';
import 'package:quran_app/services/api_client.dart';
import 'package:quran_app/utils/app_logger.dart';

/// QF *content* API token acquisition (cloud-first migration Phase 7).
///
/// Preferred path: `POST /v1/content/token` on jawhar-api with a Firebase
/// ID token — the client-credentials secret lives in Secret Manager on the
/// server, not in the binary.
///
/// Fallback path (KEPT ON PURPOSE): the historical direct
/// client-credentials exchange against `oauth2.quran.foundation`. It runs
/// whenever the user is signed out OR the endpoint is unreachable/not yet
/// deployed. **Consequence: `QURAN_API_CLIENT_SECRET` must keep shipping in
/// builds for now** — content (all Quran text/audio) must work for
/// signed-out users, and Firebase sign-in is optional in this app. The
/// secret can only leave the binary once signed-out content traffic has a
/// server-side path that needs no Firebase identity (e.g. an
/// unauthenticated, rate-limited token route or proxy-attached tokens).
class QuranAuthService {
  static const String _clientId = String.fromEnvironment('QURAN_API_CLIENT_ID');
  static const String _clientSecret = String.fromEnvironment(
    'QURAN_API_CLIENT_SECRET',
  );
  static const String _authUrl = String.fromEnvironment(
    'QURAN_API_AUTH_URL',
    defaultValue: 'https://oauth2.quran.foundation/oauth2/token',
  );

  static String? _cachedToken;
  static DateTime? _tokenExpiry;
  static Future<String>? _tokenFetchFuture;

  /// Test seams (debug/test builds set these; production never does).
  static Future<String?> Function()? idTokenProviderOverride;
  static http.Client? httpClientOverride;
  static String? apiBaseUrlOverride;

  static String get clientId => _clientId;

  static String get _apiBaseUrl {
    final raw = apiBaseUrlOverride ?? kJawharApiBaseUrl;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  /// Retrieves a valid OAuth token. If the token is missing or expired,
  /// it fetches a new one. Handles concurrent requests by sharing the same future.
  static Future<String> getValidToken() async {
    // Check if we have a valid cached token (buffer of 60 seconds before expiry)
    if (_cachedToken != null && _tokenExpiry != null) {
      if (DateTime.now().isBefore(
        _tokenExpiry!.subtract(const Duration(seconds: 60)),
      )) {
        return _cachedToken!;
      }
    }

    // If a fetch is already in progress, await it to prevent stampedes
    if (_tokenFetchFuture != null) {
      return _tokenFetchFuture!;
    }

    // Start a new fetch
    _tokenFetchFuture = _fetchNewToken();
    try {
      final token = await _tokenFetchFuture!;
      return token;
    } finally {
      // Clear the future once complete (whether success or error)
      _tokenFetchFuture = null;
    }
  }

  static Future<String> _fetchNewToken() async {
    // 1. Server-side exchange via jawhar-api — only possible with a
    //    Firebase identity (the endpoint is authenticated, §5 #12).
    final viaServer = await _fetchTokenViaServer();
    if (viaServer != null) return viaServer;

    // 2. Graceful fallback: the historical direct exchange. Required for
    //    signed-out reading and for endpoint outages.
    return _fetchTokenDirect();
  }

  /// Attempts `POST /v1/content/token`. Returns null (→ fallback) when the
  /// user is signed out, no base URL is configured, or the call fails in
  /// any way — content loading must never depend on jawhar-api liveness.
  static Future<String?> _fetchTokenViaServer() async {
    final base = _apiBaseUrl;
    if (base.isEmpty) return null;

    String? idToken;
    try {
      idToken = idTokenProviderOverride != null
          ? await idTokenProviderOverride!()
          : await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (e) {
      AppLogger.info('QuranAuth', 'ID token unavailable: $e');
      return null;
    }
    if (idToken == null || idToken.isEmpty) return null; // signed out

    final client = httpClientOverride ?? http.Client();
    try {
      final response = await client
          .post(
            Uri.parse('$base/v1/content/token'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        AppLogger.info(
          'QuranAuth',
          'content/token HTTP ${response.statusCode}; falling back to '
              'direct exchange',
        );
        return null;
      }
      final data = json.decode(response.body);
      if (data is! Map<String, dynamic>) return null;
      // Lenient field names: access_token (OAuth convention) or token.
      final token = (data['access_token'] ?? data['token']) as String?;
      if (token == null || token.isEmpty) return null;
      // The server's actual wire shape is {token, expiresAt: ISO-8601,
      // expiresIn, clientId} — and crucially `expiresAt` is the REMAINING
      // life of the server-cached QF token (as little as ~60s near its
      // refresh edge), so it is the primary expiry source. Defaulting to
      // 3600s when only seconds-fields are absent would cache a nearly-dead
      // token for an hour and break all content loading until it "expired".
      DateTime? expiry;
      final expiresAtRaw = data['expiresAt'] ?? data['expires_at'];
      if (expiresAtRaw is String) {
        final parsed = DateTime.tryParse(expiresAtRaw);
        if (parsed != null) expiry = parsed.toLocal();
      }
      if (expiry == null) {
        final expiresIn =
            (data['expires_in'] ?? data['expiresIn']) as num? ?? 3600;
        expiry = DateTime.now().add(Duration(seconds: expiresIn.toInt()));
      }
      _cachedToken = token;
      _tokenExpiry = expiry;
      AppLogger.info(
        'QuranAuth',
        'Content token acquired via jawhar-api. Expires at $_tokenExpiry',
      );
      return token;
    } catch (e) {
      AppLogger.info(
        'QuranAuth',
        'content/token unreachable ($e); falling back to direct exchange',
      );
      return null;
    } finally {
      if (httpClientOverride == null) client.close();
    }
  }

  /// The historical direct client-credentials exchange (fallback path).
  static Future<String> _fetchTokenDirect() async {
    try {
      AppLogger.info('QuranAuth', 'Fetching new Quran API OAuth Token...');
      final authStr = base64Encode(utf8.encode('$_clientId:$_clientSecret'));

      // Use ApiClient.post() for retry + SSL error recovery.
      // This handles SSLV3_ALERT_BAD_RECORD_MAC by resetting the
      // HTTP client and retrying with a fresh TLS handshake.
      final response = await ApiClient.post(
        Uri.parse(_authUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $authStr',
        },
        body: 'grant_type=client_credentials&scope=content',
        timeout: const Duration(seconds: 10),
        maxRetries: 3,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedToken = data['access_token'];
        // expire in response is usually 3600 (1 hour)
        final expiresInSeconds = data['expires_in'] ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresInSeconds));

        AppLogger.info(
          'QuranAuth',
          'OAuth token acquired. Expires at $_tokenExpiry',
        );
        return _cachedToken!;
      } else {
        throw Exception(
          'Failed to fetch OAuth token: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.info('QuranAuth', 'QuranAuthService Error: $e');
      rethrow;
    }
  }

  /// Drops the cached token (e.g. after a 401 from a content host) so the
  /// next [getValidToken] fetches a fresh one — defense in depth against a
  /// cached-but-already-expired token.
  static void invalidateToken() {
    _cachedToken = null;
    _tokenExpiry = null;
  }

  /// Sets a token manually for testing purposes.
  static void setTestToken(String token) {
    _cachedToken = token;
    _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
  }

  /// Clears all cached/test state (testing only).
  static void resetForTest() {
    _cachedToken = null;
    _tokenExpiry = null;
    _tokenFetchFuture = null;
    idTokenProviderOverride = null;
    httpClientOverride = null;
    apiBaseUrlOverride = null;
  }
}
