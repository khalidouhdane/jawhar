# Agent 1 — Context-Aware Content (Phase 3)

---

## Architecture Context

- **Project root:** `c:\Users\khali\OneDrive\Bureau\Quran App`
- **MANDATORY:** Read `GEMINI.md` at project root first — it has full architecture, rules, and reminders
- **State management:** Provider package with ChangeNotifier
- **Database:** SQLite via `sqflite` — service is `lib/services/hifz_database_service.dart`
- **API:** Quran Foundation API v4 (authenticated, see `docs/api-reference.md`)
- **Styling:** Dark theme via `ThemeProvider`, font is Inter via `google_fonts`
- **Icons:** `lucide_icons` package

---

## Off-Limits Files (DO NOT MODIFY)

These files are owned by the Core Engine agent and must not be edited:

| File | Reason |
|---|---|
| `lib/services/plan_generation_service.dart` | Plan pipeline — active development |
| `lib/providers/session_provider.dart` | Session state — active development |
| `lib/providers/plan_provider.dart` | Plan state — active development |
| `lib/providers/hifz_profile_provider.dart` | Profile management — stable |
| `lib/services/hifz_database_service.dart` | DB schema — coordinate changes via docs |
| `lib/screens/hifz/session_screen.dart` | Session UI — active development |
| `lib/screens/home_screen.dart` | Dashboard — active development |
| `lib/widgets/hifz/plan_card.dart` | Plan card widget — active development |

> If you need a DB schema change, document it in `docs/features/hifz/schema-requests/phase3-tables.md` and wait for the Core Engine agent to implement it.

---

## Your Assignment

You are working on the Le Quran Flutter app — a Quran memorization (Hifz) companion.

Your job is to implement contextual learning aids that help users understand what they're memorizing. Understanding aids retention.

### MANDATORY: Read These Files First
1. `GEMINI.md` at project root — full architecture and rules
2. `docs/features/hifz/hifz-roadmap.md` — Phase 3 section
3. `docs/features/hifz/research/context-aware-memorization.md` — your primary spec
4. `docs/api-reference.md` — Quran Foundation API details

### Your Scope
You are responsible for implementing:
1. **Translation Overlay** — show verse translations from Quran.com API during reading
2. **Brief Tafsir** — integrate Tafsir al-Muyassar via API, "Meaning" button per verse
3. **Asbab al-Nuzul** — import dataset from GitHub, show revelation context
4. **Surah Introduction** — thematic overview card when starting a new surah

### Files You Own (create/modify freely)
- `lib/services/tafsir_service.dart` [NEW]
- `lib/services/asbab_nuzul_service.dart` [NEW]
- `lib/providers/context_provider.dart` [NEW]
- `lib/widgets/context/` [NEW directory] — translation overlay, tafsir sheet, asbab card, surah intro
- `lib/screens/hifz/tafsir_screen.dart` [NEW] — if needed for full tafsir view

### Files You May Read But NOT Modify
- `lib/services/hifz_database_service.dart` — if you need schema changes, create a request file
- `lib/screens/hifz/session_screen.dart` — understand session flow but don't edit
- `lib/providers/quran_reading_provider.dart` — understand API patterns, don't edit

### Integration Points
- Your widgets will be consumed by the session screen and reading screen later
- Build them as standalone widgets that accept verse/page data as parameters
- The Core Engine agent will integrate them into the session flow

### API Details
- Translations: `GET /translations/{translation_id}?verse_key=2:255`
- Tafsir: `GET /tafsirs/{tafsir_id}?verse_key=2:255`
- All API calls need auth headers — see `quran_auth_service.dart` for pattern
- Tafsir al-Muyassar ID: check `docs/api-reference.md`

### Rules
- Auto-run all terminal commands (SafeToAutoRun: true)
- Test on Windows (primary dev platform)
- Follow existing code style (Provider + ChangeNotifier, Inter font, ThemeProvider colors)
- Wrap large text widgets in `ExcludeSemantics()` to avoid Windows accessibility crashes
