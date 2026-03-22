# ⚙️ Core Engine — Mini Roadmap

> **Scope:** Profiles, Assessment, Plan Generation, Session Engine, Progress Tracking, Dashboard.
> This is the beating heart of the Hifz module. Everything else builds on top of it.

---

## Status Summary

| Component | Status | Notes |
|---|---|---|
| Profiles & Assessment | ✅ Done | Summary screen, pre-populate on retake, delete/reset/switch |
| Plan Generation | ✅ Done | Page-level + verse-level carry-over, daily goal info |
| Session Engine | ✅ Done | Timer, reps, coverage dialog with verse picker, multi-session |
| Progress Tracking | ✅ Done | Session history, Surahs tab, quick stats, pace, est. completion |
| Dashboard | ✅ Done | Plan card, extra session CTA, profile switcher, error recovery |
| Missed Day Handling | ✅ Done | Matches spec |

---

## All Tasks — COMPLETE ✅

- **CE-1** ✅ Assessment Summary (2-axis chart, load table, timeline)
- **CE-2** ✅ Multi-Session Day Support (extra session CTA, session count)
- **CE-3** ✅ Actual Progress Reporting (coverage dialog, multi-page saves)
- **CE-4** ✅ Session History Screen (date-grouped, weekly stats)
- **CE-5** ✅ Progress Enhancements (quick stats, Surahs tab, session history link)
- **CE-6** ✅ Dashboard Polish (CTA flicker fix, session count badge, error recovery)
- **CE-7** ✅ Critical Bug Fixes (timer, plan state, session completion)
- **CE-8** ✅ Rich Plan Card (daily goal, time allocation, page numbers)
- **CE-9** ✅ Verse-Level Tracking (DB v3, partial page carry-over, verse picker)
- **CE-10** ✅ Progress Widget Enrichment (juz bar, pace, streak, last session)
- **CE-11** ✅ Profile Management (retake, reset, delete with confirmations)

---

## Key Files

| File | Purpose |
|---|---|
| [session_screen.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/screens/hifz/session_screen.dart) | Session UI — timer, verse coverage picker |
| [session_provider.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/providers/session_provider.dart) | Active session state — verse tracking |
| [plan_provider.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/providers/plan_provider.dart) | Plan state — error state, retry |
| [plan_generation_service.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/services/plan_generation_service.dart) | Plan pipeline — partial page carry-over |
| [plan_card.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/widgets/hifz/plan_card.dart) | Dashboard plan widget — daily goal info |
| [progress_card.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/widgets/hifz/progress_card.dart) | Dashboard progress widget — enrichment |
| [progress_detail_screen.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/screens/hifz/progress_detail_screen.dart) | Pages + Surahs tabs, quick stats |
| [home_screen.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/screens/home_screen.dart) | Dashboard — retry card, profile switcher |
| [hifz_database_service.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/services/hifz_database_service.dart) | SQLite — v3 with verse columns |
| [hifz_models.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/models/hifz_models.dart) | Data models — verse tracking fields |
| [profile_screen.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/screens/profile_screen.dart) | Profile settings — delete/reset/retake |
