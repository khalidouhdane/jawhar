# Agent 4 — Social/Accountability + Notifications (Phase 6 + 1.9)

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

> If you need a DB schema change, document it in `docs/features/hifz/schema-requests/phase6-tables.md` and wait for the Core Engine agent to implement it.

---

## Your Assignment

You are working on the Le Quran Flutter app — a Quran memorization (Hifz) companion.

Your job covers two related areas: (1) push notifications for session reminders, and (2) social/accountability features for shared progress.

### MANDATORY: Read These Files First
1. `GEMINI.md` at project root — full architecture and rules
2. `docs/features/hifz/hifz-roadmap.md` — Phase 6 section + Phase 1.9 (Notifications)
3. `docs/features/hifz/user-flows.md` — Flow 12 (notifications)

### Your Scope — Notifications (Phase 1.9)
1. **Daily Session Reminder** — push notification at user's preferred time
2. **Tap to Session** — notification opens directly into pre-session/session screen
3. **Smart Skip** — don't notify if today's session is already completed

### Your Scope — Social (Phase 6)
1. **Accountability Partners** — invite a friend to see your streaks/progress (read-only)
2. **Teacher Mode** — share progress report as a link or PDF
3. **Community Milestones** — shareable completion cards (juz/khatm)

### Files You Own (create/modify freely)
- `lib/services/push_notification_service.dart` [NEW]
- `lib/services/sharing_service.dart` [NEW] — progress sharing, PDF generation
- `lib/providers/notification_provider.dart` [NEW]
- `lib/providers/social_provider.dart` [NEW]
- `lib/screens/hifz/share_progress_screen.dart` [NEW]
- `lib/screens/hifz/accountability_screen.dart` [NEW]
- `lib/widgets/hifz/milestone_card.dart` [NEW] — shareable completion cards
- `lib/widgets/sheets/notification_settings_sheet.dart` [NEW]

### Files You May Read But NOT Modify
- `lib/providers/hifz_profile_provider.dart` — understand profile/streak data
- `lib/services/hifz_database_service.dart` — understand data model
- `lib/screens/profile_screen.dart` — understand settings UI patterns (but don't edit)

### Notification Implementation Notes
- Use `flutter_local_notifications` package for local push notifications
- Android: use `android_alarm_manager_plus` for exact timing
- iOS: use `flutter_local_notifications` iOS support
- Windows: low priority (notifications mainly for mobile)
- Add notification preferences to SharedPreferences (not SQLite — user setting, not profile data)

### Social Implementation Notes
- Phase 6 is read-only sharing (no backend, no real-time sync)
- "Share with friend" = generate a shareable image or link
- "Teacher mode" = generate a PDF report of recent progress
- Use `pdf` package for PDF generation, `share_plus` for sharing
- NO backend/server required — everything is local/shareable

### Rules
- Auto-run all terminal commands (SafeToAutoRun: true)
- Test on Windows for notification settings UI, but notifications are mobile-only
- Follow existing code style (Provider + ChangeNotifier, Inter font, ThemeProvider)
- Add new packages via `flutter pub add` before using them
