---
name: le-quran-flutter
description: Flutter/Dart conventions, Arabic text rendering, Quran data models, and audio playback patterns for the Le Quran app.
---

# Le Quran Flutter Skill

## Project Context
Le Quran is a Flutter app for Quran reading, listening, and memorization. Stack: Flutter 3.x, Dart 3.x, Riverpod state management.

## Architecture Rules
- **State Management**: Riverpod only — no setState, no BLoC
- **Navigation**: GoRouter with typed routes
- **Theming**: Material 3 with custom Quran-themed design tokens
- **Platform targets**: Android, iOS, Web

## Arabic Text Rendering
- Always use `Directionality.rtl` for Quran text widgets
- Use `Amiri Quran` or `KFGQPC Uthmanic Script HAFS` fonts
- Set `textDirection: TextDirection.rtl` explicitly on every Arabic text widget
- Surah names and ayah numbers: use Eastern Arabic numerals (٠١٢٣٤٥٦٧٨٩)
- Never truncate or ellipsize ayah text

## Data Models
```dart
// Surah model
class Surah {
  final int number;       // 1-114
  final String nameAr;    // Arabic name
  final String nameEn;    // English transliteration
  final int ayahCount;
  final RevelationType type; // makki / madani
}

// Ayah model  
class Ayah {
  final int surahNumber;
  final int ayahNumber;
  final String textUthmani;   // Uthmanic script
  final String textSimple;    // Simple Arabic
  final String? translation;
  final String? audioUrl;
}
```

## Audio Patterns
- Use `just_audio` package for Quran recitation playback
- Support gapless playback between ayahs
- Cache audio files locally for offline use
- Provide reciter selection (Mishary, Husary, Sudais, etc.)

## Testing
- Widget tests for all screens
- Golden tests for Arabic text rendering
- Integration tests for audio playback flow
- Use `flutter_test` and `mocktail` for mocking

## File Structure
```
lib/
  core/           # Theme, routing, constants
  data/           # Repositories, data sources, models
  features/
    quran/        # Reading, browsing surahs
    audio/        # Playback, reciter selection
    bookmarks/    # Saved positions
    search/       # Quran text search
  shared/         # Common widgets, Arabic text components
```
