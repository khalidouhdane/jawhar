# Session Design — Physical-First

> **Default mode:** Physical Quran. The app is a **guide, timer, and tracker** — not the reading surface.  
> **Secondary mode:** Digital reading. The app's reading canvas shows the assigned content.

---

## Session Flow

```
Start Session (Dashboard or Notification)
    │
    ├─ Confirm today's plan (or override)
    │
    ├─ Phase 1: SABAQ ──────┐
    │   New memorization     │  User controls:
    │                        │  - Timer
    ├─ Phase 2: SABQI ──────┤  - Rep counter
    │   Recent review        │  - Audio
    │                        │  - Skip/Done
    ├─ Phase 3: MANZIL ─────┤  - End early
    │   Long-term review     │
    │                        │
    ├─ Optional: FLASHCARDS ─┘
    │
    └─ Session Complete → Self-assessment → Dashboard
```

---

## Session Entry

| Entry Point | Behavior |
|---|---|
| Dashboard "Start Session" button | Opens session with today's plan pre-loaded |
| Notification tap | Opens directly into session |
| Override | User can change what to work on before starting |

---

## Pre-Session Screen

Before entering the session, the user sees:

```
┌────────────────────────────────────────┐
│  Today's Plan          [Edit Plan ✎]  │
│                                        │
│  📖 Sabaq:  Page 45 (Al-Baqarah)      │
│  🔄 Sabqi:  Pages 40-44 (last 5 days) │
│  📚 Manzil: Juz 30, Pages 582-587     │
│  🃏 Cards:  12 due                     │
│                                        │
│  ☑ I already did Sabaq offline         │
│  ☑ I already did Sabqi offline         │
│                                        │
│         [ Start Session ▶ ]            │
│                                        │
│  ⏱ Estimated time: 35 min             │
└────────────────────────────────────────┘
```

- Checkboxes for "I already did this" (individual or all)
- Edit plan button to override assigned content
- Estimated time based on profile

---

## Physical Quran Mode — Control Panel

The core session screen when using a physical Quran:

```
┌────────────────────────────────────────┐
│  SABAQ · Page 45 · Al-Baqarah         │
│  ─────────────────────────────────     │
│                                        │
│           ⏱  04:32                     │
│        Repetition: 7 / 10             │
│                                        │
│         ┌───────────┐                  │
│         │   + REP   │  ← Tap to count │
│         └───────────┘                  │
│                                        │
│  ◀◀   ▶ Play Audio   ▶▶   🔁          │
│                                        │
│  ─────────────────────────────────     │
│  Step 1 of 3   [ Skip → ]  [ Done ✓ ] │
└────────────────────────────────────────┘
```

### Elements
| Element | Purpose |
|---|---|
| Phase indicator | Shows current phase (Sabaq/Sabqi/Manzil) + content info |
| Timer | Counts up from start, or counts down from target time |
| Rep counter | Tap to increment. Shows current / minimum target |
| Audio controls | Play assigned reciter at correct position |
| Step indicator | Phase 1/2/3, skip button, done button |

---

## Digital Reading Mode

When user switches to digital, the reading canvas shows:

```
┌────────────────────────────────────────┐
│  SABAQ · Page 45                       │
│  ─────────────────────────             │
│                                        │
│  ┌──────────────────────────────┐      │
│  │                              │      │
│  │   [Arabic text of page 45]   │      │
│  │   Only assigned content      │      │
│  │   Verse highlighting active  │      │
│  │                              │      │
│  └──────────────────────────────┘      │
│                                        │
│  ⏱ 04:32  Rep: 7/10  ▶ Audio         │
│  Step 1/3   [ Skip ]   [ Done ✓ ]     │
└────────────────────────────────────────┘
```

- **Scoped:** Only assigned pages visible (no scrolling to unassigned content)
- **Reading canvas** re-used from existing reading screen
- **Floating controls** overlay at bottom (timer, rep counter, audio, nav)

---

## Self-Assessment (End of Phase)

After each phase, a quick self-check:

```
┌────────────────────────────────────────┐
│  How did your Sabaq go?                │
│                                        │
│  😊 Strong — I can recite fluently     │
│  😐 Okay — Some hesitation             │
│  😟 Weak — I need more time            │
│                                        │
│  [ Continue to Sabqi → ]               │
└────────────────────────────────────────┘
```

- 3 simple options, no friction
- Feeds into SRS and adaptive calibration
- Not graded — compassionate language

---

## Session Complete

```
┌────────────────────────────────────────┐
│  ✨ Session Complete                   │
│                                        │
│  📖 Sabaq:  Page 45 ✓                 │
│  🔄 Sabqi:  5 pages reviewed ✓        │
│  📚 Manzil: 6 pages reviewed ✓        │
│  🃏 Cards:  12/12 done ✓              │
│                                        │
│  ⏱ Total time: 38 min                 │
│  🔥 Day 14 active                      │
│                                        │
│  [ Back to Dashboard ]                 │
└────────────────────────────────────────┘
```

---

## Flexibility Rules

| Action | Supported? |
|---|---|
| Skip any phase | ✅ |
| Increase time mid-session | ✅ |
| Reduce time mid-session | ✅ |
| End session early | ✅ |
| Override today's content | ✅ |
| Mark phases as done offline | ✅ (from pre-session screen) |
| Reorder phases | ✅ (do tasks in any order) |
| Pause and resume later | ✅ (session saves state) |
