import 'dart:io';

/// Default Gemini model id when GEMINI_MODEL is not set.
///
/// Decided 2026-06-10 (roadmap §4.4): GA on Vertex AI, global endpoint.
const String kDefaultGeminiModel = 'gemini-3.5-flash';

/// The Firebase project this service belongs to (token audience).
const String kDefaultProjectId = 'quran-app-e5e86';

/// Default CORS allow-list when CORS_ALLOWED_ORIGINS is not set: the
/// production web app (Vercel) plus local Flutter-web dev servers, which
/// bind a RANDOM localhost port per `flutter run` (hence the `:*` port
/// wildcard — see [Config.corsAllowedOrigins] for the entry syntax).
const List<String> kDefaultCorsAllowedOrigins = [
  'https://website-lilac-phi-50.vercel.app',
  'http://localhost:*',
  'http://127.0.0.1:*',
];

/// Immutable server configuration, read once from the environment at startup.
class Config {
  const Config({
    required this.gitSha,
    required this.modelId,
    required this.projectId,
    required this.port,
    this.sentryDsn,
    this.minSupportedBuild = 1,
    this.datasetEpoch = 'e1',
    this.writePath = 'legacy',
    this.aiDailyQuota = 10,
    this.rateLimitBurst = 20,
    this.rateLimitPerMinute = 60,
    this.corsAllowedOrigins = kDefaultCorsAllowedOrigins,
  });

  factory Config.fromEnvironment([Map<String, String>? env]) {
    final e = env ?? Platform.environment;
    return Config(
      gitSha: _nonEmpty(e['GIT_SHA']) ?? 'unknown',
      modelId: _nonEmpty(e['GEMINI_MODEL']) ?? kDefaultGeminiModel,
      projectId: _nonEmpty(e['GOOGLE_CLOUD_PROJECT']) ?? kDefaultProjectId,
      port: int.tryParse(e['PORT'] ?? '') ?? 8080,
      sentryDsn: _nonEmpty(e['SENTRY_DSN']),
      minSupportedBuild: int.tryParse(e['MIN_SUPPORTED_BUILD'] ?? '') ?? 1,
      datasetEpoch: _nonEmpty(e['DATASET_EPOCH']) ?? 'e1',
      writePath: _nonEmpty(e['WRITE_PATH']) ?? 'legacy',
      aiDailyQuota: int.tryParse(e['AI_DAILY_QUOTA'] ?? '') ?? 10,
      rateLimitBurst: int.tryParse(e['RATE_LIMIT_BURST'] ?? '') ?? 20,
      rateLimitPerMinute:
          double.tryParse(e['RATE_LIMIT_PER_MINUTE'] ?? '') ?? 60,
      corsAllowedOrigins: _originList(e['CORS_ALLOWED_ORIGINS']),
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

  /// Builds below this number block SYNC ONLY, never the offline loop
  /// (roadmap §5; env MIN_SUPPORTED_BUILD). Default 1 = no client blocked.
  final int minSupportedBuild;

  /// Server data-generation id (roadmap §5; env DATASET_EPOCH). Bumped only
  /// through the tester reset protocol (§8).
  final String datasetEpoch;

  /// Phase 4 per-fleet write-path flag, plumbed now: `legacy` until the facts
  /// write path ships (env WRITE_PATH).
  final String writePath;

  /// Per-uid daily AI quota shared by the AI endpoints
  /// (env AI_DAILY_QUOTA, default 10/day).
  final int aiDailyQuota;

  /// Token-bucket burst size per uid (env RATE_LIMIT_BURST).
  final int rateLimitBurst;

  /// Token-bucket refill rate per uid (env RATE_LIMIT_PER_MINUTE).
  final double rateLimitPerMinute;

  /// CORS allow-list (env CORS_ALLOWED_ORIGINS, comma-separated; default
  /// [kDefaultCorsAllowedOrigins] — setting the env var REPLACES the default
  /// list, localhost entries included). Each entry is either an exact origin
  /// (`https://app.example`) or a scheme+host with an any-port wildcard
  /// (`http://localhost:*`). Enforced by `middleware/cors.dart`.
  final List<String> corsAllowedOrigins;

  static String? _nonEmpty(String? v) => (v == null || v.isEmpty) ? null : v;

  static List<String> _originList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return kDefaultCorsAllowedOrigins;
    return [
      for (final entry in raw.split(','))
        if (entry.trim().isNotEmpty) entry.trim(),
    ];
  }
}
