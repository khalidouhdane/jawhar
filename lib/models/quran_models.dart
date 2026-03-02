class Verse {
  final int id;
  final int verseNumber;
  final String verseKey;
  final int pageNumber;
  final int juzNumber;
  final List<Word> words;
  final String? audioUrl;

  Verse({
    required this.id,
    required this.verseNumber,
    required this.verseKey,
    required this.pageNumber,
    required this.juzNumber,
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

class Reciter {
  final int id;
  final String reciterName;
  final String? style;

  Reciter({required this.id, required this.reciterName, this.style});

  /// Standard API format: { "id": 7, "reciter_name": "...", "style": "..." }
  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['id'],
      reciterName: json['reciter_name'],
      style: json['style'],
    );
  }

  /// QDC API format: { "id": 7, "name": "...", "style": { "name": "..." } }
  factory Reciter.fromQdcJson(Map<String, dynamic> json) {
    String? styleName;
    if (json['style'] is Map) {
      styleName = json['style']['name'] as String?;
    }
    return Reciter(
      id: json['id'],
      reciterName: json['name'] ?? json['translated_name']?['name'] ?? '',
      style: styleName,
    );
  }
}
