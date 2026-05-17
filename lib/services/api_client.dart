import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:quran_app/services/quran_auth_service.dart';
import 'package:quran_app/utils/app_logger.dart';

/// Centralized, resilient HTTP client for all Quran API communication.
///
/// ## Architecture: Fresh Client Per Request
///
/// Each request gets its own `HttpClient` → `IOClient` instance. This is
/// intentional and solves three problems at once:
///
/// 1. **SSLV3_ALERT_BAD_RECORD_MAC** — The primary failure mode. BoringSSL's
///    TLS session resumption fails when something (antivirus SSL inspection,
///    VPN, corporate proxy) corrupts cached TLS session tickets. A fresh
///    `HttpClient` forces a full TLS handshake with no cached state.
///
/// 2. **No concurrent reset race conditions** — With a shared client, one
///    request's SSL error resets the client, killing all other in-flight
///    requests ("Connection closed before full header was received").
///    Per-request clients are fully isolated.
///
/// 3. **No stale keep-alive connections** — The server drops idle connections
///    before the client detects it. Per-request clients have no idle state.
///
/// The overhead of a fresh TLS handshake (~50ms) is negligible compared
/// to API response times (200-500ms).
class ApiClient {
  /// Default timeout for API requests.
  static const Duration defaultTimeout = Duration(seconds: 12);

  /// Default number of retry attempts.
  static const int defaultMaxRetries = 3;

  /// Create a fresh, isolated HTTP client for a single request.
  ///
  /// Each client gets its own TCP connection and TLS context — no
  /// cached sessions, no stale connections, no shared state.
  static http.Client _freshClient() {
    final inner = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10)
      ..idleTimeout = const Duration(seconds: 0); // Close immediately after use
    return IOClient(inner);
  }

  /// Check if an error is SSL/TLS related.
  static bool _isSslError(Object error) {
    final msg = error.toString().toUpperCase();
    return msg.contains('SSL') ||
        msg.contains('TLS') ||
        msg.contains('HANDSHAKE') ||
        msg.contains('BAD_RECORD_MAC') ||
        msg.contains('CERTIFICATE');
  }

  /// Perform an authenticated GET request with retry and timeout.
  ///
  /// Each attempt uses a fresh HTTP client (fresh TCP + TLS handshake).
  /// On SSL errors, the next attempt starts completely clean.
  static Future<http.Response> get(
    Uri uri, {
    Duration timeout = defaultTimeout,
    int maxRetries = defaultMaxRetries,
    Map<String, String>? headers,
    bool retryOn5xx = true,
  }) async {
    final authHeaders = await _getAuthHeaders();
    final mergedHeaders = {...authHeaders, ...?headers};

    Object? lastError;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final client = _freshClient();
      try {
        final response = await client
            .get(uri, headers: mergedHeaders)
            .timeout(timeout);

        // Success
        if (response.statusCode == 200) return response;

        // Server error — retry with backoff
        if (retryOn5xx &&
            response.statusCode >= 500 &&
            attempt < maxRetries - 1) {
          final delay = Duration(seconds: 1 << attempt);
          AppLogger.info('ApiClient', '[ApiClient] Server ${response.statusCode} on $uri — '
            'retry ${attempt + 1}/$maxRetries in ${delay.inSeconds}s',
          );
          await Future.delayed(delay);
          continue;
        }

        return response;
      } on TimeoutException catch (e) {
        lastError = e;
        if (attempt < maxRetries - 1) {
          final delay = Duration(seconds: 1 << attempt);
          AppLogger.info('ApiClient', '[ApiClient] Timeout on $uri — '
            'retry ${attempt + 1}/$maxRetries in ${delay.inSeconds}s',
          );
          await Future.delayed(delay);
        }
      } on SocketException catch (e) {
        lastError = e;
        if (attempt < maxRetries - 1) {
          final delay = Duration(seconds: 1 << attempt);
          AppLogger.info('ApiClient', '[ApiClient] Network error on $uri ($e) — '
            'retry ${attempt + 1}/$maxRetries in ${delay.inSeconds}s',
          );
          await Future.delayed(delay);
        }
      } on http.ClientException catch (e) {
        lastError = e;
        if (attempt < maxRetries - 1) {
          final delay = Duration(seconds: 1 << attempt);
          final kind = _isSslError(e) ? 'SSL' : 'Connection';
          AppLogger.info('ApiClient', '[ApiClient] $kind error on $uri ($e) — '
            'retry ${attempt + 1}/$maxRetries in ${delay.inSeconds}s',
          );
          await Future.delayed(delay);
        }
      } catch (e) {
        lastError = e;
        if (attempt < maxRetries - 1) {
          final delay = Duration(seconds: 1 << attempt);
          AppLogger.info('ApiClient', '[ApiClient] Unexpected error on $uri ($e) — '
            'retry ${attempt + 1}/$maxRetries in ${delay.inSeconds}s',
          );
          await Future.delayed(delay);
        }
      } finally {
        client.close();
      }
    }

    throw Exception(
      'ApiClient: all $maxRetries retries failed for $uri — $lastError',
    );
  }

  /// Perform an unauthenticated POST with retry (used for OAuth token fetch).
  static Future<http.Response> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 10),
    int maxRetries = 3,
  }) async {
    Object? lastError;

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      final client = _freshClient();
      try {
        final response = await client
            .post(uri, headers: headers, body: body)
            .timeout(timeout);
        return response;
      } on TimeoutException catch (e) {
        lastError = e;
        if (attempt < maxRetries - 1) {
          AppLogger.info('ApiClient', '[ApiClient] POST timeout on $uri — '
            'retry ${attempt + 1}/$maxRetries',
          );
          await Future.delayed(Duration(seconds: 1 << attempt));
        }
      } catch (e) {
        lastError = e;
        if (attempt < maxRetries - 1) {
          AppLogger.info('ApiClient', '[ApiClient] POST error on $uri ($e) — '
            'retry ${attempt + 1}/$maxRetries',
          );
          await Future.delayed(Duration(seconds: 1 << attempt));
        }
      } finally {
        client.close();
      }
    }

    throw Exception(
      'ApiClient POST failed after $maxRetries attempts for $uri — $lastError',
    );
  }

  /// Perform an authenticated GET without application-level retry.
  static Future<http.Response> getOnce(
    Uri uri, {
    Duration timeout = defaultTimeout,
    Map<String, String>? headers,
  }) {
    return get(uri, timeout: timeout, maxRetries: 1, headers: headers);
  }

  /// Get authenticated headers (OAuth token + client ID).
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await QuranAuthService.getValidToken();
    return {
      'x-auth-token': token,
      'x-client-id': QuranAuthService.clientId,
    };
  }
}
