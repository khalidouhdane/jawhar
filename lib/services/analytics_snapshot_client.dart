import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:hifz_core/hifz_core.dart' show hifzCoreVersion;
import 'package:http/http.dart' as http;
import 'package:quran_app/config/api_config.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/utils/app_logger.dart';

/// Compile-time switch for the server-side analytics snapshot source
/// (roadmap §8 Phase 6 task 2). The local computation stays compiled-in
/// underneath either way — rollback is a rebuild with the flag off.
const bool kUseApiV1Analytics = bool.fromEnvironment(
  'USE_API_V1_ANALYTICS',
  defaultValue: true,
);

/// Which source produced the dashboard's snapshots on the last load.
enum AnalyticsDataSource { local, server, cache }

/// Classification of one `GET /v1/me/analytics/snapshot` attempt.
enum AnalyticsFetchStatus {
  /// 200 with a parseable snapshot — [AnalyticsSnapshotResult.snapshot] set.
  ok,

  /// Signed out, transport disabled, HTTP error, or unusable body — the
  /// caller computes locally (the server cannot be trusted to be richer
  /// than local SQLite in any of these cases).
  unusable,

  /// Network-level failure (no transport at all) — the caller may show
  /// the cached last server snapshot before falling back to local.
  offline,
}

/// Outcome of [AnalyticsSnapshotClient.fetchWindow].
class AnalyticsSnapshotResult {
  final AnalyticsFetchStatus status;
  final WeeklySnapshot? snapshot;
  final String? detail;

  const AnalyticsSnapshotResult._(this.status, this.snapshot, this.detail);

  const AnalyticsSnapshotResult.ok(WeeklySnapshot snapshot)
    : this._(AnalyticsFetchStatus.ok, snapshot, null);

  const AnalyticsSnapshotResult.unusable(String detail)
    : this._(AnalyticsFetchStatus.unusable, null, detail);

  const AnalyticsSnapshotResult.offline(String detail)
    : this._(AnalyticsFetchStatus.offline, null, detail);
}

/// Thin client for `GET /v1/me/analytics/snapshot` on jawhar-api
/// (roadmap §5 #10), mirroring the [AICalibrationService] transport
/// conventions: injectable flag, base URL, `http.Client`, and Firebase ID
/// token provider, with every failure mapped to a non-throwing result so
/// callers can fall back (the API path must never be worse than the local
/// path).
class AnalyticsSnapshotClient {
  final bool _useApi;
  final String _baseUrl;
  final http.Client? _httpClient;
  final Future<String?> Function()? _idTokenProvider;
  final Duration _timeout;

  AnalyticsSnapshotClient({
    bool? useApi,
    String? apiBaseUrl,
    http.Client? httpClient,
    Future<String?> Function()? idTokenProvider,
    Duration timeout = const Duration(seconds: 10),
  }) : _useApi = useApi ?? kUseApiV1Analytics,
       _baseUrl = _normalizeBase(apiBaseUrl ?? kJawharApiBaseUrl),
       _httpClient = httpClient,
       _idTokenProvider = idTokenProvider,
       _timeout = timeout;

  static String _normalizeBase(String raw) =>
      raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;

  /// Whether the server transport is configured at all. When false the
  /// caller skips straight to the local computation.
  bool get enabled => _useApi && _baseUrl.isNotEmpty;

  /// Fetch the server snapshot for one `[start, end]` window (inclusive,
  /// `YYYY-MM-DD` local days — same semantics as the local
  /// `AnalyticsService.generateSnapshot` window).
  ///
  /// Never throws: every failure is classified into
  /// [AnalyticsFetchStatus.unusable] or [AnalyticsFetchStatus.offline].
  Future<AnalyticsSnapshotResult> fetchWindow({
    required String profileId,
    required DateTime start,
    required DateTime end,
  }) async {
    if (!enabled) {
      return const AnalyticsSnapshotResult.unusable('transport disabled');
    }

    final token = await _getIdToken();
    if (token == null || token.isEmpty) {
      return const AnalyticsSnapshotResult.unusable('signed out');
    }

    final uri = Uri.parse('$_baseUrl/v1/me/analytics/snapshot').replace(
      queryParameters: {
        'profileId': profileId,
        'start': isoDay(start),
        'end': isoDay(end),
      },
    );

    final client = _httpClient ?? http.Client();
    try {
      final response = await client
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'X-Client-Core-Version': hifzCoreVersion,
            },
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return AnalyticsSnapshotResult.unusable('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const AnalyticsSnapshotResult.unusable(
          'body is not a JSON object',
        );
      }
      final payloadProfile = decoded['profileId'];
      if (payloadProfile is String && payloadProfile != profileId) {
        return const AnalyticsSnapshotResult.unusable('profileId mismatch');
      }
      final raw = decoded['snapshot'];
      if (raw is! Map<String, dynamic>) {
        return const AnalyticsSnapshotResult.unusable(
          'missing snapshot payload',
        );
      }
      final snapshot = weeklySnapshotFromJson(raw);
      if (snapshot == null) {
        return const AnalyticsSnapshotResult.unusable('unparseable snapshot');
      }
      return AnalyticsSnapshotResult.ok(snapshot);
    } on TimeoutException {
      return const AnalyticsSnapshotResult.offline('timeout');
    } on http.ClientException catch (e) {
      return AnalyticsSnapshotResult.offline(e.message);
    } catch (e) {
      // dart:io-free offline check (web-safe) — same trick as ApiClient.
      final text = e.toString();
      if (text.contains('SocketException')) {
        return AnalyticsSnapshotResult.offline(text);
      }
      return AnalyticsSnapshotResult.unusable(text);
    } finally {
      if (_httpClient == null) client.close();
    }
  }

  /// Current user's Firebase ID token, or `null` (signed out / auth not
  /// initialized / auth error) — mirrors [AICalibrationService].
  Future<String?> _getIdToken() async {
    final provider = _idTokenProvider;
    try {
      if (provider != null) return await provider();
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (e) {
      AppLogger.warn('Analytics', 'Failed to get ID token: $e');
      return null;
    }
  }
}

/// "Nothing useful" gate: an account that never synced yields an all-zero
/// server snapshot while local SQLite may hold months of history — the
/// dashboard must never be emptier than today's local computation.
bool isEmptyWeeklySnapshot(WeeklySnapshot s) =>
    s.totalSessions == 0 &&
    s.plannedDays == 0 &&
    s.pagesMemorized == 0 &&
    s.pagesReviewed == 0;

/// Parse the server's snapshot JSON (the `_snapshotToJson` shape in
/// `server/api/lib/handlers/analytics.dart`) into the shared model.
/// Returns `null` when the payload is structurally unusable.
WeeklySnapshot? weeklySnapshotFromJson(Map<String, dynamic> json) {
  final start = _parseDay(json['startDate']);
  final end = _parseDay(json['endDate']);
  if (start == null || end == null) return null;

  final sessionsPerDay = <int, int>{};
  final rawPerDay = json['sessionsPerDay'];
  if (rawPerDay is Map) {
    for (final entry in rawPerDay.entries) {
      final day = int.tryParse('${entry.key}');
      final count = entry.value;
      if (day != null && count is num) sessionsPerDay[day] = count.toInt();
    }
  }

  int asInt(String key) {
    final value = json[key];
    return value is num ? value.toInt() : 0;
  }

  double asDouble(String key) {
    final value = json[key];
    return value is num ? value.toDouble() : 0.0;
  }

  return WeeklySnapshot(
    startDate: start,
    endDate: end,
    totalSessions: asInt('totalSessions'),
    totalDurationMinutes: asInt('totalDurationMinutes'),
    avgDurationMinutes: asDouble('avgDurationMinutes'),
    sessionsPerDay: sessionsPerDay,
    plannedDays: asInt('plannedDays'),
    completedDays: asInt('completedDays'),
    completionRate: asDouble('completionRate'),
    strongCount: asInt('strongCount'),
    okayCount: asInt('okayCount'),
    needsWorkCount: asInt('needsWorkCount'),
    pagesMemorized: asInt('pagesMemorized'),
    pagesReviewed: asInt('pagesReviewed'),
    pagesPerWeek: asDouble('pagesPerWeek'),
  );
}

/// Serialize a snapshot for the local cache — byte-compatible with the
/// server's `_snapshotToJson`, so [weeklySnapshotFromJson] reads both.
Map<String, dynamic> weeklySnapshotToJson(WeeklySnapshot s) => {
  'startDate': isoDay(s.startDate),
  'endDate': isoDay(s.endDate),
  'totalSessions': s.totalSessions,
  'totalDurationMinutes': s.totalDurationMinutes,
  'avgDurationMinutes': s.avgDurationMinutes,
  'sessionsPerDay': {
    for (final e in s.sessionsPerDay.entries) '${e.key}': e.value,
  },
  'plannedDays': s.plannedDays,
  'completedDays': s.completedDays,
  'completionRate': s.completionRate,
  'strongCount': s.strongCount,
  'okayCount': s.okayCount,
  'needsWorkCount': s.needsWorkCount,
  'pagesMemorized': s.pagesMemorized,
  'pagesReviewed': s.pagesReviewed,
  'pagesPerWeek': s.pagesPerWeek,
};

/// `YYYY-MM-DD` for a (local) calendar day.
String isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime? _parseDay(Object? raw) {
  if (raw is! String) return null;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}
