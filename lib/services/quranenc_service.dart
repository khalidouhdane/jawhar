import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quran_app/services/tafsir_service.dart';
import 'package:quran_app/utils/app_logger.dart';

/// Service for fetching tafsir from the QuranEnc API (quranenc.com).
///
/// Used as a supplement to the Quran Foundation API for resources that
/// the primary API doesn't offer — specifically concise English tafsir.
///
/// ## Why This Exists
///
/// The Quran Foundation API has **no concise English tafsir**. Their only
/// English tafsirs (Ibn Kathir Abridged = 14k chars, Ma'arif al-Qur'an =
/// 10k chars per verse) are passage-level scholarly works unsuitable for
/// a "Brief" tab.
///
/// QuranEnc's Al-Mukhtasar provides per-verse concise explanations
/// (~100-800 chars), perfect for the Brief tab.
///
/// ## API Reference
///
/// ```
/// GET /api/v1/translation/aya/{key}/{sura}/{aya}
/// ```
///
/// No authentication required. Public API.
///
/// Available keys:
/// - `english_mokhtasar` — Al-Mukhtasar (concise EN tafsir)
/// - `arabic_moyassar` — Al-Muyassar (concise AR tafsir)
class QuranEncService {
  static const String _baseUrl = 'https://quranenc.com/api/v1';

  /// QuranEnc translation key for English Al-Mukhtasar tafsir.
  static const String englishMokhtasarKey = 'english_mokhtasar';

  /// QuranEnc translation key for Arabic Al-Muyassar tafsir.
  static const String arabicMoyassarKey = 'arabic_moyassar';

  /// In-memory cache keyed by "translationKey:sura:aya".
  final Map<String, VerseText> _cache = {};

  /// Fetch a per-verse tafsir from QuranEnc.
  ///
  /// [verseKey] format: "chapter:verse" e.g. "2:255"
  /// [translationKey] is the QuranEnc resource key (e.g. 'english_mokhtasar').
  ///
  /// Returns a [VerseText] with `resourceId = -1` to distinguish from
  /// Quran Foundation API results. The `text` field contains the clean
  /// tafsir text (no HTML).
  Future<VerseText?> getTafsir(
    String verseKey, {
    String translationKey = englishMokhtasarKey,
  }) async {
    final cacheKey = '$translationKey:$verseKey';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    // Parse verse key: "2:255" → sura=2, aya=255
    final parts = verseKey.split(':');
    if (parts.length != 2) {
      AppLogger.info('QuranEnc', 'Invalid verse key format: $verseKey');
      return null;
    }
    final sura = parts[0];
    final aya = parts[1];

    try {
      final url = '$_baseUrl/translation/aya/$translationKey/$sura/$aya';
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'] as Map<String, dynamic>?;

        if (result != null) {
          var text = result['translation'] as String? ?? '';

          // Strip leading verse number (e.g. "255. " or "1. ")
          text = _stripLeadingVerseNumber(text);

          // Handle footnotes if present
          final footnotes = result['footnotes'] as String?;
          if (footnotes != null && footnotes.isNotEmpty) {
            text = '$text\n\n$footnotes';
          }

          final verseText = VerseText(
            verseKey: verseKey,
            text: text.trim(),
            resourceId: -1, // Marker for QuranEnc source
          );
          _cache[cacheKey] = verseText;
          return verseText;
        }
      } else if (response.statusCode == 404) {
        AppLogger.info(
          'QuranEnc',
          'Verse not found: $verseKey (key: $translationKey)',
        );
      } else {
        AppLogger.info('QuranEnc', 'HTTP ${response.statusCode} for $verseKey');
      }
    } catch (e) {
      AppLogger.info('QuranEnc', 'Error fetching $verseKey: $e');
    }
    return null;
  }

  /// Strip the leading verse number prefix from QuranEnc responses.
  ///
  /// QuranEnc prepends "255. " or "1. " to each verse's translation text.
  /// We strip this since the verse number is already shown in the UI header.
  String _stripLeadingVerseNumber(String text) {
    // Match patterns like "255. " or "1. " at the start
    final match = RegExp(r'^\d+\.\s*').firstMatch(text);
    if (match != null) {
      return text.substring(match.end);
    }
    return text;
  }

  /// Clear all cached data.
  void clearCache() {
    _cache.clear();
  }
}
