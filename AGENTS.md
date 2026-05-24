# AGENTS.md — Developer Agent Instructions & Standards

This document defines critical patterns and developer guidelines for all AI agents working on the Quran App repository. All agents must read and follow these rules without exception.

---

## 📖 Verse Reference Formatting Standards

To maintain a clean, premium, and fully localized user experience (UX), **never display raw database verse references (e.g. `12:87` or `'Verse 12:87'`) directly to the user.** 

Always format references using the centralized `VerseRefFormatter` utility.

### 1. Unified Formatting Utility
Use `VerseRefFormatter.format(...)` located in [verse_ref_formatter.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/utils/verse_ref_formatter.dart):
```dart
import 'package:quran_app/utils/verse_ref_formatter.dart';
```

### 2. Localization Context
Always dynamically resolve and pass the current locale name to the formatter (`localeName`). This allows correct numeral conversions (e.g. converting to Eastern Arabic numerals `٨٧` for `'ar'`) and localized Surah names.
- Resolve using: `AppLocalizations.of(context)!.localeName` (or localized strings helper `l.localeName`).

### 3. Formatting Tiers
Understand and apply the correct formatting tier depending on the UI context:

#### 🟢 Full Tier (`VerseRefFormat.full`)
* **Format**:
  * English: `Surah Yusuf, Verse 87`
  * Arabic: `سورة يوسف، الآية ٨٧`
* **Use Cases**: External copy/share clipboard data, explicit title headers, long descriptions.
* **Code Example**:
  ```dart
  VerseRefFormatter.format(
    verseKey,
    locale: locale,
    tier: VerseRefFormat.full,
  );
  ```

#### 🟡 Standard Tier (`VerseRefFormat.standard`)
* **Format**:
  * English: `Yusuf · Verse 87`
  * Arabic: `يوسف · الآية ٨٧`
* **Use Cases**: Occasion of revelation cards, list item subtitles, transient snackbar messages, inline headers.
* **Code Example**:
  ```dart
  VerseRefFormatter.format(
    verseKey,
    locale: locale,
    tier: VerseRefFormat.standard,
  );
  ```

#### 🔵 Compact Tier (`VerseRefFormat.compact`)
* **Format**:
  * English: `Yusuf · 87`
  * Arabic: `يوسف · ٨٧`
* **Use Cases**: Top-right verse badges in translation view, tiny overlay headers (translation/dictionary), audio active player control labels.
* **Code Example**:
  ```dart
  VerseRefFormatter.format(
    verseKey,
    locale: locale,
    tier: VerseRefFormat.compact,
  );
  ```

## 🔑 Environment Configuration & Compilation Flags

This project relies on environmental variables located in the `.env` file at the root level to configure core authentication, dynamic APIs, and database services.

### 1. Mandatory Build and Run Flags
Whenever compiling, building, or running the application (for any platform: Android, iOS, Windows, Web, etc.), you **MUST** explicitly append the `--dart-define-from-file=.env` flag so that these parameters are loaded correctly. 

Failure to do so will cause authentication, cloud syncing, and key app features to break.

* **Run Command:**
  ```bash
  flutter run --dart-define-from-file=.env
  ```
* **Build APK Command:**
  ```bash
  flutter build apk --dart-define-from-file=.env
  ```
* **Build Bundle Command:**
  ```bash
  flutter build appbundle --dart-define-from-file=.env
  ```
