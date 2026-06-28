import 'dart:io';
import 'package:quran_app/utils/app_logger.dart';

/// A lightweight HTTP loopback proxy server running inside the Flutter app.
///
/// Bypasses Windows Media Foundation's SSL/TLS renegotiation bugs (0x80072F8F)
/// by downloading remote audio content via Dart's robust native `HttpClient`
/// and serving it to `audioplayers` locally over plain HTTP.
class AudioProxyServer {
  static final AudioProxyServer _instance = AudioProxyServer._internal();
  factory AudioProxyServer() => _instance;
  AudioProxyServer._internal();

  HttpServer? _server;
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 15);

  bool get isRunning => _server != null;
  int get port => _server?.port ?? 0;

  /// Starts the proxy server on an ephemeral port, bound to 127.0.0.1.
  Future<void> start() async {
    if (isRunning) return;
    try {
      AppLogger.info(
        'AudioProxy',
        'start() called. Stack trace:\n${StackTrace.current}',
      );
      // Bind to loopback IPv4 with port 0 to allocate any free ephemeral port
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server!.listen(
        _handleRequest,
        onError: (e) {
          AppLogger.error('AudioProxy', 'Error in proxy server listener', e);
        },
      );
      AppLogger.info('AudioProxy', 'Audio proxy server started on port $port');
    } catch (e) {
      AppLogger.error('AudioProxy', 'Failed to start proxy server', e);
      rethrow;
    }
  }

  /// Gracefully shut down the proxy server and close the HTTP client.
  Future<void> shutdown() async {
    await stop();
    _client.close(force: false);
  }

  /// Stops the proxy server.
  Future<void> stop() async {
    if (!isRunning) return;
    try {
      await _server?.close(force: false);
      _server = null;
      AppLogger.info('AudioProxy', 'Audio proxy server stopped');
    } catch (e) {
      AppLogger.error('AudioProxy', 'Error stopping proxy server', e);
    }
  }

  /// Translates a remote URL to a proxy URL if the server is running.
  String proxyUrl(String originalUrl) {
    if (!isRunning) {
      AppLogger.warn(
        'AudioProxy',
        'proxyUrl called but server is not running. Returning original: $originalUrl',
      );
      return originalUrl;
    }
    // Don't proxy local files or already proxied/loopback URLs
    if (originalUrl.startsWith('http://127.0.0.1') ||
        originalUrl.startsWith('http://localhost') ||
        originalUrl.startsWith('file:') ||
        originalUrl.startsWith('asset:')) {
      return originalUrl;
    }
    final proxied =
        'http://127.0.0.1:$port/proxy?url=${Uri.encodeComponent(originalUrl)}';
    AppLogger.info('AudioProxy', 'Translating URL: $originalUrl -> $proxied');
    return proxied;
  }

  /// Handles incoming connection requests from audioplayers.
  Future<void> _handleRequest(HttpRequest request) async {
    if (request.method != 'GET' && request.method != 'HEAD') {
      request.response
        ..statusCode = HttpStatus.methodNotAllowed
        ..headers.set(HttpHeaders.allowHeader, 'GET, HEAD');
      await request.response.close();
      return;
    }

    final urlString = request.uri.queryParameters['url'];
    if (urlString == null) {
      AppLogger.warn(
        'AudioProxy',
        'Received proxy request with missing url parameter',
      );
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    AppLogger.info(
      'AudioProxy',
      'Proxying request: ${request.method} $urlString',
    );

    // Security: validate the target URL before proxying
    final targetUri = Uri.tryParse(urlString);
    if (targetUri == null) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    if (!isAllowedTarget(targetUri)) {
      AppLogger.warn(
        'AudioProxy',
        'Blocked proxy request to unauthorized URL: $urlString',
      );
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }

    if (!await _resolvesToPublicAddress(targetUri.host)) {
      AppLogger.warn(
        'AudioProxy',
        'Blocked proxy request resolving to a non-public address: $urlString',
      );
      request.response.statusCode = HttpStatus.forbidden;
      await request.response.close();
      return;
    }

    try {
      final clientRequest = await _client.openUrl(request.method, targetUri);

      // Forward request headers from player to remote server (except connection-handling ones)
      final ignoredRequestHeaders = ['host', 'connection', 'keep-alive'];
      request.headers.forEach((name, values) {
        if (!ignoredRequestHeaders.contains(name.toLowerCase())) {
          for (var value in values) {
            clientRequest.headers.add(name, value);
          }
        }
      });

      final clientResponse = await clientRequest.close();

      AppLogger.info(
        'AudioProxy',
        'Remote server responded with status: ${clientResponse.statusCode}',
      );

      // Copy response status and headers back to the player
      request.response.statusCode = clientResponse.statusCode;
      clientResponse.headers.forEach((name, values) {
        final lowerName = name.toLowerCase();
        // Skip connection headers that should be handled by the loopback HTTP server
        if (lowerName != 'connection' && lowerName != 'transfer-encoding') {
          for (var value in values) {
            request.response.headers.add(name, value);
          }
        }
      });

      // Stream the response body directly to the player
      await request.response.addStream(clientResponse);
      AppLogger.info(
        'AudioProxy',
        'Stream piping finished successfully for $urlString',
      );
    } catch (e) {
      AppLogger.error('AudioProxy', 'Proxy error requesting $urlString', e);
      request.response.statusCode = HttpStatus.internalServerError;
    } finally {
      await request.response.close();
    }
  }

  static bool isAllowedTarget(Uri targetUri) {
    if (targetUri.scheme != 'https' || targetUri.userInfo.isNotEmpty) {
      return false;
    }
    const allowedHosts = [
      'audio.qurancdn.com',
      'verses.quran.com',
      'everyayah.com',
      'mp3quran.net',
      'download.quran.com',
      'quranicaudio.com',
    ];
    final hostname = targetUri.host.toLowerCase();
    return allowedHosts.any(
      (host) => hostname == host || hostname.endsWith('.$host'),
    );
  }

  /// DNS-rebinding guard: an allow-listed hostname must not resolve to a
  /// loopback/link-local/private address. Resolution failure also rejects.
  static Future<bool> _resolvesToPublicAddress(String host) async {
    try {
      final addresses = await InternetAddress.lookup(host);
      if (addresses.isEmpty) return false;
      return addresses.every(isPublicAddress);
    } catch (_) {
      return false;
    }
  }

  /// Whether [address] is publicly routable (not loopback, link-local,
  /// multicast, unspecified, RFC 1918 private, or IPv6 unique-local).
  static bool isPublicAddress(InternetAddress address) {
    if (address.isLoopback || address.isLinkLocal || address.isMulticast) {
      return false;
    }
    final bytes = address.rawAddress;
    if (address.type == InternetAddressType.IPv4) {
      if (bytes[0] == 0) return false; // 0.0.0.0/8
      if (bytes[0] == 10) return false; // 10.0.0.0/8
      if (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) {
        return false; // 172.16.0.0/12
      }
      if (bytes[0] == 192 && bytes[1] == 168) return false; // 192.168.0.0/16
      if (bytes[0] == 100 && bytes[1] >= 64 && bytes[1] <= 127) {
        return false; // 100.64.0.0/10 (CGNAT)
      }
      return true;
    }
    // IPv6: unique-local fc00::/7, unspecified ::
    if ((bytes[0] & 0xfe) == 0xfc) return false;
    if (bytes.every((b) => b == 0)) return false;
    return true;
  }
}
