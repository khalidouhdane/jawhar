// Static surah metadata for offline-first rendering.
//
// This data never changes — it's fixed Islamic knowledge.
// Used by the Understand tab to render the surah browser
// without depending on QuranReadingProvider.chapters (API).
//
// Rewaya-aware: Hafs (rewaya=1) and Warsh (rewaya=2) verse counts
// are both provided. When in Warsh mode, all UI surfaces automatically
// show the correct Warsh verse count.

/// Rewaya constants — keep in sync with LocalStorageService.
const int rewayaHafs = 1;
const int rewayaWarsh = 2;

/// Surah number → starting Mushaf page (Madani layout, 1-indexed).
/// Note: These are Hafs Madani mushaf page starts.
/// Warsh mushafs use different page layouts.
const List<int> surahStartPages = [
  0, // Index 0 unused (surahs are 1-indexed)
  1, 2, 50, 77, 106, 128, 151, 177, 187, 208, // 1-10
  221, 235, 249, 255, 262, 267, 282, 293, 305, 312, // 11-20
  322, 332, 342, 350, 359, 367, 377, 385, 396, 404, // 21-30
  411, 415, 418, 428, 434, 440, 446, 453, 458, 467, // 31-40
  477, 483, 489, 496, 499, 502, 507, 511, 515, 518, // 41-50
  520, 523, 526, 528, 531, 534, 537, 542, 545, 549, // 51-60
  551, 553, 554, 556, 558, 560, 562, 564, 566, 568, // 61-70
  570, 572, 574, 575, 577, 578, 580, 582, 583, 585, // 71-80
  586, 587, 587, 589, 590, 591, 591, 592, 593, 594, // 81-90
  595, 595, 596, 596, 597, 597, 598, 598, 599, 599, // 91-100
  600, 600, 601, 601, 601, 602, 602, 602, 603, 603, // 101-110
  603, 604, 604, 604, // 111-114
];

/// Minimal surah metadata for offline rendering.
class SurahInfo {
  final int id;
  final String nameSimple;
  final String nameArabic;
  final int versesCount;
  final bool isMeccan;

  const SurahInfo({
    required this.id,
    required this.nameSimple,
    required this.nameArabic,
    required this.versesCount,
    required this.isMeccan,
  });

  String get revelationType => isMeccan ? 'Meccan' : 'Medinan';
  int get startPage => surahStartPages[id];
}

/// Warsh verse counts for all 114 surahs.
///
/// The fawazahmed0/quran-api Warsh CDN uses standard Medina Mushaf
/// 6236-verse numbering (same as Hafs). For surahs where scholarly
/// Warsh counting differs, update the values here.
const List<int> warshVerseCounts = [
  0, // Index 0 unused (surahs are 1-indexed)
  7, 286, 200, 176, 120, 165, 206, 75, 129, 109, // 1-10
  123, 111, 43, 52, 99, 128, 111, 110, 98, 135, // 11-20
  112, 78, 118, 64, 77, 227, 93, 88, 69, 60, // 21-30
  34, 30, 73, 54, 45, 83, 182, 88, 75, 85, // 31-40
  54, 53, 89, 59, 37, 35, 38, 29, 18, 45, // 41-50
  60, 49, 62, 55, 78, 96, 29, 22, 24, 13, // 51-60
  14, 11, 11, 18, 12, 12, 30, 52, 52, 44, // 61-70
  28, 28, 20, 56, 40, 31, 50, 40, 46, 42, // 71-80
  29, 19, 36, 25, 22, 17, 19, 26, 30, 20, // 81-90
  15, 21, 11, 8, 8, 19, 5, 8, 8, 11, // 91-100
  11, 8, 3, 9, 5, 4, 7, 3, 6, 3, // 101-110
  5, 4, 5, 6, // 111-114
];

/// Get the verse count for a surah, respecting the selected rewaya.
int getVersesCount(int surahId, {int rewaya = rewayaHafs}) {
  assert(surahId >= 1 && surahId <= 114);
  if (rewaya == rewayaWarsh) {
    return warshVerseCounts[surahId];
  }
  // Default: Hafs counts from the quran package
  // These match the surah_metadata hardcoded list below.
  return allSurahs[surahId - 1].versesCount;
}

/// Get all surahs with rewaya-aware verse counts.
List<SurahInfo> getAllSurahs({int rewaya = rewayaHafs}) {
  if (rewaya == rewayaWarsh) {
    return List.generate(114, (i) {
      final hafs = allSurahs[i];
      return SurahInfo(
        id: hafs.id,
        nameSimple: hafs.nameSimple,
        nameArabic: hafs.nameArabic,
        versesCount: warshVerseCounts[hafs.id],
        isMeccan: hafs.isMeccan,
      );
    });
  }
  return allSurahs;
}

/// All 114 surahs with static metadata (Hafs verse counts).
const List<SurahInfo> allSurahs = [
  SurahInfo(id: 1, nameSimple: 'Al-Fatihah', nameArabic: 'الفاتحة', versesCount: 7, isMeccan: true),
  SurahInfo(id: 2, nameSimple: 'Al-Baqarah', nameArabic: 'البقرة', versesCount: 286, isMeccan: false),
  SurahInfo(id: 3, nameSimple: "Ali 'Imran", nameArabic: 'آل عمران', versesCount: 200, isMeccan: false),
  SurahInfo(id: 4, nameSimple: 'An-Nisa', nameArabic: 'النساء', versesCount: 176, isMeccan: false),
  SurahInfo(id: 5, nameSimple: "Al-Ma'idah", nameArabic: 'المائدة', versesCount: 120, isMeccan: false),
  SurahInfo(id: 6, nameSimple: "Al-An'am", nameArabic: 'الأنعام', versesCount: 165, isMeccan: true),
  SurahInfo(id: 7, nameSimple: "Al-A'raf", nameArabic: 'الأعراف', versesCount: 206, isMeccan: true),
  SurahInfo(id: 8, nameSimple: 'Al-Anfal', nameArabic: 'الأنفال', versesCount: 75, isMeccan: false),
  SurahInfo(id: 9, nameSimple: 'At-Tawbah', nameArabic: 'التوبة', versesCount: 129, isMeccan: false),
  SurahInfo(id: 10, nameSimple: 'Yunus', nameArabic: 'يونس', versesCount: 109, isMeccan: true),
  SurahInfo(id: 11, nameSimple: 'Hud', nameArabic: 'هود', versesCount: 123, isMeccan: true),
  SurahInfo(id: 12, nameSimple: 'Yusuf', nameArabic: 'يوسف', versesCount: 111, isMeccan: true),
  SurahInfo(id: 13, nameSimple: "Ar-Ra'd", nameArabic: 'الرعد', versesCount: 43, isMeccan: false),
  SurahInfo(id: 14, nameSimple: 'Ibrahim', nameArabic: 'إبراهيم', versesCount: 52, isMeccan: true),
  SurahInfo(id: 15, nameSimple: 'Al-Hijr', nameArabic: 'الحجر', versesCount: 99, isMeccan: true),
  SurahInfo(id: 16, nameSimple: 'An-Nahl', nameArabic: 'النحل', versesCount: 128, isMeccan: true),
  SurahInfo(id: 17, nameSimple: 'Al-Isra', nameArabic: 'الإسراء', versesCount: 111, isMeccan: true),
  SurahInfo(id: 18, nameSimple: 'Al-Kahf', nameArabic: 'الكهف', versesCount: 110, isMeccan: true),
  SurahInfo(id: 19, nameSimple: 'Maryam', nameArabic: 'مريم', versesCount: 98, isMeccan: true),
  SurahInfo(id: 20, nameSimple: 'Ta-Ha', nameArabic: 'طه', versesCount: 135, isMeccan: true),
  SurahInfo(id: 21, nameSimple: 'Al-Anbya', nameArabic: 'الأنبياء', versesCount: 112, isMeccan: true),
  SurahInfo(id: 22, nameSimple: 'Al-Hajj', nameArabic: 'الحج', versesCount: 78, isMeccan: false),
  SurahInfo(id: 23, nameSimple: "Al-Mu'minun", nameArabic: 'المؤمنون', versesCount: 118, isMeccan: true),
  SurahInfo(id: 24, nameSimple: 'An-Nur', nameArabic: 'النور', versesCount: 64, isMeccan: false),
  SurahInfo(id: 25, nameSimple: 'Al-Furqan', nameArabic: 'الفرقان', versesCount: 77, isMeccan: true),
  SurahInfo(id: 26, nameSimple: "Ash-Shu'ara", nameArabic: 'الشعراء', versesCount: 227, isMeccan: true),
  SurahInfo(id: 27, nameSimple: 'An-Naml', nameArabic: 'النمل', versesCount: 93, isMeccan: true),
  SurahInfo(id: 28, nameSimple: 'Al-Qasas', nameArabic: 'القصص', versesCount: 88, isMeccan: true),
  SurahInfo(id: 29, nameSimple: "Al-'Ankabut", nameArabic: 'العنكبوت', versesCount: 69, isMeccan: true),
  SurahInfo(id: 30, nameSimple: 'Ar-Rum', nameArabic: 'الروم', versesCount: 60, isMeccan: true),
  SurahInfo(id: 31, nameSimple: 'Luqman', nameArabic: 'لقمان', versesCount: 34, isMeccan: true),
  SurahInfo(id: 32, nameSimple: 'As-Sajdah', nameArabic: 'السجدة', versesCount: 30, isMeccan: true),
  SurahInfo(id: 33, nameSimple: 'Al-Ahzab', nameArabic: 'الأحزاب', versesCount: 73, isMeccan: false),
  SurahInfo(id: 34, nameSimple: "Saba'", nameArabic: 'سبأ', versesCount: 54, isMeccan: true),
  SurahInfo(id: 35, nameSimple: 'Fatir', nameArabic: 'فاطر', versesCount: 45, isMeccan: true),
  SurahInfo(id: 36, nameSimple: 'Ya-Sin', nameArabic: 'يس', versesCount: 83, isMeccan: true),
  SurahInfo(id: 37, nameSimple: 'As-Saffat', nameArabic: 'الصافات', versesCount: 182, isMeccan: true),
  SurahInfo(id: 38, nameSimple: 'Sad', nameArabic: 'ص', versesCount: 88, isMeccan: true),
  SurahInfo(id: 39, nameSimple: 'Az-Zumar', nameArabic: 'الزمر', versesCount: 75, isMeccan: true),
  SurahInfo(id: 40, nameSimple: 'Ghafir', nameArabic: 'غافر', versesCount: 85, isMeccan: true),
  SurahInfo(id: 41, nameSimple: 'Fussilat', nameArabic: 'فصلت', versesCount: 54, isMeccan: true),
  SurahInfo(id: 42, nameSimple: 'Ash-Shura', nameArabic: 'الشورى', versesCount: 53, isMeccan: true),
  SurahInfo(id: 43, nameSimple: 'Az-Zukhruf', nameArabic: 'الزخرف', versesCount: 89, isMeccan: true),
  SurahInfo(id: 44, nameSimple: 'Ad-Dukhan', nameArabic: 'الدخان', versesCount: 59, isMeccan: true),
  SurahInfo(id: 45, nameSimple: 'Al-Jathiyah', nameArabic: 'الجاثية', versesCount: 37, isMeccan: true),
  SurahInfo(id: 46, nameSimple: 'Al-Ahqaf', nameArabic: 'الأحقاف', versesCount: 35, isMeccan: true),
  SurahInfo(id: 47, nameSimple: 'Muhammad', nameArabic: 'محمد', versesCount: 38, isMeccan: false),
  SurahInfo(id: 48, nameSimple: 'Al-Fath', nameArabic: 'الفتح', versesCount: 29, isMeccan: false),
  SurahInfo(id: 49, nameSimple: 'Al-Hujurat', nameArabic: 'الحجرات', versesCount: 18, isMeccan: false),
  SurahInfo(id: 50, nameSimple: 'Qaf', nameArabic: 'ق', versesCount: 45, isMeccan: true),
  SurahInfo(id: 51, nameSimple: 'Adh-Dhariyat', nameArabic: 'الذاريات', versesCount: 60, isMeccan: true),
  SurahInfo(id: 52, nameSimple: 'At-Tur', nameArabic: 'الطور', versesCount: 49, isMeccan: true),
  SurahInfo(id: 53, nameSimple: 'An-Najm', nameArabic: 'النجم', versesCount: 62, isMeccan: true),
  SurahInfo(id: 54, nameSimple: 'Al-Qamar', nameArabic: 'القمر', versesCount: 55, isMeccan: true),
  SurahInfo(id: 55, nameSimple: 'Ar-Rahman', nameArabic: 'الرحمن', versesCount: 78, isMeccan: false),
  SurahInfo(id: 56, nameSimple: "Al-Waqi'ah", nameArabic: 'الواقعة', versesCount: 96, isMeccan: true),
  SurahInfo(id: 57, nameSimple: 'Al-Hadid', nameArabic: 'الحديد', versesCount: 29, isMeccan: false),
  SurahInfo(id: 58, nameSimple: 'Al-Mujadila', nameArabic: 'المجادلة', versesCount: 22, isMeccan: false),
  SurahInfo(id: 59, nameSimple: 'Al-Hashr', nameArabic: 'الحشر', versesCount: 24, isMeccan: false),
  SurahInfo(id: 60, nameSimple: 'Al-Mumtahanah', nameArabic: 'الممتحنة', versesCount: 13, isMeccan: false),
  SurahInfo(id: 61, nameSimple: 'As-Saff', nameArabic: 'الصف', versesCount: 14, isMeccan: false),
  SurahInfo(id: 62, nameSimple: "Al-Jumu'ah", nameArabic: 'الجمعة', versesCount: 11, isMeccan: false),
  SurahInfo(id: 63, nameSimple: 'Al-Munafiqun', nameArabic: 'المنافقون', versesCount: 11, isMeccan: false),
  SurahInfo(id: 64, nameSimple: 'At-Taghabun', nameArabic: 'التغابن', versesCount: 18, isMeccan: false),
  SurahInfo(id: 65, nameSimple: 'At-Talaq', nameArabic: 'الطلاق', versesCount: 12, isMeccan: false),
  SurahInfo(id: 66, nameSimple: 'At-Tahrim', nameArabic: 'التحريم', versesCount: 12, isMeccan: false),
  SurahInfo(id: 67, nameSimple: 'Al-Mulk', nameArabic: 'الملك', versesCount: 30, isMeccan: true),
  SurahInfo(id: 68, nameSimple: 'Al-Qalam', nameArabic: 'القلم', versesCount: 52, isMeccan: true),
  SurahInfo(id: 69, nameSimple: 'Al-Haqqah', nameArabic: 'الحاقة', versesCount: 52, isMeccan: true),
  SurahInfo(id: 70, nameSimple: "Al-Ma'arij", nameArabic: 'المعارج', versesCount: 44, isMeccan: true),
  SurahInfo(id: 71, nameSimple: 'Nuh', nameArabic: 'نوح', versesCount: 28, isMeccan: true),
  SurahInfo(id: 72, nameSimple: 'Al-Jinn', nameArabic: 'الجن', versesCount: 28, isMeccan: true),
  SurahInfo(id: 73, nameSimple: 'Al-Muzzammil', nameArabic: 'المزمل', versesCount: 20, isMeccan: true),
  SurahInfo(id: 74, nameSimple: 'Al-Muddaththir', nameArabic: 'المدثر', versesCount: 56, isMeccan: true),
  SurahInfo(id: 75, nameSimple: 'Al-Qiyamah', nameArabic: 'القيامة', versesCount: 40, isMeccan: true),
  SurahInfo(id: 76, nameSimple: 'Al-Insan', nameArabic: 'الإنسان', versesCount: 31, isMeccan: false),
  SurahInfo(id: 77, nameSimple: 'Al-Mursalat', nameArabic: 'المرسلات', versesCount: 50, isMeccan: true),
  SurahInfo(id: 78, nameSimple: "An-Naba'", nameArabic: 'النبأ', versesCount: 40, isMeccan: true),
  SurahInfo(id: 79, nameSimple: "An-Nazi'at", nameArabic: 'النازعات', versesCount: 46, isMeccan: true),
  SurahInfo(id: 80, nameSimple: "'Abasa", nameArabic: 'عبس', versesCount: 42, isMeccan: true),
  SurahInfo(id: 81, nameSimple: 'At-Takwir', nameArabic: 'التكوير', versesCount: 29, isMeccan: true),
  SurahInfo(id: 82, nameSimple: 'Al-Infitar', nameArabic: 'الانفطار', versesCount: 19, isMeccan: true),
  SurahInfo(id: 83, nameSimple: 'Al-Mutaffifin', nameArabic: 'المطففين', versesCount: 36, isMeccan: true),
  SurahInfo(id: 84, nameSimple: 'Al-Inshiqaq', nameArabic: 'الانشقاق', versesCount: 25, isMeccan: true),
  SurahInfo(id: 85, nameSimple: 'Al-Buruj', nameArabic: 'البروج', versesCount: 22, isMeccan: true),
  SurahInfo(id: 86, nameSimple: 'At-Tariq', nameArabic: 'الطارق', versesCount: 17, isMeccan: true),
  SurahInfo(id: 87, nameSimple: "Al-A'la", nameArabic: 'الأعلى', versesCount: 19, isMeccan: true),
  SurahInfo(id: 88, nameSimple: 'Al-Ghashiyah', nameArabic: 'الغاشية', versesCount: 26, isMeccan: true),
  SurahInfo(id: 89, nameSimple: 'Al-Fajr', nameArabic: 'الفجر', versesCount: 30, isMeccan: true),
  SurahInfo(id: 90, nameSimple: 'Al-Balad', nameArabic: 'البلد', versesCount: 20, isMeccan: true),
  SurahInfo(id: 91, nameSimple: 'Ash-Shams', nameArabic: 'الشمس', versesCount: 15, isMeccan: true),
  SurahInfo(id: 92, nameSimple: 'Al-Layl', nameArabic: 'الليل', versesCount: 21, isMeccan: true),
  SurahInfo(id: 93, nameSimple: 'Ad-Duha', nameArabic: 'الضحى', versesCount: 11, isMeccan: true),
  SurahInfo(id: 94, nameSimple: 'Ash-Sharh', nameArabic: 'الشرح', versesCount: 8, isMeccan: true),
  SurahInfo(id: 95, nameSimple: 'At-Tin', nameArabic: 'التين', versesCount: 8, isMeccan: true),
  SurahInfo(id: 96, nameSimple: "Al-'Alaq", nameArabic: 'العلق', versesCount: 19, isMeccan: true),
  SurahInfo(id: 97, nameSimple: 'Al-Qadr', nameArabic: 'القدر', versesCount: 5, isMeccan: true),
  SurahInfo(id: 98, nameSimple: 'Al-Bayyinah', nameArabic: 'البينة', versesCount: 8, isMeccan: false),
  SurahInfo(id: 99, nameSimple: 'Az-Zalzalah', nameArabic: 'الزلزلة', versesCount: 8, isMeccan: false),
  SurahInfo(id: 100, nameSimple: "Al-'Adiyat", nameArabic: 'العاديات', versesCount: 11, isMeccan: true),
  SurahInfo(id: 101, nameSimple: "Al-Qari'ah", nameArabic: 'القارعة', versesCount: 11, isMeccan: true),
  SurahInfo(id: 102, nameSimple: 'At-Takathur', nameArabic: 'التكاثر', versesCount: 8, isMeccan: true),
  SurahInfo(id: 103, nameSimple: "Al-'Asr", nameArabic: 'العصر', versesCount: 3, isMeccan: true),
  SurahInfo(id: 104, nameSimple: 'Al-Humazah', nameArabic: 'الهمزة', versesCount: 9, isMeccan: true),
  SurahInfo(id: 105, nameSimple: 'Al-Fil', nameArabic: 'الفيل', versesCount: 5, isMeccan: true),
  SurahInfo(id: 106, nameSimple: 'Quraysh', nameArabic: 'قريش', versesCount: 4, isMeccan: true),
  SurahInfo(id: 107, nameSimple: "Al-Ma'un", nameArabic: 'الماعون', versesCount: 7, isMeccan: true),
  SurahInfo(id: 108, nameSimple: 'Al-Kawthar', nameArabic: 'الكوثر', versesCount: 3, isMeccan: true),
  SurahInfo(id: 109, nameSimple: 'Al-Kafirun', nameArabic: 'الكافرون', versesCount: 6, isMeccan: true),
  SurahInfo(id: 110, nameSimple: 'An-Nasr', nameArabic: 'النصر', versesCount: 3, isMeccan: false),
  SurahInfo(id: 111, nameSimple: 'Al-Masad', nameArabic: 'المسد', versesCount: 5, isMeccan: true),
  SurahInfo(id: 112, nameSimple: 'Al-Ikhlas', nameArabic: 'الإخلاص', versesCount: 4, isMeccan: true),
  SurahInfo(id: 113, nameSimple: 'Al-Falaq', nameArabic: 'الفلق', versesCount: 5, isMeccan: true),
  SurahInfo(id: 114, nameSimple: 'An-Nas', nameArabic: 'الناس', versesCount: 6, isMeccan: true),
];
