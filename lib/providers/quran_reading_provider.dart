import 'package:flutter/material.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/services/quran_api_service.dart';

class QuranReadingProvider extends ChangeNotifier {
  final QuranApiService _apiService = QuranApiService();

  List<Verse> _verses = [];
  List<Chapter> _chapters = [];
  List<Reciter> _reciters = [];

  bool _isLoading = false;
  int _activePage = 1;
  String _error = '';

  // Page cache for smooth swipe transitions
  final Map<int, List<Verse>> _pageCache = {};

  List<Verse> get verses => _verses;
  List<Chapter> get chapters => _chapters;
  List<Reciter> get reciters => _reciters;
  bool get isLoading => _isLoading;
  int get activePage => _activePage;
  String get error => _error;

  QuranReadingProvider() {
    loadPage(1);
    loadChapters();
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
      _reciters = await _apiService.getReciters();
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to load reciters: $e");
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

  /// Set the active page without triggering a full reload (used by PageView)
  void setActivePage(int page) {
    if (_activePage == page) return;
    _activePage = page;
    final cachedVerses = _pageCache[page];
    if (cachedVerses != null) {
      _verses = cachedVerses;
    }
    notifyListeners();
    prefetchPages(page);
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
