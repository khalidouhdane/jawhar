# 🏗️ Architecture & Technical Decisions

> **Tech stack, project structure, and key engineering decisions for Le Quran.**

---

## 1. Tech Stack

| Layer | Technology | Notes |
|-------|-----------|-------|
| Framework | Flutter | Dart 3.x |
| State Management | Provider + ChangeNotifier | 7 providers |
| Persistence | SharedPreferences | Via `LocalStorageService` |
| HTTP | `http` package | For quran.com API v4 |
| Audio Engine | `audioplayers` | Windows-compatible |
| Background Audio | `audio_service` | Lock screen / notification controls |
| Audio Session | `audio_session` | Focus, interruptions |
| Typography | `google_fonts` | Arabic + Latin |
| Icons | `lucide_icons` | UI icons |
| SVG | `path_drawing` | SVG path rendering |

### Dev Commands
```bash
flutter run -d windows    # Primary dev target
flutter run -d chrome     # Web testing
flutter build apk         # Android release
```

---

## 2. Project Structure

```
lib/
├── main.dart                          # App entry, MultiProvider setup
├── l10n/
│   └── app_localizations.dart         # i18n string lookup (English/Arabic)
├── models/
│   ├── quran_models.dart              # Verse, Word, Chapter, Reciter models
│   ├── hifz_models.dart               # Hifz memorization data models
│   └── werd_models.dart               # WerdConfig, WerdMode (fixedRange/dailyPages)
├── providers/
│   ├── audio_provider.dart            # Audio playback (full chapter audio + seek)
│   ├── hifz_provider.dart             # Memorization tracking and daily streaks
│   ├── locale_provider.dart           # UI localization (English/Arabic switching)
│   ├── navigation_provider.dart       # Controls bottom nav visibility during reading
│   ├── quran_reading_provider.dart    # Page loading, caching, chapter/reciter lists
│   ├── theme_provider.dart            # App aesthetics, alignments, overlay settings
│   └── werd_provider.dart             # Daily werd state, auto-daily-reset, progress
├── services/
│   ├── local_storage_service.dart     # SharedPreferences persistence layer
│   ├── mp3quran_service.dart          # mp3quran.net API for Warsh reciters
│   ├── quran_api_service.dart         # HTTP calls to quran.com API (v4)
│   ├── quran_audio_handler.dart       # audio_service handler for media controls
│   ├── quran_auth_service.dart        # OAuth2 token management for Quran API
│   └── warsh_text_service.dart        # CDN-based Warsh text fetching/caching
├── screens/
│   ├── app_shell.dart                 # Bottom nav bar scaffold (Home/Read/Audio/Hifz/Profile)
│   ├── audio_screen.dart              # Audio library / reciter browsing
│   ├── hifz_screen.dart               # Hifz memorization tracker screen
│   ├── home_screen.dart               # Home screen (greeting, hero card, werd card, ayah)
│   ├── onboarding_screen.dart         # First-launch rewaya selection + language
│   ├── profile_screen.dart            # User profile / settings screen
│   ├── read_index_screen.dart         # Surah/Juz index for quick navigation
│   └── reading_screen.dart            # Main reading screen (PageView + overlays + werd tracking)
└── widgets/
    ├── animated_svg_icon.dart         # Custom animated icon widget
    ├── audio_player_bridge.dart       # Audio playback UI (controls, progress bar)
    ├── bottom_dock.dart               # Bottom navigation dock overlay (reading)
    ├── bottom_nav_bar.dart            # App-wide bottom navigation bar
    ├── overlays.dart                  # Barrel file exporting all sheets
    ├── reading_canvas.dart            # Renders Arabic verse text per page
    ├── surah_list_tile.dart           # Reusable surah list item widget
    ├── top_nav_bar.dart               # Top navigation bar overlay (reading)
    ├── werd_card.dart                 # Home screen werd progress card
    └── sheets/                        # Segmented bottom sheet overlays
        ├── audio_settings_sheet.dart  # Audio controls (repeat mode, etc.)
        ├── nav_menu_sheet.dart        # Surah index and bookmarks
        ├── reciter_menu_sheet.dart    # Reciter selection and search
        ├── search_sheet.dart          # Quran text search overlay
        ├── theme_picker_sheet.dart    # Appearance settings (theme, font size)
        └── werd_setup_sheet.dart      # Werd goal configuration
```

---

## 3. State Management

| Provider | Responsibility |
|----------|---------------|
| `QuranReadingProvider` | Page data, chapter list, reciter list, page cache, rewaya selection (Hafs/Warsh) |
| `AudioProvider` | Audio playback state, verse timing, reciter switching, `audio_service` integration |
| `ThemeProvider` | App aesthetics, custom text alignments, overlay settings |
| `LocaleProvider` | UI localization (English/Arabic) |
| `NavigationProvider` | Bottom nav bar visibility when entering/exiting reading screen |
| `HifzProvider` | Memorization tracking and daily streaks |
| `WerdProvider` | Daily werd goal state, auto-daily-reset, progress, persistence |

### Data Flow
1. `QuranReadingProvider` fetches page data from quran.com API
2. `ReadingCanvas` renders verses for the current page
3. `AudioProvider` fetches chapter audio + timing data
4. Position tracking maps playback position → active verse → UI highlighting

### Werd Progress Tracking
1. `ReadingScreen` starts a 5-second timer when user lands on a page
2. After 5 seconds → `WerdProvider.incrementProgress(1)`
3. `Set<int>` tracks pages already counted to avoid double-counting
4. Milestone Snackbars at 50%, 80%, 100%, >100% of daily goal

---

## 4. Key Technical Decisions

### Audio: Full Chapter Audio with Verse Seeking
**DO NOT go back to per-verse audio files.** Single chapter mp3 + seek using `?segments=true` timestamp data. Eliminates gaps and "tick" sound between verses. See [api-reference.md](./api-reference.md).

### Warsh Text Rendering
CDN-based (`fawazahmed0/quran-api`), NOT bundled fonts. Flat JSON array of 6236 Warsh verses in Unicode. `WarshTextService` caches in memory. `ReadingCanvas` dynamically switches between Hafs/Warsh rendering.

### Background Audio & Media Controls
`audioplayers` engine wrapped with `audio_service` for lock screen and notification media controls. `QuranAudioHandler` syncs state between system media session and `AudioProvider`.

### Rewaya & Onboarding
One-time flow: auto-detect language → select Rewaya (Hafs/Warsh) → persist via `SharedPreferences`. Reciter menu auto-filters by saved rewaya.

---

## 5. Known Technical Constraints

| # | Issue | Severity |
|---|-------|----------|
| 1 | `just_audio` doesn't work on Windows (`ConcatenatingAudioSource` fails) | High |
| 2 | Windows Accessibility Bridge crashes with large `RichText` widgets — must wrap in `ExcludeSemantics()` | High |
| 3 | `just_audio` and `just_audio_web` are in pubspec but NOT actively used | Low |
| 4 | Large files (`reading_canvas.dart`, `reading_screen.dart`, `audio_player_bridge.dart`) may need splitting | Medium |

---

## 6. Reference

- **API Reference**: [api-reference.md](./api-reference.md)
- **Data Models**: [data-models.md](./data-models.md)
- **Roadmap**: [roadmap.md](./roadmap.md)
- **API Docs (external)**: https://api-docs.quran.com/docs/category/quran.com-api
