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
  });
}
