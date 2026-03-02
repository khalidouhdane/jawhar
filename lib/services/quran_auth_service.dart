import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class QuranAuthService {
  static const String _clientId = '879421dc-68cb-4a1d-a500-c060d10478e6';
  static const String _clientSecret = 'cKEt~daJ4tgXiJ1td0t4JwBB_z';
  static const String _authUrl = 'https://oauth2.quran.foundation/oauth2/token';

  static String? _cachedToken;
  static DateTime? _tokenExpiry;
  static Future<String>? _tokenFetchFuture;

  static String get clientId => _clientId;

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
    try {
      debugPrint('Fetching new Quran API OAuth Token...');
      final authStr = base64Encode(utf8.encode('$_clientId:$_clientSecret'));

      final response = await http.post(
        Uri.parse(_authUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic $authStr',
        },
        body: 'grant_type=client_credentials&scope=content',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cachedToken = data['access_token'];
        // expire in response is usually 3600 (1 hour)
        final expiresInSeconds = data['expires_in'] ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresInSeconds));

        debugPrint('OAuth token acquired. Expires at $_tokenExpiry');
        return _cachedToken!;
      } else {
        throw Exception(
          'Failed to fetch OAuth token: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('QuranAuthService Error: $e');
      rethrow;
    }
  }
}
