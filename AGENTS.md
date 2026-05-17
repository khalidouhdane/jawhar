# Jawhar — Agent Rules

> **Jawhar** (جوهر) — A Flutter Quran memorization (Hifz) companion app. *Memorize with Meaning.*

---

## ⚠️ MANDATORY: Hifz Roadmap & Research Files

**Before starting ANY work on this project, you MUST read** these files:

1. **[hifz-roadmap.md](docs/features/hifz/hifz-roadmap.md)** — The master roadmap. All development follows this phase-by-phase plan.
2. **[user-flows.md](docs/features/hifz/user-flows.md)** — 12 user flows that define exactly how features work.
3. **[session-design.md](docs/features/hifz/methods-and-planning/session-design.md)** — Session UX spec.
4. **[plan-generation.md](docs/features/hifz/methods-and-planning/plan-generation.md)** — How daily plans are generated.

**Rules:**
- Follow the roadmap **to the letter**. Do not skip phases or add features from later phases.
- When implementing a phase, cross-reference the referenced docs (`📄 Reference:` links in the roadmap).
- Every new feature must be validated against user flows to ensure all scenarios are covered.
- If you encounter ambiguity, check the research files in `docs/features/hifz/research/`.

---

## ⚠️ MANDATORY: Brand Strategy

**Before ANY user-facing work, you MUST read**:
1. **[brand-strategy.md](docs/brand-strategy.md)** — The Jawhar brand strategy. All copy, UI text, marketing, and documentation must align with this strategy.

**Key rules:**
- The app name is **Jawhar**, not "Le Quran." Use "Jawhar" in all new code, docs, and UI.
- Primary tagline: **"Memorize with Meaning"** (accessible, for everyone)
- Technical tagline: **"Encode the Essence"** (for dev/hackathon audience only)
- Brand voice: Calm, confident, precise. NOT preachy, gamified, or casual.
- Design philosophy: **"The app disappears. The Quran appears."**

---

## ⚠️ MANDATORY: Design System

**Before making UI changes, you MUST read**:
1. **[DESIGN.md](DESIGN.md)** — The Vercel Design System by Open Design. All UI changes must strictly adhere to this design system.

---

## ⚠️ MANDATORY: Skills Framework (Superpowers)

All agents use skills from `.agents/skills/`. **Before any task, check if a relevant skill exists and invoke it.**

| Skill | When to use |
|-------|-------------|
| `brainstorming` | Before creating features, components, or UI changes |
| `writing-plans` | Before multi-step implementation work |
| `test-driven-development` | Before writing any production code |
| `systematic-debugging` | Before fixing any bug or unexpected behavior |
| `verification-before-completion` | Before claiming work is done or committing |
| `requesting-code-review` | After completing major features, before merge |
| `receiving-code-review` | When handling review feedback |
| `using-git-worktrees` | When starting isolated feature work |

See `.agents/skills/using-superpowers/SKILL.md` for the full protocol. If there's even a 1% chance a skill applies, invoke it.

---

## Project Overview

**Jawhar** (جوهر) — The first Quran memorization companion built on understanding. *Memorize with Meaning.*

**Core philosophy:** Memorization without understanding is incomplete. Jawhar helps users memorize the Quran while deeply understanding every verse — through translations, tafsir, reasons of revelation, and adaptive planning.

**Three Beats** (product narrative — for onboarding, website, marketing, pitch):
1. **Read & Listen** — Beautiful Mushaf, 40+ reciters, verse-synced audio, Hafs + Warsh
2. **Understand** — Translations, tafsir (brief/detailed), asbab al-nuzul, surah intros
3. **Memorize** — AI plans, structured sessions, flashcards, analytics

**Three Pillars** (hifz methodology — for session design, plan generation, technical docs):
1. **The Plan** — Adaptive daily plans (sabaq/sabqi/manzil), pace projection, analytics
2. **The Session** — Structured timer, rep counter, self-assessment, digital mode
3. **The Understanding** — Translations, tafsir (brief/detailed), asbab al-nuzul, surah intros

**Full feature set:**
- **Hifz Dashboard** — Daily plan, progress tracking, session management, suggestion cards
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
├── providers/                         # ChangeNotifier-based state management
│   ├── analytics_provider.dart        # Weekly snapshots, performance analytics, pace projection
│   ├── audio_provider.dart            # Audio playback (full chapter audio + seek)
│   ├── bookmark_provider.dart         # Bookmark CRUD, 12 colors + custom hex → syncs settings
│   ├── context_provider.dart          # Translation, tafsir, asbab al-nuzul; language-aware switching
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
├── services/                          # Business logic layer
│   ├── auth_service.dart              # Firebase Auth + Google Sign-In (mobile + desktop)
│   ├── cloud_sync_service.dart        # SQLite ↔ Firestore sync engine (ChangeNotifier)
│   ├── desktop_google_auth.dart       # Desktop OAuth loopback flow (PKCE + client_secret)
│   ├── analytics_service.dart         # Computes WeeklySnapshot from session history data
│   ├── asbab_nuzul_service.dart       # GitHub dataset import, verse-key lookup
│   ├── card_generation_service.dart   # Generates flashcards from memorized content (6 types)
│   ├── hifz_database_service.dart     # SQLite (9+ tables) — profiles, plans, sessions, flashcards
│   ├── local_storage_service.dart     # SharedPreferences persistence layer
│   ├── mp3quran_service.dart          # mp3quran.net API for Warsh reciters
│   ├── mutashabihat_import_service.dart # GitHub dataset → SQLite import
│   ├── notification_service.dart      # Local notification scheduling logic
│   ├── plan_generation_service.dart   # Profile → daily plan pipeline (sabaq/sabqi/manzil)
│   ├── push_notification_service.dart # flutter_local_notifications + android_alarm_manager_plus
│   ├── quran_api_service.dart         # HTTP calls to Quran Foundation API (v4)
│   ├── quran_audio_handler.dart       # audio_service handler for media controls
│   ├── quran_auth_service.dart        # OAuth2 token management for Quran API
│   ├── sharing_service.dart           # System share sheet + MilestoneType enum
│   ├── srs_engine.dart                # SM-2 spaced repetition algorithm
│   ├── tafsir_service.dart            # Translation + tafsir via Quran API v4 (with caching)
│   ├── update_service.dart            # GitHub Releases API check + APK download/install
│   └── warsh_text_service.dart        # CDN-based Warsh text fetching/caching
├── screens/
│   ├── app_shell.dart                 # Bottom nav scaffold (Home/Read/Understand/Practice/Profile)
│   ├── home_screen.dart               # Hifz Dashboard (plan card, progress, CTA, suggestion cards)
│   ├── practice_screen.dart           # Practice tab (flashcard stats, mutashabihat link)
│   ├── audio_screen.dart              # Audio library / reciter browsing (accessed from Read tab)
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
    │   ├── session_overlay.dart       # Floating session controls for digital mode
    │   ├── session_reading_view.dart  # Scoped single-page ReadingCanvas for sessions
    │   ├── suggestion_card.dart       # Adaptive suggestion card (7 types)
    │   ├── verse_highlighter.dart     # SessionAudioHelper — verse-scoped playback utilities
    │   └── weekly_report.dart         # Performance analytics visualization
    ├── context/                       # Context-aware content widgets
    │   ├── asbab_nuzul_card.dart      # Expandable card for reasons of revelation
    │   ├── surah_intro_card.dart      # Surah introduction card (curated, 24 surahs)
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
        ├── notification_settings_sheet.dart  # Daily reminder settings
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

### Key Data Flows

1. **Hifz:** Profile → Plan Generation → Session → Completion → Plan Regeneration
2. **Context:** Verse tap → ContextProvider → Translation/Tafsir/Asbab al-Nuzul
3. **Digital Session:** SessionScreen toggle → SessionReadingView (scoped single-page) → SessionOverlay
4. **Analytics:** SessionHistory → WeeklySnapshot → SuggestionCards
5. **Cloud Sync:** SQLite (source of truth) → fire-and-forget push → Firestore; new device login → pull from Firestore → merge into SQLite
6. **Quran Reading:** QuranReadingProvider → API fetch → ReadingCanvas → AudioProvider → verse highlighting
7. **Werd Tracking:** ReadingScreen 5s timer → WerdProvider.incrementProgress → milestone snackbars at 50/80/100%
8. **Cloud Sync Detail:** SQLite (source of truth) → fire-and-forget push → Firestore; `CloudSyncService.performInitialSync(uid)` on new device → merge into SQLite

### Cloud Sync Architecture
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

**Sync rules:**
- Auth is **optional** — app works fully offline without sign-in
- All writes go to SQLite first, then pushed to Firestore in the background
- Merge strategy: Cloud wins for profile/settings, additive/max-status for progress
- Auto-sync triggers: session completion, profile update, plan regeneration, bookmark change, flashcard review
- Retry: exponential backoff (1s → 2s → 4s, 3 attempts)
- `CloudSyncService` extends `ChangeNotifier` — UI reacts to `SyncStatus` (idle/syncing/synced/error)

---

## Key Technical Decisions

### Audio: Full Chapter Audio with Verse Seeking
**DO NOT go back to per-verse audio files.** The current approach plays a single chapter mp3 and seeks using timestamp data from the `?segments=true` API parameter. This eliminates the "tick" sound and gaps between verses. See [docs/api-reference.md](docs/api-reference.md) for full details.

### API: Quran Foundation API (v4)
All data comes from the authenticated API: `https://apis.quran.foundation/content/api/v4`.
The legacy `api.quran.com` endpoints are **deprecated** and returning 503 errors.

**Authentication:** See `.env` file for credentials. Method: `POST` to auth URL with `grant_type=client_credentials&scope=content`. Headers: `x-auth-token: <token>` and `x-client-id: <clientId>`.

Key endpoints in [docs/api-reference.md](docs/api-reference.md).

### Tafsir & Translation via API
Uses `/verses/by_key/{key}?translations={id}` and `/verses/by_key/{key}?tafsirs={id}` — **NOT** the `/quran/translations/` or `/quran/tafsirs/` endpoints (those return empty arrays in v4). Batch page translations use `/verses/by_page/{page}?translations={id}&per_page=50`. Resource IDs auto-switch based on locale via `ContextProvider.setLocale()`.

### Asbab al-Nuzul Dataset
Imported from `mostafaahmed97/asbab-al-nuzul-dataset` (JSON, MIT license). Loaded once into memory by `AsbabNuzulService`, lookups are synchronous by verse key. Not stored in SQLite.

### Default Reciter
Reciter ID `7` = Mishary Rashid al-Afasy (default). Users can switch reciters via the settings overlay.

### Warsh Text Rendering
CDN-based (`fawazahmed0/quran-api`) — flat JSON array of 6236 Warsh verses in Unicode. `WarshTextService` caches in memory. `ReadingCanvas` switches between Hafs/Warsh based on persisted rewaya preference.

### Background Audio & Media Controls
`audioplayers` for the audio engine + `audio_service` for lock screen and notification media controls. `QuranAudioHandler` syncs state between the system media session and the app's `AudioProvider`.

### Digital Session Mode
Reuses `ReadingCanvas` inside `SessionReadingView` (scoped to a single page, no PageView swiping). `SessionOverlay` provides floating top phase bar and bottom control bar with full `AudioPlayerBridge`. `_isDigitalMode` toggle persists timer/reps/phase across mode switches.

### Notifications
`flutter_local_notifications` + `android_alarm_manager_plus` for scheduled daily reminders. Desktop shows "mobile only" warning. Smart skip: won't notify if today's session is already completed.

### Rewaya & Onboarding
One-time onboarding flow auto-detects system language and prompts rewaya selection (Hafs vs Warsh). Persisted via `SharedPreferences`. Reciter menu auto-filters by saved rewaya.

### Firebase Cloud Backend
- **Firebase Project:** See `.env` for project ID.
- **Auth:** Google Sign-In (mobile via `google_sign_in`, desktop via loopback OAuth with PKCE + client_secret)
- **Desktop OAuth:** See `.env` for client ID and secret.
- **Firestore Rules:** Per-user isolation (`/users/{uid}/**` — read/write only if `auth.uid == uid`)
- **Sync Service:** `CloudSyncService` extends `ChangeNotifier` with `SyncStatus` enum (idle/syncing/synced/error)
- **Delete Account:** Wipes all Firestore data + Firebase Auth user

### In-App Self-Update (GitHub Releases)
GitHub Releases as update server for sideloaded APKs. `UpdateProvider.checkForUpdate()` calls `https://api.github.com/repos/khalidouhdane/le-quran/releases/latest`. Compares `tag_name` vs running version via `package_info_plus`. APK downloads via `dio`, installs via `open_filex`. Requires `REQUEST_INSTALL_PACKAGES` + `FileProvider`.

---

## Important Reminders

1. **Read the Hifz roadmap FIRST** — Before any implementation work.
2. **Use Superpowers skills** — Check `.agents/skills/` before starting any task.
3. **Test on Windows** — Primary dev platform. Audio behavior differs across platforms.
4. **Windows Accessibility Bridge Crashes** — Wrap large `RichText` in `ExcludeSemantics()`.
5. **`just_audio` doesn't work on Windows** — Stick with `audioplayers`.
6. **Page numbers are 1-604** — Madani Mushaf layout.
7. **Verse keys format**: `"chapter:verse"` (e.g., `"2:255"`)
8. **Hifz data is in SQLite** — Do NOT use SharedPreferences for Hifz data. Use `HifzDatabaseService`.
9. **Session completion must regenerate plan** — Always call `PlanProvider.regeneratePlan()`.
10. **First-time users get sabaq-only** — sabqi/manzil phases auto-skipped.
11. **Tafsir API quirk** — `/quran/tafsirs/{id}` returns empty arrays in v4. Use `/verses/by_key/` instead.
12. **Context resources are locale-aware** — Always call `ContextProvider.setLocale()` on locale change.
13. **Cloud sync is optional** — Auth is not required. App must work fully offline.
14. **Sync triggers are fire-and-forget** — Never block UI on sync operations.
15. **Desktop OAuth needs client_secret** — Web-type OAuth client IDs require it even with PKCE.
16. **API credentials are in `.env`** — Never hardcode secrets in source files or docs.
17. **No `const` with `GeistTypography`** — Never use `const` on `Text` or `TextStyle` when setting `fontFamily: GeistTypography.primaryFontFamily`, as it evaluates dynamically via GoogleFonts.

---

## Git Workflow & Code Standards

### Branch Naming
`feat/`, `fix/`, `refactor/`, `docs/`, `chore/` — always prefix branches.

### Conventional Commits
Format: `type(scope): description`

| Type | Use for |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code change (no feature/fix) |
| `docs` | Documentation only |
| `style` | Formatting, whitespace |
| `test` | Adding/fixing tests |
| `chore` | Build, CI, dependency updates |
| `perf` | Performance improvement |

### Code Quality Gates
Before committing:
1. `flutter analyze` — zero warnings
2. Tests pass — all unit + integration
3. `dart format .` — auto-formatted

### PR Standards
- Title matches conventional commit format
- Description includes: What, Why, How, Testing
- Screenshots for UI changes
- Max 400 lines changed per PR
- Squash merge to main, always rebase before PR

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
| `dio` | HTTP with download progress (self-update) |
| `package_info_plus` | Read current app version at runtime |
| `open_filex` | Trigger Android system APK installer |
| `flutter_local_notifications` | Push notification scheduling (mobile) |
| `android_alarm_manager_plus` | Scheduled notification alarms (Android) |
| `share_plus` | System share sheet |
| `quran` | Offline verse text, surah metadata |
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Firebase Authentication |
| `cloud_firestore` | Cloud Firestore database |
| `google_sign_in` | Google Sign-In (mobile/web) |
| `crypto` | PKCE code challenge (SHA-256) for desktop OAuth |

---

## Completed Phases & Current State

- [x] **Hifz Phase 1** — Profile assessment, dashboard, plan generation, sessions, progress tracking, missed-day handling, notifications, pre-session screen
- [x] **Hifz Phase 2** — Flashcards (6 types), SM-2 SRS engine, mutashabihat import + 4 practice modes, integration triggers
- [x] **Hifz Phase 3** — Translation overlay, tafsir sheet (Brief + Detailed + Occasion), asbab al-nuzul, surah intros (24 surahs)
- [x] **Hifz Phase 4** — Digital session mode, session overlays, mode switching (physical ↔ digital), verse-level audio sync
- [x] **Hifz Phase 5** — Adaptive calibration (7 suggestion types), smart notifications, performance analytics (weekly reports, pace projection)
- [x] **Hifz Phase 6** — Accountability partners, teacher mode, community milestones
- [x] **Hifz Phase 7** — Cloud Backend (Firebase Auth, Firestore sync, desktop OAuth, delete account, flashcard sync)
- [x] Bottom navigation, Warsh text, Rewaya onboarding, Werd tracking, Localization (EN/AR), Search, Bookmarks, Dark mode, Lock screen controls, Self-update

### 🏆 HACKATHON SPRINT (Deadline: May 20, 2026)

**Quran Foundation Hackathon** — $10K prize pool, 7 winners.
**Brand:** Jawhar — *Memorize with Meaning*
**Pitch angle:** "We asked: what if a Quran app didn't just count your pages, but helped you understand every verse you memorize?"

Current focus:
- Integrate **User APIs**: Bookmarks, Streaks, Goals, Reading Sessions (replacing local-only implementations)
- **OAuth2 PKCE** flow (pre-production keys for dev, production pending approval)
- Polish UI/UX for 2-3 min demo video
- Must use at least one **Content API** (✅ already done) + one **User API** (in progress)
- All UI copy and marketing must follow [brand-strategy.md](docs/brand-strategy.md)

Phase 8 (AI assessment, Ramadan mode, story mode) deferred post-hackathon.

See [hifz-roadmap.md](docs/features/hifz/hifz-roadmap.md) for full details.

---

## Reference

- **Brand Strategy (READ FIRST)**: [brand-strategy.md](docs/brand-strategy.md)
- **Hifz World Map**: [hifz-world-map.md](docs/features/hifz/hifz-world-map.md)
- **Hifz Phase Roadmap**: [hifz-roadmap.md](docs/features/hifz/hifz-roadmap.md)
- **Core Engine Mini Roadmap**: [core-engine-roadmap.md](docs/features/hifz/roadmaps/core-engine-roadmap.md)
- **User Flows**: [user-flows.md](docs/features/hifz/user-flows.md)
- **API Docs**: https://api-docs.quran.com/docs/category/quran.com-api
- **API Reference**: [api-reference.md](docs/api-reference.md)
- **Technical Discoveries**: [findings.md](docs/research/findings.md)
- **Design System**: [DESIGN.md](DESIGN.md)
- **Skills**: `.agents/skills/` (Superpowers framework)
- **Credentials**: `.env` (gitignored)
