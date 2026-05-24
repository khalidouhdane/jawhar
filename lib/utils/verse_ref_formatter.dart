import 'package:quran_app/data/surah_metadata.dart';

enum VerseRefFormat { full, standard, compact }

class VerseRefFormatter {
  /// Converts standard digits to Eastern Arabic numerals if the locale is Arabic.
  static String localizeNumbers(String input, String locale) {
    if (!locale.startsWith('ar')) return input;
    final digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return input.split('').map((char) {
      final val = int.tryParse(char);
      return val != null ? digits[val] : char;
    }).join('');
  }

  /// Parse a verseKey "12:14" → (surahId: 12, verse: 14)
  static (int surahId, int verse) parse(String verseKey) {
    final parts = verseKey.split(':');
    if (parts.length != 2) {
      return (1, 1); // Fallback
    }
    final surahId = int.tryParse(parts[0]) ?? 1;
    final verse = int.tryParse(parts[1]) ?? 1;
    return (surahId, verse);
  }

  /// Get surah name for a given ID and locale
  static String surahName(int surahId, String locale) {
    if (surahId < 1 || surahId > 114) return '';
    final info = allSurahs[surahId - 1];
    return locale.startsWith('ar') ? info.nameArabic : info.nameSimple;
  }

  /// Format a verse reference from a verseKey like "12:14"
  static String format(
    String verseKey, {
    required String locale,
    VerseRefFormat tier = VerseRefFormat.standard,
    int? page,
  }) {
    final parsed = parse(verseKey);
    return formatParts(
      surahId: parsed.$1,
      verse: parsed.$2,
      locale: locale,
      tier: tier,
      page: page,
    );
  }

  /// Format from individual parts
  static String formatParts({
    required int surahId,
    required int verse,
    required String locale,
    VerseRefFormat tier = VerseRefFormat.standard,
    int? page,
  }) {
    final name = surahName(surahId, locale);
    final isArabic = locale.startsWith('ar');

    String formatted;
    switch (tier) {
      case VerseRefFormat.full:
        if (isArabic) {
          final verseStr = localizeNumbers(verse.toString(), locale);
          formatted = 'سورة $name، الآية $verseStr';
        } else {
          formatted = 'Surah $name, Verse $verse';
        }
        break;
      case VerseRefFormat.standard:
        if (isArabic) {
          final verseStr = localizeNumbers(verse.toString(), locale);
          formatted = '$name · الآية $verseStr';
        } else {
          formatted = '$name · Verse $verse';
        }
        break;
      case VerseRefFormat.compact:
        final verseStr = localizeNumbers(verse.toString(), locale);
        formatted = '$name · $verseStr';
        break;
    }

    if (page != null) {
      if (isArabic) {
        final pageStr = localizeNumbers(page.toString(), locale);
        formatted += ' · ص.$pageStr';
      } else {
        formatted += ' · p.$page';
      }
    }

    return formatted;
  }
}
