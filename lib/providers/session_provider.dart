import 'package:flutter/material.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/services/card_generation_service.dart';

/// Manages the active Hifz session state.
/// Tracks timer, rep counts, phase progression, and self-assessments.
class SessionProvider extends ChangeNotifier {
  final HifzDatabaseService _db;

  DailyPlan? _plan;
  SessionPhase _currentPhase = SessionPhase.sabaq;
  bool _isActive = false;
  bool _isPaused = false;

  // Timer state (managed by the UI Stopwatch, not a Dart Timer)
  int _elapsedSeconds = 0;
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

  SessionProvider(this._db);

  // ── Getters ──

  DailyPlan? get plan => _plan;
  SessionPhase get currentPhase => _currentPhase;
  bool get isActive => _isActive;
  bool get isPaused => _isPaused;
  int get elapsedSeconds => _elapsedSeconds;
  int get repCount => _repCount;
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
    notifyListeners();
  }

  /// Reset rep counter to 0.
  void resetReps() {
    _repCount = 0;
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
    _showingAssessment = false;

    if (!isSessionComplete) {
      _advanceToNextPhase();
    }
    notifyListeners();
  }

  void _advanceToNextPhase() {
    if (!_sabaqDone) {
      _currentPhase = SessionPhase.sabaq;
    } else if (!_sabqiDone) {
      _currentPhase = SessionPhase.sabqi;
    } else if (!_manzilDone) {
      _currentPhase = SessionPhase.manzil;
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

    notifyListeners();
    return record;
  }

  /// Clear session state (on exit without completing).
  void clearSession() {
    _isActive = false;
    _isPaused = false;
    _plan = null;
    _elapsedSeconds = 0;
    _repCount = 0;
    _totalSessionReps = 0;
    _showingAssessment = false;
    _showingCoverageDialog = false;
    _actualPagesCovered = [];
    _lastVerseLearned = null;
    _totalVersesOnPage = null;
    notifyListeners();
  }
}
