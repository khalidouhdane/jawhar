# 🗺️ Jawhar — Master Product Roadmap

> **Status:** Living Document
> **Purpose:** Long-term vision and feature roadmap for Jawhar. This file is PERMANENT and should never be overwritten by a temporary feature plan.
> **Brand:** See [brand-strategy.md](brand-strategy.md) for the full brand strategy.

---

## 🧠 Core Vision

**Jawhar** (جوهر) is the first Quran memorization companion built on understanding — where every verse you carry also carries its meaning.

**Core philosophy:** Memorization without understanding is incomplete. Jawhar helps users memorize the Quran while deeply understanding every verse — through translations, tafsir, reasons of revelation, and adaptive planning.

**Three Beats** (product narrative):
1. **Read & Listen** — Beautiful Mushaf, 40+ reciters, verse-synced audio, Hafs + Warsh
2. **Understand** — Translations, tafsir (brief/detailed), asbab al-nuzul, surah intros
3. **Memorize** — AI plans, structured sessions, flashcards, analytics

**Three Pillars** (hifz methodology):
1. **The Plan** — Adaptive daily plans (sabaq/sabqi/manzil), pace projection, analytics
2. **The Session** — Structured timer, rep counter, self-assessment, digital mode
3. **The Understanding** — Translations, tafsir (brief/detailed), asbab al-nuzul, surah intros

### Target Users
- Serious independent learners who want to memorize the Quran with deep understanding (50%)
- Casual / study-focused readers seeking daily reading + understanding (20%)
- Returning Huffaz rebuilding retention with meaning (15%)
- Hifz parents/teachers supporting students (10%)
- Exploratory learners using practice cards casually (5%)

### Target Platforms
Windows (primary dev), Android, iOS, Web, macOS, Linux

### Design Language
B&W Vercel-inspired Geist system — "The app disappears. The Quran appears."

---

## ✅ Phase 1: Foundation — *Complete*

- [x] Page-by-page Mushaf reading (604 pages, Madani layout)
- [x] Arabic text rendering with proper line layout (`ReadingCanvas`)
- [x] Chapter list and navigation (`QuranReadingProvider`)
- [x] Multiple reciter support with audio playback
- [x] Full chapter audio with verse seeking (gapless)
- [x] Lock screen / Media Notification controls via `audio_service`
- [x] Contextual overlays (bookmarks, reciter selection, search)
- [x] Advanced Theme Picker (vertical alignment, text alignment, page shadow)
- [x] Bookmarks and reading progress persistence

---

## ✅ Phase 2: Personalization & Daily Practice — *Complete*

- [x] Warsh text integration via CDN & Unicode rendering
- [x] Persistent Rewaya selection with first-launch onboarding
- [x] App Localization (English/Arabic) with auto-detection
- [x] Daily Werd with progress tracking (timer-based page counting, milestone snackbars)
- [x] Werd setup sheet (fixed page range or daily pages mode)
- [x] Home screen (greeting, resume journey hero card, quick access)
- [x] Bottom navigation with 5 tabs (Home, Read, Understand, Practice, Profile)
- [x] Surah search

---

## ✅ Hifz Phase 1-7 — *Complete*

See [hifz-roadmap.md](features/hifz/hifz-roadmap.md) for the detailed phase-by-phase breakdown.

- [x] **Phase 1** — Profile assessment, dashboard, plan generation, sessions, progress tracking, missed-day handling, notifications
- [x] **Phase 2** — Flashcards (6 types), SM-2 SRS engine, mutashabihat import + 4 practice modes
- [x] **Phase 3** — Translation overlay, tafsir sheet (Brief + Detailed + Occasion), asbab al-nuzul, surah intros
- [x] **Phase 4** — Digital session mode, session overlays, mode switching, verse-level audio sync
- [x] **Phase 5** — Adaptive calibration (7 suggestion types), smart notifications, performance analytics
- [x] **Phase 6** — Accountability partners, teacher mode, community milestones
- [x] **Phase 7** — Cloud Backend (Firebase Auth, Firestore sync, desktop OAuth, delete account)

---

## 🏆 HACKATHON SPRINT (Deadline: May 20, 2026)

**Quran Foundation Hackathon** — $10K prize pool, 7 winners.
**Brand:** Jawhar — *Memorize with Meaning*

- [ ] Integrate **User APIs**: Bookmarks, Streaks, Goals, Reading Sessions
- [ ] **OAuth2 PKCE** flow for user authentication
- [ ] Geist Design System migration (B&W visual overhaul)
- [ ] Polish UI/UX for 2-3 min demo video
- [ ] All UI copy follows [brand-strategy.md](brand-strategy.md)

---

## 🔮 Phase 8: Post-Hackathon

- [ ] AI-powered Hifz assessment
- [ ] Ramadan mode
- [ ] Story mode (narrative Quran exploration)
- [ ] Offline audio caching
- [ ] Android/iOS home screen widgets
