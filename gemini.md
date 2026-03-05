# Gemini — Project Context & Instructions

> This file is for AI assistants working on this project. It contains essential context, architecture decisions, and instructions to maintain consistency across sessions.
>
> **NOTE:** Don't push and build until fixes are confirmed by the user.

---

## Project Overview

**Le Quran Prototype** — A Flutter desktop/mobile Quran reading app with:
- Page-by-page Mushaf reading (604 pages of the Madani layout)
- Arabic text rendering with proper line layout
- Audio recitation with verse-level synchronization
- Multiple reciter support
- Contextual overlays (verse tafsir, bookmarks, reciter selection)

**Target platforms**: Windows (primary dev), Android, iOS, Web, macOS, Linux

---

## Architecture

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
    ├── werd_card.dart                 # Home screen werd progress card (empty + active states)
    └── sheets/                        # Segmented bottom sheet overlays
        ├── audio_settings_sheet.dart  # Audio controls (repeat mode, etc.)
        ├── nav_menu_sheet.dart        # Surah index and bookmarks
        ├── reciter_menu_sheet.dart    # Reciter selection and search
        ├── search_sheet.dart          # Quran text search overlay
        ├── theme_picker_sheet.dart    # Appearance settings (theme, font size)
        └── werd_setup_sheet.dart      # Werd goal configuration (mode, pages, save/delete)
```

### State Management
- **Provider** package with `ChangeNotifier`
- `QuranReadingProvider` — page data, chapter list, reciter list, page cache, rewaya selection (Hafs/Warsh)
- `AudioProvider` — audio playback state, verse timing, reciter switching, integration with `audio_service`
- `ThemeProvider` — app aesthetics, custom text alignments, overlay settings
- `LocaleProvider` — UI localization (English/Arabic)
- `NavigationProvider` — controls bottom nav bar visibility when entering/exiting the reading screen
- `HifzProvider` — memorization tracking and daily streaks
- `WerdProvider` — daily werd goal state, auto-daily-reset based on date, progress increment, persistence via `LocalStorageService`
- `LocalStorageService` — persistent storage (SharedPreferences) for rewaya, werd goals, last read page

### Data Flow
1. `QuranReadingProvider` fetches page data from quran.com API
2. `ReadingCanvas` renders verses for the current page
3. `AudioProvider` fetches chapter audio + timing data (see `findings.md`)
4. Position tracking maps playback position → active verse → UI highlighting

### Werd Progress Tracking
1. `ReadingScreen` starts a 5-second timer when the user lands on a page
2. If the user stays on the page for 5 seconds, it calls `WerdProvider.incrementProgress(1)`
3. A `Set<int>` tracks pages already counted in the current session to avoid double-counting
4. Milestone Snackbars appear at 50%, 80%, 100%, and >100% of the daily goal

---

## Key Technical Decisions

### Audio: Full Chapter Audio with Verse Seeking
**DO NOT go back to per-verse audio files.** The current approach plays a single chapter mp3 and seeks using timestamp data from the `?segments=true` API parameter. This eliminates the "tick" sound and gaps between verses. See [findings.md](./findings.md) for full details.

### API: Quran Foundation API (v4)
All data comes from the new authenticated API: `https://apis.quran.foundation/content/api/v4`. 
The legacy `api.quran.com` endpoints are **deprecated** and currently returning 503 errors.

**Authentication Details:**
- **Auth URL:** `https://oauth2.quran.foundation/oauth2/token`
- **Method:** `POST` with `grant_type=client_credentials&scope=content`
- **Client ID:** `879421dc-68cb-4a1d-a500-c060d10478e6`
- **Client Secret:** `cKEt~daJ4tgXiJ1td0t4JwBB_z`
- **Headers Needed:** `x-auth-token: <token>` and `x-client-id: <clientId>`

Key endpoints and discoveries are documented in [findings.md](./findings.md).

### Default Reciter
Reciter ID `7` = Mishary Rashid al-Afasy (default). Users can switch reciters via the settings overlay.

### Warsh Text Rendering
To keep the app size small, we do NOT bundle custom fonts for Warsh. Instead, we use a CDN (`fawazahmed0/quran-api`) to fetch a flat JSON array of all 6236 Warsh verses rendered in basic Unicode. The `WarshTextService` caches this in memory. `ReadingCanvas` dynamically switches between Hafs verse rendering and Warsh verse rendering based on the user's persisted rewaya preference.

### Background Audio & Media Controls
We use `audioplayers` for the audio engine but wrap it with `audio_service` to provide lock screen and notification media controls. The `QuranAudioHandler` syncs state between the system media session and the app's internal `AudioProvider`.

### Rewaya & Onboarding
The app features a one-time onboarding flow that auto-detects the system language and prompts the user to select their preferred *Rewaya* (Hafs vs Warsh). This preference is persisted via `SharedPreferences`. The reciter selection menu automatically filters to show reciters matching the saved rewaya first.

---

## Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management |
| `http` | API requests |
| `audioplayers` | Audio playback (Windows-compatible) |
| `audio_service` | Background audio and lock screen controls |
| `audio_session` | Audio session management (focus, interruptions) |
| `shared_preferences` | Persistent user settings (theme, rewaya, werd) |
| `google_fonts` | Typography |
| `lucide_icons` | UI icons |
| `path_drawing` | SVG path rendering |
| `just_audio` | In pubspec but NOT actively used (Windows issues) |
| `just_audio_web` | In pubspec but NOT actively used |

---

## Important Reminders For Future AI Agents

1. **Auto-run terminal commands** — Always set `SafeToAutoRun: true` for all terminal commands in this project. The user has approved auto-execution.
2. **Test on Windows** — This is the primary dev platform. Audio behavior differs significantly across platforms.
3. **Windows Accessibility Bridge Crashes** — Be very careful with large `RichText` widgets (like `ReadingCanvas` which has 1000s of spans). You MUST wrap them in `ExcludeSemantics()` otherwise dynamically updating them (e.g., changing font size via a slider) will crash the Windows Accessibility bridge and close the app.
4. **`just_audio` doesn't work on Windows** — `ConcatenatingAudioSource` and `setSourceUrl` both fail. Stick with `audioplayers` + full chapter audio.
5. **Page numbers are 1-604** — Madani Mushaf layout. Never go outside this range.
6. **Verse keys format**: `"chapter:verse"` (e.g., `"2:255"` = Al-Baqarah, Ayat al-Kursi)
7. **Cache chapter audio data per reciter** — Key pattern: `"reciterId:chapterNumber"`
8. **File Size Management** — `overlays.dart` was previously split into the `sheets/` directory to improve maintainability. If other files like `reading_canvas.dart`, `reading_screen.dart`, or `audio_player_bridge.dart` grow too large, consider segmenting them similarly.
9. **Don't push or build until confirmed** — Do NOT push to GitHub or build APKs until the user has confirmed fixes look correct on their device.

---

## Completed Features

- [x] Warsh text integration via CDN & Unicode rendering
- [x] Persistent Rewaya selection with first-launch onboarding
- [x] Daily Werd with progress tracking (timer-based page counting, milestone snackbars)
- [x] Werd setup sheet (fixed page range or daily pages mode, slider, summary preview)
- [x] Advanced Theme Picker (vertical alignment, text alignment, page shadow toggles)
- [x] Fullscreen overlay with dynamic page info (Juz, Hizb, Surah, Page, Book indicator)
- [x] Lock screen / Media Notification controls via `audio_service`
- [x] App Localization (English/Arabic) with auto-detection
- [x] Search (Surahs)
- [x] Bookmarks and reading progress persistence
- [x] Dark mode (alongside Classic and Warm themes)
- [x] Home screen with greeting, resume journey hero card, quick access, Ayah of the Day
- [x] Bottom navigation with 5 tabs (Home, Read, Audio, Hifz, Profile)
- [x] App shell with NavigationProvider for hiding nav during reading

## Planned / Upcoming Features

- [ ] Verse-by-verse highlighting synced with audio
- [ ] Offline audio caching
- [ ] Translation overlay

---

## Reference

- **API Docs**: https://api-docs.quran.com/docs/category/quran.com-api
- **Technical Discoveries**: [findings.md](./findings.md)
