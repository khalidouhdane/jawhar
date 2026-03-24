import 'package:flutter/material.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/models/session_recipe_models.dart';
import 'package:quran_app/services/ai_plan_service.dart';
import 'package:quran_app/services/ai_plan_validator.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/services/plan_generation_service.dart';

/// AI plan generation progress states.
enum AiProgress { idle, analyzing, generating, validating, done, fallback }

/// Manages today's daily plan state.
/// Tries AI plan generation first, falls back to deterministic.
class PlanProvider extends ChangeNotifier {
  final HifzDatabaseService _db;
  final PlanGenerationService _planService;
  final AIPlanService? _aiService;

  DailyPlan? _todayPlan;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isRestDay = false;
  int _todaySessionCount = 0;
  List<SessionRecipe> _todayRecipes = [];
  bool _isAiGenerated = false;
  String? _aiReasoning;
  AiProgress _aiProgress = AiProgress.idle;

  PlanProvider(this._db, {AIPlanService? aiPlanService})
      : _planService = PlanGenerationService(_db),
        _aiService = aiPlanService;

  // ── Getters ──

  DailyPlan? get todayPlan => _todayPlan;
  bool get isLoading => _isLoading;
  bool get hasPlan => _todayPlan != null;
  bool get hasError => _hasError;
  bool get isRestDay => _isRestDay;
  int get todaySessionCount => _todaySessionCount;
  bool get isPlanCompleted => _todayPlan?.isCompleted ?? false;
  List<SessionRecipe> get todayRecipes => _todayRecipes;
  bool get isAiGenerated => _isAiGenerated;
  String? get aiReasoning => _aiReasoning;
  AiProgress get aiProgress => _aiProgress;

  /// Check if today is a rest day for the given profile.
  /// Days are 0=Monday, 1=Tuesday, ..., 6=Sunday.
  static bool isTodayRestDay(MemoryProfile profile) {
    if (profile.activeDays.length >= 7) return false; // All days active
    final today = DateTime.now().weekday - 1; // DateTime: 1=Mon → 0-indexed
    return !profile.activeDays.contains(today);
  }

  /// Check if a specific date is a rest day.
  static bool isDateRestDay(DateTime date, List<int> activeDays) {
    if (activeDays.length >= 7) return false;
    final dayIndex = date.weekday - 1; // 0=Mon..6=Sun
    return !activeDays.contains(dayIndex);
  }

  // ── Load or generate today's plan ──

  /// Load existing plan for today, or generate a new one.
  /// If today is a rest day, no plan is generated.
  Future<void> loadOrGeneratePlan(MemoryProfile profile,
      {bool forceRegenerate = false}) async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    // Check rest day
    _isRestDay = isTodayRestDay(profile);
    if (_isRestDay && !forceRegenerate) {
      _todayPlan = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // Try AI plan generation first
      bool aiSuccess = false;
      if (_aiService != null && !forceRegenerate) {
        try {
          aiSuccess = await _tryAIPlanGeneration(profile);
          if (!aiSuccess) {
            _aiProgress = AiProgress.fallback;
            notifyListeners();
          }
        } catch (e) {
          debugPrint('AI plan generation failed, falling back: $e');
          _aiProgress = AiProgress.fallback;
          notifyListeners();
        }
      }

      // Fallback to deterministic if AI didn't work
      if (!aiSuccess) {
        _todayPlan = await _planService.generateTodayPlan(
          profile,
          forceRegenerate: forceRegenerate,
        );
        _isAiGenerated = false;
        _aiReasoning = null;
        _todayRecipes = [];
      }

      // If plan exists, load any stored recipes — or generate defaults
      if (_todayPlan != null && _todayRecipes.isEmpty) {
        try {
          _todayRecipes = await _db.getRecipesForPlan(_todayPlan!.id);
        } catch (e) {
          debugPrint('[AI] Recipe DB load failed: $e');
        }

        // No stored recipes? Generate and save defaults.
        if (_todayRecipes.isEmpty) {
          _todayRecipes = PlanGenerationService.generateDefaultRecipes(_todayPlan!);
          try {
            await _db.saveRecipes(_todayRecipes);
          } catch (e) {
            debugPrint('[AI] Recipe DB save failed: $e');
          }
        }
      }

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
    _todayRecipes = [];
    _isAiGenerated = false;
    _aiReasoning = null;
    _aiProgress = AiProgress.idle;
    notifyListeners();
  }

  // ── AI Plan Generation ──

  /// Try to generate a plan using AI. Returns true if successful.
  Future<bool> _tryAIPlanGeneration(MemoryProfile profile) async {
    // Check if plan already exists for today
    final existing = await _db.getTodayPlan(profile.id);
    if (existing != null) {
      _todayPlan = existing;
      _isAiGenerated = existing.isAiGenerated;
      _aiReasoning = existing.aiReasoning;
      _aiProgress = AiProgress.done;
      return true;
    }

    // Step 1: Analyzing progress
    _aiProgress = AiProgress.analyzing;
    notifyListeners();

    // Build progress snapshot for AI context
    final allProgress = await _db.getAllPageProgress(profile.id);
    final sessions = await _db.getSessionHistory(profile.id, limit: 10);
    final recentSessions = sessions.map((s) => {
      'date': s.date.toIso8601String(),
      'durationMinutes': s.durationMinutes,
      'sabaqCompleted': s.sabaqCompleted,
      'sabaqPage': s.sabaqPage,
      'sabaqAssessment': s.sabaqAssessment?.name,
      'repCount': s.repCount,
    }).toList();

    final strongCount = allProgress.values
        .where((p) => p.status == PageStatus.memorized)
        .length;

    final progressSnapshot = {
      'totalPagesMemorized': allProgress.length,
      'strongPages': strongCount,
      'currentSabaqPage': profile.startingPage + allProgress.length,
    };

    // Step 2: Generating plan via AI
    _aiProgress = AiProgress.generating;
    notifyListeners();

    // Call AI
    final rawResult = await _aiService!.generatePlan(
      profile: profile,
      progressSnapshot: progressSnapshot,
      recentSessions: recentSessions,
    );

    // Step 3: Validating result
    _aiProgress = AiProgress.validating;
    notifyListeners();

    // Validate
    final validated = AIPlanValidator.validate(rawResult);
    final planData = validated['plan'] as Map<String, dynamic>;
    final sabaq = planData['sabaq'] as Map<String, dynamic>;
    final sabqi = planData['sabqi'] as Map<String, dynamic>? ?? {};
    final manzil = planData['manzil'] as Map<String, dynamic>? ?? {};
    final reasoning = validated['reasoning'] as String? ?? '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final planId = '${profile.id}_${today.toIso8601String()}_ai_${now.millisecondsSinceEpoch}';

    // Extract pages first to determine if phases should be active
    final sabqiPages = (sabqi['pages'] as List<dynamic>?)?.cast<int>() ?? [];
    final manzilPages = (manzil['pages'] as List<dynamic>?)?.cast<int>() ?? [];
    final hasSabqiContent = sabqiPages.isNotEmpty;
    final hasManzilContent = manzilPages.isNotEmpty;

    // ── Smart time redistribution (mirrors deterministic logic) ──
    // Always use the full daily budget. AI suggestions are hints,
    // but the total must equal profile.dailyTimeMinutes.
    int sabaqTargetMin, sabqiTargetMin, manzilTargetMin;

    if (!hasSabqiContent && !hasManzilContent) {
      // Sabaq only → full daily budget
      sabaqTargetMin = profile.dailyTimeMinutes;
      sabqiTargetMin = 0;
      manzilTargetMin = 0;
    } else if (hasSabqiContent && !hasManzilContent) {
      // Sabaq + sabqi → 60/40 split
      sabaqTargetMin = (profile.dailyTimeMinutes * 0.60).round();
      sabqiTargetMin = profile.dailyTimeMinutes - sabaqTargetMin;
      manzilTargetMin = 0;
    } else if (!hasSabqiContent && hasManzilContent) {
      // Sabaq + manzil → 65/35 split
      sabaqTargetMin = (profile.dailyTimeMinutes * 0.65).round();
      manzilTargetMin = profile.dailyTimeMinutes - sabaqTargetMin;
      sabqiTargetMin = 0;
    } else {
      // All three phases → use AI suggestions if they add up right
      final aiTotal = (sabaq['targetMinutes'] as int? ?? 15)
          + (sabqi['targetMinutes'] as int? ?? 10)
          + (manzil['targetMinutes'] as int? ?? 10);
      if (aiTotal == profile.dailyTimeMinutes) {
        sabaqTargetMin = sabaq['targetMinutes'] as int? ?? 15;
        sabqiTargetMin = sabqi['targetMinutes'] as int? ?? 10;
        manzilTargetMin = manzil['targetMinutes'] as int? ?? 10;
      } else {
        // Fallback: standard 45/30/25 split
        sabaqTargetMin = (profile.dailyTimeMinutes * 0.45).round();
        sabqiTargetMin = (profile.dailyTimeMinutes * 0.30).round();
        manzilTargetMin = profile.dailyTimeMinutes - sabaqTargetMin - sabqiTargetMin;
      }
    }

    final plan = DailyPlan(
      id: planId,
      profileId: profile.id,
      date: today,
      sabaqPage: sabaq['page'] as int? ?? profile.startingPage,
      sabaqLineStart: sabaq['lineStart'] as int? ?? 1,
      sabaqLineEnd: sabaq['lineEnd'] as int? ?? 15,
      sabaqRepetitionTarget: sabaq['repetitionTarget'] as int? ?? 10,
      sabaqTargetMinutes: sabaqTargetMin,
      sabqiPages: sabqiPages,
      sabqiTargetMinutes: sabqiTargetMin,
      manzilPages: manzilPages,
      manzilJuz: manzil['juz'] as int? ?? 0,
      manzilTargetMinutes: manzilTargetMin,
      isAiGenerated: true,
      aiReasoning: reasoning,
      // Auto-skip empty phases so they don't show in the session
      sabqiDoneOffline: !hasSabqiContent,
      manzilDoneOffline: !hasManzilContent,
    );

    // Save plan
    await _db.saveDailyPlan(plan);

    // Parse and save recipes if present
    final recipesRaw = validated['recipes'] as Map<String, dynamic>? ?? {};
    if (recipesRaw.isNotEmpty) {
      _todayRecipes = [];
      for (final entry in recipesRaw.entries) {
        final phaseKey = entry.key;
        if (entry.value is! Map<String, dynamic>) continue;
        _todayRecipes.add(SessionRecipe.fromAIResponse(
          planId: planId,
          phase: phaseKey,
          recipeMap: entry.value as Map<String, dynamic>,
        ));
      }
      try {
        await _db.saveRecipes(_todayRecipes);
      } catch (e) {
        debugPrint('[AI] AI recipe save failed: $e');
      }
    }

    _todayPlan = plan;
    _isAiGenerated = true;
    _aiReasoning = reasoning;
    _aiProgress = AiProgress.done;
    return true;
  }
}
