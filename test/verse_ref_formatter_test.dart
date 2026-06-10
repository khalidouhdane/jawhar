import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/utils/verse_ref_formatter.dart';

void main() {
  group('VerseRefFormatter Latin Numbers Tests', () {
    test('localizeNumbers returns Latin digits even for Arabic locale', () {
      expect(VerseRefFormatter.localizeNumbers('123', 'ar'), '123');
      expect(VerseRefFormatter.localizeNumbers('123', 'en'), '123');
    });

    test(
      'delocalizeNumbers converts Eastern Arabic digits to Latin digits',
      () {
        expect(VerseRefFormatter.delocalizeNumbers('۝١٦'), '۝16');
        expect(VerseRefFormatter.delocalizeNumbers('٠١٢٣٤٥٦٧٨٩'), '0123456789');
      },
    );

    test(
      'surahName formats simple name and English translation for English locale',
      () {
        expect(
          VerseRefFormatter.surahName(1, 'en'),
          'Al-Fatihah (The Opening)',
        );
        expect(VerseRefFormatter.surahName(2, 'en'), 'Al-Baqarah (The Cow)');
      },
    );

    test('surahName formats Arabic name for Arabic locale', () {
      expect(VerseRefFormatter.surahName(1, 'ar'), 'الفاتحة');
    });

    test('format formats references with the compound English name', () {
      expect(
        VerseRefFormatter.format(
          '1:1',
          locale: 'en',
          tier: VerseRefFormat.compact,
        ),
        'Al-Fatihah (The Opening) · 1',
      );
    });
  });
}
