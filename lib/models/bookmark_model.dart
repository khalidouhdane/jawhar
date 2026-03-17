import 'dart:convert';

/// The type of bookmark — either a specific verse or a whole page.
enum BookmarkType { verse, page }

/// Represents a user-saved bookmark in the Quran.
class Bookmark {
  final String id;
  final BookmarkType type;
  final String? verseKey;      // e.g. "2:255" — null for page bookmarks
  final int pageNumber;        // 1–604
  final String surahName;      // display name
  final DateTime createdAt;
  final String? collectionId;  // links to BookmarkCollection (null = uncategorized)
  final String? note;          // personal note
  final int? colorIndex;       // index into 6-color palette (null = no color)

  const Bookmark({
    required this.id,
    required this.type,
    this.verseKey,
    required this.pageNumber,
    required this.surahName,
    required this.createdAt,
    this.collectionId,
    this.note,
    this.colorIndex,
  });

  Bookmark copyWith({
    String? collectionId,
    String? note,
    int? colorIndex,
    bool clearCollection = false,
    bool clearNote = false,
    bool clearColor = false,
  }) => Bookmark(
    id: id,
    type: type,
    verseKey: verseKey,
    pageNumber: pageNumber,
    surahName: surahName,
    createdAt: createdAt,
    collectionId: clearCollection ? null : (collectionId ?? this.collectionId),
    note: clearNote ? null : (note ?? this.note),
    colorIndex: clearColor ? null : (colorIndex ?? this.colorIndex),
  );

  /// Generate a unique ID from the current timestamp.
  static String generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type == BookmarkType.verse ? 'verse' : 'page',
        'verseKey': verseKey,
        'pageNumber': pageNumber,
        'surahName': surahName,
        'createdAt': createdAt.millisecondsSinceEpoch,
        if (collectionId != null) 'collectionId': collectionId,
        if (note != null) 'note': note,
        if (colorIndex != null) 'colorIndex': colorIndex,
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'] as String,
        type: json['type'] == 'verse' ? BookmarkType.verse : BookmarkType.page,
        verseKey: json['verseKey'] as String?,
        pageNumber: json['pageNumber'] as int,
        surahName: json['surahName'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          json['createdAt'] as int,
        ),
        collectionId: json['collectionId'] as String?,
        note: json['note'] as String?,
        colorIndex: json['colorIndex'] as int?,
      );

  /// Encode the full list to a JSON string for SharedPreferences.
  static String encodeList(List<Bookmark> bookmarks) =>
      jsonEncode(bookmarks.map((b) => b.toJson()).toList());

  /// Decode a JSON string back into a list of bookmarks.
  static List<Bookmark> decodeList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => Bookmark.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
