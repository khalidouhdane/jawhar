import 'package:flutter/material.dart';
import 'package:quran_app/services/tafsir_service.dart';
import 'package:quran_app/services/asbab_nuzul_service.dart';

/// Provides contextual content state for translations, tafsir, and
/// asbab al-nuzul. This is a standalone provider — it does not depend on
/// session or reading providers so it can be consumed by any screen.
class ContextProvider extends ChangeNotifier {
  final TafsirService _tafsirService;
  final AsbabNuzulService _asbabService;

  // ── User Preferences ──
  bool _translationEnabled = false;
  int _selectedTranslationId = TafsirService.defaultTranslationId;
  int _selectedBriefTafsirId = TafsirService.defaultBriefTafsirId;
  int _selectedDetailedTafsirId = TafsirService.defaultDetailedTafsirId;
  String _locale = 'en';

  // ── Active Content State ──
  String? _activeVerseKey;
  VerseText? _activeTranslation;
  VerseText? _activeBriefTafsir;
  VerseText? _activeDetailedTafsir;
  List<String>? _activeAsbabNuzul;
  AsbabNuzulEntry? _activeAsbabEntry;

  // ── Page-level translation cache (LRU, max 30 pages) ──
  final Map<int, Map<String, VerseText>> _pageTranslationCache = {};
  static const int _maxCachedPages = 30;
  final Set<int> _loadingPages = {};

  // ── Verse highlighting for mode switch ──
  String? _highlightVerseKey;

  // ── Loading States ──
  bool _isLoadingTranslation = false;
  bool _isLoadingBriefTafsir = false;
  bool _isLoadingDetailedTafsir = false;

  // ── Error State ──
  String? _error;

  ContextProvider({
    TafsirService? tafsirService,
    AsbabNuzulService? asbabService,
  }) : _tafsirService = tafsirService ?? TafsirService(),
       _asbabService = asbabService ?? AsbabNuzulService();

  // ── Getters ──
  bool get translationEnabled => _translationEnabled;
  int get selectedTranslationId => _selectedTranslationId;
  int get selectedBriefTafsirId => _selectedBriefTafsirId;
  int get selectedDetailedTafsirId => _selectedDetailedTafsirId;
  String get locale => _locale;

  String? get activeVerseKey => _activeVerseKey;
  VerseText? get activeTranslation => _activeTranslation;
  VerseText? get activeBriefTafsir => _activeBriefTafsir;
  VerseText? get activeDetailedTafsir => _activeDetailedTafsir;
  List<String>? get activeAsbabNuzul => _activeAsbabNuzul;
  AsbabNuzulEntry? get activeAsbabEntry => _activeAsbabEntry;

  /// Get translations for a specific page from cache.
  Map<String, VerseText> getPageTranslations(int pageNumber) {
    return _pageTranslationCache[pageNumber] ?? {};
  }

  String? get highlightVerseKey => _highlightVerseKey;

  bool get isLoadingTranslation =>
      _isLoadingTranslation || _loadingPages.isNotEmpty;
  bool get isLoadingBriefTafsir => _isLoadingBriefTafsir;
  bool get isLoadingDetailedTafsir => _isLoadingDetailedTafsir;
  String? get error => _error;

  /// Check if a specific page's translations are currently loading.
  bool isPageLoading(int pageNumber) => _loadingPages.contains(pageNumber);

  bool get isAsbabNuzulLoaded => _asbabService.isLoaded;

  /// Whether the current verse has asbab al-nuzul data.
  bool get hasAsbabNuzul => _activeAsbabNuzul != null;

  /// Access the asbab service for direct queries (e.g. in tafsir mode).
  AsbabNuzulService get asbabService => _asbabService;

  // ── Language-Aware Switching ──

  /// Set the locale and auto-switch all resource IDs accordingly.
  ///
  /// English: translation=85, detailedTafsir=168
  ///          (brief tafsir is handled by hybrid routing in TafsirService)
  /// Arabic:  translation=1014, briefTafsir=16, detailedTafsir=14
  void setLocale(String locale) {
    final lang = locale.startsWith('ar') ? 'ar' : 'en';
    if (_locale == lang) return;
    _locale = lang;

    if (lang == 'ar') {
      _selectedTranslationId = 1014; // Tafsir Al-Muyasser (Arabic)
      _selectedBriefTafsirId = 16; // Muyassar
      _selectedDetailedTafsirId = 14; // Ibn Kathir Arabic
    } else {
      _selectedTranslationId = 85; // Abdel Haleem (English)
      // Brief tafsir for EN is routed through QuranEnc (Al-Mukhtasar)
      // by TafsirService.getBriefTafsir() — ID is not used.
      _selectedBriefTafsirId = TafsirService.defaultBriefTafsirId;
      _selectedDetailedTafsirId = 168; // Ma'arif al-Qur'an (English)
    }

    // Clear caches since resource IDs changed
    _pageTranslationCache.clear();
    _activeTranslation = null;
    _activeBriefTafsir = null;
    _activeDetailedTafsir = null;
    notifyListeners();
  }

  /// Ensure the asbab al-nuzul dataset is loaded.
  Future<void> ensureAsbabLoaded() async {
    await _asbabService.importIfNeeded();
  }

  // ── User Preference Methods ──

  /// Toggle translation overlay on/off.
  void toggleTranslation() {
    _translationEnabled = !_translationEnabled;
    notifyListeners();
  }

  /// Enable translation overlay.
  void enableTranslation() {
    if (_translationEnabled) return;
    _translationEnabled = true;
    notifyListeners();
  }

  /// Disable translation overlay.
  void disableTranslation() {
    if (!_translationEnabled) return;
    _translationEnabled = false;
    notifyListeners();
  }

  /// Set the translation resource ID.
  void setTranslationId(int id) {
    if (_selectedTranslationId == id) return;
    _selectedTranslationId = id;
    // Clear cached page translations since the resource changed
    _pageTranslationCache.clear();
    _activeTranslation = null;
    notifyListeners();
  }

  /// Set the brief tafsir resource ID.
  void setBriefTafsirId(int id) {
    if (_selectedBriefTafsirId == id) return;
    _selectedBriefTafsirId = id;
    _activeBriefTafsir = null;
    notifyListeners();
  }

  /// Set the detailed tafsir resource ID.
  void setDetailedTafsirId(int id) {
    if (_selectedDetailedTafsirId == id) return;
    _selectedDetailedTafsirId = id;
    _activeDetailedTafsir = null;
    notifyListeners();
  }

  // ── Data Loading Methods ──

  /// Load translation for a specific verse.
  Future<void> loadTranslation(String verseKey) async {
    // Check all page caches
    for (final pageCache in _pageTranslationCache.values) {
      if (pageCache.containsKey(verseKey)) {
        _activeVerseKey = verseKey;
        _activeTranslation = pageCache[verseKey];
        notifyListeners();
        return;
      }
    }

    _isLoadingTranslation = true;
    _activeVerseKey = verseKey;
    _error = null;
    notifyListeners();

    try {
      final result = await _tafsirService.getTranslation(
        verseKey,
        translationId: _selectedTranslationId,
      );
      // Only update if we're still on the same verse
      if (_activeVerseKey == verseKey) {
        _activeTranslation = result;
        _isLoadingTranslation = false;
        notifyListeners();
      }
    } catch (e) {
      if (_activeVerseKey == verseKey) {
        _error = e.toString();
        _isLoadingTranslation = false;
        notifyListeners();
      }
    }
  }

  /// Load translations for all verses on a page (batch).
  Future<void> loadPageTranslations(int pageNumber) async {
    // Skip if already cached or already loading
    if (_pageTranslationCache.containsKey(pageNumber) ||
        _loadingPages.contains(pageNumber)) {
      return;
    }

    _loadingPages.add(pageNumber);
    _error = null;
    notifyListeners();

    try {
      final results = await _tafsirService.getTranslationsForPage(
        pageNumber,
        translationId: _selectedTranslationId,
      );

      // LRU eviction: remove oldest entry if at capacity
      if (_pageTranslationCache.length >= _maxCachedPages) {
        _pageTranslationCache.remove(_pageTranslationCache.keys.first);
      }
      _pageTranslationCache[pageNumber] = results;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loadingPages.remove(pageNumber);
      notifyListeners();
    }
  }

  /// Proactively load adjacent pages into the LRU cache without changing loading UI state.
  /// Triggered silently in the background on page change.
  Future<void> prefetchAdjacentPages(int currentPage) async {
    final pagesToPrefetch = [
      currentPage + 1,
      currentPage - 1,
      currentPage + 2,
    ].where((p) => p >= 1 && p <= 604).toList();

    for (final page in pagesToPrefetch) {
      if (!_pageTranslationCache.containsKey(page) &&
          !_loadingPages.contains(page)) {
        _loadingPages.add(page);
        try {
          final results = await _tafsirService.getTranslationsForPage(
            page,
            translationId: _selectedTranslationId,
          );
          if (results.isNotEmpty) {
            // Keep cache within limit
            if (_pageTranslationCache.length >= _maxCachedPages) {
              _pageTranslationCache.remove(_pageTranslationCache.keys.first);
            }
            _pageTranslationCache[page] = results;
          }
        } catch (_) {
          // Silent fail for background prefetch
        } finally {
          _loadingPages.remove(page);
          notifyListeners();
        }
      }
    }
  }

  /// Load brief tafsir for a verse.
  ///
  /// Uses the hybrid strategy:
  /// - Arabic → Quran Foundation API (Al-Muyassar, ID 16)
  /// - English → QuranEnc API (Al-Mukhtasar)
  Future<void> loadBriefTafsir(String verseKey) async {
    _isLoadingBriefTafsir = true;
    _activeVerseKey = verseKey;
    _error = null;
    notifyListeners();

    try {
      final result = await _tafsirService.getBriefTafsir(
        verseKey,
        locale: _locale,
      );
      if (_activeVerseKey == verseKey) {
        _activeBriefTafsir = result;
        _isLoadingBriefTafsir = false;
        notifyListeners();
      }
    } catch (e) {
      if (_activeVerseKey == verseKey) {
        _error = e.toString();
        _isLoadingBriefTafsir = false;
        notifyListeners();
      }
    }
  }

  /// Load detailed tafsir (Ibn Kathir) for a verse.
  Future<void> loadDetailedTafsir(String verseKey) async {
    _isLoadingDetailedTafsir = true;
    _activeVerseKey = verseKey;
    _error = null;
    notifyListeners();

    try {
      final result = await _tafsirService.getTafsir(
        verseKey,
        tafsirId: _selectedDetailedTafsirId,
      );
      if (_activeVerseKey == verseKey) {
        _activeDetailedTafsir = result;
        _isLoadingDetailedTafsir = false;
        notifyListeners();
      }
    } catch (e) {
      if (_activeVerseKey == verseKey) {
        _error = e.toString();
        _isLoadingDetailedTafsir = false;
        notifyListeners();
      }
    }
  }

  /// Load asbab al-nuzul for a verse.
  ///
  /// This is synchronous once the dataset is loaded — it just does a
  /// map lookup.
  void loadAsbabNuzul(String verseKey) {
    _activeVerseKey = verseKey;

    if (!_asbabService.isLoaded) {
      _activeAsbabNuzul = null;
      _activeAsbabEntry = null;
      notifyListeners();
      return;
    }

    _activeAsbabNuzul = _asbabService.getOccasionsByKey(verseKey);
    // Parse verse key to get surah/ayah for the full entry
    final parts = verseKey.split(':');
    if (parts.length == 2) {
      final surah = int.tryParse(parts[0]);
      final ayah = int.tryParse(parts[1]);
      if (surah != null && ayah != null) {
        _activeAsbabEntry = _asbabService.getEntry(surah, ayah);
      }
    }
    notifyListeners();
  }

  /// Load all contextual data for a verse.
  ///
  /// Loads translation (if enabled), and asbab al-nuzul synchronously.
  /// Tafsir is loaded on demand when the user taps "Meaning".
  Future<void> loadContextForVerse(String verseKey) async {
    _activeVerseKey = verseKey;
    _activeBriefTafsir = null;
    _activeDetailedTafsir = null;

    // Always load asbab al-nuzul (synchronous)
    loadAsbabNuzul(verseKey);

    // Load translation if enabled
    if (_translationEnabled) {
      await loadTranslation(verseKey);
    }
  }

  /// Set a verse to highlight and scroll to in translation view.
  void setHighlightVerse(String verseKey) {
    _highlightVerseKey = verseKey;
    notifyListeners();
  }

  /// Clear the highlight after scroll animation completes.
  void clearHighlightVerse() {
    if (_highlightVerseKey == null) return;
    _highlightVerseKey = null;
    notifyListeners();
  }

  /// Clear all active content state.
  void clearActiveContent() {
    _activeVerseKey = null;
    _activeTranslation = null;
    _activeBriefTafsir = null;
    _activeDetailedTafsir = null;
    _activeAsbabNuzul = null;
    _activeAsbabEntry = null;
    _error = null;
    notifyListeners();
  }

  // ── Resource Discovery ──

  /// Get available translation resources.
  Future<List<TafsirResource>> getAvailableTranslations() {
    return _tafsirService.getAvailableTranslations();
  }

  /// Get available tafsir resources.
  Future<List<TafsirResource>> getAvailableTafsirs() {
    return _tafsirService.getAvailableTafsirs();
  }

  /// Check if a verse has asbab al-nuzul data.
  bool verseHasAsbabNuzul(String verseKey) {
    return _asbabService.hasOccasionByKey(verseKey);
  }
}
