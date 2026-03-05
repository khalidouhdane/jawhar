import 'package:flutter/material.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/services/quran_api_service.dart';
import 'package:quran_app/services/mp3quran_service.dart';
import 'package:quran_app/services/warsh_text_service.dart';

class QuranReadingProvider extends ChangeNotifier {
  final QuranApiService _apiService = QuranApiService();
  final Mp3QuranService _mp3QuranService = Mp3QuranService();
  final WarshTextService _warshTextService = WarshTextService();
  final LocalStorageService? _storage;

  List<Verse> _verses = [];
  List<Chapter> _chapters = [];
  List<Reciter> _hafsReciters = [];
  List<Reciter> _warshReciters = [];

  bool _isLoading = false;
  int _activePage = 1;
  String _error = '';
  int _selectedRewaya = 1; // 1 = Hafs, 2 = Warsh

  // Page cache for smooth swipe transitions
  final Map<int, List<Verse>> _pageCache = {};

  List<Verse> get verses => _verses;
  List<Chapter> get chapters => _chapters;
  List<Reciter> get reciters =>
      _selectedRewaya == 2 ? _warshReciters : _hafsReciters;
  bool get isLoading => _isLoading;
  int get activePage => _activePage;
  String get error => _error;
  int get selectedRewaya => _selectedRewaya;

  /// Whether the Warsh text data is loaded and ready
  bool get isWarshTextLoaded => _warshTextService.isLoaded;

  void setRewaya(int rewaya) {
    if (_selectedRewaya == rewaya) return;
    _selectedRewaya = rewaya;
    _storage?.saveRewaya(rewaya);
    // Clear page cache so pages re-render with the new text
    _pageCache.clear();
    notifyListeners();
    if (rewaya == 2) {
      _preloadWarshText();
    }
    // Reload the current page to reflect new rewaya
    loadPage(_activePage);
  }

  /// Preload Warsh text data from CDN
  Future<void> _preloadWarshText() async {
    if (_warshTextService.isLoaded) return;
    await _warshTextService.preload();
    // Notify so the canvas re-renders with Warsh text
    if (_selectedRewaya == 2) {
      _pageCache.clear();
      notifyListeners();
    }
  }

  /// Get Warsh text for a verse key (e.g. "2:255")
  String? getWarshVerseText(String verseKey) {
    return _warshTextService.getVerseText(verseKey);
  }

  QuranReadingProvider({LocalStorageService? storage, String language = 'en'})
    : _storage = storage,
      _language = language {
    // Load persisted rewaya preference
    _selectedRewaya = storage?.savedRewaya ?? 1;
    if (_selectedRewaya == 2) {
      _preloadWarshText();
    }
    loadPage(1);
    loadChapters();
    loadReciters();
  }

  String _language;

  /// Update the language used for API calls (reciter names, etc.)
  /// and re-fetch reciters so names display in the new language.
  void setLanguage(String language) {
    if (_language == language) return;
    _language = language;
    loadReciters();
  }

  Future<void> loadChapters() async {
    try {
      _chapters = await _apiService.getChapters();
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load chapters: $e");
    }
  }

  Future<void> loadReciters() async {
    try {
      _hafsReciters = await _apiService.getReciters(language: _language);
      try {
        _warshReciters = await _mp3QuranService.getRecitersWithTimingInfo(
          rewaya: 2,
          language: _language,
        );
      } catch (e) {
        debugPrint("Failed to load Warsh reciters: $e");
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load Hafs reciters: $e");
    }
  }

  /// Get cached page verses, or fetch them
  Future<List<Verse>> getPageVerses(int pageNumber) async {
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }
    try {
      final verses = await _apiService.getVersesByPage(pageNumber);
      _pageCache[pageNumber] = verses;
      // Trim cache to 10 pages max
      while (_pageCache.length > 10) {
        _pageCache.remove(_pageCache.keys.first);
      }
      return verses;
    } catch (e) {
      debugPrint("Failed to load page $pageNumber: $e");
      return [];
    }
  }

  /// Pre-fetch adjacent pages for smooth swiping
  void prefetchPages(int currentPage) {
    if (currentPage > 1) getPageVerses(currentPage - 1);
    if (currentPage < 604) getPageVerses(currentPage + 1);
  }

  Future<void> loadPage(int pageNumber) async {
    _isLoading = true;
    _error = '';
    _activePage = pageNumber;
    notifyListeners();

    try {
      _verses = await getPageVerses(pageNumber);
      prefetchPages(pageNumber);
    } catch (e) {
      _error = e.toString();
      _verses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set the active page (used by PageView).
  /// If the page is already cached, updates _verses immediately.
  /// Otherwise, triggers a full load so edge info is always correct.
  void setActivePage(int page) {
    if (_activePage == page) return;
    _activePage = page;
    final cachedVerses = _pageCache[page];
    if (cachedVerses != null) {
      _verses = cachedVerses;
      notifyListeners();
      prefetchPages(page);
    } else {
      // Page not cached yet — do a full load so _verses gets updated
      loadPage(page);
    }
  }

  void nextPage() {
    if (_activePage < 604) {
      loadPage(_activePage + 1);
    }
  }

  void previousPage() {
    if (_activePage > 1) {
      loadPage(_activePage - 1);
    }
  }
}
