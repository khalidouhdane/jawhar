import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:quran_app/config/api_config.dart';
import 'package:quran_app/utils/app_logger.dart';

/// Outcome of a `DELETE /v1/me` round-trip that reached the server.
class AccountDeleteOutcome {
  /// The server deleted the caller's Firestore tree.
  final bool deleted;

  /// The server also deleted the Firebase Auth user. When false the client
  /// must keep its own `user.delete()` as step two (§5 #11 fallback split).
  final bool authUserDeleted;

  const AccountDeleteOutcome({
    required this.deleted,
    required this.authUserDeleted,
  });
}

/// Thin client for `DELETE /v1/me` (roadmap §5 #11) — account + cascade
/// deletion moves server-side, where it survives the Phase 8 deny-all rules
/// flip that kills the legacy client-side Firestore cascade.
///
/// Deliberately returns **null** (instead of throwing) on every "the API
/// path is not available" condition — no base URL, no token, network error,
/// timeout, non-200 — so the caller's contract is a simple
/// "null → fall back to the legacy client-side deletion".
class AccountApi {
  final String _baseUrl;
  final http.Client? _injectedClient;
  final Future<String?> Function({bool forceRefresh}) _idTokenProvider;
  final Duration _requestTimeout;

  AccountApi({
    required Future<String?> Function({bool forceRefresh}) idTokenProvider,
    String? apiBaseUrl,
    http.Client? httpClient,
    Duration requestTimeout = const Duration(seconds: 20),
  }) : _idTokenProvider = idTokenProvider,
       _injectedClient = httpClient,
       _baseUrl = _normalizeBase(apiBaseUrl ?? kJawharApiBaseUrl),
       _requestTimeout = requestTimeout;

  static String _normalizeBase(String raw) =>
      raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;

  /// Attempts the server-side account deletion. Returns the parsed outcome
  /// on HTTP 200, null when the API was unreachable or refused (caller
  /// falls back to the legacy client-side cascade). A 401 is retried once
  /// with a force-refreshed ID token (§5 error rules).
  Future<AccountDeleteOutcome?> deleteAccount() async {
    if (_baseUrl.isEmpty) return null;
    var token = await _token();
    if (token == null) return null;

    final client = _injectedClient ?? http.Client();
    try {
      var response = await _send(client, token);
      if (response.statusCode == 401) {
        token = await _token(forceRefresh: true);
        if (token == null) return null;
        response = await _send(client, token);
      }

      if (response.statusCode != 200) {
        AppLogger.warn(
          'Account',
          'DELETE /v1/me -> HTTP ${response.statusCode}; '
              'falling back to client-side deletion',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return AccountDeleteOutcome(
        deleted: decoded['deleted'] == true,
        authUserDeleted: decoded['authUserDeleted'] == true,
      );
    } catch (e) {
      // Network / timeout / parse — API unreachable, use the fallback.
      AppLogger.warn('Account', 'DELETE /v1/me failed: $e');
      return null;
    } finally {
      if (_injectedClient == null) client.close();
    }
  }

  Future<http.Response> _send(http.Client client, String token) {
    return client
        .delete(
          Uri.parse('$_baseUrl/v1/me'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(_requestTimeout);
  }

  Future<String?> _token({bool forceRefresh = false}) async {
    try {
      final token = await _idTokenProvider(forceRefresh: forceRefresh);
      return (token == null || token.isEmpty) ? null : token;
    } catch (e) {
      AppLogger.warn('Account', 'ID token fetch failed: $e');
      return null;
    }
  }
}
