import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/services/api_client.dart';
import 'package:quran_app/services/quranenc_service.dart';
import 'package:quran_app/utils/app_logger.dart';

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
  static const String _baseUrl = 'https://apis.quran.foundation/content/api/v4';

  // Default resource IDs (verified working in v4 API)
  // Defaults are English since the default app locale is 'en'.
  // Arabic IDs are set dynamically via ContextProvider.setLocale('ar').
  //
  // 85 = Abdel Haleem (English translation) — verified working
  static const int defaultTranslationId = 85;
  // 169 = Ibn Kathir Abridged (English) — used for DETAILED tab only.
  //       NOT suitable for Brief (14k chars/verse = passage-level commentary).
  static const int defaultBriefTafsirId = 169;
  // 168 = Ma'arif al-Qur'an (English, detailed) — verified working
  static const int defaultDetailedTafsirId = 168;

  // Arabic brief tafsir ID — Al-Muyassar (688 chars/verse, concise)
  static const int arabicBriefTafsirId = 16;

  // QuranEnc service for concise English tafsir
  final QuranEncService _quranEncService = QuranEncService();

  // In-memory caches keyed by "resourceId:verseKey"
  final Map<String, VerseText> _translationCache = {};
  final Map<String, VerseText> _tafsirCache = {};

  // Bundled offline default translations
  static Map<String, String>? _bundledEnglish;
  static Map<String, String>? _bundledArabic;

  /// Loads bundled translations into memory on first access
  Future<void> _loadBundledTranslations() async {
    if (_bundledEnglish == null) {
      try {
        final enData = await rootBundle.loadString('assets/data/translations/en_85.json');
        final Map<String, dynamic> enMap = json.decode(enData);
        _bundledEnglish = enMap.map((k, v) => MapEntry(k, v.toString()));
      } catch (e) {
        _bundledEnglish = {}; // fail gracefully
        AppLogger.info('Tafsir', 'Failed to load bundled EN translation: $e');
      }
    }
    if (_bundledArabic == null) {
      try {
        final arData = await rootBundle.loadString('assets/data/translations/ar_16.json');
        final Map<String, dynamic> arMap = json.decode(arData);
        _bundledArabic = arMap.map((k, v) => MapEntry(k, v.toString()));
      } catch (e) {
        _bundledArabic = {}; // fail gracefully
        AppLogger.info('Tafsir', 'Failed to load bundled AR tafsir: $e');
      }
    }
  }

  // Cached resource lists
  List<TafsirResource>? _availableTranslations;
  List<TafsirResource>? _availableTafsirs;

  // ── Translation Methods ──

  /// Fetch the translation for a single verse via /verses/by_key.
  ///
  /// [verseKey] format: "chapter:verse" e.g. "2:255"
  /// [translationId] defaults to 85 (Abdel Haleem, English).
  Future<VerseText?> getTranslation(
    String verseKey, {
    int translationId = defaultTranslationId,
  }) async {
    // 1. Check bundled offline translation
    if (translationId == defaultTranslationId) {
      await _loadBundledTranslations();
      final text = _bundledEnglish?[verseKey];
      if (text != null) {
        return VerseText(
          verseKey: verseKey,
          text: text,
          resourceId: translationId,
        );
      }
    }

    final cacheKey = '$translationId:$verseKey';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey];
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl/verses/by_key/$verseKey'
        '?translations=$translationId',
      );

      final response = await ApiClient.get(
        uri,
        timeout: const Duration(seconds: 10),
        maxRetries: 2,
      );

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
        AppLogger.info(
          'Tafsir',
          'TafsirService: Failed to fetch translation for $verseKey: '
              '${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.info(
        'Tafsir',
        'TafsirService: Error fetching translation for $verseKey: $e',
      );
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

    // 1. Check bundled offline translation
    if (translationId == defaultTranslationId) {
      await _loadBundledTranslations();
      if (_bundledEnglish != null && _bundledEnglish!.isNotEmpty) {
        final pageSegments = quran.getPageData(pageNumber);
        for (final segment in pageSegments) {
          final surah = segment['surah'] as int;
          final start = segment['start'] as int;
          final end = segment['end'] as int;
          for (int v = start; v <= end; v++) {
            final vk = '$surah:$v';
            final text = _bundledEnglish![vk];
            if (text != null) {
              results[vk] = VerseText(
                verseKey: vk,
                text: text,
                resourceId: translationId,
              );
            }
          }
        }
        if (results.isNotEmpty) return results;
      }
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl/verses/by_page/$pageNumber'
        '?translations=$translationId'
        '&per_page=50',
      );

      final response = await ApiClient.get(
        uri,
        timeout: const Duration(seconds: 12),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final verses = data['verses'] as List<dynamic>?;

        if (verses != null) {
          for (final v in verses) {
            final vk = v['verse_key'] as String?;
            final translations = v['translations'] as List<dynamic>?;
            if (vk != null && translations != null && translations.isNotEmpty) {
              final text = _stripHtml(
                translations.first['text'] as String? ?? '',
              );
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
        AppLogger.info(
          'Tafsir',
          'TafsirService: Failed to fetch page translations: '
              '${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.info(
        'Tafsir',
        'TafsirService: Error fetching page translations: $e',
      );
    }
    return results;
  }

  // ── Tafsir Methods ──

  /// Fetch **brief** tafsir for a verse, using the hybrid strategy.
  ///
  /// - **Arabic**: Uses Quran Foundation API (Al-Muyassar, ID 16) — concise
  /// - **English**: Uses QuranEnc API (Al-Mukhtasar) — the QF API has NO
  ///   concise English tafsir (smallest is 14k chars/verse)
  ///
  /// [verseKey] format: "chapter:verse" e.g. "2:255"
  /// [locale] determines which backend to use.
  Future<VerseText?> getBriefTafsir(
    String verseKey, {
    String locale = 'en',
  }) async {
    if (locale == 'ar') {
      // Arabic: use Quran Foundation API — Al-Muyassar (ID 16)
      return getTafsir(verseKey, tafsirId: arabicBriefTafsirId);
    } else {
      // English: use QuranEnc API — Al-Mukhtasar
      return _quranEncService.getTafsir(
        verseKey,
        translationKey: QuranEncService.englishMokhtasarKey,
      );
    }
  }

  /// Fetch tafsir for a single verse via the Quran Foundation /verses/by_key.
  ///
  /// [verseKey] format: "chapter:verse" e.g. "2:255"
  /// [tafsirId] is the QF API resource ID.
  Future<VerseText?> getTafsir(
    String verseKey, {
    int tafsirId = defaultBriefTafsirId,
  }) async {
    // 1. Check bundled offline brief Arabic tafsir
    if (tafsirId == arabicBriefTafsirId) {
      await _loadBundledTranslations();
      final text = _bundledArabic?[verseKey];
      if (text != null) {
        return VerseText(
          verseKey: verseKey,
          text: text,
          resourceId: tafsirId,
        );
      }
    }

    final cacheKey = '$tafsirId:$verseKey';
    if (_tafsirCache.containsKey(cacheKey)) {
      return _tafsirCache[cacheKey];
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl/verses/by_key/$verseKey'
        '?tafsirs=$tafsirId',
      );

      final response = await ApiClient.get(
        uri,
        timeout: const Duration(seconds: 10),
        maxRetries: 2,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final verse = data['verse'] as Map<String, dynamic>?;
        if (verse == null) return null;

        final tafsirs = verse['tafsirs'] as List<dynamic>?;
        if (tafsirs != null && tafsirs.isNotEmpty) {
          final text =
              _formatTafsirHtml(tafsirs.first['text'] as String? ?? '');
          final result = VerseText(
            verseKey: verseKey,
            text: text,
            resourceId: tafsirId,
          );
          _tafsirCache[cacheKey] = result;
          return result;
        }
      } else {
        AppLogger.info(
          'Tafsir',
          'TafsirService: Failed to fetch tafsir for $verseKey: '
              '${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.info(
        'Tafsir',
        'TafsirService: Error fetching tafsir for $verseKey: $e',
      );
    }
    return null;
  }

  // ── Resource Discovery ──

  /// Fetch the list of available translations from the API.
  Future<List<TafsirResource>> getAvailableTranslations() async {
    if (_availableTranslations != null) return _availableTranslations!;

    try {
      final uri = Uri.parse('$_baseUrl/resources/translations');
      final response = await ApiClient.get(
        uri,
        timeout: const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['translations'] as List<dynamic>?;
        if (list != null) {
          _availableTranslations = list
              .map((j) => TafsirResource.fromJson(j))
              .toList();
          return _availableTranslations!;
        }
      }
    } catch (e) {
      AppLogger.info(
        'Tafsir',
        'TafsirService: Error fetching translations list: $e',
      );
    }
    return [];
  }

  /// Fetch the list of available tafsirs from the API.
  Future<List<TafsirResource>> getAvailableTafsirs() async {
    if (_availableTafsirs != null) return _availableTafsirs!;

    try {
      final uri = Uri.parse('$_baseUrl/resources/tafsirs');
      final response = await ApiClient.get(
        uri,
        timeout: const Duration(seconds: 8),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['tafsirs'] as List<dynamic>?;
        if (list != null) {
          _availableTafsirs = list
              .map((j) => TafsirResource.fromJson(j))
              .toList();
          return _availableTafsirs!;
        }
      }
    } catch (e) {
      AppLogger.info(
        'Tafsir',
        'TafsirService: Error fetching tafsirs list: $e',
      );
    }
    return [];
  }

  // ── Helpers ──

  /// Convert HTML from API response text to readable plain text.
  ///
  /// Unlike a naive `replaceAll(RegExp(r'<[^>]*>'), '')` strip, this
  /// preserves structural formatting: paragraphs become double newlines,
  /// line breaks become single newlines, and headers get visual separation.
  static String _formatTafsirHtml(String html) {
    return html
        // Convert block-level closing tags to double newlines
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        // Convert <br> to single newline
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        // Strip all remaining HTML tags
        .replaceAll(RegExp(r'<[^>]*>'), '')
        // Decode HTML entities
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        // Collapse excessive whitespace
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();
  }

  /// Legacy alias — callers that used _stripHtml now get formatted output.
  String _stripHtml(String html) => _formatTafsirHtml(html);
}
