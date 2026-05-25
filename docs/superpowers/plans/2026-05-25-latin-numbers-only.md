# Latin Numbers Only Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enforce Latin numerals (0-9) universally across all UI elements, including in the Arabic locale and Quranic verse end symbols.

**Architecture:** 
Disable locale-based Eastern Arabic numeral conversion in the central `VerseRefFormatter.localizeNumbers` utility, and add a post-processing helper `delocalizeNumbers` to filter third-party `quran` package's verse end symbols back to Latin digits.

**Tech Stack:** Flutter / Dart / standard `flutter_test` library.

---

### Task 1: Add Unit Tests for `VerseRefFormatter`

**Files:**
- Create: [verse_ref_formatter_test.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/test/verse_ref_formatter_test.dart)

- [ ] **Step 1: Create the failing unit test file**

Write the following code to `test/verse_ref_formatter_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/utils/verse_ref_formatter.dart';

void main() {
  group('VerseRefFormatter Latin Numbers Tests', () {
    test('localizeNumbers returns Latin digits even for Arabic locale', () {
      expect(VerseRefFormatter.localizeNumbers('123', 'ar'), '123');
      expect(VerseRefFormatter.localizeNumbers('123', 'en'), '123');
    });

    test('delocalizeNumbers converts Eastern Arabic digits to Latin digits', () {
      expect(VerseRefFormatter.delocalizeNumbers('۝١٦'), '۝16');
      expect(VerseRefFormatter.delocalizeNumbers('٠١٢٣٤٥٦٧٨٩'), '0123456789');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/verse_ref_formatter_test.dart`
Expected: FAIL due to compilation error (missing `delocalizeNumbers`) or failure to return Latin numbers for `'ar'`.

---

### Task 2: Implement changes in `VerseRefFormatter`

**Files:**
- Modify: [verse_ref_formatter.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/utils/verse_ref_formatter.dart)

- [ ] **Step 1: Write minimal implementation to make tests pass**

Modify `lib/utils/verse_ref_formatter.dart` to implement `delocalizeNumbers` and bypass translation in `localizeNumbers`:
```dart
  /// Converts standard digits to Eastern Arabic numerals if the locale is Arabic.
  /// (Deprecated/Disabled: Enforces Latin numbers globally as requested).
  static String localizeNumbers(String input, String locale) {
    return input;
  }

  /// Converts Eastern Arabic numerals back to Latin digits.
  static String delocalizeNumbers(String input) {
    final digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(digits[i], i.toString());
    }
    return result;
  }
```

- [ ] **Step 2: Run test to verify it passes**

Run: `flutter test test/verse_ref_formatter_test.dart`
Expected: PASS

- [ ] **Step 3: Stage and commit the formatter changes**

Run:
```bash
git add lib/utils/verse_ref_formatter.dart test/verse_ref_formatter_test.dart
git commit -m "feat(format): disable Arabic digit localization and add delocalizeNumbers"
```

---

### Task 3: Wrap `quran.getVerseEndSymbol` calls in screens/widgets

**Files:**
- Modify: [surah_detail_sheet.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/widgets/understand/surah_detail_sheet.dart)
- Modify: [asbab_detail_screen.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/screens/asbab_detail_screen.dart)
- Modify: [asbab_list_screen.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/screens/asbab_list_screen.dart)

- [ ] **Step 1: Update `surah_detail_sheet.dart`**

Modify line 208 of `lib/widgets/understand/surah_detail_sheet.dart`:
```dart
// Change:
final versesArabic = entry.ayahs
    .map((a) => '${quran.getVerse(surah.id, a)} ﴿${quran.getVerseEndSymbol(a)}﴾')
    .join(' ');

// To:
final versesArabic = entry.ayahs
    .map((a) => '${quran.getVerse(surah.id, a)} ﴿${VerseRefFormatter.delocalizeNumbers(quran.getVerseEndSymbol(a))}﴾')
    .join(' ');
```

- [ ] **Step 2: Update `asbab_detail_screen.dart`**

Modify line 44 of `lib/screens/asbab_detail_screen.dart`:
```dart
// Change:
final versesArabic = entry.ayahs
    .map((a) => '${quran.getVerse(surah.id, a)} ﴿${quran.getVerseEndSymbol(a)}﴾')
    .join(' ');

// To:
final versesArabic = entry.ayahs
    .map((a) => '${quran.getVerse(surah.id, a)} ﴿${VerseRefFormatter.delocalizeNumbers(quran.getVerseEndSymbol(a))}﴾')
    .join(' ');
```

- [ ] **Step 3: Update `asbab_list_screen.dart`**

Modify line 75 of `lib/screens/asbab_list_screen.dart`:
```dart
// Change:
final versesArabic = entry.ayahs
    .map((a) => '${quran.getVerse(surah.id, a)} ﴿${quran.getVerseEndSymbol(a)}﴾')
    .join(' ');

// To:
final versesArabic = entry.ayahs
    .map((a) => '${quran.getVerse(surah.id, a)} ﴿${VerseRefFormatter.delocalizeNumbers(quran.getVerseEndSymbol(a))}﴾')
    .join(' ');
```

- [ ] **Step 4: Run analyzer to check for compilation issues**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 5: Run unit tests**

Run: `flutter test`
Expected: All tests PASS

- [ ] **Step 6: Stage and commit the screen changes**

Run:
```bash
git add lib/widgets/understand/surah_detail_sheet.dart lib/screens/asbab_detail_screen.dart lib/screens/asbab_list_screen.dart
git commit -m "feat(ui): delocalize verse end symbols to Latin digits"
```
