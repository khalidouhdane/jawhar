# Agent 2 — Digital Session Mode (Phase 4)

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

> If you need a DB schema change, document it in `docs/features/hifz/schema-requests/phase4-tables.md` and wait for the Core Engine agent to implement it.

---

## Your Assignment

You are working on the Le Quran Flutter app — a Quran memorization (Hifz) companion.

Your job is to implement in-app reading during Hifz sessions. Currently sessions are "physical Quran mode" — a timer and rep counter. You're adding a digital reading mode that shows the actual Quran page inside the session.

### MANDATORY: Read These Files First
1. `GEMINI.md` at project root — full architecture and rules
2. `docs/features/hifz/hifz-roadmap.md` — Phase 4 section
3. `docs/features/hifz/methods-and-planning/session-design.md` — especially "Digital Reading Mode"
4. `docs/features/hifz/user-flows.md` — Flow 4 (daily session)

### Your Scope
You are responsible for implementing:
1. **Scoped Reading Canvas** — restrict the existing ReadingCanvas to show only assigned pages during a session
2. **Session Overlays** — floating timer, rep counter, phase indicator on top of the reading canvas
3. **Mode Switching** — toggle between physical and digital mode mid-session (state persists)
4. **Verse-level Audio Sync** — highlight the active verse using existing audio timing data

### Files You Own (create/modify freely)
- `lib/widgets/hifz/session_reading_view.dart` [NEW] — scoped reading canvas wrapper
- `lib/widgets/hifz/session_overlay.dart` [NEW] — floating controls overlay
- `lib/widgets/hifz/verse_highlighter.dart` [NEW] — verse-level highlighting

### Files You May Read But NOT Modify
- `lib/widgets/reading_canvas.dart` — understand how the reading canvas works, but create a wrapper instead of modifying it directly
- `lib/screens/hifz/session_screen.dart` — understand the session phases. DO NOT EDIT. The Core Engine agent will integrate your widgets.
- `lib/providers/session_provider.dart` — understand session state (currentPhase, plan, etc.)
- `lib/providers/audio_provider.dart` — understand audio playback and verse timing

### Integration Contract
Your `SessionReadingView` widget should accept:
- `int pageNumber` — which page to display
- `bool showOverlay` — whether to show floating controls
- `SessionProvider session` — to read timer, reps, phase
- `VoidCallback onRepTap` — to count reps
- `VoidCallback onDone` — to finish phase

The Core Engine agent will add a toggle button in `session_screen.dart` that swaps between the existing control panel and your `SessionReadingView`.

### Rules
- Auto-run all terminal commands (SafeToAutoRun: true)
- Test on Windows (primary dev platform)
- DO NOT use `just_audio` — use `audioplayers` (just_audio crashes on Windows)
- Wrap large Arabic text in `ExcludeSemantics()` — Windows accessibility bridge crashes otherwise
- Follow existing code style (Provider + ChangeNotifier, Inter font, ThemeProvider)
