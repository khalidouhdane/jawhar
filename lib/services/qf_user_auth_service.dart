import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/utils/app_logger.dart';

/// Handles OAuth2 Authorization Code + PKCE flow for Quran Foundation User APIs.
///
/// This is the user-level authentication service, distinct from [QuranAuthService]
/// which handles app-level client_credentials for Content APIs.
///
/// Flow:
/// 1. Starts a local HTTP server on a random port (desktop loopback)
/// 2. Opens the system browser to QF's consent screen
/// 3. QF redirects back to localhost with an auth code
/// 4. Exchanges the auth code + code_verifier for access + refresh + id tokens
/// 5. Stores tokens in SharedPreferences
/// 6. Returns access_token for User API calls
class QfUserAuthService extends ChangeNotifier {
  // ── Credentials injected via --dart-define-from-file=.env ──
  static const _clientId = String.fromEnvironment('QURAN_PREPROD_CLIENT_ID');
  static const _clientSecret = String.fromEnvironment(
    'QURAN_PREPROD_CLIENT_SECRET',
  );

  // ── Pre-live OAuth2 endpoints (from OIDC discovery) ──
  static const _authEndpoint =
      'https://prelive-oauth2.quran.foundation/oauth2/auth';
  static const _tokenEndpoint =
      'https://prelive-oauth2.quran.foundation/oauth2/token';
  static const _revokeEndpoint =
      'https://prelive-oauth2.quran.foundation/oauth2/revoke';
  // ignore: unused_field — kept for future production logout flow
  static const _logoutEndpoint =
      'https://prelive-oauth2.quran.foundation/oauth2/sessions/logout';

  /// Scopes for user-level access.
  /// - `openid`: Required for OIDC id_token
  /// - `offline_access`: Enables refresh_token
  /// - `user`: Access to user data (bookmarks, reading sessions, goals, streaks)
  /// - `collection`: Access to user collections
  static const _scopes = 'openid offline_access user collection';

  /// Fixed loopback port for OAuth redirect URI.
  /// QF whitelisted http://localhost:3000/callback for our client.
  static const _loopbackPort = 3000;

  // ── SharedPreferences keys ──
  static const _keyAccessToken = 'qf_access_token';
  static const _keyRefreshToken = 'qf_refresh_token';
  static const _keyIdToken = 'qf_id_token';
  static const _keyTokenExpiry = 'qf_token_expiry';
  static const _keyUserSub = 'qf_user_sub';

  /// The public client ID accessor for API calls.
  static String get clientId => _clientId;

  // ── State ──
  String? _accessToken;
  String? _refreshToken;
  String? _idToken;
  DateTime? _tokenExpiry;
  String? _userSub;
  bool _isSigningIn = false;

  /// Whether the user is currently signed in with a QF account.
  bool get isSignedIn => _accessToken != null && !_isTokenExpired;

  /// Whether a sign-in flow is in progress.
  bool get isSigningIn => _isSigningIn;

  /// The stable user identifier from the id_token `sub` claim.
  /// Use this as the foreign key to link QF user data to local data.
  String? get userSub => _userSub;

  bool get _isTokenExpired {
    if (_tokenExpiry == null) return true;
    // Consider expired 60 seconds early to avoid edge cases
    return DateTime.now().isAfter(
      _tokenExpiry!.subtract(const Duration(seconds: 60)),
    );
  }

  /// Initialize from stored tokens on app startup.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_keyAccessToken);
    _refreshToken = prefs.getString(_keyRefreshToken);
    _idToken = prefs.getString(_keyIdToken);
    _userSub = prefs.getString(_keyUserSub);

    final expiryMs = prefs.getInt(_keyTokenExpiry);
    if (expiryMs != null) {
      _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(expiryMs);
    }

    if (_accessToken != null) {
      AppLogger.info(
        'QfAuth',
        '[QF_AUTH] Restored session for user: $_userSub',
      );
      if (_isTokenExpired && _refreshToken != null) {
        AppLogger.info(
          'QfAuth',
          '[QF_AUTH] Token expired, attempting refresh...',
        );
        await refreshAccessToken();
      }
    }

    notifyListeners();
  }

  /// Returns a valid access token, refreshing if needed.
  /// Returns null if the user is not signed in.
  Future<String?> getValidAccessToken() async {
    if (_accessToken == null) return null;

    if (_isTokenExpired) {
      if (_refreshToken != null) {
        final success = await refreshAccessToken();
        if (!success) return null;
      } else {
        return null;
      }
    }

    return _accessToken;
  }

  // ══════════════════════════════════════════════════════════════════════
  // Sign In — Desktop Loopback OAuth2 + PKCE
  // ══════════════════════════════════════════════════════════════════════

  /// Initiates the OAuth2 sign-in flow.
  ///
  /// Opens the system browser to QF's consent screen, waits for the
  /// redirect on a local loopback server, and exchanges the auth code
  /// for tokens.
  ///
  /// Returns `true` if sign-in was successful.
  Future<bool> signIn() async {
    if (_isSigningIn) return false;
    _isSigningIn = true;
    notifyListeners();

    HttpServer? server;
    try {
      // 1. Start local HTTP server on port 3000
      //    (QF whitelisted http://localhost:3000/callback)
      try {
        server = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          _loopbackPort,
        );
      } on SocketException catch (e) {
        AppLogger.info(
          'QfAuth',
          '[QF_AUTH] Port $_loopbackPort is in use. '
              'Stop the website dev server first, then try again. Error: $e',
        );
        return false;
      }
      final redirectUri = 'http://localhost:$_loopbackPort/callback';
      AppLogger.info(
        'QfAuth',
        '[QF_AUTH] Loopback server listening on port $_loopbackPort',
      );

      // 2. Generate PKCE code verifier + challenge
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      // 3. Generate state + nonce for security
      final state = _generateRandomString(32);
      final nonce = _generateRandomString(32);

      // 4. Build the authorization URL
      final authUrl = Uri.parse(_authEndpoint).replace(
        queryParameters: {
          'client_id': _clientId,
          'redirect_uri': redirectUri,
          'response_type': 'code',
          'scope': _scopes,
          'code_challenge': codeChallenge,
          'code_challenge_method': 'S256',
          'state': state,
          'nonce': nonce,
        },
      );

      // 5. Open the browser
      AppLogger.info(
        'QfAuth',
        '[QF_AUTH] Opening browser for QF User sign-in...',
      );
      await _openBrowser(authUrl.toString());

      // 6. Wait for the redirect (with timeout)
      final code = await _waitForAuthCode(
        server,
        state,
      ).timeout(const Duration(minutes: 5));

      if (code == null) {
        AppLogger.info(
          'QfAuth',
          '[QF_AUTH] User cancelled or error in OAuth flow',
        );
        return false;
      }

      // 7. Close the server before exchanging the code
      await server.close(force: true);
      server = null;

      // 8. Exchange auth code for tokens
      final success = await _exchangeCodeForTokens(
        code,
        redirectUri,
        codeVerifier,
      );
      return success;
    } on TimeoutException {
      AppLogger.info('QfAuth', '[QF_AUTH] OAuth flow timed out');
      return false;
    } catch (e) {
      AppLogger.info('QfAuth', '[QF_AUTH] Sign-in error: $e');
      return false;
    } finally {
      await server?.close(force: true);
      _isSigningIn = false;
      notifyListeners();
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // Sign Out
  // ══════════════════════════════════════════════════════════════════════

  /// Signs out the user, clears tokens, and optionally revokes them.
  Future<void> signOut() async {
    // Revoke the refresh token if available
    if (_refreshToken != null) {
      try {
        await http.post(
          Uri.parse(_revokeEndpoint),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'token': _refreshToken!,
            'client_id': _clientId,
            'client_secret': _clientSecret,
          },
        );
        AppLogger.info('QfAuth', '[QF_AUTH] Refresh token revoked');
      } catch (e) {
        AppLogger.info(
          'QfAuth',
          '[QF_AUTH] Token revocation failed (non-critical): $e',
        );
      }
    }

    // Clear local state
    _accessToken = null;
    _refreshToken = null;
    _idToken = null;
    _tokenExpiry = null;
    _userSub = null;

    // Clear stored tokens
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyIdToken);
    await prefs.remove(_keyTokenExpiry);
    await prefs.remove(_keyUserSub);

    AppLogger.info('QfAuth', '[QF_AUTH] Signed out');
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════════════
  // Token Exchange + Refresh
  // ══════════════════════════════════════════════════════════════════════

  /// Base64-encoded "client_id:client_secret" for HTTP Basic Auth.
  /// QF's Hydra server requires `client_secret_basic` authentication.
  static String get _basicAuthHeader {
    final credentials = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
    return 'Basic $credentials';
  }

  /// Exchanges the authorization code for access, refresh, and id tokens.
  ///
  /// On Windows, uses PowerShell's Invoke-WebRequest to bypass BoringSSL
  /// TLS compatibility issues. On other platforms, uses dart:io HttpClient.
  Future<bool> _exchangeCodeForTokens(
    String code,
    String redirectUri,
    String codeVerifier,
  ) async {
    try {
      AppLogger.info('QfAuth', '[QF_AUTH] Exchanging code for tokens...');

      final bodyParams = {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'code_verifier': codeVerifier,
      };

      final responseBody = await _postToQf(
        _tokenEndpoint,
        bodyParams,
        authHeader: _basicAuthHeader,
      );
      if (responseBody == null) return false;

      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      await _storeTokens(data);
      AppLogger.info(
        'QfAuth',
        '[QF_AUTH] Signed in successfully. User: $_userSub',
      );
      return true;
    } catch (e, stack) {
      AppLogger.info('QfAuth', '[QF_AUTH] Token exchange error: $e');
      AppLogger.info('QfAuth', '[QF_AUTH] Stack trace: $stack');
      return false;
    }
  }

  /// Makes a POST request to a QF endpoint, bypassing BoringSSL on Windows.
  ///
  /// On Windows, Dart's HTTP clients (both `http` package and `dart:io`)
  /// use BoringSSL which has TLS handshake failures with QF's servers
  /// (SSLV3_ALERT_BAD_RECORD_MAC). This method uses PowerShell's
  /// Invoke-WebRequest on Windows to leverage the native SChannel TLS stack.
  ///
  /// [authHeader] is the Authorization header value (e.g. 'Basic ...').
  /// Returns the response body string, or `null` on failure.
  static Future<String?> _postToQf(
    String url,
    Map<String, String> params, {
    String? authHeader,
  }) async {
    if (Platform.isWindows) {
      return _postViaProcess(url, params, authHeader: authHeader);
    }

    // Non-Windows: use dart:io HttpClient
    try {
      final ioClient = HttpClient();
      final request = await ioClient.postUrl(Uri.parse(url));
      request.headers.set('Content-Type', 'application/x-www-form-urlencoded');
      if (authHeader != null) {
        request.headers.set('Authorization', authHeader);
      }

      final encodedBody = params.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&');
      request.write(encodedBody);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      ioClient.close();

      AppLogger.info('QfAuth', '[QF_AUTH] Response: ${response.statusCode}');
      if (response.statusCode != 200) {
        AppLogger.info('QfAuth', '[QF_AUTH] Error body: $body');
        return null;
      }
      return body;
    } catch (e) {
      AppLogger.info('QfAuth', '[QF_AUTH] HttpClient error: $e');
      return null;
    }
  }

  /// Uses PowerShell Invoke-WebRequest to make the POST request.
  /// This uses the Windows native TLS stack (SChannel) instead of BoringSSL.
  static Future<String?> _postViaProcess(
    String url,
    Map<String, String> params, {
    String? authHeader,
  }) async {
    try {
      // URL-encode the body manually
      final encodedBody = params.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
          )
          .join('&');

      // Build headers hashtable
      final headersBlock = authHeader != null
          ? "\$headers = @{ 'Authorization' = '$authHeader' }\n  "
          : '';
      final headersArg = authHeader != null ? ' -Headers \$headers' : '';

      final psScript =
          '''
try {
  $headersBlock\$body = '$encodedBody'
  \$response = Invoke-WebRequest -Uri '$url' -Method POST -Body \$body -ContentType 'application/x-www-form-urlencoded'$headersArg -UseBasicParsing
  Write-Output \$response.Content
} catch {
  if (\$_.Exception.Response) {
    \$reader = New-Object System.IO.StreamReader(\$_.Exception.Response.GetResponseStream())
    \$reader.BaseStream.Position = 0
    \$errorBody = \$reader.ReadToEnd()
    Write-Error "HTTP \$(\$_.Exception.Response.StatusCode.value__): \$errorBody"
  } else {
    Write-Error \$_.Exception.Message
  }
  exit 1
}
''';

      AppLogger.info(
        'QfAuth',
        '[QF_AUTH] Calling QF via PowerShell (Basic Auth)...',
      );
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-Command',
        psScript,
      ]);

      if (result.exitCode != 0) {
        AppLogger.info(
          'QfAuth',
          '[QF_AUTH] PowerShell error (exit ${result.exitCode}): ${result.stderr}',
        );
        return null;
      }

      final responseBody = (result.stdout as String).trim();
      AppLogger.info(
        'QfAuth',
        '[QF_AUTH] PowerShell response received (${responseBody.length} chars)',
      );
      return responseBody;
    } catch (e) {
      AppLogger.info('QfAuth', '[QF_AUTH] Process error: $e');
      return null;
    }
  }

  /// Refreshes the access token using the stored refresh token.
  ///
  /// Returns `true` if the refresh was successful.
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final bodyParams = {
        'grant_type': 'refresh_token',
        'refresh_token': _refreshToken!,
      };

      final responseBody = await _postToQf(
        _tokenEndpoint,
        bodyParams,
        authHeader: _basicAuthHeader,
      );
      if (responseBody == null) {
        AppLogger.info('QfAuth', '[QF_AUTH] Token refresh failed');
        await signOut();
        return false;
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      await _storeTokens(data);
      AppLogger.info('QfAuth', '[QF_AUTH] Token refreshed successfully');
      return true;
    } catch (e) {
      AppLogger.info('QfAuth', '[QF_AUTH] Token refresh error: $e');
      return false;
    }
  }

  /// Stores tokens from the OAuth2 token response.
  Future<void> _storeTokens(Map<String, dynamic> data) async {
    _accessToken = data['access_token'] as String?;
    _refreshToken = data['refresh_token'] as String? ?? _refreshToken;
    _idToken = data['id_token'] as String?;

    final expiresIn = data['expires_in'] as int? ?? 3600;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

    // Extract sub from id_token (JWT payload)
    if (_idToken != null) {
      _userSub = _extractSub(_idToken!);
    }

    // Persist to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    if (_accessToken != null) prefs.setString(_keyAccessToken, _accessToken!);
    if (_refreshToken != null) {
      prefs.setString(_keyRefreshToken, _refreshToken!);
    }
    if (_idToken != null) prefs.setString(_keyIdToken, _idToken!);
    if (_tokenExpiry != null) {
      prefs.setInt(_keyTokenExpiry, _tokenExpiry!.millisecondsSinceEpoch);
    }
    if (_userSub != null) prefs.setString(_keyUserSub, _userSub!);

    notifyListeners();
  }

  /// Extracts the `sub` claim from a JWT id_token without full validation.
  /// Note: JWT signature verification should be handled by a secure backend wrapper.
  String? _extractSub(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final claims = jsonDecode(payload) as Map<String, dynamic>;
      return claims['sub'] as String?;
    } catch (e) {
      AppLogger.info(
        'QfAuth',
        '[QF_AUTH] Failed to extract sub from id_token: $e',
      );
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // Loopback Server Helpers
  // ══════════════════════════════════════════════════════════════════════

  /// Waits for the OAuth2 redirect on the local server.
  static Future<String?> _waitForAuthCode(
    HttpServer server,
    String expectedState,
  ) async {
    await for (final request in server) {
      final uri = request.uri;

      // Skip favicon and other non-callback requests
      if (uri.path != '/callback') {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write('')
          ..close();
        continue;
      }

      // Check for error
      if (uri.queryParameters.containsKey('error')) {
        final error = uri.queryParameters['error'];
        AppLogger.info('QfAuth', '[QF_AUTH] OAuth error: $error');
        _sendResponse(
          request,
          'Sign-in cancelled or denied. You can close this window.',
          success: false,
        );
        return null;
      }

      // Verify state matches (CSRF protection)
      final returnedState = uri.queryParameters['state'];
      if (returnedState != expectedState) {
        AppLogger.info(
          'QfAuth',
          '[QF_AUTH] State mismatch! Expected: $expectedState, got: $returnedState',
        );
        _sendResponse(
          request,
          'Security error: state mismatch. Please try again.',
          success: false,
        );
        return null;
      }

      // Extract the authorization code
      final code = uri.queryParameters['code'];
      if (code != null) {
        _sendResponse(
          request,
          'Signed in successfully! You can close this window and return to Jawhar.',
          success: true,
        );
        return code;
      }

      _sendResponse(
        request,
        'Unexpected response. Please try again.',
        success: false,
      );
      return null;
    }
    return null;
  }

  /// Sends an HTML response to the browser after OAuth redirect.
  static void _sendResponse(
    HttpRequest request,
    String message, {
    bool success = true,
  }) {
    final icon = success ? '✓' : '✕';
    final color = success ? '#10b981' : '#ef4444';
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.html
      ..write('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Jawhar — Sign In</title>
  <style>
    body {
      font-family: 'Geist', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background: #000;
      color: #ededed;
    }
    .card {
      text-align: center;
      padding: 48px;
      background: #0a0a0a;
      border: 1px solid #1a1a1a;
      border-radius: 12px;
      max-width: 400px;
    }
    .icon { font-size: 48px; margin-bottom: 16px; color: $color; }
    h2 { margin: 0 0 8px; color: #ededed; font-weight: 500; }
    p { color: #666; margin: 0; font-size: 14px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">$icon</div>
    <h2>$message</h2>
    <p>Return to Jawhar to continue.</p>
  </div>
</body>
</html>
''')
      ..close();
  }

  // ══════════════════════════════════════════════════════════════════════
  // Platform Helpers
  // ══════════════════════════════════════════════════════════════════════

  /// Opens a URL in the system default browser.
  static Future<void> _openBrowser(String url) async {
    if (Platform.isWindows) {
      final escaped = url.replaceAll('&', '^&');
      await Process.run('cmd', ['/c', 'start', '', escaped]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [url]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // PKCE Helpers
  // ══════════════════════════════════════════════════════════════════════

  /// Generates a random code verifier for PKCE (64 chars).
  static String _generateCodeVerifier() {
    return _generateRandomString(64);
  }

  /// Generates the S256 code challenge from a code verifier.
  static String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// Generates a cryptographically random string.
  static String _generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
