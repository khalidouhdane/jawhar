# 📊 Data Models

> **All Dart model schemas used in Le Quran.**
> Source files: `lib/models/quran_models.dart`, `hifz_models.dart`, `werd_models.dart`

---

## Core Entities

### Verse

Represents a single verse (ayah) from a Quran page.

```dart
class Verse {
  final int id;
  final int verseNumber;
  final String verseKey;      // Format: "chapter:verse" (e.g., "2:255")
  final int pageNumber;       // 1–604 (Madani Mushaf)
  final int juzNumber;
  final int hizbNumber;
  final List<Word> words;
  final String? audioUrl;
}
```

**Source**: quran.com API `GET /verses/by_page/{page}?words=true`

---

### Word

Represents a single word within a verse.

```dart
class Word {
  final int id;
  final int position;
  final String? audioUrl;
  final String charTypeName;        // "word" (Arabic text) or "end" (verse number marker)
  final String textUthmani;         // Uthmani script text
  final String? translationText;
  final String? transliterationText;
  final int lineNumber;             // Line position on the mushaf page
}
```

**Key**: `charTypeName` distinguishes between Arabic text (`"word"`) and verse number markers (`"end"`).

---

### Chapter

Represents a surah (chapter) of the Quran.

```dart
class Chapter {
  final int id;               // 1–114
  final String nameSimple;    // English transliteration (e.g., "Al-Fatihah")
  final String nameArabic;    // Arabic name (e.g., "الفاتحة")
  final int versesCount;
}
```

---

### Reciter

Represents a Quran reciter. Supports two API sources.

```dart
enum ApiSource { quranDotCom, mp3Quran }

class Reciter {
  final int id;
  final String reciterName;
  final String? style;
  final ApiSource apiSource;
  final String? serverUrl;       // MP3Quran only
  final int? moshafId;           // MP3Quran timing API
  final bool hasTimingData;      // Whether ayat_timing is available
}
```

**Factory constructors**:
- `Reciter.fromJson()` — Standard quran.com API format
- `Reciter.fromQdcJson()` — QDC (Quran.com v4) API format with Arabic name fallback
- `Reciter.fromMp3QuranJson()` — MP3Quran API format

**Default reciter**: ID `7` = Mishary Rashid al-Afasy

---

## Memorization (Hifz)

### HifzStatus (enum)

```dart
enum HifzStatus {
  none,        // Not started
  learning,    // Sabaq — currently learning
  reviewing,   // Sabqi — recently memorized, needs frequent review
  memorized,   // Manzil — solidly memorized, periodic maintenance
}
```

### MemorizationRecord

```dart
class MemorizationRecord {
  final int surahId;
  final HifzStatus status;
  final DateTime? lastReviewed;
  final int reviewCount;
}
```

**Storage**: Serialized as pipe-delimited string `"status|timestamp|count"` via `SharedPreferences`.

### StreakData

```dart
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDay;
}
```

---

## Daily Werd

### WerdMode (enum)

```dart
enum WerdMode {
  fixedRange,   // Read a fixed range of pages (e.g., pages 50–60)
  dailyPages,   // Read N pages per day, advancing through the Quran
}
```

### WerdConfig

```dart
class WerdConfig {
  final WerdMode mode;
  final int startPage;        // 1–604
  final int endPage;          // 1–604
  final int pagesPerDay;
  final int pagesReadToday;
  final DateTime lastResetDate;
  final bool isEnabled;
}
```

**Computed properties**:
| Property | Description |
|----------|-------------|
| `totalPages` | `(endPage - startPage + 1).clamp(1, 604)` |
| `todayTarget` | `totalPages` for fixedRange, `pagesPerDay` for dailyPages |
| `progress` | `pagesReadToday / todayTarget` (clamped 0.0–1.0) |
| `isComplete` | `pagesReadToday >= todayTarget` |

**Storage**: JSON-encoded string via `SharedPreferences`. Auto-resets daily based on `lastResetDate`.

---

## Storage Keys

| Key | Data |
|-----|------|
| `werd_config` | JSON-encoded `WerdConfig` |
| `rewaya` | `"hafs"` or `"warsh"` |
| `last_read_page` | Page number (int) |
| `bookmarks` | JSON-encoded bookmark list |
| `hifz_*` | Per-surah memorization records |
