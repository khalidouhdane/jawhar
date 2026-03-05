# Gemini — Project Context & Instructions

> This file is for AI assistants working on this project. It contains essential context, architecture decisions, and instructions to maintain consistency across sessions.

---

## Project Overview

**Le Quran Prototype** — A Flutter desktop/mobile Quran reading app with:
- Page-by-page Mushaf reading (604 pages of the Madani layout)
- Word-by-word Arabic text rendering with proper line layout
- Audio recitation with verse-level synchronization
- Multiple reciter support
- Contextual overlays (verse tafsir, bookmarks, reciter selection)

**Target platforms**: Windows (primary dev), Android, iOS, Web, macOS, Linux

---

## Architecture

```
lib/
├── main.dart                         # App entry, MultiProvider setup
├── models/
│   └── quran_models.dart             # Verse, Word, Chapter, Reciter models
├── providers/
│   ├── audio_provider.dart           # Audio playback (full chapter audio + seek)
│   └── quran_reading_provider.dart   # Page loading, caching, chapter/reciter lists
├── services/
│   └── quran_api_service.dart        # HTTP calls to quran.com API
├── screens/
│   └── reading_screen.dart           # Main reading screen (PageView + overlays)
└── widgets/
    ├── reading_canvas.dart           # Renders Arabic text word-by-word per page
    ├── audio_player_bridge.dart      # Audio playback UI (controls, progress bar)
    ├── top_nav_bar.dart              # Top navigation bar overlay
    ├── bottom_dock.dart              # Bottom navigation dock overlay
    ├── overlays.dart                 # Barrel file exporting all sheets
    ├── sheets/                       # Segmented bottom sheet overlays
    │   ├── reciter_menu_sheet.dart   # Reciter selection and search
    │   ├── audio_settings_sheet.dart # Audio controls (repeat mode, etc.)
    │   ├── nav_menu_sheet.dart       # Surah index and bookmarks
    │   ├── theme_picker_sheet.dart   # Appearance settings (theme, font size)
    │   └── search_sheet.dart         # Quran text search overlay
    └── animated_svg_icon.dart        # Custom animated icon widget
```

### State Management
- **Provider** package with `ChangeNotifier`
- `QuranReadingProvider` — page data, chapter list, reciter list, page cache, rewaya selection (Hafs/Warsh)
- `AudioProvider` — audio playback state, verse timing, reciter switching, integration with `audio_service`
- `ThemeProvider` — app aesthetics, custom text alignments, overlay settings
- `LocaleProvider` — UI localization (English/Arabic)
- `HifzProvider` — memorization tracking and daily streaks
- `LocalStorageService` — persistent storage (SharedPreferences) for rewaya, werd goals, last read page

### Data Flow
1. `QuranReadingProvider` fetches page data from quran.com API
2. `ReadingCanvas` renders words for the current page
3. `AudioProvider` fetches chapter audio + timing data (see `findings.md`)
4. Position tracking maps playback position → active verse → UI highlighting

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
To keep the app size small, we do NOT bundle custom fonts for Warsh. Instead, we use a CDN (`fawazahmed0/quran-api`) to fetch a flat JSON array of all 6236 Warsh verses rendered in basic Unicode. The `WarshTextService` caches this in memory. `ReadingCanvas` dynamically switches between Hafs word-by-word rendering and Warsh full-verse rendering based on the user's persisted rewaya preference.

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

---

## Completed Features

- [x] Warsh text integration via CDN & Unicode rendering
- [x] Persistent Rewaya selection with first-launch onboarding
- [x] Daily Werd (custom reading goals tracking)
- [x] Advanced Theme Picker (vertical alignment, justify options, page shadow toggles)
- [x] Lock screen / Media Notification controls via `audio_service`
- [x] App Localization (English/Arabic)
- [x] Search (Surahs)
- [x] Bookmarks and reading progress persistence
- [x] Dark mode (Implemented alongside Classic and Warm themes)

## Planned / Upcoming Features

- [ ] Word-by-word highlighting synced with audio (using word-level `segments` data)
- [ ] Offline audio caching
- [ ] Translation overlay

---

## Reference

- **API Docs**: https://api-docs.quran.com/docs/category/quran.com-api
- **Technical Discoveries**: [findings.md](./findings.md)
