import 'dart:convert';

/// A user-created folder/group for organizing bookmarks.
class BookmarkCollection {
  final String id;
  final String name;
  final int iconIndex; // index into predefined icon set
  final DateTime createdAt;

  const BookmarkCollection({
    required this.id,
    required this.name,
    this.iconIndex = 0,
    required this.createdAt,
  });

  static String generateId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  BookmarkCollection copyWith({String? name, int? iconIndex}) =>
      BookmarkCollection(
        id: id,
        name: name ?? this.name,
        iconIndex: iconIndex ?? this.iconIndex,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconIndex': iconIndex,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory BookmarkCollection.fromJson(Map<String, dynamic> json) =>
      BookmarkCollection(
        id: json['id'] as String,
        name: json['name'] as String,
        iconIndex: json['iconIndex'] as int? ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          json['createdAt'] as int,
        ),
      );

  static String encodeList(List<BookmarkCollection> collections) =>
      jsonEncode(collections.map((c) => c.toJson()).toList());

  static List<BookmarkCollection> decodeList(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => BookmarkCollection.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
