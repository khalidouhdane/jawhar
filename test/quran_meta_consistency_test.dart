// Pins the metadata tables vendored inside packages/hifz_core
// (lib/src/quran_meta/) to the `quran` pub package (roadmap §6 / R6).
//
// `hifz_core` must run server-side, and the `quran` package declares Flutter
// as a main dependency, so the juz/page tables the planner needs are vendored
// into the package. This Flutter-side test is the guard against silent
// divergence between the vendored copy and the canonical package data: if it
// fails, fix the vendored table (or consciously re-pin) — never ignore it,
// because the server generates plans from the vendored values.

import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_core/hifz_core.dart';
import 'package:quran/quran.dart' as quran;

void main() {
  test('vendored mushaf constants match the quran package', () {
    expect(QuranMeta.totalPages, quran.totalPagesCount);
    expect(QuranMeta.totalJuz, quran.totalJuzCount);
  });

  test('vendored juz start pages match the quran package', () {
    for (var juz = 1; juz <= quran.totalJuzCount; juz++) {
      final surahVerses = quran.getSurahAndVersesFromJuz(juz);
      final firstSurah = surahVerses.keys.reduce((a, b) => a < b ? a : b);
      final firstVerse = surahVerses[firstSurah]![0];
      final startPage = quran.getPageNumber(firstSurah, firstVerse);
      expect(
        QuranMeta.juzStartPage(juz),
        startPage,
        reason: 'juz $juz starts at $firstSurah:$firstVerse '
            '(page $startPage per the quran package)',
      );
    }
  });

  test('vendored juz end pages are consistent with the start-page table', () {
    for (var juz = 1; juz < quran.totalJuzCount; juz++) {
      expect(
        QuranMeta.juzEndPage(juz),
        QuranMeta.juzStartPage(juz + 1) - 1,
        reason: 'juz $juz must end on the page before juz ${juz + 1} starts',
      );
    }
    expect(QuranMeta.juzEndPage(quran.totalJuzCount), quran.totalPagesCount);
  });

  test('juzStartPage clamps out-of-range juz numbers (historical behavior)', () {
    expect(QuranMeta.juzStartPage(0), QuranMeta.juzStartPage(1));
    expect(QuranMeta.juzStartPage(31), QuranMeta.juzStartPage(30));
  });
}
