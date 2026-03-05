class Verse {
  final int id;
  final int verseNumber;
  final String verseKey;
  final int pageNumber;
  final int juzNumber;
  final int hizbNumber;
  final List<Word> words;
  final String? audioUrl;

  Verse({
    required this.id,
    required this.verseNumber,
    required this.verseKey,
    required this.pageNumber,
    required this.juzNumber,
    required this.hizbNumber,
    required this.words,
    this.audioUrl,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      id: json['id'],
      verseNumber: json['verse_number'],
      verseKey: json['verse_key'],
      pageNumber: json['page_number'],
      juzNumber: json['juz_number'],
      hizbNumber: json['hizb_number'] ?? 0,
      words: (json['words'] as List).map((w) => Word.fromJson(w)).toList(),
      audioUrl: json['audio']?['url'],
    );
  }
}

class Word {
  final int id;
  final int position;
  final String? audioUrl;
  final String charTypeName;
  final String textUthmani;
  final String? translationText;
  final String? transliterationText;
  final int lineNumber;

  Word({
    required this.id,
    required this.position,
    this.audioUrl,
    required this.charTypeName,
    required this.textUthmani,
    this.translationText,
    this.transliterationText,
    required this.lineNumber,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      position: json['position'],
      audioUrl: json['audio_url'],
      charTypeName: json['char_type_name'],
      textUthmani: json['text_uthmani'] ?? json['text'] ?? '',
      translationText: json['translation']?['text'],
      transliterationText: json['transliteration']?['text'],
      lineNumber: json['line_number'] ?? 1,
    );
  }
}

class Chapter {
  final int id;
  final String nameSimple;
  final String nameArabic;
  final int versesCount;

  Chapter({
    required this.id,
    required this.nameSimple,
    required this.nameArabic,
    required this.versesCount,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'],
      nameSimple: json['name_simple'],
      nameArabic: json['name_arabic'],
      versesCount: json['verses_count'],
    );
  }
}

enum ApiSource { quranDotCom, mp3Quran }

class Reciter {
  final int id;
  final String reciterName;
  final String? style;
  final ApiSource apiSource;
  final String? serverUrl; // For MP3Quran
  final int? moshafId; // For MP3Quran timing API
  final bool hasTimingData; // Whether ayat_timing is available

  Reciter({
    required this.id,
    required this.reciterName,
    this.style,
    this.apiSource = ApiSource.quranDotCom,
    this.serverUrl,
    this.moshafId,
    this.hasTimingData = true,
  });

  /// Standard API format: { "id": 7, "reciter_name": "...", "style": "...", "translated_name": { "name": "..." } }
  /// When called with language=ar, translated_name.name contains the Arabic name.
  factory Reciter.fromJson(Map<String, dynamic> json) {
    // Prefer translated_name (localized) over reciter_name (always English)
    final translatedName = json['translated_name']?['name'] as String?;
    final fallbackName = json['reciter_name'] ?? '';
    return Reciter(
      id: json['id'],
      reciterName: (translatedName != null && translatedName.isNotEmpty)
          ? translatedName
          : fallbackName,
      style: json['style'],
      apiSource: ApiSource.quranDotCom,
    );
  }

  /// Public Arabic names map — keyed by reciter ID.
  /// Used by AudioProvider and main.dart to set the localized initial name.
  static const Map<int, String> arabicNamesById = {
    1: 'عبد الباسط عبد الصمد (مجوّد)',
    2: 'عبد الباسط عبد الصمد',
    3: 'عبد الرحمن السديس',
    4: 'أبو بكر الشاطري',
    5: 'هاني الرفاعي',
    6: 'محمود خليل الحصري',
    7: 'مشاري راشد العفاسي',
    9: 'محمد صديق المنشاوي',
    10: 'سعود الشريم',
    12: 'محمود خليل الحصري (حفص)',
    13: 'سعد الغامدي',
    19: 'أحمد بن علي العجمي',
    158: 'عبدالله علي جابر',
    159: 'ماهر المعيقلي',
    160: 'بندر بليلة',
    161: 'خليفة الطنيجي',
    168: 'محمد صديق المنشاوي (مع أطفال)',
    173: 'مشاري راشد العفاسي (بث مباشر)',
    174: 'ياسر الدوسري',
    175: 'عبدالله حمد أبو شريدة',
  };

  /// QDC API format: { "id": 7, "name": "...", "style": { "name": "..." } }
  /// Note: arabic_name is always empty in the API response; we use a local map instead.
  factory Reciter.fromQdcJson(
    Map<String, dynamic> json, {
    String language = 'en',
  }) {
    String? styleName;
    if (json['style'] is Map) {
      styleName = json['style']['name'] as String?;
    }
    final id = json['id'] as int;
    final fallbackName = json['name'] ?? json['reciter_name'] ?? '';

    String finalName;
    if (language == 'ar') {
      // API arabic_name field is always empty — use local map instead
      finalName = arabicNamesById[id] ?? fallbackName;
    } else {
      finalName = fallbackName;
    }

    return Reciter(
      id: id,
      reciterName: finalName,
      style: styleName,
      apiSource: ApiSource.quranDotCom,
    );
  }

  /// MP3Quran API format
  factory Reciter.fromMp3QuranJson(Map<String, dynamic> json) {
    String? server;
    String? styleName;
    int? moshafId;
    if (json['moshaf'] != null && (json['moshaf'] as List).isNotEmpty) {
      final moshaf = json['moshaf'][0];
      server = moshaf['server'];
      styleName = moshaf['name'];
      moshafId = moshaf['id'];
    }
    return Reciter(
      id: json['id'],
      reciterName: json['name'] ?? '',
      style: styleName,
      apiSource: ApiSource.mp3Quran,
      serverUrl: server,
      moshafId: moshafId,
    );
  }
}
