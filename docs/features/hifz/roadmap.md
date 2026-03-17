# 🧠 Hifz (Memorization) — Feature Roadmap

> **Status:** ✅ Foundation Complete (Phase 2)
> **Files:** `hifz_provider.dart`, `hifz_models.dart`, `hifz_screen.dart`

---

## ✅ Completed

- [x] Per-surah memorization status tracking (None → Learning → Reviewing → Memorized)
- [x] Review count and last-reviewed date per surah
- [x] Daily streak tracking (`StreakData`)
- [x] Hifz screen with surah status overview
- [x] Persistence via `SharedPreferences` (pipe-delimited string per surah)

## 📋 Planned Enhancements

- [ ] Spaced repetition scheduling (automated review reminders)
- [ ] Mutashabihat (similar verses) grouping and practice
- [ ] Audio-based self-test mode (listen without text, then check)
- [ ] Per-ayah memorization granularity (not just per-surah)
- [ ] Statistics dashboard (memorized percentage, review calendar)
- [ ] Integration with Werd (count hifz review pages toward werd goal)
