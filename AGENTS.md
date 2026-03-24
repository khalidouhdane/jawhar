# Le Quran — Agent Rules

> **Le Quran** — A Flutter Quran memorization (Hifz) companion app.

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
- Multiple reciter support, Arabic text rendering

**Target platforms**: Windows (primary dev), Android, iOS, Web, macOS, Linux

---

## Architecture

```
lib/
├── main.dart                          # App entry, MultiProvider setup, SQLite init
├── models/
│   ├── quran_models.dart              # Verse, Word, Chapter, Reciter
│   ├── hifz_models.dart               # MemoryProfile, DailyPlan, PageProgress, SessionRecord
│   ├── flashcard_models.dart          # Flashcard, FlashcardReview, MutashabihatGroup
│   └── werd_models.dart               # WerdConfig, WerdMode
├── providers/                         # ChangeNotifier-based state management
│   ├── analytics_provider.dart        # Weekly snapshots, pace projection
│   ├── audio_provider.dart            # Audio playback (full chapter + seek)
│   ├── bookmark_provider.dart         # Bookmark CRUD, 12 colors + custom hex
│   ├── context_provider.dart          # Translation, tafsir, asbab al-nuzul
│   ├── flashcard_provider.dart        # Flashcard review sessions, SRS
│   ├── hifz_profile_provider.dart     # Active profile, CRUD, streak (SQLite)
│   ├── plan_provider.dart             # Today's DailyPlan, generation, completion
│   ├── session_provider.dart          # Active session: timer, reps, phases
│   ├── notification_provider.dart     # Daily reminders, smart skip
│   ├── social_provider.dart           # Milestones, accountability partners
│   └── ...                            # theme, locale, navigation, werd, update
├── services/                          # Business logic layer
│   ├── hifz_database_service.dart     # SQLite (9+ tables)
│   ├── plan_generation_service.dart   # Profile → daily plan pipeline
│   ├── srs_engine.dart                # SM-2 spaced repetition
│   ├── quran_api_service.dart         # Quran.com API v4
│   ├── tafsir_service.dart            # Translation + tafsir (cached)
│   └── ...                            # audio, sharing, notifications, update
├── screens/                           # UI screens
│   ├── app_shell.dart                 # Bottom nav (Dashboard/Practice/Read/Listen/Profile)
│   ├── reading_screen.dart            # Main reading (PageView + overlays)
│   └── hifz/                          # Hifz-specific screens
└── widgets/                           # Reusable widgets
```

### State Management
- **Provider** package with `ChangeNotifier`
- Key providers: HifzProfileProvider, PlanProvider, SessionProvider, FlashcardProvider, ContextProvider, AnalyticsProvider, NotificationProvider, SocialProvider

### Key Data Flows
1. **Hifz:** Profile → Plan Generation → Session → Completion → Plan Regeneration
2. **Context:** Verse tap → ContextProvider → Translation/Tafsir/Asbab al-Nuzul
3. **Digital Session:** SessionScreen toggle → SessionReadingView (scoped single-page) → SessionOverlay
4. **Analytics:** SessionHistory → WeeklySnapshot → SuggestionCards

---

## Key Technical Decisions

### Audio: Full Chapter Audio with Verse Seeking
**DO NOT go back to per-verse audio files.** The current approach plays a single chapter mp3 and seeks using timestamp data from the `?segments=true` API parameter.

### API: Quran Foundation API (v4)
All data comes from: `https://apis.quran.foundation/content/api/v4`.
The legacy `api.quran.com` endpoints are **deprecated**.

**Authentication:**
- **Auth URL:** `https://oauth2.quran.foundation/oauth2/token`
- **Method:** `POST` with `grant_type=client_credentials&scope=content`
- **Client ID:** `879421dc-68cb-4a1d-a500-c060d10478e6`
- **Client Secret:** `cKEt~daJ4tgXiJ1td0t4JwBB_z`
- **Headers:** `x-auth-token: <token>` and `x-client-id: <clientId>`

Key endpoints in [docs/api-reference.md](docs/api-reference.md).

### Other Decisions
- **Tafsir API:** Use `/verses/by_key/` with `?tafsirs=`/`?translations=` params (NOT `/quran/tafsirs/`)
- **Asbab al-Nuzul:** `mostafaahmed97/asbab-al-nuzul-dataset` (JSON, in-memory)
- **Default Reciter:** ID `7` = Mishary Rashid al-Afasy
- **Warsh Text:** CDN-based (`fawazahmed0/quran-api`), cached in memory
- **Background Audio:** `audioplayers` + `audio_service` for lock screen controls
- **Notifications:** `flutter_local_notifications` + `android_alarm_manager_plus`
- **Self-Update:** GitHub Releases API → APK download/install

---

## Important Reminders

1. **Read the Hifz roadmap FIRST** — Before any implementation work.
2. **Test on Windows** — Primary dev platform. Audio behavior differs across platforms.
3. **Windows Accessibility Bridge Crashes** — Wrap large `RichText` in `ExcludeSemantics()`.
4. **`just_audio` doesn't work on Windows** — Stick with `audioplayers`.
5. **Page numbers are 1-604** — Madani Mushaf layout.
6. **Verse keys format**: `"chapter:verse"` (e.g., `"2:255"`)
7. **Hifz data is in SQLite** — Do NOT use SharedPreferences for Hifz data.
8. **Session completion must regenerate plan** — Always call `PlanProvider.regeneratePlan()`.
9. **First-time users get sabaq-only** — sabqi/manzil phases auto-skipped.
10. **Tafsir API quirk** — `/quran/tafsirs/{id}` returns empty arrays in v4.
11. **Context resources are locale-aware** — Always call `ContextProvider.setLocale()` on locale change.

---

## Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management |
| `http` | API requests |
| `sqflite` / `sqflite_common_ffi` | SQLite (Hifz data, desktop compat) |
| `audioplayers` + `audio_service` | Audio playback + lock screen controls |
| `shared_preferences` | Persistent user settings |
| `google_fonts` | Typography |
| `dio` | HTTP with download progress (self-update) |
| `flutter_local_notifications` | Push notifications |
| `share_plus` | System share sheet |
| `quran` | Offline verse text, surah metadata |

---

## Completed Phases & Current State

- [x] **Phase 1-6** — All complete (Profile, Dashboard, Plans, Sessions, Flashcards, SRS, Context, Digital Mode, Analytics, Notifications, Social)
- **Phase 7 NEXT** — Advanced Features (AI assessment, cloud sync, Ramadan mode, story mode)

See [hifz-roadmap.md](docs/features/hifz/hifz-roadmap.md) for details.

---

## Reference

- **Hifz Roadmap**: [hifz-roadmap.md](docs/features/hifz/hifz-roadmap.md)
- **User Flows**: [user-flows.md](docs/features/hifz/user-flows.md)
- **API Docs**: [api-reference.md](docs/api-reference.md)
- **Research**: [findings.md](docs/research/findings.md)
