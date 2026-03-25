import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran_app/models/bookmark_model.dart';
import 'package:quran_app/models/bookmark_collection.dart';
import 'package:quran_app/services/auth_service.dart';
import 'package:quran_app/services/cloud_sync_service.dart';
import 'package:quran_app/services/local_storage_service.dart';

/// Predefined bookmark color palette (12 colors).
class BookmarkColors {
  static const List<int> palette = [
    0xFF26A69A, // teal
    0xFFFFB74D, // amber
    0xFFEF5350, // rose
    0xFF5C6BC0, // indigo
    0xFF66BB6A, // emerald
    0xFFFF7043, // orange
    0xFF8D6E63, // brown
    0xFFAB47BC, // purple
    0xFF42A5F5, // sky blue
    0xFFEC407A, // pink
    0xFF78909C, // slate
    0xFFD4E157, // lime
  ];
}

/// Manages bookmarks and collections state with persistence.
class BookmarkProvider extends ChangeNotifier {
  final LocalStorageService _storage;
  final AuthService _auth;
  final CloudSyncService _sync;
  List<Bookmark> _bookmarks = [];
  List<BookmarkCollection> _collections = [];

  BookmarkProvider(this._storage, this._auth, this._sync) {
    _load();
  }

  // ── Bookmark Getters ──

  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);
  int get count => _bookmarks.length;

  // ── Collection Getters ──

  List<BookmarkCollection> get collections => List.unmodifiable(_collections);

  // ── Transient highlight ──
  String? _highlightVerseKey;
  Timer? _highlightTimer;
  String? get highlightVerseKey => _highlightVerseKey;

  void setHighlight(String verseKey,
      {Duration duration = const Duration(seconds: 2)}) {
    _highlightTimer?.cancel();
    _highlightVerseKey = verseKey;
    notifyListeners();
    _highlightTimer = Timer(duration, () {
      _highlightVerseKey = null;
      notifyListeners();
    });
  }

  // ── Bookmark Queries ──

  List<Bookmark> getAll() {
    final sorted = List<Bookmark>.from(_bookmarks);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  List<Bookmark> getByCollection(String? collectionId) {
    final filtered = collectionId == null
        ? _bookmarks
        : _bookmarks.where((b) => b.collectionId == collectionId).toList();
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  bool isVerseBookmarked(String verseKey) =>
      _bookmarks
          .any((b) => b.type == BookmarkType.verse && b.verseKey == verseKey);

  bool isPageBookmarked(int page) =>
      _bookmarks
          .any((b) => b.type == BookmarkType.page && b.pageNumber == page);

  Bookmark? getVerseBookmark(String verseKey) {
    try {
      return _bookmarks.firstWhere(
        (b) => b.type == BookmarkType.verse && b.verseKey == verseKey,
      );
    } catch (_) {
      return null;
    }
  }

  Bookmark? getPageBookmark(int page) {
    try {
      return _bookmarks.firstWhere(
        (b) => b.type == BookmarkType.page && b.pageNumber == page,
      );
    } catch (_) {
      return null;
    }
  }

  Bookmark? getById(String id) {
    try {
      return _bookmarks.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Bookmark Mutators ──

  void addBookmark(Bookmark bookmark) {
    _bookmarks.add(bookmark);
    _save();
    notifyListeners();
  }

  void removeBookmark(String id) {
    _bookmarks.removeWhere((b) => b.id == id);
    _save();
    notifyListeners();
  }

  bool toggleVerseBookmark({
    required String verseKey,
    required int pageNumber,
    required String surahName,
  }) {
    final existing = getVerseBookmark(verseKey);
    if (existing != null) {
      removeBookmark(existing.id);
      return false;
    } else {
      addBookmark(Bookmark(
        id: Bookmark.generateId(),
        type: BookmarkType.verse,
        verseKey: verseKey,
        pageNumber: pageNumber,
        surahName: surahName,
        createdAt: DateTime.now(),
      ));
      return true;
    }
  }

  bool togglePageBookmark({
    required int pageNumber,
    required String surahName,
  }) {
    final existing = getPageBookmark(pageNumber);
    if (existing != null) {
      removeBookmark(existing.id);
      return false;
    } else {
      addBookmark(Bookmark(
        id: Bookmark.generateId(),
        type: BookmarkType.page,
        pageNumber: pageNumber,
        surahName: surahName,
        createdAt: DateTime.now(),
      ));
      return true;
    }
  }

  /// Update a bookmark's note.
  void updateNote(String bookmarkId, String? note) {
    final idx = _bookmarks.indexWhere((b) => b.id == bookmarkId);
    if (idx == -1) return;
    _bookmarks[idx] = _bookmarks[idx].copyWith(
      note: note,
      clearNote: note == null || note.isEmpty,
    );
    _save();
    notifyListeners();
  }

  /// Update a bookmark's color from the palette (clears any custom color).
  void updateColor(String bookmarkId, int? colorIndex) {
    final idx = _bookmarks.indexWhere((b) => b.id == bookmarkId);
    if (idx == -1) return;
    _bookmarks[idx] = _bookmarks[idx].copyWith(
      colorIndex: colorIndex,
      clearColor: colorIndex == null,
      clearCustomColor: true,
    );
    _save();
    notifyListeners();
  }

  /// Set a custom ARGB color (clears palette colorIndex).
  void updateCustomColor(String bookmarkId, int? argb) {
    final idx = _bookmarks.indexWhere((b) => b.id == bookmarkId);
    if (idx == -1) return;
    _bookmarks[idx] = _bookmarks[idx].copyWith(
      customColor: argb,
      clearCustomColor: argb == null,
      clearColor: true,
    );
    _save();
    notifyListeners();
  }

  /// Move a bookmark to a collection (null = uncategorized).
  void moveToCollection(String bookmarkId, String? collectionId) {
    final idx = _bookmarks.indexWhere((b) => b.id == bookmarkId);
    if (idx == -1) return;
    _bookmarks[idx] = _bookmarks[idx].copyWith(
      collectionId: collectionId,
      clearCollection: collectionId == null,
    );
    _save();
    notifyListeners();
  }

  // ── Collection CRUD ──

  void createCollection(String name, {int iconIndex = 0}) {
    _collections.add(BookmarkCollection(
      id: BookmarkCollection.generateId(),
      name: name,
      iconIndex: iconIndex,
      createdAt: DateTime.now(),
    ));
    _saveCollections();
    notifyListeners();
  }

  void renameCollection(String id, String newName) {
    final idx = _collections.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    _collections[idx] = _collections[idx].copyWith(name: newName);
    _saveCollections();
    notifyListeners();
  }

  void deleteCollection(String id) {
    _collections.removeWhere((c) => c.id == id);
    // Un-assign bookmarks from the deleted collection
    for (int i = 0; i < _bookmarks.length; i++) {
      if (_bookmarks[i].collectionId == id) {
        _bookmarks[i] = _bookmarks[i].copyWith(clearCollection: true);
      }
    }
    _save();
    _saveCollections();
    notifyListeners();
  }

  BookmarkCollection? getCollection(String id) {
    try {
      return _collections.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Export ──

  String exportAsText({String? collectionId}) {
    final bks = collectionId == null ? getAll() : getByCollection(collectionId);
    final buffer = StringBuffer();
    buffer.writeln('📖 My Bookmarks — Le Quran');
    buffer.writeln();

    if (collectionId != null) {
      final col = getCollection(collectionId);
      if (col != null) buffer.writeln('── ${col.name} ──');
    }

    for (final b in bks) {
      if (b.type == BookmarkType.verse) {
        buffer.writeln('• ${b.verseKey} — ${b.surahName} (Page ${b.pageNumber})');
      } else {
        buffer.writeln('• Page ${b.pageNumber} — ${b.surahName}');
      }
      if (b.note != null && b.note!.isNotEmpty) {
        buffer.writeln('  Note: "${b.note}"');
      }
    }
    return buffer.toString().trimRight();
  }

  Future<void> shareBookmarks({String? collectionId}) async {
    final text = exportAsText(collectionId: collectionId);
    await SharePlus.instance.share(ShareParams(text: text));
  }

  // ── Persistence ──

  void _load() {
    _bookmarks = Bookmark.decodeList(_storage.getBookmarks());
    _collections =
        BookmarkCollection.decodeList(_storage.getCollections());
  }

  void _save() {
    _storage.saveBookmarks(Bookmark.encodeList(_bookmarks));
    // Cloud sync (fire-and-forget)
    if (_auth.isSignedIn) {
      _sync.syncSettings(_auth.uid!);
    }
  }

  void _saveCollections() {
    _storage.saveCollections(BookmarkCollection.encodeList(_collections));
    // Cloud sync (fire-and-forget)
    if (_auth.isSignedIn) {
      _sync.syncSettings(_auth.uid!);
    }
  }
}
