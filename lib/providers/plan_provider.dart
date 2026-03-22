import 'package:flutter/material.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/services/plan_generation_service.dart';

/// Manages today's daily plan state.
class PlanProvider extends ChangeNotifier {
  final HifzDatabaseService _db;
  final PlanGenerationService _planService;

  DailyPlan? _todayPlan;
  bool _isLoading = false;
  bool _hasError = false;
  int _todaySessionCount = 0;

  PlanProvider(this._db) : _planService = PlanGenerationService(_db);

  // ── Getters ──

  DailyPlan? get todayPlan => _todayPlan;
  bool get isLoading => _isLoading;
  bool get hasPlan => _todayPlan != null;
  bool get hasError => _hasError;
  int get todaySessionCount => _todaySessionCount;
  bool get isPlanCompleted => _todayPlan?.isCompleted ?? false;

  // ── Load or generate today's plan ──

  /// Load existing plan for today, or generate a new one.
  Future<void> loadOrGeneratePlan(MemoryProfile profile,
      {bool forceRegenerate = false}) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      _todayPlan = await _planService.generateTodayPlan(
        profile,
        forceRegenerate: forceRegenerate,
      );
      // Count how many sessions were done today
      _todaySessionCount = await _db.getSessionCountForDate(
        profile.id,
        DateTime.now(),
      );
    } catch (e) {
      debugPrint('Plan generation error: $e');
      _hasError = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Force-regenerate today's plan (after completing a session).
  /// This ensures the next sabaq page is assigned.
  Future<void> regeneratePlan(MemoryProfile profile) async {
    _todaySessionCount++;
    await loadOrGeneratePlan(profile, forceRegenerate: true);
  }

  /// Generate a fresh extra session plan (CE-2).
  /// Called when the user wants to do more after completing today's plan.
  Future<void> generateExtraSession(MemoryProfile profile) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Force-create a new plan from current progress
      _todayPlan = await _planService.generateTodayPlan(
        profile,
        forceRegenerate: true,
      );
      // Mark it as not completed (it's a fresh session)
      if (_todayPlan != null) {
        _todayPlan = _todayPlan!.copyWith(isCompleted: false);
        await _db.updateDailyPlan(_todayPlan!);
      }
    } catch (e) {
      debugPrint('Extra session generation error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Plan modifications ──

  /// Mark a phase as done offline ("I already did this").
  Future<void> markPhaseOffline(SessionPhase phase) async {
    if (_todayPlan == null) return;

    switch (phase) {
      case SessionPhase.sabaq:
        _todayPlan = _todayPlan!.copyWith(sabaqDoneOffline: true);
        break;
      case SessionPhase.sabqi:
        _todayPlan = _todayPlan!.copyWith(sabqiDoneOffline: true);
        break;
      case SessionPhase.manzil:
        _todayPlan = _todayPlan!.copyWith(manzilDoneOffline: true);
        break;
      case SessionPhase.flashcards:
        break; // Not applicable yet
    }

    await _db.updateDailyPlan(_todayPlan!);
    notifyListeners();
  }

  /// Mark the plan as fully completed.
  Future<void> completePlan() async {
    if (_todayPlan == null) return;
    _todayPlan = _todayPlan!.copyWith(isCompleted: true);
    await _db.updateDailyPlan(_todayPlan!);
    notifyListeners();
  }

  /// Override the plan with custom content.
  Future<void> overridePlan(DailyPlan newPlan) async {
    _todayPlan = newPlan;
    await _db.updateDailyPlan(newPlan);
    notifyListeners();
  }

  /// Clear the plan (e.g., on profile switch).
  void clearPlan() {
    _todayPlan = null;
    _todaySessionCount = 0;
    notifyListeners();
  }
}
