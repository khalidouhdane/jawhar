import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/services/ai_calibration_service.dart';
import 'package:quran_app/services/analytics_service.dart';
import 'package:quran_app/services/analytics_snapshot_client.dart';
import 'package:quran_app/services/notification_service.dart';
import 'package:quran_app/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Weekly snapshots resolved by [AnalyticsProvider._resolveSnapshots],
/// tagged with the source that produced them.
typedef _ResolvedSnapshots = ({
  WeeklySnapshot current,
  WeeklySnapshot previous,
  AnalyticsDataSource source,
});

/// Manages analytics state for the Hifz program.
/// Generates weekly snapshots, adaptive suggestions, and pace data.
///
/// Snapshot source (roadmap §8 Phase 6 task 2): when signed in and online
/// the weekly snapshots come from `GET /v1/me/analytics/snapshot`; the last
/// server snapshot is persisted locally and shown when offline; and the
/// original on-device computation remains the unconditional fallback — the
/// dashboard is never emptier than it was before the server existed.
/// Suggestions, smart notifications, and pace stay locally computed.
class AnalyticsProvider extends ChangeNotifier {
  static String _lastCalibrationKey(String profileId) =>
      'last_ai_calibration_at_$profileId';

  static String _snapshotCacheKey(String profileId) =>
      'analytics_snapshot_cache_$profileId';

  final AnalyticsService _analyticsService;
  final NotificationService _notificationService;
  final AICalibrationService? _calibrationService;
  final AnalyticsSnapshotClient _snapshotClient;

  WeeklySnapshot? _currentWeek;
  WeeklySnapshot? _previousWeek;
  List<Suggestion> _activeSuggestions = [];
  Map<String, dynamic>? _paceData;
  bool _isLoading = false;
  String? _error;
  bool _lastCalibrationWasAI = false;
  AnalyticsDataSource _dataSource = AnalyticsDataSource.local;

  AnalyticsProvider(
    this._analyticsService,
    this._notificationService, {
    AICalibrationService? calibrationService,
    AnalyticsSnapshotClient? snapshotClient,
  }) : _calibrationService = calibrationService,
       _snapshotClient = snapshotClient ?? AnalyticsSnapshotClient();

  bool _disposed = false;

  /// Race token: bumped by every [loadAnalytics] call and by [clear], so a
  /// stale in-flight load (slow network fetch racing a profile switch) can
  /// never overwrite newer state. Same convention as AudioProvider's
  /// `_generation`.
  int _loadGeneration = 0;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // ── Getters ──

  WeeklySnapshot? get currentWeek => _currentWeek;
  WeeklySnapshot? get previousWeek => _previousWeek;
  List<Suggestion> get activeSuggestions => _activeSuggestions
      .where((s) => s.action == SuggestionAction.pending)
      .toList();
  List<Suggestion> get allSuggestions => _activeSuggestions;
  Map<String, dynamic>? get paceData => _paceData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSuggestions => activeSuggestions.isNotEmpty;
  bool get lastCalibrationWasAI => _lastCalibrationWasAI;

  /// Which source produced [currentWeek]/[previousWeek] on the last load
  /// (server snapshot, cached server snapshot, or local computation).
  AnalyticsDataSource get dataSource => _dataSource;

  // ── Load Analytics ──

  /// Load all analytics data for a profile.
  /// Call this when the dashboard loads or when the user opens analytics.
  Future<void> loadAnalytics(
    MemoryProfile profile, {
    int totalSessionCount = 0,
  }) async {
    final gen = ++_loadGeneration;
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Calculate this week's date range (Monday to today)
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = today;

      // Previous week
      final prevWeekStart = weekStart.subtract(const Duration(days: 7));
      final prevWeekEnd = weekStart.subtract(const Duration(days: 1));

      // Resolve snapshots: server → cached server snapshot → local.
      final resolved = await _resolveSnapshots(
        profile.id,
        weekStart: weekStart,
        weekEnd: weekEnd,
        prevWeekStart: prevWeekStart,
        prevWeekEnd: prevWeekEnd,
      );
      if (_disposed || gen != _loadGeneration) return;
      _currentWeek = resolved.current;
      _previousWeek = resolved.previous;
      _dataSource = resolved.source;

      // Generate suggestions — try AI first, fall back to deterministic
      List<Suggestion> calibrationSuggestions;
      _lastCalibrationWasAI = false;

      final calService = _calibrationService;
      final prefs = await SharedPreferences.getInstance();
      if (_disposed || gen != _loadGeneration) return;
      final calibrationKey = _lastCalibrationKey(profile.id);
      final lastCalStr = prefs.getString(calibrationKey);
      final lastCal = lastCalStr != null ? DateTime.tryParse(lastCalStr) : null;

      if (calService != null &&
          calService.isCalibrationDue(
            totalSessionCount,
            lastCalibrationDate: lastCal,
          ) &&
          _currentWeek!.hasEnoughData) {
        // AI calibration
        final aiSuggestions = await calService.generateCalibration(
          profile: profile,
          currentWeek: _currentWeek!,
          previousWeek: _previousWeek,
          totalSessionCount: totalSessionCount,
        );
        if (_disposed || gen != _loadGeneration) return;
        if (aiSuggestions.isNotEmpty) {
          calibrationSuggestions = aiSuggestions;
          _lastCalibrationWasAI = true;
          await prefs.setString(
            calibrationKey,
            DateTime.now().toUtc().toIso8601String(),
          );
          if (_disposed || gen != _loadGeneration) return;
        } else {
          // AI returned empty or failed → deterministic fallback
          calibrationSuggestions = _analyticsService.generateSuggestions(
            profile,
            _currentWeek!,
            previous: _previousWeek,
          );
        }
      } else {
        // Deterministic (not enough sessions or no AI service)
        calibrationSuggestions = _analyticsService.generateSuggestions(
          profile,
          _currentWeek!,
          previous: _previousWeek,
        );
      }

      // Generate smart notifications
      final smartNotifications = await _notificationService
          .generateSmartNotifications(profile.id);
      if (_disposed || gen != _loadGeneration) return;

      // Merge, keeping existing dismissed/accepted state
      _mergeSuggestions([...calibrationSuggestions, ...smartNotifications]);

      // Calculate pace
      _paceData = await _analyticsService.calculatePace(profile.id, profile);
      if (_disposed || gen != _loadGeneration) return;

      _isLoading = false;
      _safeNotify();
    } catch (e) {
      if (_disposed || gen != _loadGeneration) return;
      _error = e.toString();
      _isLoading = false;
      _safeNotify();
    }
  }

  // ── Snapshot source selection (roadmap §8 Phase 6 task 2) ──

  /// Decision tree:
  ///
  /// 1. Transport disabled (flag off / empty base URL) → local computation.
  /// 2. Signed out, HTTP error, or unusable body → local computation.
  /// 3. Both windows fetched but all-zero (account never synced) → local
  ///    computation (the dashboard must never be emptier than today).
  /// 4. Both windows fetched and useful → server snapshots; persist them
  ///    as the offline cache.
  /// 5. Network-level failure (offline) → cached last server snapshot for
  ///    this profile and current week, else local computation.
  ///
  /// Never throws on the server/cache path; only the local computation can
  /// surface errors (exactly as before this provider knew about servers).
  Future<_ResolvedSnapshots> _resolveSnapshots(
    String profileId, {
    required DateTime weekStart,
    required DateTime weekEnd,
    required DateTime prevWeekStart,
    required DateTime prevWeekEnd,
  }) async {
    if (_snapshotClient.enabled) {
      final current = await _snapshotClient.fetchWindow(
        profileId: profileId,
        start: weekStart,
        end: weekEnd,
      );
      final previous = current.status == AnalyticsFetchStatus.ok
          ? await _snapshotClient.fetchWindow(
              profileId: profileId,
              start: prevWeekStart,
              end: prevWeekEnd,
            )
          : null;

      if (current.status == AnalyticsFetchStatus.ok &&
          previous?.status == AnalyticsFetchStatus.ok) {
        final cur = current.snapshot!;
        final prev = previous!.snapshot!;
        if (isEmptyWeeklySnapshot(cur) && isEmptyWeeklySnapshot(prev)) {
          // Nothing useful (e.g. never-synced account) → local fallback.
          AppLogger.info(
            'Analytics',
            'Server snapshots empty for $profileId — using local computation',
          );
        } else {
          await _persistSnapshotCache(profileId, cur, prev);
          return (
            current: cur,
            previous: prev,
            source: AnalyticsDataSource.server,
          );
        }
      } else if (current.status == AnalyticsFetchStatus.offline ||
          previous?.status == AnalyticsFetchStatus.offline) {
        final cached = await _readSnapshotCache(
          profileId,
          expectedWeekStart: weekStart,
        );
        if (cached != null) {
          return (
            current: cached.current,
            previous: cached.previous,
            source: AnalyticsDataSource.cache,
          );
        }
      }
    }

    // Local computation — identical to the pre-Phase-6 behavior.
    final current = await _analyticsService.generateSnapshot(
      profileId,
      weekStart,
      weekEnd,
    );
    final previous = await _analyticsService.generateSnapshot(
      profileId,
      prevWeekStart,
      prevWeekEnd,
    );
    return (
      current: current,
      previous: previous,
      source: AnalyticsDataSource.local,
    );
  }

  /// Persist the last server snapshots for offline display. Failures are
  /// logged and swallowed — caching must never break a successful load.
  Future<void> _persistSnapshotCache(
    String profileId,
    WeeklySnapshot current,
    WeeklySnapshot previous,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _snapshotCacheKey(profileId),
        jsonEncode({
          'profileId': profileId,
          'fetchedAtUtc': DateTime.now().toUtc().toIso8601String(),
          'currentWeek': weeklySnapshotToJson(current),
          'previousWeek': weeklySnapshotToJson(previous),
        }),
      );
    } catch (e) {
      AppLogger.warn('Analytics', 'snapshot cache write failed: $e');
    }
  }

  /// Read the cached server snapshots, or `null` when absent/unusable.
  ///
  /// A cached snapshot whose window starts on an OLDER week would mislabel
  /// stale numbers as "this week" while the local computation is both
  /// available offline and fresher — so the cache is only used when its
  /// current-week window matches [expectedWeekStart].
  Future<({WeeklySnapshot current, WeeklySnapshot previous})?>
  _readSnapshotCache(
    String profileId, {
    required DateTime expectedWeekStart,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_snapshotCacheKey(profileId));
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['profileId'] != profileId) return null;
      final curRaw = decoded['currentWeek'];
      final prevRaw = decoded['previousWeek'];
      if (curRaw is! Map<String, dynamic> || prevRaw is! Map<String, dynamic>) {
        return null;
      }
      final current = weeklySnapshotFromJson(curRaw);
      final previous = weeklySnapshotFromJson(prevRaw);
      if (current == null || previous == null) return null;
      if (current.startDate != expectedWeekStart) return null;
      return (current: current, previous: previous);
    } catch (e) {
      AppLogger.warn('Analytics', 'snapshot cache read failed: $e');
      return null;
    }
  }

  /// Force an AI calibration regardless of session count.
  Future<void> forceAICalibration(MemoryProfile profile) async {
    if (_calibrationService == null || _currentWeek == null) return;
    final gen = _loadGeneration;

    final aiSuggestions = await _calibrationService.generateCalibration(
      profile: profile,
      currentWeek: _currentWeek!,
      previousWeek: _previousWeek,
      totalSessionCount: 999, // bypass threshold
    );
    if (_disposed || gen != _loadGeneration) return;

    if (aiSuggestions.isNotEmpty) {
      _lastCalibrationWasAI = true;
      _mergeSuggestions(aiSuggestions);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _lastCalibrationKey(profile.id),
        DateTime.now().toUtc().toIso8601String(),
      );
      _safeNotify();
    }
  }

  /// Generate a monthly snapshot.
  Future<WeeklySnapshot?> generateMonthlySnapshot(String profileId) async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      return await _analyticsService.generateSnapshot(
        profileId,
        monthStart,
        now,
      );
    } catch (e) {
      return null;
    }
  }

  // ── Suggestion Actions ──

  /// Accept a suggestion — plan will adjust for next day.
  void acceptSuggestion(String suggestionId) {
    _activeSuggestions = _activeSuggestions.map((s) {
      if (s.id == suggestionId) {
        return s.copyWith(action: SuggestionAction.accepted);
      }
      return s;
    }).toList();
    notifyListeners();
  }

  /// Dismiss a suggestion — it disappears.
  void dismissSuggestion(String suggestionId) {
    _activeSuggestions = _activeSuggestions.map((s) {
      if (s.id == suggestionId) {
        return s.copyWith(action: SuggestionAction.dismissed);
      }
      return s;
    }).toList();
    notifyListeners();
  }

  /// Snooze a suggestion — reappears next week.
  void remindLater(String suggestionId) {
    _activeSuggestions = _activeSuggestions.map((s) {
      if (s.id == suggestionId) {
        return s.copyWith(action: SuggestionAction.remindLater);
      }
      return s;
    }).toList();
    notifyListeners();
  }

  /// Merge new suggestions with existing state.
  /// Preserves dismissed/accepted status for matching types.
  void _mergeSuggestions(List<Suggestion> newSuggestions) {
    final dismissedTypes = _activeSuggestions
        .where(
          (s) =>
              s.action == SuggestionAction.dismissed ||
              s.action == SuggestionAction.accepted,
        )
        .map((s) => s.type)
        .toSet();

    // Only add suggestions whose type hasn't been resolved this session
    _activeSuggestions = newSuggestions
        .where((s) => !dismissedTypes.contains(s.type))
        .toList();
  }

  /// Clear all analytics data (e.g., on profile switch).
  void clear() {
    _loadGeneration++; // Cancel any in-flight load.
    _currentWeek = null;
    _previousWeek = null;
    _activeSuggestions = [];
    _paceData = null;
    _error = null;
    _dataSource = AnalyticsDataSource.local;
    notifyListeners();
  }
}
