import 'package:quran/quran.dart' as quran;

void main() {
  try {
    print('getSurahName: ${quran.getSurahName(1)}');
  } catch (e) {
    print('getSurahName Error: $e');
  }

  try {
    print('getSurahNameEnglish: ${quran.getSurahNameEnglish(1)}');
  } catch (e) {
    print('getSurahNameEnglish Error: $e');
  }
}
