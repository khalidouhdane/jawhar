# Design Spec: Latin Numbers Only in Arabic Locale

## Goal
Enforce Latin numerals (`0-9`) universally across the application (specifically for Arabic locale displays). Eastern Arabic numerals (`٠-٩`) will be completely removed/unsupported in all UI layers.

## Proposed Changes

### 1. Central Formatting Utility
Modify `VerseRefFormatter` in `lib/utils/verse_ref_formatter.dart`:
- Disable digit localization in `localizeNumbers` so it returns the input string directly.
- Implement `delocalizeNumbers` to replace Eastern Arabic digits with standard Latin digits.

### 2. Verse End Symbols
Update screens that display the Quranic verse end ornament via the `quran` package. Wrap `quran.getVerseEndSymbol` calls with `VerseRefFormatter.delocalizeNumbers`:
- `lib/widgets/understand/surah_detail_sheet.dart`
- `lib/screens/asbab_detail_screen.dart`
- `lib/screens/asbab_list_screen.dart`

## Verification
- Run `flutter analyze` to ensure code compiles.
- Run tests (if applicable) or verify visually that verse numbers/page numbers show in standard Latin numerals in Arabic translation/detail pages.
