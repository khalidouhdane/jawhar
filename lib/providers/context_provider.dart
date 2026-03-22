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

  // ── Page-level translation cache ──
  Map<String, VerseText> _pageTranslations = {};
  int? _cachedPageNumber;

  // ── Loading States ──
  bool _isLoadingTranslation = false;
  bool _isLoadingBriefTafsir = false;
  bool _isLoadingDetailedTafsir = false;

  // ── Error State ──
  String? _error;

  ContextProvider({
    TafsirService? tafsirService,
    AsbabNuzulService? asbabService,
  })  : _tafsirService = tafsirService ?? TafsirService(),
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
  Map<String, VerseText> get pageTranslations => _pageTranslations;

  bool get isLoadingTranslation => _isLoadingTranslation;
  bool get isLoadingBriefTafsir => _isLoadingBriefTafsir;
  bool get isLoadingDetailedTafsir => _isLoadingDetailedTafsir;
  String? get error => _error;

  bool get isAsbabNuzulLoaded => _asbabService.isLoaded;

  /// Whether the current verse has asbab al-nuzul data.
  bool get hasAsbabNuzul => _activeAsbabNuzul != null;

  /// Access the asbab service for direct queries (e.g. in tafsir mode).
  AsbabNuzulService get asbabService => _asbabService;

  // ── Language-Aware Switching ──

  /// Set the locale and auto-switch all resource IDs accordingly.
  ///
  /// English: translation=85, briefTafsir=169, detailedTafsir=168
  /// Arabic:  translation=1014, briefTafsir=16, detailedTafsir=14
  void setLocale(String locale) {
    final lang = locale.startsWith('ar') ? 'ar' : 'en';
    if (_locale == lang) return;
    _locale = lang;

    if (lang == 'ar') {
      _selectedTranslationId = 1014; // Tafsir Al-Muyasser (Arabic)
      _selectedBriefTafsirId = 16;   // Muyassar
      _selectedDetailedTafsirId = 14; // Ibn Kathir Arabic
    } else {
      _selectedTranslationId = 85;   // Abdel Haleem (English)
      _selectedBriefTafsirId = 169;  // Ibn Kathir Abridged (English)
      _selectedDetailedTafsirId = 168; // Ma'arif al-Qur'an (English)
    }

    // Clear caches since resource IDs changed
    _pageTranslations.clear();
    _cachedPageNumber = null;
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
    _pageTranslations.clear();
    _cachedPageNumber = null;
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
    // Check page cache first
    if (_pageTranslations.containsKey(verseKey)) {
      _activeVerseKey = verseKey;
      _activeTranslation = _pageTranslations[verseKey];
      notifyListeners();
      return;
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
    // Skip if already cached for this page with same translation ID
    if (_cachedPageNumber == pageNumber && _pageTranslations.isNotEmpty) {
      return;
    }

    _isLoadingTranslation = true;
    _error = null;
    notifyListeners();

    try {
      _pageTranslations = await _tafsirService.getTranslationsForPage(
        pageNumber,
        translationId: _selectedTranslationId,
      );
      _cachedPageNumber = pageNumber;
      _isLoadingTranslation = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoadingTranslation = false;
      notifyListeners();
    }
  }

  /// Load brief tafsir (Tafsir al-Muyassar) for a verse.
  Future<void> loadBriefTafsir(String verseKey) async {
    _isLoadingBriefTafsir = true;
    _activeVerseKey = verseKey;
    _error = null;
    notifyListeners();

    try {
      final result = await _tafsirService.getTafsir(
        verseKey,
        tafsirId: _selectedBriefTafsirId,
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
