import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Service that fetches and caches Warsh Quran text from the
/// fawazahmed0/quran-api CDN (King Fahd Complex, Version 8).
///
/// The data is ~1.5 MB and is cached in memory as a Map keyed by "chapter:verse".
class WarshTextService {
  static const String _cdnUrl =
      'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/ara-quranwarsh.min.json';

  /// Singleton instance
  static final WarshTextService _instance = WarshTextService._internal();
  factory WarshTextService() => _instance;
  WarshTextService._internal();

  /// In-memory cache: "chapter:verse" → Warsh text
  Map<String, String>? _cache;

  /// Whether a fetch is currently in progress
  bool _loading = false;

  /// Whether the data has been loaded
  bool get isLoaded => _cache != null;

  /// Preload the Warsh text data from CDN.
  /// Safe to call multiple times — only fetches once.
  Future<void> preload() async {
    if (_cache != null || _loading) return;
    _loading = true;

    try {
      debugPrint('[WarshTextService] Fetching Warsh text from CDN...');
      final response = await http
          .get(Uri.parse(_cdnUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> quranList = jsonData['quran'];

        _cache = {};
        for (final entry in quranList) {
          final chapter = entry['chapter'] as int;
          final verse = entry['verse'] as int;
          final text = entry['text'] as String;
          _cache!['$chapter:$verse'] = text;
        }

        debugPrint('[WarshTextService] Loaded ${_cache!.length} Warsh verses.');
      } else {
        debugPrint('[WarshTextService] CDN returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[WarshTextService] Failed to load Warsh text: $e');
    } finally {
      _loading = false;
    }
  }

  /// Get the Warsh text for a single verse, identified by "chapter:verse" key.
  /// Returns null if data isn't loaded or verse isn't found.
  String? getVerseText(String verseKey) {
    return _cache?[verseKey];
  }

  /// Get Warsh text for a chapter and verse number.
  String? getVerse(int chapter, int verse) {
    return _cache?['$chapter:$verse'];
  }
}
