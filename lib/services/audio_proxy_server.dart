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
      AppLogger.info('AudioProxy', 'start() called. Stack trace:\n${StackTrace.current}');
      // Bind to loopback IPv4 with port 0 to allocate any free ephemeral port
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server!.listen(_handleRequest, onError: (e) {
        AppLogger.error('AudioProxy', 'Error in proxy server listener', e);
      });
      AppLogger.info('AudioProxy', 'Audio proxy server started on port $port');
    } catch (e) {
      AppLogger.error('AudioProxy', 'Failed to start proxy server', e);
    }
  }

  /// Stops the proxy server.
  Future<void> stop() async {
    if (!isRunning) return;
    try {
      await _server?.close(force: true);
      _server = null;
      AppLogger.info('AudioProxy', 'Audio proxy server stopped');
    } catch (e) {
      AppLogger.error('AudioProxy', 'Error stopping proxy server', e);
    }
  }

  /// Translates a remote URL to a proxy URL if the server is running.
  String proxyUrl(String originalUrl) {
    if (!isRunning) {
      AppLogger.warn('AudioProxy', 'proxyUrl called but server is not running. Returning original: $originalUrl');
      return originalUrl;
    }
    // Don't proxy local files or already proxied/loopback URLs
    if (originalUrl.startsWith('http://127.0.0.1') ||
        originalUrl.startsWith('http://localhost') ||
        originalUrl.startsWith('file:') ||
        originalUrl.startsWith('asset:')) {
      return originalUrl;
    }
    final proxied = 'http://127.0.0.1:$port/proxy?url=${Uri.encodeComponent(originalUrl)}';
    AppLogger.info('AudioProxy', 'Translating URL: $originalUrl -> $proxied');
    return proxied;
  }

  /// Handles incoming connection requests from audioplayers.
  Future<void> _handleRequest(HttpRequest request) async {
    final urlString = request.uri.queryParameters['url'];
    if (urlString == null) {
      AppLogger.warn('AudioProxy', 'Received proxy request with missing url parameter');
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    AppLogger.info('AudioProxy', 'Proxying request: ${request.method} $urlString');

    try {
      final targetUri = Uri.parse(urlString);
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

      AppLogger.info('AudioProxy', 'Remote server responded with status: ${clientResponse.statusCode}');

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
      AppLogger.info('AudioProxy', 'Stream piping finished successfully for $urlString');
    } catch (e) {
      AppLogger.error('AudioProxy', 'Proxy error requesting $urlString', e);
      request.response.statusCode = HttpStatus.internalServerError;
    } finally {
      await request.response.close();
    }
  }
}
