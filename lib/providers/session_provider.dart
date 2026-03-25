import 'package:flutter/material.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/models/session_recipe_models.dart';
import 'package:quran_app/services/auth_service.dart';
import 'package:quran_app/services/cloud_sync_service.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/services/card_generation_service.dart';

/// Manages the active Hifz session state.
/// Tracks timer, rep counts, phase progression, and self-assessments.
class SessionProvider extends ChangeNotifier {
  final HifzDatabaseService _db;
  final AuthService _auth;
  final CloudSyncService _sync;

  DailyPlan? _plan;
  SessionPhase _currentPhase = SessionPhase.sabaq;
  bool _isActive = false;
  bool _isPaused = false;

  // Timer state (managed by the UI Stopwatch, not a Dart Timer)
  int _elapsedSeconds = 0;
  int _targetSeconds = 0; // Countdown target (0 = no countdown, count up)
  int _repCount = 0;
  int _totalSessionReps = 0; // Accumulated across all phases

  // Per-phase assessments
  SelfAssessment? _sabaqAssessment;
  SelfAssessment? _sabqiAssessment;
  SelfAssessment? _manzilAssessment;

  // Phase completion
  bool _sabaqDone = false;
  bool _sabqiDone = false;
  bool _manzilDone = false;

  // Show assessment
  bool _showingAssessment = false;

  // Actual coverage tracking (CE-3)
  bool _showingCoverageDialog = false;
  List<int> _actualPagesCovered = [];
  int? _lastVerseLearned;     // CE-9: verse-level coverage
  int? _totalVersesOnPage;    // CE-9: total verses on the page

  // ── Recipe-guided mode ──
  bool _isGuidedMode = true;
  Map<String, SessionRecipe> _recipes = {}; // keyed by phase name
  int _currentStepIndex = 0;
  int _stepRepCount = 0; // rep count for current step

  SessionProvider(this._db, this._auth, this._sync);

  // ── Getters ──

  DailyPlan? get plan => _plan;
  SessionPhase get currentPhase => _currentPhase;
  bool get isActive => _isActive;
  bool get isPaused => _isPaused;
  int get elapsedSeconds => _elapsedSeconds;
  int get targetSeconds => _targetSeconds;
  int get repCount => _repCount;

  /// Seconds remaining on the countdown (negative = overtime).
  int get remainingSeconds => _targetSeconds > 0 ? _targetSeconds - _elapsedSeconds : 0;

  /// Whether the user has gone past the allocated time.
  bool get isOvertime => _targetSeconds > 0 && _elapsedSeconds > _targetSeconds;
  bool get showingAssessment => _showingAssessment;
  bool get showingCoverageDialog => _showingCoverageDialog;
  List<int> get actualPagesCovered => _actualPagesCovered;

  bool get sabaqDone => _sabaqDone;
  bool get sabqiDone => _sabqiDone;
  bool get manzilDone => _manzilDone;

  SelfAssessment? get sabaqAssessment => _sabaqAssessment;
  SelfAssessment? get sabqiAssessment => _sabqiAssessment;
  SelfAssessment? get manzilAssessment => _manzilAssessment;

  int get totalRepCount => _totalSessionReps;

  // Recipe-guided mode getters
  bool get isGuidedMode => _isGuidedMode;
  int get currentStepIndex => _currentStepIndex;
  int get stepRepCount => _stepRepCount;

  /// Get the recipe for the current phase (may be null/empty).
  SessionRecipe? get currentRecipe {
    final key = _currentPhase.name; // 'sabaq', 'sabqi', 'manzil'
    return _recipes[key];
  }

  /// Get the current step from the active recipe (null if no recipe or past end).
  RecipeStep? get currentStep {
    final recipe = currentRecipe;
    if (recipe == null || recipe.isEmpty) return null;
    if (_currentStepIndex >= recipe.steps.length) return null;
    return recipe.steps[_currentStepIndex];
  }

  /// Whether the current step target has been met.
  bool get isStepComplete {
    final step = currentStep;
    if (step == null) return false;
    return _stepRepCount >= step.target;
  }

  /// Whether there are recipes loaded and guided mode makes sense.
  bool get hasRecipes => _recipes.values.any((r) => r.isNotEmpty);

  bool get isSessionComplete => _sabaqDone && _sabqiDone && _manzilDone;

  /// Number of active (non-offline) phases in this session.
  int get activePhaseCount {
    int c = 0;
    if (_plan != null) {
      if (!_plan!.sabaqDoneOffline) c++;
      if (!_plan!.sabqiDoneOffline && _plan!.sabqiPages.isNotEmpty) c++;
      if (!_plan!.manzilDoneOffline && _plan!.manzilPages.isNotEmpty) c++;
    }
    return c;
  }

  /// Current step number (1-based) among active phases.
  int get currentStepNumber {
    int step = 0;
    if (_plan != null) {
      if (!_plan!.sabaqDoneOffline) {
        step++;
        if (_currentPhase == SessionPhase.sabaq) return step;
      }
      if (!_plan!.sabqiDoneOffline && _plan!.sabqiPages.isNotEmpty) {
        step++;
        if (_currentPhase == SessionPhase.sabqi) return step;
      }
      if (!_plan!.manzilDoneOffline && _plan!.manzilPages.isNotEmpty) {
        step++;
        if (_currentPhase == SessionPhase.manzil) return step;
      }
    }
    return step;
  }

  String get currentPhaseLabel {
    switch (_currentPhase) {
      case SessionPhase.sabaq: return 'New Memorization';
      case SessionPhase.sabqi: return 'Recent Review';
      case SessionPhase.manzil: return 'Long-term Review';
      case SessionPhase.flashcards: return 'Flashcards';
    }
  }

  String get currentPhaseEmoji {
    switch (_currentPhase) {
      case SessionPhase.sabaq: return '📖';
      case SessionPhase.sabqi: return '🔁';
      case SessionPhase.manzil: return '📚';
      case SessionPhase.flashcards: return '🃏';
    }
  }

  // ── Session lifecycle ──

  /// Start a session with the given plan.
  void startSession(DailyPlan plan) {
    _plan = plan;
    _isActive = true;
    _isPaused = false;
    _elapsedSeconds = 0;
    _targetSeconds = 0;
    _repCount = 0;
    _totalSessionReps = 0;
    _sabaqAssessment = null;
    _sabqiAssessment = null;
    _manzilAssessment = null;
    _sabaqDone = plan.sabaqDoneOffline;
    _sabqiDone = plan.sabqiDoneOffline;
    _manzilDone = plan.manzilDoneOffline;
    _showingAssessment = false;
    _showingCoverageDialog = false;
    _actualPagesCovered = [];

    // Start with the first non-offline phase
    if (!_sabaqDone) {
      _currentPhase = SessionPhase.sabaq;
    } else if (!_sabqiDone) {
      _currentPhase = SessionPhase.sabqi;
    } else if (!_manzilDone) {
      _currentPhase = SessionPhase.manzil;
    }

    // Reset guided mode state
    _currentStepIndex = 0;
    _stepRepCount = 0;

    notifyListeners();
  }

  /// Load recipes for the current session (call after startSession).
  void loadRecipes(List<SessionRecipe> recipes) {
    _recipes = {};
    for (final r in recipes) {
      _recipes[r.phase] = r;
    }
    _currentStepIndex = 0;
    _stepRepCount = 0;
    notifyListeners();
  }

  /// Toggle between guided and free mode.
  void toggleGuidedMode() {
    _isGuidedMode = !_isGuidedMode;
    notifyListeners();
  }

  /// Set guided mode explicitly.
  void setGuidedMode(bool guided) {
    _isGuidedMode = guided;
    notifyListeners();
  }

  /// Increment elapsed time by 1 second (called from UI timer).
  void tick() {
    if (!_isActive || _isPaused) return;
    _elapsedSeconds++;
    notifyListeners();
  }

  /// Count a repetition.
  void countRep() {
    _repCount++;
    _totalSessionReps++;
    _stepRepCount++;
    notifyListeners();
  }

  /// Reset rep counter to 0.
  void resetReps() {
    _repCount = 0;
    notifyListeners();
  }

  /// Set the countdown target in minutes.
  void setTargetTime(int minutes) {
    _targetSeconds = minutes * 60;
    notifyListeners();
  }

  /// Adjust countdown target by delta minutes (e.g., +1 or -1).
  void adjustTime(int deltaMinutes) {
    _targetSeconds = (_targetSeconds + deltaMinutes * 60).clamp(60, 7200);
    notifyListeners();
  }

  /// Toggle pause/resume.
  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  /// Complete the current phase and request self-assessment.
  void finishPhase() {
    _showingAssessment = true;
    notifyListeners();
  }

  /// Submit self-assessment for the current phase.
  void submitAssessment(SelfAssessment assessment) {
    switch (_currentPhase) {
      case SessionPhase.sabaq:
        _sabaqAssessment = assessment;
        _sabaqDone = true;
        _showingAssessment = false;
        // Show coverage dialog for sabaq only
        _showingCoverageDialog = true;
        _repCount = 0;
        notifyListeners();
        return; // Don't advance yet — wait for coverage input
      case SessionPhase.sabqi:
        _sabqiAssessment = assessment;
        _sabqiDone = true;
        break;
      case SessionPhase.manzil:
        _manzilAssessment = assessment;
        _manzilDone = true;
        break;
      case SessionPhase.flashcards:
        break;
    }

    _showingAssessment = false;
    _repCount = 0;

    // Move to the next incomplete phase
    if (!isSessionComplete) {
      _advanceToNextPhase();
    }

    notifyListeners();
  }

  /// Set the actual pages covered during sabaq and advance.
  /// [pages] is the list of page numbers actually covered.
  /// CE-9: [lastVerseLearned] and [totalVersesOnPage] track partial page progress.
  void setActualCoverage(List<int> pages, {int? lastVerseLearned, int? totalVersesOnPage}) {
    _actualPagesCovered = pages;
    _lastVerseLearned = lastVerseLearned;
    _totalVersesOnPage = totalVersesOnPage;
    _showingCoverageDialog = false;

    // Move to the next incomplete phase
    if (!isSessionComplete) {
      _advanceToNextPhase();
    }

    notifyListeners();
  }

  /// Skip the current phase.
  void skipPhase() {
    switch (_currentPhase) {
      case SessionPhase.sabaq: _sabaqDone = true; break;
      case SessionPhase.sabqi: _sabqiDone = true; break;
      case SessionPhase.manzil: _manzilDone = true; break;
      case SessionPhase.flashcards: break;
    }
    _repCount = 0;
    _stepRepCount = 0;
    _currentStepIndex = 0;
    _showingAssessment = false;

    if (!isSessionComplete) {
      _advanceToNextPhase();
    }
    notifyListeners();
  }

  /// Advance to next step in the recipe (guided mode).
  void nextStep() {
    final recipe = currentRecipe;
    if (recipe == null || recipe.isEmpty) return;
    if (_currentStepIndex < recipe.steps.length - 1) {
      _currentStepIndex++;
      _stepRepCount = 0;
      notifyListeners();
    }
  }

  /// Go back to previous step in the recipe (guided mode).
  void previousStep() {
    if (_currentStepIndex > 0) {
      _currentStepIndex--;
      _stepRepCount = 0;
      notifyListeners();
    }
  }

  /// Skip the current recipe step (guided mode).
  void skipStep() {
    nextStep();
  }

  void _advanceToNextPhase() {
    if (!_sabaqDone) {
      _currentPhase = SessionPhase.sabaq;
    } else if (!_sabqiDone) {
      _currentPhase = SessionPhase.sabqi;
    } else if (!_manzilDone) {
      _currentPhase = SessionPhase.manzil;
    }
    // Reset step tracking for the new phase
    _currentStepIndex = 0;
    _stepRepCount = 0;

    // Reset timer for the new phase's allocated minutes
    _elapsedSeconds = 0;
    if (_plan != null) {
      int phaseMinutes;
      switch (_currentPhase) {
        case SessionPhase.sabaq:
          phaseMinutes = _plan!.sabaqTargetMinutes;
          break;
        case SessionPhase.sabqi:
          phaseMinutes = _plan!.sabqiTargetMinutes;
          break;
        case SessionPhase.manzil:
          phaseMinutes = _plan!.manzilTargetMinutes;
          break;
        default:
          phaseMinutes = 0;
      }
      _targetSeconds = phaseMinutes * 60;
    }
  }

  /// Complete the session and save it to the database.
  Future<SessionRecord> completeSession() async {
    _isActive = false;
    _isPaused = false;

    // Determine actual sabaq pages: use reported coverage, or fall back to planned page
    final coveredPages = _actualPagesCovered.isNotEmpty
        ? _actualPagesCovered
        : (_plan != null ? [_plan!.sabaqPage] : <int>[]);

    final record = SessionRecord(
      id: '${_plan?.profileId}_${DateTime.now().millisecondsSinceEpoch}',
      profileId: _plan?.profileId ?? '',
      date: DateTime.now(),
      durationMinutes: (_elapsedSeconds / 60).ceil(),
      sabaqCompleted: _sabaqDone,
      sabqiCompleted: _sabqiDone,
      manzilCompleted: _manzilDone,
      sabaqAssessment: _sabaqAssessment,
      sabqiAssessment: _sabqiAssessment,
      manzilAssessment: _manzilAssessment,
      sabaqPage: _plan?.sabaqPage,
      sabqiPages: _plan?.sabqiPages ?? [],
      manzilPages: _plan?.manzilPages ?? [],
      repCount: _totalSessionReps,
    );

    await _db.saveSessionRecord(record);

    // ── Save page progress with status promotion ──
    // Sabaq pages → learning (new memorization)
    if (_sabaqDone && _plan != null) {
      for (int i = 0; i < coveredPages.length; i++) {
        final page = coveredPages[i];
        final isLastPage = i == coveredPages.length - 1;
        // Check if this page already exists (to increment reviewCount)
        final existing = await _db.getAllPageProgress(_plan!.profileId);
        final prev = existing[page];
        await _db.savePageProgress(PageProgress(
          pageNumber: page,
          profileId: _plan!.profileId,
          status: PageStatus.learning,
          lastReviewedAt: DateTime.now(),
          reviewCount: (prev?.reviewCount ?? 0) + 1,
          lastVerseLearned: isLastPage ? _lastVerseLearned : null,
          totalVersesOnPage: isLastPage ? _totalVersesOnPage : null,
        ));
      }
    }

    // Sabqi pages → reviewing (short-term review promotes from learning)
    if (_sabqiDone && _plan != null) {
      final existing = await _db.getAllPageProgress(_plan!.profileId);
      for (final page in _plan!.sabqiPages) {
        final prev = existing[page];
        await _db.savePageProgress(PageProgress(
          pageNumber: page,
          profileId: _plan!.profileId,
          status: PageStatus.reviewing,
          lastReviewedAt: DateTime.now(),
          reviewCount: (prev?.reviewCount ?? 0) + 1,
        ));
      }
    }

    // Manzil pages → memorized (if Strong) or reviewing (if weaker)
    if (_manzilDone && _plan != null) {
      final isStrong = _manzilAssessment == 'strong';
      final existing = await _db.getAllPageProgress(_plan!.profileId);
      for (final page in _plan!.manzilPages) {
        final prev = existing[page];
        final newStatus = isStrong ? PageStatus.memorized : PageStatus.reviewing;
        await _db.savePageProgress(PageProgress(
          pageNumber: page,
          profileId: _plan!.profileId,
          status: newStatus,
          lastReviewedAt: DateTime.now(),
          reviewCount: (prev?.reviewCount ?? 0) + 1,
          memorizedAt: isStrong ? DateTime.now() : prev?.memorizedAt,
        ));
      }
    }

    // Record as an active day
    if (_plan != null) {
      await _db.recordActiveDay(_plan!.profileId);
    }

    // Generate flashcards from the pages just practiced
    if (_plan != null) {
      try {
        final gen = CardGenerationService(_db);
        final count = await gen.generateCards(_plan!.profileId);
        if (count > 0) {
          debugPrint('Generated $count flashcards after session completion');
        }
      } catch (e) {
        debugPrint('Flashcard generation after session failed: $e');
      }
    }

    // ── Cloud sync (fire-and-forget) ──
    if (_auth.isSignedIn && _plan != null) {
      final uid = _auth.uid!;
      _sync.syncSession(uid, record);
      _sync.syncStreak(uid, await _db.getStreak(_plan!.profileId));
      // Sync all progress pages involved
      final allProgress = await _db.getAllPageProgress(_plan!.profileId);
      for (final page in coveredPages) {
        final p = allProgress[page];
        if (p != null) {
          _sync.syncProgress(uid, page, p.toMap());
        }
      }
    }

    notifyListeners();
    return record;
  }

  /// Clear session state (on exit without completing).
  void clearSession() {
    _isActive = false;
    _isPaused = false;
    _plan = null;
    _elapsedSeconds = 0;
    _targetSeconds = 0;
    _repCount = 0;
    _totalSessionReps = 0;
    _showingAssessment = false;
    _showingCoverageDialog = false;
    _actualPagesCovered = [];
    _lastVerseLearned = null;
    _totalVersesOnPage = null;
    _recipes = {};
    _currentStepIndex = 0;
    _stepRepCount = 0;
    notifyListeners();
  }
}
