/// Vendored Madani-mushaf metadata needed by the planner.
///
/// The `quran` pub package (1.4.1) declares Flutter as a main dependency and
/// therefore can never run server-side — these tables are vendored here so
/// `hifz_core` (and the jawhar-api server) never need it. A Flutter-side
/// consistency test in the app (`test/quran_meta_consistency_test.dart`)
/// pins these values to the `quran` package to prevent silent divergence
/// (roadmap §6 / R6).
class QuranMeta {
  QuranMeta._();

  /// Total pages in the Madani mushaf.
  static const int totalPages = 604;

  /// Total juz count.
  static const int totalJuz = 30;

  /// Lines per page in the Madani mushaf.
  static const int linesPerPage = 15;

  /// Start page of each juz (index 0 unused; index 1 = juz 1).
  ///
  /// Values are byte-identical to the table previously inlined in
  /// `lib/services/plan_generation_service.dart` (`_juzStartPage`).
  static const List<int> juzStartPages = [
    0,
    1,
    22,
    42,
    62,
    82,
    102,
    121,
    142,
    162,
    182,
    201,
    222,
    242,
    262,
    282,
    302,
    322,
    342,
    362,
    382,
    402,
    422,
    442,
    462,
    482,
    502,
    522,
    542,
    562,
    582,
  ];

  /// Start page of [juz] (clamped to 1–30) — same semantics as the
  /// historical `PlanGenerationService._juzStartPage`.
  static int juzStartPage(int juz) => juzStartPages[juz.clamp(1, totalJuz)];

  /// Last page of [juz]: the page before the next juz starts
  /// (juz 30 ends on page 604).
  static int juzEndPage(int juz) =>
      juz < totalJuz ? juzStartPage(juz + 1) - 1 : totalPages;

  /// The juz containing [page] — the largest juz whose start page is
  /// <= [page] (same semantics as the historical
  /// `AnalyticsService._pageToJuz` table walk; pages below 1 map to juz 1).
  static int pageToJuz(int page) {
    for (var juz = totalJuz; juz >= 1; juz--) {
      if (page >= juzStartPages[juz]) return juz;
    }
    return 1;
  }
}
