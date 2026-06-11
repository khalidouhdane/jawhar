import 'dart:io';

/// Default Gemini model id when GEMINI_MODEL is not set.
///
/// Decided 2026-06-10 (roadmap §4.4): GA on Vertex AI, global endpoint.
const String kDefaultGeminiModel = 'gemini-3.5-flash';

/// The Firebase project this service belongs to (token audience).
const String kDefaultProjectId = 'quran-app-e5e86';

/// Immutable server configuration, read once from the environment at startup.
class Config {
  const Config({
    required this.gitSha,
    required this.modelId,
    required this.projectId,
    required this.port,
    this.sentryDsn,
  });

  factory Config.fromEnvironment([Map<String, String>? env]) {
    final e = env ?? Platform.environment;
    return Config(
      gitSha: _nonEmpty(e['GIT_SHA']) ?? 'unknown',
      modelId: _nonEmpty(e['GEMINI_MODEL']) ?? kDefaultGeminiModel,
      projectId: _nonEmpty(e['GOOGLE_CLOUD_PROJECT']) ?? kDefaultProjectId,
      port: int.tryParse(e['PORT'] ?? '') ?? 8080,
      sentryDsn: _nonEmpty(e['SENTRY_DSN']),
    );
  }

  /// Git SHA baked into the image at build time (env GIT_SHA).
  final String gitSha;

  /// Gemini model id (env GEMINI_MODEL, default [kDefaultGeminiModel]).
  final String modelId;

  /// Firebase/GCP project id — also the required ID-token audience.
  final String projectId;

  /// Listen port (Cloud Run injects PORT).
  final int port;

  /// Sentry DSN; when null, Sentry is a no-op (env SENTRY_DSN).
  final String? sentryDsn;

  static String? _nonEmpty(String? v) => (v == null || v.isEmpty) ? null : v;
}
