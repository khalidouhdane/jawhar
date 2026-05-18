import 'package:flutter/material.dart';
import 'package:quran_app/models/flashcard_models.dart';
import 'package:quran_app/services/auth_service.dart';
import 'package:quran_app/services/cloud_sync_service.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/services/srs_engine.dart';
import 'package:quran_app/services/card_generation_service.dart';
import 'package:quran_app/utils/app_logger.dart';

/// State management for flashcard review sessions.
class FlashcardProvider extends ChangeNotifier {
  final HifzDatabaseService _db;
  final AuthService _auth;
  final CloudSyncService _sync;

  List<Flashcard> _dueCards = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  bool _isRevealed = false;
  bool _isSandbox = false;

  // Session stats
  int _reviewedCount = 0;
  int _strongCount = 0;
  int _okCount = 0;
  int _weakCount = 0;
  int _forgotCount = 0;

  // Dashboard stats
  Map<String, int> _stats = {'total': 0, 'due': 0};
  Map<String, dynamic> _accuracy = {'total': 0, 'correct': 0, 'accuracy': 0};
  bool _lastWeakWasMutashabihat = false;

  // Per-type stats: {FlashcardType.index: {total: X, due: Y}}
  Map<int, Map<String, int>> _statsByType = {};

  FlashcardProvider(this._db, this._auth, this._sync);

  // ── Getters ──

  List<Flashcard> get dueCards => _dueCards;
  int get currentIndex => _currentIndex;
  Flashcard? get currentCard =>
      _currentIndex < _dueCards.length ? _dueCards[_currentIndex] : null;
  bool get isLoading => _isLoading;
  bool get isRevealed => _isRevealed;
  bool get isSandbox => _isSandbox;
  bool get hasCards => _dueCards.isNotEmpty;
  bool get isSessionComplete => _currentIndex >= _dueCards.length;
  int get remainingCards => (_dueCards.length - _currentIndex).clamp(0, 999);

  int get reviewedCount => _reviewedCount;
  int get strongCount => _strongCount;
  int get okCount => _okCount;
  int get weakCount => _weakCount;
  int get forgotCount => _forgotCount;

  int get totalCards => _stats['total'] ?? 0;
  int get dueCardCount => _stats['due'] ?? 0;
  int get accuracyPercent => _accuracy['accuracy'] as int? ?? 0;
  bool get lastWeakWasMutashabihat => _lastWeakWasMutashabihat;
  void clearMutashabihatFlag() {
    _lastWeakWasMutashabihat = false;
    notifyListeners();
  }

  /// Get due count for a specific card type.
  int getDueCountForType(FlashcardType type) {
    return _statsByType[type.index]?['due'] ?? 0;
  }

  /// Get total count for a specific card type.
  int getTotalForType(FlashcardType type) {
    return _statsByType[type.index]?['total'] ?? 0;
  }

  // ── Actions ──

  /// Load due cards for a profile and optionally generate new ones.
  Future<void> loadDueCards(String profileId, {bool generate = true}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (generate) {
        // Auto-clean old page-format cards (migration from page-based to verse-based)
        await _cleanOldFormatCards(profileId);

        AppLogger.info('Flashcard', '[FlashcardProvider] Generating cards for $profileId...');
        final gen = CardGenerationService(_db);
        final count = await gen.generateCards(profileId);
        AppLogger.info('Flashcard', '[FlashcardProvider] Generated $count new cards');
      }

      _dueCards = await _db.getDueFlashcards(profileId);
      AppLogger.info('Flashcard', '[FlashcardProvider] Due cards loaded: ${_dueCards.length}');
      _currentIndex = 0;
      _isRevealed = false;
      _isSandbox = false;
      _resetSessionStats();

      // Load dashboard stats + per-type stats
      _stats = await _db.getFlashcardStats(profileId);
      _accuracy = await _db.getFlashcardAccuracy(profileId);
      _statsByType = await _db.getFlashcardStatsByType(profileId);
      AppLogger.info('Flashcard', '[FlashcardProvider] Stats: $_stats');
    } catch (e, stack) {
      AppLogger.info('Flashcard', '[FlashcardProvider] ERROR loading flashcards: $e');
      AppLogger.info('Flashcard', '[FlashcardProvider] Stack: $stack');
      _dueCards = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load due cards filtered by type for the review screen.
  /// type = null means mixed (all types).
  Future<void> loadDueCardsByType(String profileId, FlashcardType? type) async {
    _isLoading = true;
    notifyListeners();

    try {
      _dueCards = await _db.getDueFlashcardsByType(profileId, type);
      AppLogger.info('Flashcard', '[FlashcardProvider] Loaded ${_dueCards.length} cards for type: ${type?.name ?? "mixed"}',
      );
      _currentIndex = 0;
      _isRevealed = false;
      _isSandbox = false;
      _resetSessionStats();
    } catch (e) {
      AppLogger.info('Flashcard', '[FlashcardProvider] ERROR loading by type: $e');
      _dueCards = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load playful cards for sandbox mode (no DB saves, just random practice).
  Future<void> loadPlayfulCards(String profileId, FlashcardType? type) async {
    _isLoading = true;
    notifyListeners();

    try {
      final gen = CardGenerationService(_db);
      _dueCards = await gen.generatePlayfulCards(profileId, type, count: 10);
      AppLogger.info('Flashcard', '[FlashcardProvider] Loaded ${_dueCards.length} playful cards for type: ${type?.name ?? "mixed"}');
      _currentIndex = 0;
      _isRevealed = false;
      _isSandbox = true;
      _resetSessionStats();
    } catch (e) {
      AppLogger.info('Flashcard', '[FlashcardProvider] ERROR loading playful cards: $e');
      _dueCards = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Remove old page-based flashcards (verseKey starts with 'page:').
  Future<void> _cleanOldFormatCards(String profileId) async {
    try {
      final db = await _db.database;
      final result = await db.delete(
        'flashcards',
        where: "profile_id = ? AND verse_key LIKE 'page:%'",
        whereArgs: [profileId],
      );
      if (result > 0) {
        AppLogger.info('Flashcard', '[FlashcardProvider] Cleaned $result old page-format cards');
      }
    } catch (e) {
      AppLogger.info('Flashcard', '[FlashcardProvider] Clean old cards error: $e');
    }
  }

  /// Force-clear all flashcards and regenerate from scratch.
  Future<void> forceRegenerate(String profileId) async {
    _isLoading = true;
    notifyListeners();

    try {
      AppLogger.info('Flashcard', '[FlashcardProvider] Force regenerating — clearing old cards');
      await _db.deleteFlashcardsForProfile(profileId);
      await loadDueCards(profileId, generate: true);
    } catch (e) {
      AppLogger.info('Flashcard', '[FlashcardProvider] Force regenerate error: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh just the dashboard stats (without loading cards).
  Future<void> refreshStats(String profileId) async {
    _stats = await _db.getFlashcardStats(profileId);
    _accuracy = await _db.getFlashcardAccuracy(profileId);
    _statsByType = await _db.getFlashcardStatsByType(profileId);
    notifyListeners();
  }

  /// Reveal the current card's answer.
  void reveal() {
    _isRevealed = true;
    notifyListeners();
  }

  /// Rate the current card and advance to the next one.
  Future<void> rate(FlashcardRating rating) async {
    if (currentCard == null) return;

    final updated = SrsEngine.processReview(currentCard!, rating);

    if (!_isSandbox) {
      // Process SRS and DB only for real cards
      await _db.updateFlashcard(updated);

      // Save review event
      final review = FlashcardReview(
        id: '${currentCard!.id}_${DateTime.now().millisecondsSinceEpoch}',
        cardId: currentCard!.id,
        rating: rating,
        reviewedAt: DateTime.now(),
      );
      await _db.saveFlashcardReview(review);

      // Cloud sync (fire-and-forget)
      if (_auth.isSignedIn) {
        _sync.syncFlashcard(_auth.uid!, updated);
        _sync.syncFlashcardReview(_auth.uid!, review);
      }
    }

    // Update session stats
    _reviewedCount++;
    switch (rating) {
      case FlashcardRating.strong:
        _strongCount++;
        break;
      case FlashcardRating.ok:
        _okCount++;
        break;
      case FlashcardRating.weak:
        _weakCount++;
        break;
      case FlashcardRating.forgot:
        _forgotCount++;
        break;
    }

    // Advance
    _currentIndex++;
    _isRevealed = false;

    // Integration trigger: check if weak/forgot card is a mutashabihat verse
    if (!_isSandbox && (rating == FlashcardRating.weak || rating == FlashcardRating.forgot)) {
      _checkMutashabihatForVerse(updated.verseKey);
    } else {
      _lastWeakWasMutashabihat = false;
    }

    notifyListeners();
  }

  /// Check if a verse key has associated mutashabihat groups.
  Future<void> _checkMutashabihatForVerse(String verseKey) async {
    try {
      final groups = await _db.getMutashabihatForVerse(verseKey);
      _lastWeakWasMutashabihat = groups.isNotEmpty;
      notifyListeners();
    } catch (e) {
      AppLogger.info('Flashcard', '[Flashcard] Mutashabihat check failed for $verseKey: $e');
      _lastWeakWasMutashabihat = false;
    }
  }

  /// Skip the current card (don't change SRS state).
  void skip() {
    _currentIndex++;
    _isRevealed = false;
    notifyListeners();
  }

  /// Reset session stats.
  void _resetSessionStats() {
    _reviewedCount = 0;
    _strongCount = 0;
    _okCount = 0;
    _weakCount = 0;
    _forgotCount = 0;
  }

  /// Estimated time for due cards.
  int get estimatedMinutes => SrsEngine.estimateMinutes(_dueCards.length);
}
