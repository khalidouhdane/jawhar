import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Handles Google OAuth on desktop platforms (Windows/macOS/Linux) where
/// the `google_sign_in` plugin isn't available.
///
/// Flow:
/// 1. Starts a local HTTP server on a random port
/// 2. Opens the system browser to Google's consent screen
/// 3. Google redirects back to localhost with an auth code
/// 4. Exchanges the auth code for tokens via Google's token endpoint
/// 5. Returns the idToken + accessToken for Firebase signInWithCredential
class DesktopGoogleAuth {
  /// Web OAuth Client ID from Firebase/Google Cloud Console.
  static const _clientId =
      '556087735735-infr9f13pfg17cpfgkvpb71olm1ppju2.apps.googleusercontent.com';

  /// Client secret — required for Web-type OAuth clients.
  /// For installed (desktop) apps, Google considers this non-confidential.
  static const _clientSecret = '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';

  static const _authEndpoint = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const _tokenEndpoint = 'https://oauth2.googleapis.com/token';
  static const _scopes = 'openid email profile';

  /// Signs in with Google using a loopback OAuth flow.
  ///
  /// Opens the system browser for Google consent, then catches the redirect
  /// on a local HTTP server. Returns a map with `idToken` and `accessToken`,
  /// or null if cancelled/failed.
  static Future<Map<String, String>?> signIn() async {
    HttpServer? server;
    try {
      // 1. Start local HTTP server on a random port
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      final redirectUri = 'http://localhost:$port';

      // 2. Generate PKCE code verifier + challenge
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      // 3. Generate state for CSRF protection
      final state = _generateRandomString(32);

      // 4. Build the authorization URL
      final authUrl = Uri.parse(_authEndpoint).replace(queryParameters: {
        'client_id': _clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': _scopes,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
        'access_type': 'offline',
      });

      // 5. Open the browser
      debugPrint('[AUTH] Opening browser for Google Sign-In...');
      await _openBrowser(authUrl.toString());

      // 6. Wait for the redirect (with timeout)
      final code = await _waitForAuthCode(server, state)
          .timeout(const Duration(minutes: 3));

      if (code == null) {
        debugPrint('[AUTH] User cancelled or error in OAuth flow');
        return null;
      }

      // 7. Close the server before exchanging the code
      await server.close(force: true);
      server = null;

      // 8. Exchange auth code for tokens
      final tokens = await _exchangeCodeForTokens(code, redirectUri, codeVerifier);
      return tokens;
    } on TimeoutException {
      debugPrint('[AUTH] OAuth flow timed out');
      return null;
    } catch (e) {
      debugPrint('[AUTH] Desktop OAuth error: $e');
      return null;
    } finally {
      await server?.close(force: true);
    }
  }

  /// Waits for Google to redirect to our local server with the auth code.
  static Future<String?> _waitForAuthCode(HttpServer server, String expectedState) async {
    await for (final request in server) {
      final uri = request.uri;

      // Check for error
      if (uri.queryParameters.containsKey('error')) {
        _sendResponse(request, 'Sign-in cancelled. You can close this window.');
        return null;
      }

      // Verify state matches
      final returnedState = uri.queryParameters['state'];
      if (returnedState != expectedState) {
        _sendResponse(request, 'Invalid state. Please try again.');
        return null;
      }

      // Extract the authorization code
      final code = uri.queryParameters['code'];
      if (code != null) {
        _sendResponse(
          request,
          'Sign-in successful! You can close this window and return to Le Quran.',
        );
        return code;
      }

      // For any other request (favicon etc.), just return 200
      _sendResponse(request, '');
    }
    return null;
  }

  /// Exchanges the authorization code for id_token and access_token.
  static Future<Map<String, String>?> _exchangeCodeForTokens(
    String code,
    String redirectUri,
    String codeVerifier,
  ) async {
    final response = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'code': code,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode != 200) {
      debugPrint('[AUTH] Token exchange failed: ${response.statusCode} ${response.body}');
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final idToken = data['id_token'] as String?;
    final accessToken = data['access_token'] as String?;

    if (idToken == null || accessToken == null) {
      debugPrint('[AUTH] Missing tokens in response');
      return null;
    }

    return {'idToken': idToken, 'accessToken': accessToken};
  }

  /// Sends an HTML response to close the browser tab.
  static void _sendResponse(HttpRequest request, String message) {
    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.html
      ..write('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Le Quran - Sign In</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      background: #1a1a2e;
      color: #e0e0e0;
    }
    .card {
      text-align: center;
      padding: 48px;
      background: #25253e;
      border-radius: 16px;
      box-shadow: 0 8px 32px rgba(0,0,0,0.3);
      max-width: 400px;
    }
    .icon { font-size: 48px; margin-bottom: 16px; }
    h2 { margin: 0 0 8px; color: #fff; }
    p { color: #aaa; margin: 0; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">✓</div>
    <h2>$message</h2>
  </div>
</body>
</html>
''')
      ..close();
  }

  /// Opens a URL in the system default browser.
  static Future<void> _openBrowser(String url) async {
    if (Platform.isWindows) {
      // cmd.exe treats & as command separator — escape with ^
      final escaped = url.replaceAll('&', '^&');
      await Process.run('cmd', ['/c', 'start', '', escaped]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [url]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
    }
  }

  /// Generates a random code verifier for PKCE (43-128 chars).
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
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
