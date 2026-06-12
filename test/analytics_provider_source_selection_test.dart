import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/analytics_provider.dart';
import 'package:quran_app/services/analytics_service.dart';
import 'package:quran_app/services/analytics_snapshot_client.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Fixtures ──

MemoryProfile _profile([String id = 'p1']) => MemoryProfile(
  id: id,
  name: 'Test',
  createdAt: DateTime(2026, 1, 1),
  startDate: DateTime(2026, 1, 1),
);

/// The provider's week windows (Monday → today; previous Monday → Sunday),
/// recomputed exactly as `loadAnalytics` does.
({
  DateTime weekStart,
  DateTime weekEnd,
  DateTime prevWeekStart,
  DateTime prevWeekEnd,
})
_windows() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  return (
    weekStart: weekStart,
    weekEnd: today,
    prevWeekStart: weekStart.subtract(const Duration(days: 7)),
    prevWeekEnd: weekStart.subtract(const Duration(days: 1)),
  );
}

/// Server payload exactly as `server/api/lib/handlers/analytics.dart`
/// shapes it ([totalSessions] doubles as a marker to tell sources apart).
Map<String, dynamic> _serverPayload(
  String profileId,
  DateTime start,
  DateTime end, {
  int totalSessions = 7,
  int plannedDays = 5,
  int pagesMemorized = 2,
  int pagesReviewed = 6,
}) => {
  'profileId': profileId,
  'startDate': isoDay(start),
  'endDate': isoDay(end),
  'computedAtUtc': '2026-06-12T00:00:00.000Z',
  'snapshot': {
    'startDate': isoDay(start),
    'endDate': isoDay(end),
    'totalSessions': totalSessions,
    'totalDurationMinutes': 120,
    'avgDurationMinutes': 24.0,
    'sessionsPerDay': {'1': 2, '3': 1},
    'plannedDays': plannedDays,
    'completedDays': 4,
    'completionRate': 0.8,
    'strongCount': 3,
    'okayCount': 2,
    'needsWorkCount': 1,
    'pagesMemorized': pagesMemorized,
    'pagesReviewed': pagesReviewed,
    'pagesPerWeek': 2.0,
    'hasEnoughData': true,
  },
};

// ── Fakes (no SQLite, no plugins) ──

/// Marker values so tests can tell which source won.
const int kLocalCurrentMarker = 5;
const int kLocalPreviousMarker = 4;

class _FakeAnalyticsService extends AnalyticsService {
  int snapshotCalls = 0;

  _FakeAnalyticsService() : super(HifzDatabaseService());

  @override
  Future<WeeklySnapshot> generateSnapshot(
    String profileId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    snapshotCalls++;
    final isCurrentWeek = startDate == _windows().weekStart;
    return WeeklySnapshot(
      startDate: startDate,
      endDate: endDate,
      totalSessions: isCurrentWeek ? kLocalCurrentMarker : kLocalPreviousMarker,
    );
  }

  @override
  List<Suggestion> generateSuggestions(
    MemoryProfile profile,
    WeeklySnapshot current, {
    WeeklySnapshot? previous,
  }) => const [];

  @override
  Future<Map<String, dynamic>> calculatePace(
    String profileId,
    MemoryProfile profile,
  ) async => const {'memorizedPages': 1};
}

class _FakeNotificationService extends NotificationService {
  _FakeNotificationService(super.analytics);

  @override
  Future<List<Suggestion>> generateSmartNotifications(String profileId) async =>
      const [];
}

AnalyticsProvider _provider(
  _FakeAnalyticsService analytics, {
  required MockClient httpClient,
  Future<String?> Function()? idTokenProvider,
}) {
  return AnalyticsProvider(
    analytics,
    _FakeNotificationService(analytics),
    snapshotClient: AnalyticsSnapshotClient(
      useApi: true,
      apiBaseUrl: 'https://api.example.com',
      httpClient: httpClient,
      idTokenProvider: idTokenProvider ?? () async => 'token-123',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AnalyticsProvider snapshot source selection', () {
    test('server ok → server snapshots used, local never computed, '
        'cache persisted', () async {
      final w = _windows();
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        final start = request.url.queryParameters['start'];
        final isCurrent = start == isoDay(w.weekStart);
        return http.Response(
          jsonEncode(
            _serverPayload(
              'p1',
              isCurrent ? w.weekStart : w.prevWeekStart,
              isCurrent ? w.weekEnd : w.prevWeekEnd,
              totalSessions: isCurrent ? 7 : 6,
            ),
          ),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final analytics = _FakeAnalyticsService();
      final provider = _provider(analytics, httpClient: client);

      await provider.loadAnalytics(_profile());

      // Transport contract.
      expect(requests, hasLength(2));
      expect(requests.first.url.path, '/v1/me/analytics/snapshot');
      expect(requests.first.headers['authorization'], 'Bearer token-123');
      expect(requests.first.url.queryParameters['profileId'], 'p1');
      expect(requests.first.url.queryParameters['start'], isoDay(w.weekStart));
      expect(requests.first.url.queryParameters['end'], isoDay(w.weekEnd));
      expect(
        requests.last.url.queryParameters['start'],
        isoDay(w.prevWeekStart),
      );

      // Server snapshots won; local computation never ran.
      expect(provider.dataSource, AnalyticsDataSource.server);
      expect(provider.currentWeek!.totalSessions, 7);
      expect(provider.previousWeek!.totalSessions, 6);
      expect(provider.currentWeek!.completionRate, 0.8);
      expect(provider.currentWeek!.sessionsPerDay, {1: 2, 3: 1});
      expect(analytics.snapshotCalls, 0);
      expect(provider.error, isNull);
      expect(provider.isLoading, isFalse);

      // Cache persisted for the offline path.
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('analytics_snapshot_cache_p1');
      expect(raw, isNotNull);
      final cached = jsonDecode(raw!) as Map<String, dynamic>;
      expect(cached['profileId'], 'p1');
      expect(
        (cached['currentWeek'] as Map<String, dynamic>)['totalSessions'],
        7,
      );
    });

    test('server HTTP error → local computation', () async {
      final client = MockClient(
        (request) async => http.Response('{"error":{"code":"internal"}}', 500),
      );
      final analytics = _FakeAnalyticsService();
      final provider = _provider(analytics, httpClient: client);

      await provider.loadAnalytics(_profile());

      expect(provider.dataSource, AnalyticsDataSource.local);
      expect(provider.currentWeek!.totalSessions, kLocalCurrentMarker);
      expect(provider.previousWeek!.totalSessions, kLocalPreviousMarker);
      expect(analytics.snapshotCalls, 2);
      expect(provider.error, isNull);
    });

    test('unparseable 200 body → local computation', () async {
      final client = MockClient(
        (request) async => http.Response('<html>gateway</html>', 200),
      );
      final analytics = _FakeAnalyticsService();
      final provider = _provider(analytics, httpClient: client);

      await provider.loadAnalytics(_profile());

      expect(provider.dataSource, AnalyticsDataSource.local);
      expect(provider.currentWeek!.totalSessions, kLocalCurrentMarker);
      expect(analytics.snapshotCalls, 2);
    });

    test('signed out → local computation, API never touched', () async {
      var apiCalls = 0;
      final client = MockClient((request) async {
        apiCalls++;
        return http.Response('{}', 200);
      });
      final analytics = _FakeAnalyticsService();
      final provider = _provider(
        analytics,
        httpClient: client,
        idTokenProvider: () async => null,
      );

      await provider.loadAnalytics(_profile());

      expect(apiCalls, 0);
      expect(provider.dataSource, AnalyticsDataSource.local);
      expect(provider.currentWeek!.totalSessions, kLocalCurrentMarker);
      expect(analytics.snapshotCalls, 2);
    });

    test('server returns all-zero snapshots (never-synced account) → '
        'local computation, dashboard never emptier than today', () async {
      final w = _windows();
      final client = MockClient((request) async {
        final start = request.url.queryParameters['start'];
        final isCurrent = start == isoDay(w.weekStart);
        return http.Response(
          jsonEncode(
            _serverPayload(
              'p1',
              isCurrent ? w.weekStart : w.prevWeekStart,
              isCurrent ? w.weekEnd : w.prevWeekEnd,
              totalSessions: 0,
              plannedDays: 0,
              pagesMemorized: 0,
              pagesReviewed: 0,
            ),
          ),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final analytics = _FakeAnalyticsService();
      final provider = _provider(analytics, httpClient: client);

      await provider.loadAnalytics(_profile());

      expect(provider.dataSource, AnalyticsDataSource.local);
      expect(provider.currentWeek!.totalSessions, kLocalCurrentMarker);
      expect(analytics.snapshotCalls, 2);
    });

    test(
      'offline with cached server snapshot → cached snapshot shown',
      () async {
        final w = _windows();
        // First load online: persists the cache.
        final onlineClient = MockClient((request) async {
          final start = request.url.queryParameters['start'];
          final isCurrent = start == isoDay(w.weekStart);
          return http.Response(
            jsonEncode(
              _serverPayload(
                'p1',
                isCurrent ? w.weekStart : w.prevWeekStart,
                isCurrent ? w.weekEnd : w.prevWeekEnd,
                totalSessions: isCurrent ? 7 : 6,
              ),
            ),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final onlineAnalytics = _FakeAnalyticsService();
        await _provider(
          onlineAnalytics,
          httpClient: onlineClient,
        ).loadAnalytics(_profile());

        // Second load offline: network is down at the transport level.
        final offlineClient = MockClient((request) async {
          throw http.ClientException('connection refused');
        });
        final offlineAnalytics = _FakeAnalyticsService();
        final provider = _provider(offlineAnalytics, httpClient: offlineClient);

        await provider.loadAnalytics(_profile());

        expect(provider.dataSource, AnalyticsDataSource.cache);
        expect(provider.currentWeek!.totalSessions, 7);
        expect(provider.previousWeek!.totalSessions, 6);
        expect(provider.currentWeek!.startDate, w.weekStart);
        expect(offlineAnalytics.snapshotCalls, 0);
        expect(provider.error, isNull);
      },
    );

    test('offline without cached snapshot → local computation', () async {
      final client = MockClient((request) async {
        throw http.ClientException('connection refused');
      });
      final analytics = _FakeAnalyticsService();
      final provider = _provider(analytics, httpClient: client);

      await provider.loadAnalytics(_profile());

      expect(provider.dataSource, AnalyticsDataSource.local);
      expect(provider.currentWeek!.totalSessions, kLocalCurrentMarker);
      expect(analytics.snapshotCalls, 2);
    });

    test('offline with a STALE cached week (older window) → local computation, '
        'stale numbers are never mislabeled as this week', () async {
      final w = _windows();
      final staleStart = w.weekStart.subtract(const Duration(days: 14));
      final staleEnd = staleStart.add(const Duration(days: 6));
      final staleSnapshot = WeeklySnapshot(
        startDate: staleStart,
        endDate: staleEnd,
        totalSessions: 99,
      );
      SharedPreferences.setMockInitialValues({
        'analytics_snapshot_cache_p1': jsonEncode({
          'profileId': 'p1',
          'fetchedAtUtc': '2026-05-29T00:00:00.000Z',
          'currentWeek': weeklySnapshotToJson(staleSnapshot),
          'previousWeek': weeklySnapshotToJson(staleSnapshot),
        }),
      });

      final client = MockClient((request) async {
        throw http.ClientException('connection refused');
      });
      final analytics = _FakeAnalyticsService();
      final provider = _provider(analytics, httpClient: client);

      await provider.loadAnalytics(_profile());

      expect(provider.dataSource, AnalyticsDataSource.local);
      expect(provider.currentWeek!.totalSessions, kLocalCurrentMarker);
      expect(analytics.snapshotCalls, 2);
    });

    test(
      'race token: a slower stale load never overwrites a newer one',
      () async {
        final w = _windows();
        final client = MockClient((request) async {
          final profileId = request.url.queryParameters['profileId'];
          if (profileId == 'a') {
            // Profile A's fetch is slow and finishes after B's load.
            await Future<void>.delayed(const Duration(milliseconds: 200));
          }
          final start = request.url.queryParameters['start'];
          final isCurrent = start == isoDay(w.weekStart);
          return http.Response(
            jsonEncode(
              _serverPayload(
                profileId!,
                isCurrent ? w.weekStart : w.prevWeekStart,
                isCurrent ? w.weekEnd : w.prevWeekEnd,
                totalSessions: profileId == 'a' ? 11 : 22,
              ),
            ),
            200,
            headers: {'content-type': 'application/json'},
          );
        });
        final analytics = _FakeAnalyticsService();
        final provider = _provider(analytics, httpClient: client);

        final slowA = provider.loadAnalytics(_profile('a'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final fastB = provider.loadAnalytics(_profile('b'));
        await Future.wait([slowA, fastB]);

        // B is the newest load; A's late completion must be discarded.
        expect(provider.dataSource, AnalyticsDataSource.server);
        expect(provider.currentWeek!.totalSessions, 22);
        expect(provider.isLoading, isFalse);
      },
    );

    test('clear() cancels an in-flight load', () async {
      final w = _windows();
      final client = MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final start = request.url.queryParameters['start'];
        final isCurrent = start == isoDay(w.weekStart);
        return http.Response(
          jsonEncode(
            _serverPayload(
              'p1',
              isCurrent ? w.weekStart : w.prevWeekStart,
              isCurrent ? w.weekEnd : w.prevWeekEnd,
            ),
          ),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final analytics = _FakeAnalyticsService();
      final provider = _provider(analytics, httpClient: client);

      final inFlight = provider.loadAnalytics(_profile());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      provider.clear();
      await inFlight;

      expect(provider.currentWeek, isNull);
      expect(provider.previousWeek, isNull);
      expect(provider.dataSource, AnalyticsDataSource.local);
    });
  });

  group('WeeklySnapshot JSON codec', () {
    test('round-trip preserves every field', () {
      final original = WeeklySnapshot(
        startDate: DateTime(2026, 6, 8),
        endDate: DateTime(2026, 6, 12),
        totalSessions: 7,
        totalDurationMinutes: 120,
        avgDurationMinutes: 24.0,
        sessionsPerDay: const {1: 2, 3: 1, 7: 4},
        plannedDays: 5,
        completedDays: 4,
        completionRate: 0.8,
        strongCount: 3,
        okayCount: 2,
        needsWorkCount: 1,
        pagesMemorized: 2,
        pagesReviewed: 6,
        pagesPerWeek: 2.0,
      );

      final decoded = weeklySnapshotFromJson(
        jsonDecode(jsonEncode(weeklySnapshotToJson(original)))
            as Map<String, dynamic>,
      );

      expect(decoded, isNotNull);
      expect(decoded!.startDate, original.startDate);
      expect(decoded.endDate, original.endDate);
      expect(decoded.totalSessions, original.totalSessions);
      expect(decoded.totalDurationMinutes, original.totalDurationMinutes);
      expect(decoded.avgDurationMinutes, original.avgDurationMinutes);
      expect(decoded.sessionsPerDay, original.sessionsPerDay);
      expect(decoded.plannedDays, original.plannedDays);
      expect(decoded.completedDays, original.completedDays);
      expect(decoded.completionRate, original.completionRate);
      expect(decoded.strongCount, original.strongCount);
      expect(decoded.okayCount, original.okayCount);
      expect(decoded.needsWorkCount, original.needsWorkCount);
      expect(decoded.pagesMemorized, original.pagesMemorized);
      expect(decoded.pagesReviewed, original.pagesReviewed);
      expect(decoded.pagesPerWeek, original.pagesPerWeek);
    });

    test('missing dates → null (unusable payload)', () {
      expect(weeklySnapshotFromJson({'totalSessions': 3}), isNull);
    });
  });
}
