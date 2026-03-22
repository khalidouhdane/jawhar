import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quran_app/services/quran_auth_service.dart';

/// Data model for a translation/tafsir resource (from /resources/* endpoints).
class TafsirResource {
  final int id;
  final String name;
  final String authorName;
  final String languageName;

  const TafsirResource({
    required this.id,
    required this.name,
    required this.authorName,
    required this.languageName,
  });

  factory TafsirResource.fromJson(Map<String, dynamic> json) {
    return TafsirResource(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      authorName: json['author_name'] as String? ?? '',
      languageName: json['language_name'] as String? ?? '',
    );
  }
}

/// Data model for a single verse's translation or tafsir text.
class VerseText {
  final String verseKey;
  final String text;
  final int resourceId;

  const VerseText({
    required this.verseKey,
    required this.text,
    required this.resourceId,
  });
}

/// Service for fetching translations and tafsir from the Quran Foundation API v4.
///
/// **IMPORTANT**: The v4 API does NOT support the `/quran/translations/{id}`
/// or `/quran/tafsirs/{id}` endpoints (they return empty arrays).
///
/// Instead, translations and tafsirs are fetched via the `/verses/` endpoints
/// using query parameters:
/// - `/verses/by_key/{key}?translations={id}` — single verse translation
/// - `/verses/by_page/{page}?translations={id}` — all page translations
/// - `/verses/by_key/{key}?tafsirs={id}` — single verse tafsir
class TafsirService {
  static const String _baseUrl =
      'https://apis.quran.foundation/content/api/v4';

  // Default resource IDs (verified working in v4 API)
  // Defaults are English since the default app locale is 'en'.
  // Arabic IDs are set dynamically via ContextProvider.setLocale('ar').
  //
  // 85 = Abdel Haleem (English translation) — verified working
  static const int defaultTranslationId = 85;
  // 169 = Ibn Kathir Abridged (English, brief) — verified working
  static const int defaultBriefTafsirId = 169;
  // 168 = Ma'arif al-Qur'an (English, detailed) — verified working
  static const int defaultDetailedTafsirId = 168;

  // In-memory caches keyed by "resourceId:verseKey"
  final Map<String, VerseText> _translationCache = {};
  final Map<String, VerseText> _tafsirCache = {};

  // Cached resource lists
  List<TafsirResource>? _availableTranslations;
  List<TafsirResource>? _availableTafsirs;

  /// Helper to get authenticated headers.
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await QuranAuthService.getValidToken();
    return {'x-auth-token': token, 'x-client-id': QuranAuthService.clientId};
  }

  // ── Translation Methods ──

  /// Fetch the translation for a single verse via /verses/by_key.
  ///
  /// [verseKey] format: "chapter:verse" e.g. "2:255"
  /// [translationId] defaults to 85 (Abdel Haleem, English).
  Future<VerseText?> getTranslation(
    String verseKey, {
    int translationId = defaultTranslationId,
  }) async {
    final cacheKey = '$translationId:$verseKey';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey];
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl/verses/by_key/$verseKey'
        '?translations=$translationId',
      );

      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final verse = data['verse'] as Map<String, dynamic>?;
        if (verse == null) return null;

        final translations = verse['translations'] as List<dynamic>?;
        if (translations != null && translations.isNotEmpty) {
          final text = _stripHtml(translations.first['text'] as String? ?? '');
          final result = VerseText(
            verseKey: verseKey,
            text: text,
            resourceId: translationId,
          );
          _translationCache[cacheKey] = result;
          return result;
        }
      } else {
        debugPrint(
          'TafsirService: Failed to fetch translation for $verseKey: '
          '${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('TafsirService: Error fetching translation for $verseKey: $e');
    }
    return null;
  }

  /// Fetch translations for all verses on a page in a single batch call.
  ///
  /// Uses /verses/by_page/{page}?translations={id}&per_page=50
  Future<Map<String, VerseText>> getTranslationsForPage(
    int pageNumber, {
    int translationId = defaultTranslationId,
  }) async {
    final results = <String, VerseText>{};

    try {
      final uri = Uri.parse(
        '$_baseUrl/verses/by_page/$pageNumber'
        '?translations=$translationId'
        '&per_page=50',
      );

      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final verses = data['verses'] as List<dynamic>?;

        if (verses != null) {
          for (final v in verses) {
            final vk = v['verse_key'] as String?;
            final translations = v['translations'] as List<dynamic>?;
            if (vk != null && translations != null && translations.isNotEmpty) {
              final text =
                  _stripHtml(translations.first['text'] as String? ?? '');
              final vt = VerseText(
                verseKey: vk,
                text: text,
                resourceId: translationId,
              );
              results[vk] = vt;
              _translationCache['$translationId:$vk'] = vt;
            }
          }
        }
      } else {
        debugPrint(
          'TafsirService: Failed to fetch page translations: '
          '${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('TafsirService: Error fetching page translations: $e');
    }
    return results;
  }

  // ── Tafsir Methods ──

  /// Fetch tafsir for a single verse via /verses/by_key.
  ///
  /// [verseKey] format: "chapter:verse" e.g. "2:255"
  /// [tafsirId] defaults to 16 (Tafsir al-Muyassar).
  Future<VerseText?> getTafsir(
    String verseKey, {
    int tafsirId = defaultBriefTafsirId,
  }) async {
    final cacheKey = '$tafsirId:$verseKey';
    if (_tafsirCache.containsKey(cacheKey)) {
      return _tafsirCache[cacheKey];
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl/verses/by_key/$verseKey'
        '?tafsirs=$tafsirId',
      );

      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final verse = data['verse'] as Map<String, dynamic>?;
        if (verse == null) return null;

        final tafsirs = verse['tafsirs'] as List<dynamic>?;
        if (tafsirs != null && tafsirs.isNotEmpty) {
          final text = _stripHtml(tafsirs.first['text'] as String? ?? '');
          final result = VerseText(
            verseKey: verseKey,
            text: text,
            resourceId: tafsirId,
          );
          _tafsirCache[cacheKey] = result;
          return result;
        }
      } else {
        debugPrint(
          'TafsirService: Failed to fetch tafsir for $verseKey: '
          '${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('TafsirService: Error fetching tafsir for $verseKey: $e');
    }
    return null;
  }

  // ── Resource Discovery ──

  /// Fetch the list of available translations from the API.
  Future<List<TafsirResource>> getAvailableTranslations() async {
    if (_availableTranslations != null) return _availableTranslations!;

    try {
      final uri = Uri.parse('$_baseUrl/resources/translations');
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['translations'] as List<dynamic>?;
        if (list != null) {
          _availableTranslations =
              list.map((j) => TafsirResource.fromJson(j)).toList();
          return _availableTranslations!;
        }
      }
    } catch (e) {
      debugPrint('TafsirService: Error fetching translations list: $e');
    }
    return [];
  }

  /// Fetch the list of available tafsirs from the API.
  Future<List<TafsirResource>> getAvailableTafsirs() async {
    if (_availableTafsirs != null) return _availableTafsirs!;

    try {
      final uri = Uri.parse('$_baseUrl/resources/tafsirs');
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['tafsirs'] as List<dynamic>?;
        if (list != null) {
          _availableTafsirs =
              list.map((j) => TafsirResource.fromJson(j)).toList();
          return _availableTafsirs!;
        }
      }
    } catch (e) {
      debugPrint('TafsirService: Error fetching tafsirs list: $e');
    }
    return [];
  }

  // ── Helpers ──

  /// Strip basic HTML tags from API response text.
  /// The API sometimes returns text wrapped in <p>, <br>, <h2>, etc.
  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }
}
