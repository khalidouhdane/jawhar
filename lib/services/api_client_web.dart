import 'package:http/http.dart' as http;

/// Creates a fresh HTTP client for web platforms.
/// This uses the standard http.Client() which maps to BrowserClient.
http.Client createFreshHttpClient() {
  return http.Client();
}
