# Hifz Program — Master Roadmap

> **Philosophy:** Plan the entire journey — MVP through final product. Each phase's architecture must accommodate later additions. No rewrites — only extensions.

---

## Document Index

All feature documentation lives in `docs/features/hifz/`:

| Category | File | What It Covers |
|---|---|---|
| **Navigation** | [app-navigation.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/app-navigation.md) | Dashboard layouts, 5-tab bottom nav, progress visualization |
| **User Journeys** | [user-flows.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/user-flows.md) | 12 user flows, 5 personas, edge cases, daily rhythm |
| **Profiles** | [profile-model.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/memory-profiles/profile-model.md) | Data model, multi-profile architecture, SQLite storage |
| **Assessment** | [assessment-flow.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/memory-profiles/assessment-flow.md) | 9-screen onboarding wizard, memory 2-axis assessment |
| **Framework** | [methods-overview.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/methods-and-planning/methods-overview.md) | Unified Sabaq-Sabqi-Manzil framework, profile-tuned parameters |
| **Sessions** | [session-design.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/methods-and-planning/session-design.md) | Physical-first session UX, control panel, self-assessment |
| **Planning** | [plan-generation.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/methods-and-planning/plan-generation.md) | Profile → daily schedule pipeline, adaptive calibration |
| **Flashcards** | [flashcard-system.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/practice-tools/flashcard-system.md) | 6 card types, SM-2 SRS engine, deck rules |
| **Mutashabihat** | [mutashabihat.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/practice-tools/mutashabihat.md) | 4 practice modes, GitHub dataset, integration triggers |
| **Research: Struggles** | [hifz-struggles.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/research/hifz-struggles.md) | 11 struggles with solutions (120+ sources) |
| **Research: Context** | [context-aware-memorization.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/research/context-aware-memorization.md) | Tafsir, asbab al-nuzul, competitor analysis |

---

## Locked Decisions

| Decision | Answer |
|---|---|
| Architecture | One unified framework (Sabaq-Sabqi-Manzil), not separate methods |
| Primary session mode | Physical Quran (default), digital reading (secondary) |
| Session flexibility | Maximum — skip, override, end early, mark offline |
| Plan adaptation | Suggest, never auto-adjust |
| Profile creation | Optional — user explores first |
| Multiple profiles | Yes — household use |
| Bottom nav | Dashboard / Practice / Read / Listen / Profile |
| Home screen | Hifz Dashboard (CTA for users without profile) |
| Werd system | Separate from hifz (for now) |
| Progress visualization | Pages primary, Juz indicators, Surah tab |
| Starting point | Full freedom with suggestions |
| Data storage | SQLite |
| Tafsir source | Quran.com API + Tafsir al-Muyassar |

---

## Phase 1 — Foundation (MVP Core) ✅

> **Goal:** The bones of the framework, the dashboard, and one working session mode.

### 1.1 Data Layer & Profiles
- [x] Migrate hifz data from SharedPreferences to **SQLite**
- [x] Implement `MemoryProfile` data model with all fields
  - 📄 Reference: [profile-model.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/memory-profiles/profile-model.md)
- [x] Multi-profile table: `profiles`, `progress_records`, `session_history`
- [x] Profile CRUD operations (create, read, update, delete)
- [x] Active profile switching

### 1.2 Assessment Wizard
- [x] Build 9-screen onboarding flow
  - 📄 Reference: [assessment-flow.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/memory-profiles/assessment-flow.md)
  - Screens: Welcome → Age → Learning Preference → Encoding Speed → Retention → Schedule + Goal → Reciter → Starting Point → Summary
- [x] Profile-to-parameter mapping (encoding × retention → framework params)
  - 📄 Reference: [plan-generation.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/methods-and-planning/plan-generation.md) § Step 1

### 1.3 Framework Engine & Plan Generation
- [x] Implement daily plan generation: Sabaq + Sabqi + Manzil assignments
  - 📄 Reference: [methods-overview.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/methods-and-planning/methods-overview.md)
  - 📄 Reference: [plan-generation.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/methods-and-planning/plan-generation.md) § Steps 2-4
- [x] Manzil auto-rotation across completed juz (user can add/remove)
- [x] Daily schedule JSON structure persisted in SQLite
- [x] Plan override: user can edit today's assigned content
- [x] Offline marking: "I already did this" (individual phase or all)

### 1.4 Dashboard (Home) Redesign
- [x] Replace current Home screen with Hifz Dashboard
  - 📄 Reference: [app-navigation.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/app-navigation.md) § Dashboard Layout
  - 📄 Reference: [user-flows.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/user-flows.md) § Flow 3
- [x] **With profile:** Today's Plan card, Progress card, Werd card, Ayah of the Day
- [x] **Without profile:** CTA card ("Start Your Hifz Journey"), Werd, Ayah
- [x] Profile selector (quick switch)

### 1.5 Session Screen — Physical Quran Mode
- [x] Pre-session screen: plan review, offline marking, estimated time
  - 📄 Reference: [session-design.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/methods-and-planning/session-design.md) § Pre-Session
  - 📄 Reference: [user-flows.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/user-flows.md) § Flow 4
- [x] Control panel: timer, rep counter, audio controls, step indicator
  - 📄 Reference: [session-design.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/methods-and-planning/session-design.md) § Physical Quran Mode
- [x] Phase progression: Sabaq → Sabqi → Manzil (skippable, reorderable)
- [x] Self-assessment after each phase (Strong / Okay / Needs Work)
- [x] Session complete screen with summary + tomorrow's preview
- [x] Session state persistence (pause and resume)

### 1.6 Progress Tracking
- [x] Page-level progress storage (memorized / learning / reviewing / not started)
- [x] Juz-level progress bars (% indicator)
- [x] Progress detail screen with Pages (default) and Surahs tabs
  - 📄 Reference: [user-flows.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/user-flows.md) § Flow 7
  - 📄 Reference: [app-navigation.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/app-navigation.md) § Progress Visualization
- [x] Active day streak counter (total, not consecutive)

### 1.7 Bottom Navigation Revamp
- [x] Restructure to 5 tabs: Dashboard / Practice / Read / Listen / Profile
  - 📄 Reference: [app-navigation.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/app-navigation.md) § Bottom Navigation
- [x] Keep existing Read screen functionality intact
- [x] Keep existing Audio screen as Listen tab
- [x] Practice tab: placeholder with "Coming in next update" (or basic structure)
- [x] Profile tab: settings, profile management, reassessment option

### 1.8 Missed Day Handling
- [x] Detect missed days on app open
- [x] Show compassionate re-entry screen: review-only suggestion
  - 📄 Reference: [user-flows.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/user-flows.md) § Flow 5 (Missed Days)
- [x] User can accept suggestion, continue normal plan, or customize

### 1.9 Notifications
- [x] Daily session reminder at user's preferred time
- [x] Tap notification → opens directly into pre-session screen
  - 📄 Reference: [user-flows.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/user-flows.md) § Flow 12
- [x] Smart: skip notification if session already completed today

---

## Phase 2 — Practice Tools ✅

> **Goal:** Flashcards + mutashabihat to strengthen retention.

### 2.1 Flashcard System
- [x] Implement all 6 card types
  - 📄 Reference: [flashcard-system.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/practice-tools/flashcard-system.md) § Card Types
  - Types: Verse Completion, Next Verse, Previous Verse, Connect Sequence, Surah Detective, Mutashabihat Duel
- [x] SM-2 SRS engine (interval × rating modifier)
  - 📄 Reference: [flashcard-system.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/practice-tools/flashcard-system.md) § SRS Engine
- [x] Deck generation from memorized content (never from un-memorized)
  - 📄 Reference: [flashcard-system.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/practice-tools/flashcard-system.md) § Deck Rules
- [x] Practice tab UI: cards due count, start review, accuracy stats
  - 📄 Reference: [user-flows.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/user-flows.md) § Flow 6

### 2.2 Mutashabihat Practice
- [x] Import `Waqar144/Quran_Mutashabihat_Data` JSON dataset
  - 📄 Reference: [mutashabihat.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/practice-tools/mutashabihat.md) § Data Source
- [x] Enrich with category/difficulty metadata
- [x] Implement 4 practice modes:
  - 📄 Reference: [mutashabihat.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/practice-tools/mutashabihat.md) § Digital Practice Modes
  - Modes: Spot the Difference, Context Anchoring, Quick Quiz, Collection Browse
- [x] Integration triggers: alert during memorization, inject into flashcard deck
  - 📄 Reference: [mutashabihat.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/practice-tools/mutashabihat.md) § When to Surface

### 2.3 Dashboard Integration
- [x] "X cards due" indicator on Dashboard → Today's Plan card
- [x] Quick flashcard round at end of sessions (optional)
- [x] Practice tab fully populated with flashcards + mutashabihat sections

---

## Phase 3 — Context-Aware Content ✅

> **Goal:** Understanding aids memorization — translations, tafsir, and context.

### 3.1 Translation Overlay
- [x] Show verse translations during sessions (Quran.com API, already integrated)
- [x] Toggle on/off per user preference
  - 📄 Reference: [context-aware-memorization.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/research/context-aware-memorization.md) § Pillar 1

### 3.2 Brief Tafsir
- [x] Integrate Tafsir al-Muyassar via Quran.com API
- [x] "Meaning" button during sessions → shows brief tafsir for current verse
- [x] "Detailed" button → shows scholar-level tafsir
  - 📄 Reference: [context-aware-memorization.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/research/context-aware-memorization.md) § Tafsir

### 3.3 Asbab al-Nuzul
- [x] Import sample from `mostafaahmed97/asbab-al-nuzul-dataset` (JSON per surah)
- [x] "Context" card during sessions → shows reason for revelation (when available)
  - 📄 Reference: [context-aware-memorization.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/research/context-aware-memorization.md) § Asbab al-Nuzul

### 3.4 Surah Introduction
- [x] Thematic overview before starting a new surah in Sabaq phase
- [x] Meccan/Medinan classification, key themes, key stories
  - 📄 Reference: [context-aware-memorization.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/research/context-aware-memorization.md) § Quranic Stories

---

## Phase 4 — Digital Session Mode ✅

> **Goal:** Full in-app reading experience during sessions.

### 4.1 Scoped Reading Canvas
- [x] Restrict reading canvas to assigned content only during sessions
- [x] Re-use existing `ReadingCanvas` widget with scoping layer
  - 📄 Reference: [session-design.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/methods-and-planning/session-design.md) § Digital Reading Mode

### 4.2 Session Overlays
- [x] Floating timer, rep counter, phase indicator on reading canvas
- [x] Step navigation (skip/done) as bottom overlay

### 4.3 Mode Switching
- [x] Toggle physical ↔ digital mid-session
- [x] State persists across switches (reps, timer, phase position)

### 4.4 Verse-level Audio Sync
- [x] Highlight active verse during audio playback in session
- [x] Use existing audio timing data from Quran.com API

---

## Phase 5 — Adaptive Intelligence ✅

> **Goal:** Smart plan adjustments based on real performance data.

### 5.1 Adaptive Calibration
- [x] Weekly pattern analysis: completion rate, self-assessment distribution
  - 📄 Reference: [plan-generation.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/methods-and-planning/plan-generation.md) § Adaptive Adjustment
- [x] Suggestion cards on dashboard (increase/decrease load, adjust review)
  - 📄 Reference: [user-flows.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/user-flows.md) § Flow 10
- [x] User accepts or dismisses — nothing changes automatically

### 5.2 Smart Notifications
- [x] "You haven't reviewed Juz 30 in 5 days" reminders
- [x] Struggle detection: consistently weak sections → add flashcards automatically

### 5.3 Performance Analytics
- [x] Weekly/monthly hifz reports (pages memorized, retention rate, streaks)
- [x] Progress pace calculation ("At this pace, you'll finish in X months")
- [x] Historical comparison ("This month vs. last month")

---

## Phase 6 — Social & Accountability ✅

> **Goal:** Community-driven motivation and shared progress.

### 6.1 Accountability Partners
- [x] Invite friend to see your streaks and progress
- [x] Mutual encouragement — no ranking, just visibility

### 6.2 Teacher Mode
- [x] Share progress report with a teacher/mentor via link or PDF
- [x] Teacher can optionally assign specific content

### 6.3 Community Milestones
- [x] Celebrate juz/khatm completions with shareable cards
- [x] Optional, opt-in leaderboards for competitive motivation

---

## Phase 7 — Advanced Features (Long-term Vision)

> **Goal:** Aspirational features for the complete Quran learning platform.

### 7.1 AI-Powered Features
- [ ] AI assessment: analyze recitation quality via microphone
- [ ] AI-powered adaptive suggestions (smarter than rule-based)
- [ ] Personalized review recommendations

### 7.2 Extended Content
- [ ] Full multi-tafsir support (multiple scholarly sources, user picks)
- [ ] Complete asbab al-nuzul database with English translation
- [ ] Story Mode — narrative walkthroughs of Quranic stories
- [ ] Tafsir Cards — contextual cards during review
- [ ] Reflection Prompts — meaning questions during manzil
  - 📄 Reference: [context-aware-memorization.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/research/context-aware-memorization.md) § Digital Integration

### 7.3 Advanced Practice
- [ ] Mind-map visualization — thematic verse connections (inspired by ITQAN app)
- [ ] Recording/playback — record yourself, compare with reciter (Audio Mirror)
  - 📄 Reference: [hifz-struggles.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/features/hifz/research/hifz-struggles.md) § Struggle 11

### 7.4 Platform Features
- [ ] Offline audio caching — download recitations for offline sessions
- [ ] Cloud sync — backup progress across devices
- [ ] Ramadan mode — heavier manzil rotation, lighter sabaq

---

## Architecture Principle

> Every phase **extends** the previous — no rewrites.

| Component | Phase 1 Creates | Later Phases Extend |
|---|---|---|
| Data layer | SQLite + profile + plan + progress | Add SRS tables, flashcard decks, tafsir cache |
| Session engine | Physical control panel | Add digital canvas (P4), AI grading (P7) |
| Dashboard | Today's plan + progress | Add card counts (P2), analytics (P5) |
| Content | Verse text + audio | Add translations (P3), tafsir (P3), stories (P7) |
| Navigation | 5 tabs: Dashboard/Practice/Read/Listen/Profile | Add analytics view (P5), social tab (P6) |
| Practice | Placeholder tab | Flashcards + SRS (P2), mutashabihat (P2) |

---

## External Datasets

| Dataset | Phase | Source |
|---|---|---|
| Mutashabihat pairs | Phase 2 | [Waqar144/Quran_Mutashabihat_Data](https://github.com/Waqar144/Quran_Mutashabihat_Data) (JSON, Dart, free) |
| Asbab al-Nuzul | Phase 3 | [mostafaahmed97/asbab-al-nuzul-dataset](https://github.com/mostafaahmed97/asbab-al-nuzul-dataset) (JSON, MIT) |
| Translations | Phase 3 | Quran.com API (already integrated) |
| Tafsir al-Muyassar | Phase 3 | Quran.com API (available endpoint) |
