import 'package:flutter/material.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/services/ai_calibration_service.dart';
import 'package:quran_app/services/analytics_service.dart';
import 'package:quran_app/services/notification_service.dart';

/// Manages analytics state for the Hifz program.
/// Generates weekly snapshots, adaptive suggestions, and pace data.
class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService;
  final NotificationService _notificationService;
  final AICalibrationService? _calibrationService;

  WeeklySnapshot? _currentWeek;
  WeeklySnapshot? _previousWeek;
  List<Suggestion> _activeSuggestions = [];
  Map<String, dynamic>? _paceData;
  bool _isLoading = false;
  String? _error;
  bool _lastCalibrationWasAI = false;

  AnalyticsProvider(
    this._analyticsService,
    this._notificationService, {
    AICalibrationService? calibrationService,
  }) : _calibrationService = calibrationService;

  // ── Getters ──

  WeeklySnapshot? get currentWeek => _currentWeek;
  WeeklySnapshot? get previousWeek => _previousWeek;
  List<Suggestion> get activeSuggestions =>
      _activeSuggestions.where((s) => s.action == SuggestionAction.pending).toList();
  List<Suggestion> get allSuggestions => _activeSuggestions;
  Map<String, dynamic>? get paceData => _paceData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSuggestions => activeSuggestions.isNotEmpty;
  bool get lastCalibrationWasAI => _lastCalibrationWasAI;

  // ── Load Analytics ──

  /// Load all analytics data for a profile.
  /// Call this when the dashboard loads or when the user opens analytics.
  Future<void> loadAnalytics(MemoryProfile profile, {int totalSessionCount = 0}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Calculate this week's date range (Monday to today)
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = today;

      // Previous week
      final prevWeekStart = weekStart.subtract(const Duration(days: 7));
      final prevWeekEnd = weekStart.subtract(const Duration(days: 1));

      // Generate snapshots
      _currentWeek = await _analyticsService.generateSnapshot(
        profile.id,
        weekStart,
        weekEnd,
      );

      _previousWeek = await _analyticsService.generateSnapshot(
        profile.id,
        prevWeekStart,
        prevWeekEnd,
      );

      // Generate suggestions — try AI first, fall back to deterministic
      List<Suggestion> calibrationSuggestions;
      _lastCalibrationWasAI = false;

      final calService = _calibrationService;
      if (calService != null &&
          calService.isCalibrationDue(totalSessionCount) &&
          _currentWeek!.hasEnoughData) {
        // AI calibration
        final aiSuggestions = await calService.generateCalibration(
          profile: profile,
          currentWeek: _currentWeek!,
          previousWeek: _previousWeek,
          totalSessionCount: totalSessionCount,
        );
        if (aiSuggestions.isNotEmpty) {
          calibrationSuggestions = aiSuggestions;
          _lastCalibrationWasAI = true;
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
      final smartNotifications =
          await _notificationService.generateSmartNotifications(profile.id);

      // Merge, keeping existing dismissed/accepted state
      _mergeSuggestions([...calibrationSuggestions, ...smartNotifications]);

      // Calculate pace
      _paceData = await _analyticsService.calculatePace(profile.id, profile);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force an AI calibration regardless of session count.
  Future<void> forceAICalibration(MemoryProfile profile) async {
    if (_calibrationService == null || _currentWeek == null) return;

    final aiSuggestions = await _calibrationService!.generateCalibration(
      profile: profile,
      currentWeek: _currentWeek!,
      previousWeek: _previousWeek,
      totalSessionCount: 999, // bypass threshold
    );

    if (aiSuggestions.isNotEmpty) {
      _lastCalibrationWasAI = true;
      _mergeSuggestions(aiSuggestions);
      notifyListeners();
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
        .where((s) =>
            s.action == SuggestionAction.dismissed ||
            s.action == SuggestionAction.accepted)
        .map((s) => s.type)
        .toSet();

    // Only add suggestions whose type hasn't been resolved this session
    _activeSuggestions = newSuggestions
        .where((s) => !dismissedTypes.contains(s.type))
        .toList();
  }

  /// Clear all analytics data (e.g., on profile switch).
  void clear() {
    _currentWeek = null;
    _previousWeek = null;
    _activeSuggestions = [];
    _paceData = null;
    _error = null;
    notifyListeners();
  }
}
