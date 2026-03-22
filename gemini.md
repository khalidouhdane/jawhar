# Gemini — Project Context & Instructions

> This file is for AI assistants working on this project. It contains essential context, architecture decisions, and instructions to maintain consistency across sessions.
>
> **NOTE:** Don't push and build until fixes are confirmed by the user.

---

## ⚠️ MANDATORY: Hifz Roadmap & Research Files

**Before starting ANY work on this project, you MUST read** these files:

1. **[hifz-roadmap.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/hifz-roadmap.md)** — The master roadmap. All development follows this phase-by-phase plan.
2. **[user-flows.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/user-flows.md)** — 12 user flows that define exactly how features work.
3. **[session-design.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/methods-and-planning/session-design.md)** — Session UX spec.
4. **[plan-generation.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/methods-and-planning/plan-generation.md)** — How daily plans are generated.

**Rules:**
- Follow the roadmap **to the letter**. Do not skip phases or add features from later phases.
- When implementing a phase, cross-reference the referenced docs (`📄 Reference:` links in the roadmap).
- Every new feature must be validated against user flows to ensure all scenarios are covered.
- If you encounter ambiguity, check the research files in `docs/features/hifz/research/`.

---

## Project Overview

**Le Quran** — A Flutter Quran memorization (Hifz) companion app with:
- **Hifz Dashboard** — Daily plan (sabaq/sabqi/manzil), progress tracking, session management
- Page-by-page Mushaf reading (604 pages of the Madani layout)
- Audio recitation with verse-level synchronization
- Practice tools — Flashcards (SRS-powered), Mutashabihat practice
- Multiple reciter support, Arabic text rendering

**Target platforms**: Windows (primary dev), Android, iOS, Web, macOS, Linux

---

## Architecture

```
lib/
├── main.dart                          # App entry, MultiProvider setup, SQLite init
├── l10n/
│   └── app_localizations.dart         # i18n string lookup (English/Arabic)
├── models/
│   ├── quran_models.dart              # Verse, Word, Chapter, Reciter models
│   ├── hifz_models.dart               # MemoryProfile, DailyPlan, PageProgress, SessionRecord
│   ├── flashcard_models.dart          # Flashcard, FlashcardReview, MutashabihatGroup
│   └── werd_models.dart               # WerdConfig, WerdMode
├── providers/
│   ├── audio_provider.dart            # Audio playback (full chapter audio + seek)
│   ├── hifz_profile_provider.dart     # Active profile, CRUD, streak tracking (SQLite)
│   ├── hifz_provider.dart             # [STUBBED] Legacy — replaced by hifz_profile_provider
│   ├── plan_provider.dart             # Today's DailyPlan state, generation, completion
│   ├── session_provider.dart          # Active session: timer, reps, phase progression
│   ├── flashcard_provider.dart        # Flashcard review session state, SRS integration
│   ├── locale_provider.dart           # UI localization (English/Arabic switching)
│   ├── navigation_provider.dart       # Controls bottom nav visibility during reading
│   ├── quran_reading_provider.dart    # Page loading, caching, chapter/reciter lists
│   ├── theme_provider.dart            # App aesthetics, alignments, overlay settings
│   ├── update_provider.dart           # In-app self-update state
│   └── werd_provider.dart             # Daily werd state, progress
├── services/
│   ├── hifz_database_service.dart     # SQLite (9 tables) — profiles, plans, sessions, flashcards, mutashabihat
│   ├── plan_generation_service.dart   # Profile → daily plan pipeline (sabaq/sabqi/manzil)
│   ├── card_generation_service.dart   # Generates flashcards from memorized content
│   ├── srs_engine.dart                # SM-2 spaced repetition algorithm
│   ├── mutashabihat_import_service.dart # GitHub dataset → SQLite import
│   ├── local_storage_service.dart     # SharedPreferences persistence layer
│   ├── mp3quran_service.dart          # mp3quran.net API for Warsh reciters
│   ├── quran_api_service.dart         # HTTP calls to quran.com API (v4)
│   ├── quran_audio_handler.dart       # audio_service handler for media controls
│   ├── quran_auth_service.dart        # OAuth2 token management for Quran API
│   ├── update_service.dart            # GitHub Releases API check + APK download/install
│   └── warsh_text_service.dart        # CDN-based Warsh text fetching/caching
├── screens/
│   ├── app_shell.dart                 # Bottom nav scaffold (Dashboard/Practice/Read/Listen/Profile)
│   ├── home_screen.dart               # Hifz Dashboard (plan card, progress, CTA)
│   ├── practice_screen.dart           # Practice tab (flashcard stats, mutashabihat link)
│   ├── audio_screen.dart              # Audio library / reciter browsing (Listen tab)
│   ├── read_index_screen.dart         # Surah/Juz index for quick navigation (Read tab)
│   ├── reading_screen.dart            # Main reading screen (PageView + overlays + werd)
│   ├── profile_screen.dart            # User profile / settings screen
│   ├── onboarding_screen.dart         # First-launch rewaya selection + language
│   ├── hifz_screen.dart               # [STUBBED] Legacy — replaced by home_screen
│   └── hifz/                          # Hifz-specific screens
│       ├── assessment_screen.dart     # 9-screen wizard for profile creation
│       ├── session_screen.dart        # Active session (timer, reps, self-assessment)
│       ├── flashcard_review_screen.dart # Card-by-card review with SRS rating
│       └── mutashabihat_screen.dart   # Browsable mutashabihat collection
└── widgets/
    ├── hifz/                          # Hifz-specific widgets
    │   ├── plan_card.dart             # Dashboard: today's plan with Start Session CTA
    │   ├── progress_card.dart         # Dashboard: progress bar + stats
    │   ├── hifz_cta_card.dart         # Dashboard: CTA for users without a profile
    │   └── missed_day_dialog.dart     # Re-engagement dialog after missed days
    ├── bottom_nav_bar.dart            # App-wide bottom navigation bar (5 tabs)
    ├── reading_canvas.dart            # Renders Arabic verse text per page
    ├── werd_card.dart                 # Home screen werd progress card
    └── sheets/                        # Bottom sheet overlays
        ├── werd_setup_sheet.dart      # Werd goal configuration
        ├── theme_picker_sheet.dart    # Appearance settings
        └── ...                        # Other sheets (audio, nav, reciter, search)
```

### State Management
- **Provider** package with `ChangeNotifier`
- `HifzProfileProvider` — active profile, CRUD, streak (SQLite-backed, replaces old `HifzProvider`)
- `PlanProvider` — today's DailyPlan, generation, completion, force-regeneration
- `SessionProvider` — active session: timer, rep counter, phase progression, self-assessment, page progress
- `FlashcardProvider` — flashcard review sessions, SRS integration, dashboard stats
- `QuranReadingProvider` — page data, chapter list, reciter list, page cache, rewaya selection (Hafs/Warsh)
- `AudioProvider` — audio playback state, verse timing, reciter switching, integration with `audio_service`
- `ThemeProvider` — app aesthetics, custom text alignments, overlay settings
- `LocaleProvider` — UI localization (English/Arabic)
- `NavigationProvider` — controls bottom nav bar visibility when entering/exiting the reading screen
- `WerdProvider` — daily werd goal state, auto-daily-reset based on date, progress increment
- `UpdateProvider` — in-app self-update state
- `LocalStorageService` — persistent storage (SharedPreferences) for rewaya, werd goals, last read page

### Hifz Data Flow
1. `HifzProfileProvider._init()` loads the active profile from SQLite
2. `HomeScreen.initState()` triggers `PlanProvider.loadOrGeneratePlan()` which creates today's DailyPlan
3. User starts a session → `SessionProvider.startSession(plan)` manages phase progression
4. Session completion → `SessionProvider.completeSession()` saves PageProgress + SessionRecord, then `PlanProvider.regeneratePlan()` creates a new plan with the next sabaq page
5. First-time users: sabqi/manzil phases are auto-skipped (no content to review)

### Quran Reading Data Flow
1. `QuranReadingProvider` fetches page data from quran.com API
2. `ReadingCanvas` renders verses for the current page
3. `AudioProvider` fetches chapter audio + timing data
4. Position tracking maps playback position → active verse → UI highlighting

### Werd Progress Tracking
1. `ReadingScreen` starts a 5-second timer when the user lands on a page
2. If the user stays on the page for 5 seconds, it calls `WerdProvider.incrementProgress(1)`
3. A `Set<int>` tracks pages already counted in the current session to avoid double-counting
4. Milestone Snackbars appear at 50%, 80%, 100%, and >100% of the daily goal

---

## Key Technical Decisions

### Audio: Full Chapter Audio with Verse Seeking
**DO NOT go back to per-verse audio files.** The current approach plays a single chapter mp3 and seeks using timestamp data from the `?segments=true` API parameter. This eliminates the "tick" sound and gaps between verses. See [docs/api-reference.md](./docs/api-reference.md) for full details.

### API: Quran Foundation API (v4)
All data comes from the new authenticated API: `https://apis.quran.foundation/content/api/v4`. 
The legacy `api.quran.com` endpoints are **deprecated** and currently returning 503 errors.

**Authentication Details:**
- **Auth URL:** `https://oauth2.quran.foundation/oauth2/token`
- **Method:** `POST` with `grant_type=client_credentials&scope=content`
- **Client ID:** `879421dc-68cb-4a1d-a500-c060d10478e6`
- **Client Secret:** `cKEt~daJ4tgXiJ1td0t4JwBB_z`
- **Headers Needed:** `x-auth-token: <token>` and `x-client-id: <clientId>`

Key endpoints and discoveries are documented in [docs/api-reference.md](./docs/api-reference.md).

### Default Reciter
Reciter ID `7` = Mishary Rashid al-Afasy (default). Users can switch reciters via the settings overlay.

### Warsh Text Rendering
To keep the app size small, we do NOT bundle custom fonts for Warsh. Instead, we use a CDN (`fawazahmed0/quran-api`) to fetch a flat JSON array of all 6236 Warsh verses rendered in basic Unicode. The `WarshTextService` caches this in memory. `ReadingCanvas` dynamically switches between Hafs verse rendering and Warsh verse rendering based on the user's persisted rewaya preference.

### Background Audio & Media Controls
We use `audioplayers` for the audio engine but wrap it with `audio_service` to provide lock screen and notification media controls. The `QuranAudioHandler` syncs state between the system media session and the app's internal `AudioProvider`.

### Rewaya & Onboarding
The app features a one-time onboarding flow that auto-detects the system language and prompts the user to select their preferred *Rewaya* (Hafs vs Warsh). This preference is persisted via `SharedPreferences`. The reciter selection menu automatically filters to show reciters matching the saved rewaya first.

### In-App Self-Update (GitHub Releases)
The app uses **GitHub Releases** as a free update server for sideloaded APK distribution. On Android, `AppShell.initState` triggers `UpdateProvider.checkForUpdate()` which calls `https://api.github.com/repos/khalidouhdane/le-quran/releases/latest` (public, no auth). It compares the release `tag_name` (e.g., `v1.1.0`) against the running app version via `package_info_plus`. If newer, a premium `UpdateDialog` shows release notes + download progress. The APK downloads via `dio` and installs via `open_filex`. Android permissions required: `REQUEST_INSTALL_PACKAGES` + a `FileProvider` in the manifest.

**Workflow to push an update:**
1. Bump `version` in `pubspec.yaml` (e.g., `1.1.0+2`)
2. Build APK: `flutter build apk --release`
3. Create a GitHub Release tagged `v1.1.0` and attach the APK file
4. All users see the update dialog on next app open

---

## Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management |
| `http` | API requests |
| `sqflite` | SQLite database (Hifz data) |
| `sqflite_common_ffi` | SQLite on desktop (Windows/macOS/Linux) |
| `path` | File path utilities |
| `audioplayers` | Audio playback (Windows-compatible) |
| `audio_service` | Background audio and lock screen controls |
| `audio_session` | Audio session management (focus, interruptions) |
| `shared_preferences` | Persistent user settings (theme, rewaya, werd) |
| `google_fonts` | Typography |
| `lucide_icons` | UI icons |
| `path_drawing` | SVG path rendering |
| `dio` | HTTP client with download progress (used by self-update) |
| `package_info_plus` | Read current app version at runtime |
| `open_filex` | Trigger Android system APK installer |

---

## Important Reminders For Future AI Agents

1. **Auto-run terminal commands** — Always set `SafeToAutoRun: true` for all terminal commands in this project. The user has approved auto-execution.
2. **Read the Hifz roadmap FIRST** — Before any implementation work, read `docs/features/hifz/hifz-roadmap.md` and all referenced docs. Follow it TO THE LETTER.
3. **Test on Windows** — This is the primary dev platform. Audio behavior differs significantly across platforms.
4. **Windows Accessibility Bridge Crashes** — Be very careful with large `RichText` widgets. Wrap them in `ExcludeSemantics()` otherwise dynamically updating them will crash the Windows Accessibility bridge.
5. **`just_audio` doesn't work on Windows** — Stick with `audioplayers` + full chapter audio.
6. **Page numbers are 1-604** — Madani Mushaf layout. Never go outside this range.
7. **Verse keys format**: `"chapter:verse"` (e.g., `"2:255"` = Al-Baqarah, Ayat al-Kursi)
8. **Hifz data is in SQLite** — Do NOT use SharedPreferences for Hifz data. Use `HifzDatabaseService`.
9. **Session completion must regenerate plan** — After `completeSession()`, always call `PlanProvider.regeneratePlan()` so the next sabaq page is assigned.
10. **First-time users get sabaq-only** — When a user has no prior progress, sabqi and manzil phases must be auto-skipped.
11. **Don't push or build until confirmed** — Do NOT push to GitHub or build APKs until the user has confirmed fixes.

---

## Completed Features

- [x] **Hifz Phase 1** — Profile assessment, dashboard, plan generation, sessions, progress, missed-day handling
- [x] **Hifz Phase 2** — Flashcard SRS system, mutashabihat dataset import, practice tab
- [x] Bottom navigation: Dashboard / Practice / Read / Listen / Profile
- [x] Warsh text integration via CDN & Unicode rendering
- [x] Persistent Rewaya selection with first-launch onboarding
- [x] Daily Werd with progress tracking
- [x] App Localization (English/Arabic) with auto-detection
- [x] Search (Surahs), Bookmarks, Dark mode
- [x] Lock screen / Media Notification controls via `audio_service`
- [x] In-app self-update via GitHub Releases (Android)

## Current Phase

**Phase 2 complete.** Next: Phase 3 — Context-Aware Content (translations, tafsir, asbab al-nuzul).
See [hifz-roadmap.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/hifz-roadmap.md) for full details.

---

## Reference

- **Hifz World Map (START HERE)**: [hifz-world-map.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/hifz-world-map.md)
- **Hifz Phase Roadmap**: [hifz-roadmap.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/hifz-roadmap.md)
- **Core Engine Mini Roadmap**: [core-engine-roadmap.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/roadmaps/core-engine-roadmap.md)
- **User Flows**: [user-flows.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/user-flows.md)
- **API Docs**: https://api-docs.quran.com/docs/category/quran.com-api
- **API Reference**: [api-reference.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/api-reference.md)
- **Technical Discoveries**: [findings.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/research/findings.md)
