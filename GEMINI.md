# Gemini — Project Context & Instructions

@AGENTS.md

> This file contains Antigravity-specific overrides. Universal project rules are in AGENTS.md.
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
- **Digital Session Mode** — In-app reading with scoped canvas, floating overlays, audio sync
- Page-by-page Mushaf reading (604 pages of the Madani layout)
- Audio recitation with verse-level synchronization
- **Context-Aware Content** — Translations, tafsir (brief/detailed), asbab al-nuzul, surah intros
- Practice tools — Flashcards (6 types, SRS-powered), Mutashabihat practice (4 modes)
- **Adaptive Intelligence** — Weekly reports, suggestion cards, smart notifications, pace projection
- **Social & Accountability** — Milestone sharing, accountability partners, teacher mode
- **Cloud Sync** — Firebase Auth (Google Sign-In), Firestore data sync, offline-first architecture
- Multiple reciter support, Arabic text rendering

**Target platforms**: Windows (primary dev), Android, iOS, Web, macOS, Linux

---

## Architecture

```
lib/
├── main.dart                          # App entry, MultiProvider setup, SQLite + Firebase init
├── firebase_options.dart              # FlutterFire auto-generated config
├── l10n/
│   └── app_localizations.dart         # i18n string lookup (English/Arabic)
├── models/
│   ├── quran_models.dart              # Verse, Word, Chapter, Reciter models
│   ├── hifz_models.dart               # MemoryProfile, DailyPlan, PageProgress, SessionRecord,
│   │                                  #   Suggestion, SuggestionType, WeeklySnapshot
│   ├── flashcard_models.dart          # Flashcard, FlashcardReview, MutashabihatGroup
│   └── werd_models.dart               # WerdConfig, WerdMode
├── providers/
│   ├── analytics_provider.dart        # Weekly snapshots, performance analytics, pace projection
│   ├── audio_provider.dart            # Audio playback (full chapter audio + seek)
│   ├── bookmark_provider.dart         # Bookmark CRUD, 12 colors + custom hex → syncs settings
│   ├── context_provider.dart          # Translation, tafsir, asbab al-nuzul state; language-aware switching
│   ├── flashcard_provider.dart        # Flashcard review sessions, SRS → syncs cards + reviews
│   ├── hifz_profile_provider.dart     # Active profile, CRUD, streak → syncs profile + streak
│   ├── hifz_provider.dart             # [STUBBED] Legacy — replaced by hifz_profile_provider
│   ├── locale_provider.dart           # UI localization (English/Arabic switching)
│   ├── navigation_provider.dart       # Controls bottom nav visibility during reading
│   ├── notification_provider.dart     # Daily reminder toggle, time, smart skip, mobile-only check
│   ├── plan_provider.dart             # Today's DailyPlan state, generation → syncs plans
│   ├── quran_reading_provider.dart    # Page loading, caching, chapter/reciter lists
│   ├── session_provider.dart          # Active session: timer, reps, phases → syncs sessions + progress
│   ├── social_provider.dart           # Milestone sharing, accountability partners
│   ├── theme_provider.dart            # App aesthetics, alignments, overlay settings
│   ├── update_provider.dart           # In-app self-update state
│   └── werd_provider.dart             # Daily werd state, progress
├── services/
│   ├── auth_service.dart              # Firebase Auth + Google Sign-In (mobile + desktop)
│   ├── cloud_sync_service.dart        # SQLite ↔ Firestore sync engine (ChangeNotifier)
│   ├── desktop_google_auth.dart       # Desktop OAuth loopback flow (PKCE + client_secret)
│   ├── analytics_service.dart         # Computes WeeklySnapshot from session history data
│   ├── asbab_nuzul_service.dart       # GitHub dataset import, verse-key lookup for occasions of revelation
│   ├── card_generation_service.dart   # Generates flashcards from memorized content (6 types)
│   ├── hifz_database_service.dart     # SQLite (9+ tables) — profiles, plans, sessions, flashcards, mutashabihat
│   ├── local_storage_service.dart     # SharedPreferences persistence layer
│   ├── mp3quran_service.dart          # mp3quran.net API for Warsh reciters
│   ├── mutashabihat_import_service.dart # GitHub dataset → SQLite import
│   ├── notification_service.dart      # Local notification scheduling logic
│   ├── plan_generation_service.dart   # Profile → daily plan pipeline (sabaq/sabqi/manzil)
│   ├── push_notification_service.dart # flutter_local_notifications + android_alarm_manager_plus
│   ├── quran_api_service.dart         # HTTP calls to quran.com API (v4)
│   ├── quran_audio_handler.dart       # audio_service handler for media controls
│   ├── quran_auth_service.dart        # OAuth2 token management for Quran API
│   ├── sharing_service.dart           # System share sheet + MilestoneType enum
│   ├── srs_engine.dart                # SM-2 spaced repetition algorithm
│   ├── tafsir_service.dart            # Translation + tafsir via Quran.com API v4 (with caching)
│   ├── update_service.dart            # GitHub Releases API check + APK download/install
│   └── warsh_text_service.dart        # CDN-based Warsh text fetching/caching
├── screens/
│   ├── app_shell.dart                 # Bottom nav scaffold (Dashboard/Practice/Read/Listen/Profile)
│   ├── home_screen.dart               # Hifz Dashboard (plan card, progress, CTA, suggestion cards)
│   ├── practice_screen.dart           # Practice tab (flashcard stats, mutashabihat link)
│   ├── audio_screen.dart              # Audio library / reciter browsing (Listen tab)
│   ├── read_index_screen.dart         # Surah/Juz index for quick navigation (Read tab)
│   ├── reading_screen.dart            # Main reading screen (PageView + overlays + werd + context bar)
│   ├── profile_screen.dart            # User profile / settings screen
│   ├── onboarding_screen.dart         # First-launch rewaya selection + language
│   ├── hifz_screen.dart               # [STUBBED] Legacy — replaced by home_screen
│   └── hifz/                          # Hifz-specific screens
│       ├── accountability_screen.dart # Accountability partners management
│       ├── analytics_screen.dart      # Weekly/monthly reports with charts
│       ├── assessment_screen.dart     # 9-screen wizard for profile creation
│       ├── flashcard_review_screen.dart # Card-by-card review with SRS rating (6 card types)
│       ├── mutashabihat_practice_screen.dart # 3 practice modes: Spot the Diff, Context, Quiz
│       ├── mutashabihat_screen.dart   # Browsable mutashabihat collection
│       ├── pre_session_screen.dart    # Pre-session plan review, offline marking, time estimate
│       ├── progress_detail_screen.dart # Pages + Surahs tabs, quick stats, session history
│       ├── session_history_screen.dart # Date-grouped session history with weekly stats
│       ├── session_screen.dart        # Active session (timer, reps, self-assessment, digital mode)
│       └── share_progress_screen.dart # Teacher mode — shareable progress reports
└── widgets/
    ├── hifz/                          # Hifz-specific widgets
    │   ├── hifz_cta_card.dart         # Dashboard: CTA for users without a profile
    │   ├── milestone_card.dart        # Shareable juz/khatm/streak milestone cards (gradient)
    │   ├── missed_day_dialog.dart     # Re-engagement dialog after missed days
    │   ├── plan_card.dart             # Dashboard: today's plan with Start Session CTA
    │   ├── progress_card.dart         # Dashboard: progress bar + stats
    │   ├── session_overlay.dart       # Floating session controls for digital mode (top bar + bottom controls)
    │   ├── session_reading_view.dart  # Scoped single-page ReadingCanvas for sessions
    │   ├── suggestion_card.dart       # Adaptive suggestion card (7 types: load, review, etc.)
    │   ├── verse_highlighter.dart     # SessionAudioHelper — verse-scoped playback utilities
    │   └── weekly_report.dart         # Performance analytics visualization (charts, comparisons, pace)
    ├── context/                       # Context-aware content widgets
    │   ├── asbab_nuzul_card.dart      # Expandable card for reasons of revelation
    │   ├── surah_intro_card.dart      # Surah introduction card (curated data for 24 surahs)
    │   ├── tafsir_sheet.dart          # Bottom sheet with Brief, Detailed, Occasion tabs
    │   └── translation_overlay.dart   # Compact verse translation overlay with shimmer loading
    ├── animated_svg_icon.dart         # Animated SVG icon for bottom nav
    ├── audio_player_bridge.dart       # Reusable audio player with scrubber, reciter info, controls
    ├── bottom_dock.dart               # Floating bottom dock bar
    ├── bottom_nav_bar.dart            # App-wide bottom navigation bar (5 tabs)
    ├── reading_canvas.dart            # Renders Arabic verse text per page
    ├── surah_list_tile.dart           # Stylized surah list item
    ├── top_nav_bar.dart               # Top navigation bar for reading screen
    ├── update_dialog.dart             # Premium in-app update dialog with progress
    ├── werd_card.dart                 # Home screen werd progress card
    └── sheets/                        # Bottom sheet overlays
        ├── notification_settings_sheet.dart  # Daily reminder settings (toggle, time picker, smart skip)
        ├── werd_setup_sheet.dart      # Werd goal configuration
        ├── theme_picker_sheet.dart    # Appearance settings
        └── ...                        # Other sheets (audio, nav, reciter, search)
```

### State Management
- **Provider** package with `ChangeNotifier`
- `HifzProfileProvider` — active profile, CRUD, streak (SQLite-backed, replaces old `HifzProvider`)
- `PlanProvider` — today's DailyPlan, generation, completion, force-regeneration
- `SessionProvider` — active session: timer, rep counter, phase progression, self-assessment, page progress, digital mode toggle
- `FlashcardProvider` — flashcard review sessions, SRS integration, dashboard stats, mutashabihat trigger
- `ContextProvider` — translation overlay, tafsir (brief/detailed), asbab al-nuzul; language-aware resource switching (EN/AR)
- `AnalyticsProvider` — weekly snapshots, performance analytics, pace projection, period comparison
- `NotificationProvider` — daily reminder toggle, time picker, smart skip, mobile-only detection
- `SocialProvider` — milestone sharing (juz/khatm/streak), accountability partners
- `BookmarkProvider` — bookmark CRUD, 12 preset colors + custom hex picker
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

### Context-Aware Data Flow
1. User taps a verse → `ContextProvider.loadContextForVerse(verseKey)` is called
2. Translation loaded from page cache or via `TafsirService.getTranslation()` (Quran.com API v4)
3. Asbab al-nuzul loaded synchronously from `AsbabNuzulService` (imported GitHub dataset)
4. User opens TafsirSheet → Brief tab auto-loads; Detailed + Occasion tabs load on demand
5. Language-aware: English uses Abdel Haleem (85) / Ibn Kathir (169,168); Arabic uses Muyassar (1014,16) / Ibn Kathir AR (14)

### Digital Session Flow
1. User taps "Digital" button in `SessionScreen` → `_isDigitalMode = true`
2. `SessionReadingView` wraps `ReadingCanvas` for a single page (no swiping)
3. `SessionOverlay` floats on top: top phase bar + bottom control bar with full `AudioPlayerBridge`
4. Toggle back to physical mode preserves all state (timer, reps, phase position)
5. `SessionAudioHelper` provides verse-scoped playback; `ReadingCanvas` highlights active verse

### Analytics & Adaptive Flow
1. `AnalyticsService` computes `WeeklySnapshot` from session history (completionRate, pagesMemorized, assessments)
2. `WeeklyReportWidget` renders: key stats, activity bar chart, assessment breakdown, period comparison, pace projection
3. `SuggestionCard` surfaces on dashboard — 7 types (increaseLoad, decreaseLoad, moreReview, etc.)
4. User accepts/dismisses — nothing changes automatically

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

### Cloud Sync Data Flow
1. Auth is **optional** — app works fully offline without sign-in
2. All writes go to SQLite first, then pushed to Firestore in the background (fire-and-forget)
3. On sign-in, `CloudSyncService.performInitialSync(uid)` checks for existing cloud data
4. Merge strategy: Cloud wins for profile/settings, additive/max-status for progress
5. Auto-sync triggers: session completion, profile update, plan regeneration, bookmark change, flashcard review
6. Retry: exponential backoff (1s → 2s → 4s, 3 attempts)
7. `CloudSyncService` extends `ChangeNotifier` — UI reacts to `SyncStatus` (idle/syncing/synced/error)

```
┌─────────────┐     fire-and-forget      ┌──────────────────────┐
│   SQLite     │  ──────────────────────► │     Firestore        │
│ (source of   │                          │  /users/{uid}        │
│   truth)     │  ◄────────────────────── │    ├─ meta/settings  │
└─────────────┘     initial sync /        │    ├─ meta/streak    │
                    new device pull       │    ├─ progress/      │
                                          │    ├─ sessions/      │
                                          │    ├─ plans/         │
                                          │    ├─ flashcards/    │
                                          │    └─ flashcard_reviews/ │
                                          └──────────────────────┘
```

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

### Tafsir & Translation via API
Uses `/verses/by_key/{key}?translations={id}` and `/verses/by_key/{key}?tafsirs={id}` — **NOT** the `/quran/translations/` or `/quran/tafsirs/` endpoints (those return empty arrays in v4). Batch page translations use `/verses/by_page/{page}?translations={id}&per_page=50`. Resource IDs auto-switch based on locale via `ContextProvider.setLocale()`.

### Asbab al-Nuzul Dataset
Imported from `mostafaahmed97/asbab-al-nuzul-dataset` (JSON, MIT license). Loaded once into memory by `AsbabNuzulService`, lookups are synchronous by verse key. Not stored in SQLite.

### Default Reciter
Reciter ID `7` = Mishary Rashid al-Afasy (default). Users can switch reciters via the settings overlay.

### Warsh Text Rendering
To keep the app size small, we do NOT bundle custom fonts for Warsh. Instead, we use a CDN (`fawazahmed0/quran-api`) to fetch a flat JSON array of all 6236 Warsh verses rendered in basic Unicode. The `WarshTextService` caches this in memory. `ReadingCanvas` dynamically switches between Hafs verse rendering and Warsh verse rendering based on the user's persisted rewaya preference.

### Background Audio & Media Controls
We use `audioplayers` for the audio engine but wrap it with `audio_service` to provide lock screen and notification media controls. The `QuranAudioHandler` syncs state between the system media session and the app's internal `AudioProvider`.

### Digital Session Mode
Reuses the existing `ReadingCanvas` widget inside `SessionReadingView` (scoped to a single page, no PageView swiping). `SessionOverlay` provides floating top phase bar and bottom control bar with full `AudioPlayerBridge`. `_isDigitalMode` toggle in `SessionScreen` persists timer/reps/phase across mode switches.

### Notifications
Uses `flutter_local_notifications` + `android_alarm_manager_plus` for scheduled daily reminders. Desktop shows "mobile only" warning. Smart skip: won't notify if today's session is already completed. Settings via `NotificationSettingsSheet`.

### Rewaya & Onboarding
The app features a one-time onboarding flow that auto-detects the system language and prompts the user to select their preferred *Rewaya* (Hafs vs Warsh). This preference is persisted via `SharedPreferences`. The reciter selection menu automatically filters to show reciters matching the saved rewaya first.

### Firebase Cloud Backend
- **Firebase Project:** `quran-app-e5e86`
- **Auth:** Google Sign-In (mobile via `google_sign_in`, desktop via loopback OAuth with PKCE + client_secret)
- **Desktop OAuth Client ID:** `556087735735-infr9f13pfg17cpfgkvpb71olm1ppju2.apps.googleusercontent.com`
- **Desktop OAuth Client Secret:** `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` (non-confidential for installed apps)
- **Firestore Rules:** Per-user isolation (`/users/{uid}/**` — read/write only if `auth.uid == uid`)
- **Sync Service:** `CloudSyncService` extends `ChangeNotifier` with `SyncStatus` enum (idle/syncing/synced/error)
- **Delete Account:** Wipes all Firestore data + Firebase Auth user
- **Sync triggers:** session completion, profile/streak update, plan regeneration, bookmark change, flashcard review

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
| `flutter_local_notifications` | Push notification scheduling (mobile) |
| `android_alarm_manager_plus` | Scheduled notification alarms (Android) |
| `share_plus` | System share sheet for milestone cards |
| `quran` | Offline verse text, surah metadata |
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Firebase Authentication |
| `cloud_firestore` | Cloud Firestore database |
| `google_sign_in` | Google Sign-In (mobile/web) |
| `crypto` | PKCE code challenge (SHA-256) for desktop OAuth |

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
12. **Tafsir API quirk** — Use `/verses/by_key/` endpoints with `?tafsirs=` or `?translations=` params. The `/quran/tafsirs/{id}` and `/quran/translations/{id}` endpoints return empty arrays.
13. **Context resources are locale-aware** — Always call `ContextProvider.setLocale()` when locale changes. Resource IDs auto-switch between English and Arabic sources.
14. **Cloud sync is optional** — Auth is not required. App must work fully offline.
15. **Sync triggers are fire-and-forget** — Never block UI on sync operations.
16. **Desktop OAuth needs client_secret** — Web-type OAuth client IDs require it even with PKCE.

---

## Completed Features

- [x] **Hifz Phase 1** — Profile assessment (9-screen wizard), dashboard (plan + progress + CTA), plan generation (sabaq/sabqi/manzil), sessions (physical mode), progress tracking (pages + surahs + juz bars + streak), missed-day handling, notifications, pre-session screen
- [x] **Hifz Phase 2** — Flashcards (6 types: Verse Completion, Next Verse, Previous Verse, Connect Sequence, Surah Detective, Mutashabihat Duel), SM-2 SRS engine, deck generation, mutashabihat import + 4 practice modes (Spot the Diff, Context Anchoring, Quick Quiz, Collection), integration triggers
- [x] **Hifz Phase 3** — Translation overlay (batch page translations, toggle on/off, EN/AR), tafsir sheet (Brief + Detailed + Occasion tabs), asbab al-nuzul (expandable card, GitHub dataset), surah intros (curated data, 24 surahs)
- [x] **Hifz Phase 4** — Digital session mode (scoped ReadingCanvas), session overlays (top phase bar + bottom controls + AudioPlayerBridge), mode switching (physical ↔ digital, state persists), verse-level audio sync (SessionAudioHelper)
- [x] **Hifz Phase 5** — Adaptive calibration (7 suggestion types), smart notifications (daily reminders, smart skip, neglected juz), performance analytics (weekly reports, pace projection, period comparison)
- [x] **Hifz Phase 6** — Accountability partners, teacher mode (shareable progress reports), community milestones (shareable juz/khatm/streak cards)
- [x] **Hifz Phase 7** — Cloud Backend (Firebase Auth + Google Sign-In, Firestore sync, desktop OAuth, delete account, flashcard sync, retry with backoff)
- [x] Bottom navigation: Dashboard / Practice / Read / Listen / Profile
- [x] Warsh text integration via CDN & Unicode rendering
- [x] Persistent Rewaya selection with first-launch onboarding
- [x] Daily Werd with progress tracking
- [x] App Localization (English/Arabic) with auto-detection
- [x] Search (Surahs), Bookmarks, Dark mode
- [x] Lock screen / Media Notification controls via `audio_service`
- [x] In-app self-update via GitHub Releases (Android)

## Current Phase

**Phase 7 complete.** Next: Phase 8 — Advanced Features (AI assessment, Ramadan mode, story mode).
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
