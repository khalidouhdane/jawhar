import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Thrown when the Vertex AI call fails (HTTP error, transport failure, or a
/// response with no usable candidates). [message] is what reaches the client
/// inside `AI generation failed: <message>` — mirroring the legacy callable's
/// error mapping (`functions/src/index.ts`).
class VertexException implements Exception {
  VertexException(this.message, {this.statusCode});

  final String message;

  /// HTTP status returned by Vertex, when the failure was an HTTP error.
  final int? statusCode;

  @override
  String toString() => message;
}

/// Thin REST client for Vertex AI `generateContent` on the GLOBAL endpoint
/// (roadmap §4.4): no API key — authentication is an ADC bearer token, which
/// `clientViaApplicationDefaultCredentials` obtains from the metadata server
/// on Cloud Run and from `gcloud auth application-default login` locally.
///
/// The HTTP client is injectable so handler tests never touch ADC or the
/// network.
class VertexClient {
  VertexClient({
    required this.projectId,
    this.location = 'global',
    http.Client? httpClient,
  }) : _injectedClient = httpClient;

  final String projectId;

  /// Vertex location. `global` (the default) uses the host without a region
  /// prefix; any other value uses `<location>-aiplatform.googleapis.com`.
  final String location;

  final http.Client? _injectedClient;
  http.Client? _adcClient;

  static const _cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  String get _host => location == 'global'
      ? 'aiplatform.googleapis.com'
      : '$location-aiplatform.googleapis.com';

  Future<http.Client> _client() async {
    if (_injectedClient != null) return _injectedClient;
    return _adcClient ??= await clientViaApplicationDefaultCredentials(
      scopes: const [_cloudPlatformScope],
    );
  }

  /// Calls `models/{model}:generateContent` and returns the concatenated text
  /// parts of the first candidate (the same thing the `@google/genai` SDK's
  /// `response.text` returns). An empty string means the model produced no
  /// text — the caller decides how to surface that (the legacy callable threw
  /// "AI returned empty response.").
  ///
  /// Defaults mirror the legacy callable config exactly:
  /// `responseMimeType: application/json`, `temperature: 0.3`, optional
  /// [systemInstruction].
  Future<String> generateContent({
    required String model,
    required String userText,
    String? systemInstruction,
    double temperature = 0.3,
    String responseMimeType = 'application/json',
  }) async {
    final uri = Uri.https(
      _host,
      '/v1/projects/$projectId/locations/$location'
      '/publishers/google/models/$model:generateContent',
    );

    final payload = <String, Object?>{
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userText},
          ],
        },
      ],
      if (systemInstruction != null && systemInstruction.isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction},
          ],
        },
      'generationConfig': {
        'responseMimeType': responseMimeType,
        'temperature': temperature,
      },
    };

    final http.Response response;
    try {
      final client = await _client();
      response = await client.post(
        uri,
        headers: const {'content-type': 'application/json'},
        body: jsonEncode(payload),
      );
    } on VertexException {
      rethrow;
    } catch (e) {
      throw VertexException('Vertex AI request failed: $e');
    }

    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode != 200) {
      throw VertexException(
        'Vertex AI HTTP ${response.statusCode}: ${_errorMessage(body)}',
        statusCode: response.statusCode,
      );
    }

    return _firstCandidateText(body);
  }

  /// Closes the lazily-created ADC client (injected clients are owned by the
  /// caller).
  void close() {
    _adcClient?.close();
    _adcClient = null;
  }

  static String _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic> && error['message'] is String) {
          return error['message'] as String;
        }
      }
    } on FormatException {
      // fall through to the raw body
    }
    final trimmed = body.trim();
    return trimmed.length > 300 ? '${trimmed.substring(0, 300)}…' : trimmed;
  }

  static String _firstCandidateText(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw VertexException('Vertex AI returned a non-JSON response body.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw VertexException('Vertex AI returned an unexpected response shape.');
    }
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return '';
    }
    final first = candidates.first;
    if (first is! Map<String, dynamic>) return '';
    final content = first['content'];
    if (content is! Map<String, dynamic>) return '';
    final parts = content['parts'];
    if (parts is! List) return '';
    return parts
        .whereType<Map<String, dynamic>>()
        .map((p) => p['text'])
        .whereType<String>()
        .join();
  }
}
