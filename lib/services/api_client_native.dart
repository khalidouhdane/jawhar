import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Creates a fresh, isolated HTTP client for native platforms.
/// This uses IOClient with specific timeouts.
http.Client createFreshHttpClient() {
  final inner = HttpClient()
    ..connectionTimeout = const Duration(seconds: 10)
    ..idleTimeout = const Duration(seconds: 0); // Close immediately after use
  return IOClient(inner);
}
