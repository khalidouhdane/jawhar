# Stitch Design Brief — Le Quran Hifz Program

> **Use this prompt alongside the combined documentation file (`all-hifz-docs-combined.md`) to ideate the UI/UX for the Hifz memorization program in Le Quran.**

---

## What This App Is

**Le Quran** is a Flutter mobile/desktop Quran reading app. We're building its biggest feature: a personalized Quran memorization (Hifz) program that adapts to each user's unique memory profile, daily schedule, and learning preferences.

Think of it as **a personal Hifz coach that lives in your pocket** — it builds your daily plan, guides your sessions, strengthens your weak spots with flashcards, and never makes you feel guilty for missing a day.

---

## The Core Experience (What to Design)

### 1. The Dashboard (Home Screen)
The app's home screen IS the hifz dashboard. It shows:
- **Today's Plan** — what the user needs to do today (new memorization + review + flashcards)  
- **Progress** — juz-level bars + page count + active day streak  
- **Start Session** button — the primary CTA  
- **Werd** — separate daily reading goal (non-hifz)  
- For users without a profile: a beautiful CTA card inviting them to create one  

**Bottom nav tabs:** Dashboard / Practice / Read / Listen / Profile

### 2. The Assessment Wizard (9 Screens)
A warm, conversational onboarding that creates a Memory Profile:
1. Welcome — name + avatar
2. Age group — child/teen/adult
3. Learning preference — visual/auditory/writing/repetition
4. Encoding speed — "How much of a page do you remember after 30 min?"
5. Retention — "Think of something you memorized last month..."
6. Schedule + Goal — daily time slider + goal (full Quran / specific juz / specific surahs)
7. Default reciter — pick one Qari for all sessions
8. Starting point — where in the Quran to begin (suggestions + full freedom)
9. Summary — your profile visualized on a 2-axis chart + framework parameters + timeline

Design principles: feels like a conversation, not an exam. No wrong answers. Beautiful illustrations. Under 3 minutes.

### 3. The Session Screen (Physical Quran Mode — Primary)
The user reads from their physical Quran. The **app is a guide and timer**, not the reading surface:
- **Clean control panel:** big timer, repetition counter (tap to increment), audio controls
- **Phase indicator:** Sabaq (new) → Sabqi (recent review) → Manzil (old review)
- **After each phase:** simple self-assessment (Strong / Okay / Needs Work)
- Maximum flexibility: skip phases, end early, override content, mark as done offline

There's also a **pre-session screen** where the user reviews today's plan and can mark things as already done, plus a **session complete screen** with a summary.

### 4. The Practice Tab
Dedicated tab with two sections:
- **Flashcards** — 6 card types testing memorized content (Verse Completion, Next Verse, Previous Verse, Connect Sequence, Surah Detective, Mutashabihat Duel). Uses spaced repetition.
- **Mutashabihat** — practice with similar-looking verses. 4 modes: Spot the Difference, Context Anchoring, Quick Quiz, Collection Browse.

### 5. Progress Visualization
- **Default: Pages** with juz bars (Juz 30: 95%, Juz 29: 40%...)
- **Page grid heatmap** (like GitHub contributions) — green/yellow/blue/grey
- **Surah tab** for alternate view
- Active day streak, estimated completion date

### 6. Missed Day / Return After Break
Compassionate design. When the user returns after missing days:
- Warm "Welcome back!" message
- Suggests a review-only session to ease back in
- Never guilt. Never penalties. The streak counts total active days, not consecutive.

---

## Design Philosophy

1. **Islamic aesthetic, premium feel** — not gamified or childish. This is sacred text. Design should feel respectful, calm, and beautiful. Dark/warm/classic themes exist in the app already.
2. **Physical Quran first** — the app is a companion to the physical mushaf, not a replacement. The session screen is a control panel, not a reader.
3. **Compassionate UX** — no guilt for missed days. Flexible schedules. Warm language. The journey matters more than the streak.
4. **One framework, not menus** — users don't pick a "method." The app auto-tunes parameters based on their profile. Simple for the user, powerful under the hood.
5. **Effortless daily rhythm** — open app → see plan → start session → done. Minimal friction.

---

## User Personas

| Persona | Who | Daily Routine |
|---|---|---|
| **The Beginner** | Never memorized, starting with Juz 'Amma | 15-30 min after Fajr |
| **The Returnee** | Memorized as a child, wants to rebuild | 30-60 min, rebuilding habit |
| **The Committed** | Active student, maybe with a teacher | 1-4 hours, structured |
| **The Casual Reader** | Just wants to read/listen, no hifz | Uses Read/Listen tabs only |
| **The Parent** | Sets up profiles for children | Manages multiple profiles |

---

## Key Screens to Design

1. **Dashboard** (with profile / without profile variants)
2. **Assessment wizard** (9 screens — conversational, illustrative)
3. **Pre-session screen** (plan review, offline marking)
4. **Session control panel** (timer, reps, audio, phase nav)
5. **Self-assessment** (post-phase, 3 options)
6. **Session complete** (summary, tomorrow preview)
7. **Practice tab** (flashcards section + mutashabihat section)
8. **Flashcard card** (front/back, rating buttons)
9. **Mutashabihat: Spot the Difference** (side-by-side verses)
10. **Progress detail** (juz bars, page grid, stats)
11. **Missed day re-entry** (welcome back, suggestions)
12. **Profile management** (switch, add, edit profiles)

---

## What Already Exists in the App

- Full Quran reading screen (604 pages, Arabic text rendering)
- Audio playback with verse-level synchronization
- Multiple reciter support (Hafs + Warsh)
- Werd (daily reading goal) tracking
- Dark/warm/classic themes
- Bookmarks, surah index, search
- Home screen with greeting, hero card, ayah of the day
- 5-tab bottom navigation
- In-app self-update system

The hifz program builds ON TOP of these existing features. The reading canvas and audio system are already built — sessions can leverage them.

---

## Technical Notes

- **Platform:** Flutter (mobile + desktop)
- **State management:** Provider
- **Data:** SQLite for hifz, SharedPreferences for settings
- **Audio:** audioplayers + audio_service (background playback)
- **API:** Quran.com Foundation API (v4) for verse data, translations, tafsir
- **Fonts:** Google Fonts (Inter, etc.) + Arabic text rendering
- **Icons:** Lucide Icons

---

## What We Need From Stitch

We're looking for **UI/UX ideation** — explore different visual approaches for these screens. The app already has a premium dark theme aesthetic. We want to see creative takes on:
- How to present the daily plan compellingly
- The session control panel layout (it's used daily — must feel effortless)
- Flashcard and practice interactions
- Progress visualization that's motivating
- The assessment wizard experience (conversational, warm)
- How to handle the "missed day" moment with grace
