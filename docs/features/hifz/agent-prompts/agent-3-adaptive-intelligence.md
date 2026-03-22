# Agent 3 — Adaptive Intelligence (Phase 5)

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

> If you need a DB schema change or new queries, document them in `docs/features/hifz/schema-requests/phase5-queries.md` and wait for the Core Engine agent to implement.

---

## Your Assignment

You are working on the Le Quran Flutter app — a Quran memorization (Hifz) companion.

Your job is to implement smart analytics and adaptive suggestions that help users optimize their memorization pace based on real performance data.

### MANDATORY: Read These Files First
1. `GEMINI.md` at project root — full architecture and rules
2. `docs/features/hifz/hifz-roadmap.md` — Phase 5 section
3. `docs/features/hifz/methods-and-planning/plan-generation.md` — "Adaptive Adjustment" section
4. `docs/features/hifz/user-flows.md` — Flow 10 (adaptive calibration)

### Your Scope
You are responsible for implementing:
1. **Adaptive Calibration** — weekly pattern analysis (completion rate, self-assessment distribution), suggestion cards
2. **Smart Notifications** — "You haven't reviewed Juz 30 in 5 days", struggle detection
3. **Performance Analytics** — weekly/monthly reports, pace calculation, historical comparison

### Files You Own (create/modify freely)
- `lib/services/analytics_service.dart` [NEW] — weekly analysis engine
- `lib/services/notification_service.dart` [NEW] — smart notification logic
- `lib/providers/analytics_provider.dart` [NEW] — analytics state
- `lib/screens/hifz/analytics_screen.dart` [NEW] — weekly/monthly report UI
- `lib/widgets/hifz/suggestion_card.dart` [NEW] — adaptive suggestion cards for dashboard
- `lib/widgets/hifz/weekly_report.dart` [NEW] — report visualization

### Files You May Read But NOT Modify
- `lib/services/hifz_database_service.dart` — you need to query session_records and page_progress
- `lib/models/hifz_models.dart` — understand SessionRecord, PageProgress, DailyPlan models
- `lib/providers/hifz_profile_provider.dart` — understand profile fields (encoding speed, retention, daily time)

### Key Data You'll Query
- `session_records` table — has date, duration, phases completed, self-assessment ratings
- `page_progress` table — has page status, lastReviewedAt, repetition count
- `daily_plans` table — has planned vs. actual (via completion status)
- `profiles` table — has encoding speed, retention strength, daily time

### Analytics Rules (from research)
- Suggestions are NEVER auto-applied — user accepts or dismisses
- Language must be compassionate (no "you failed", use "looks like things have been busy")
- Streak counts TOTAL active days, not consecutive
- Progress bar NEVER goes backward

### Integration
Your `SuggestionCard` widget will be placed on the dashboard by the Core Engine agent. Build it to accept a suggestion model and display independently.

### Rules
- Auto-run all terminal commands (SafeToAutoRun: true)
- Test on Windows (primary dev platform)
- Follow existing code style (Provider + ChangeNotifier, Inter font, ThemeProvider)
