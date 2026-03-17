# 📊 Werd Tracking — Feature Roadmap

> **Status:** ✅ Complete (Phase 2)
> **Files:** `werd_provider.dart`, `werd_models.dart`, `werd_card.dart`, `werd_setup_sheet.dart`

---

## ✅ Completed

- [x] Two werd modes: Fixed Page Range and Daily Pages
- [x] Timer-based page counting (5-second dwell time per page)
- [x] Session deduplication via `Set<int>` of counted pages
- [x] Auto-daily-reset based on `lastResetDate`
- [x] Milestone Snackbars at 50%, 80%, 100%, >100%
- [x] Werd setup sheet with slider and summary preview
- [x] Home screen werd card (empty state + active progress)
- [x] Persistence via `SharedPreferences` (JSON-encoded `WerdConfig`)

## 📋 Planned Enhancements

- [ ] Werd completion history (track daily completion over time)
- [ ] Streak tracking for werd completion
- [ ] Weekly/monthly werd statistics
- [ ] Notification reminders for daily werd
