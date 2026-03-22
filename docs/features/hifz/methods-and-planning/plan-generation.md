# 📅 Plan Generation — Profile → Personalized Daily Plan

> **Purpose:** Define how the assessment results translate into a concrete memorization plan with scheduling, customization, and adaptive adjustment.

---

## The Plan Generation Pipeline

```
Assessment → Profile → Framework Parameters → Daily Schedule → Adaptive Calibration
```

---

## Step 1: Profile → Framework Parameters

The assessment tunes the Sabaq-Sabqi-Manzil framework:

| Encoding | Retention | Key Parameters |
|---|---|---|
| Fast | Strong | Large daily load (1 page), fewer reps (5-7), lighter sabqi |
| Fast | Fragile | Large daily load, more reps (10+), audio-first emphasis, heavy sabqi |
| Moderate | Strong | Medium load (0.5 page), standard reps (7-10) |
| Moderate | Moderate | Medium load, standard reps, balanced phases |
| Moderate | Fragile | Medium load, high reps (10-15), heavier manzil rotation |
| Slow | Strong | Small load (3-5 lines), fewer reps, page-visual emphasis |
| Slow | Moderate | Small load, standard reps, extra sabqi days |
| Slow | Fragile | Smallest load (2-3 lines), highest reps (15+), heaviest review |

No method selection — the framework parameters auto-adjust to the profile.

---

## Step 2: Profile + Time → Plan Parameters

### Daily New Material (Sabaq Load)

| Daily Time | Encoding Speed | Daily Sabaq |
|---|---|---|
| 15-30 min | Fast | 5-8 lines |
| 15-30 min | Moderate | 3-5 lines |
| 15-30 min | Slow | 2-3 lines |
| 1 hour | Fast | 0.5-1 page |
| 1 hour | Moderate | 5-8 lines |
| 1 hour | Slow | 3-5 lines |
| 2 hours | Fast | 1-2 pages |
| 2 hours | Moderate | 0.5-1 page |
| 2 hours | Slow | 5-8 lines |
| 4+ hours | Fast | 2-3 pages |
| 4+ hours | Moderate | 1-2 pages |
| 4+ hours | Slow | 0.5-1 page |

### Time Distribution Across Phases

| Daily Time | Sabaq | Sabqi | Manzil | Flashcards |
|---|---|---|---|---|
| 15 min | 8 min | 5 min | 2 min | — |
| 30 min | 15 min | 10 min | 5 min | — |
| 1 hour | 25 min | 15 min | 15 min | 5 min |
| 2 hours | 45 min | 30 min | 35 min | 10 min |
| 4 hours | 90 min | 45 min | 75 min | 30 min |

---

## Step 3: Goal → Timeline Calculation

### Full Quran (604 pages)

| Daily Load | Timeline |
|---|---|
| 3 lines/day | ~10 years |
| 5 lines/day | ~6 years |
| 0.5 page/day | ~3.5 years |
| 1 page/day | ~2 years |
| 2 pages/day | ~1 year |
| 3 pages/day | ~8 months |

### Specific Juz (20 pages each)

| Daily Load | Per Juz |
|---|---|
| 3 lines/day | ~4 months |
| 0.5 page/day | ~6 weeks |
| 1 page/day | ~3 weeks |

Timeline shown to user as: "At your pace, you'll reach your goal in approximately **X months**"

---

## Step 4: Daily Schedule Generation

Each day, the app generates a schedule:

```json
{
  "date": "2026-03-20",
  "profileId": "uuid",
  "sabaq": {
    "surahId": 2,
    "pageNumber": 3,
    "lineStart": 5,
    "lineEnd": 8,
    "targetMinutes": 25,
    "repetitionTarget": 10
  },
  "sabqi": [
    {
      "surahId": 1,
      "pageNumber": 1,
      "memorizedDate": "2026-03-17",
      "daysSince": 3,
      "targetMinutes": 15
    }
  ],
  "manzil": {
    "juzNumber": 30,
    "pagesAssigned": [582, 583, 584, 585, 586, 587],
    "rotationDay": 3,
    "targetMinutes": 15
  },
  "flashcards": {
    "enabled": true,
    "targetMinutes": 5,
    "deckSource": "memorized"
  }
}
```

---

## Customization Options

Users can always adjust:

| Setting | Range | Effect |
|---|---|---|
| Daily time | 15 min – 4+ hours | Adjusts all load calculations |
| Rest days | 0-3 per week | Extends timeline proportionally |
| Sabaq pace | Manual override | "I want to do 1 page/day no matter what" |
| Start point | Any page/surah | "I've already memorized Juz 30, start from Juz 29" |
| Manzil rotation | Add/remove juz | Control which completed juz are in the rotation |
| Flashcard time | 0-30 min/day | Adds practice time |

---

## Adaptive Adjustment

### Weekly Check (Automatic)
After each week, the system evaluates:
- Session completion rate (did they complete most days?)
- Self-assessment distribution (mostly strong? mostly weak?)
- Actual vs. planned material covered

### Adjustment Actions (Suggest, Never Auto-Adjust)

| Signal | Suggestion Shown |
|---|---|
| Completing consistently, mostly "Strong" | "🌟 You're doing great! Want to increase your daily load?" |
| Missing sessions frequently | "💡 Looks like things have been busy. Want to reduce your daily plan?" |
| Mostly "Weak" assessments | "💪 Consider reviewing more before adding new material. Reduce daily load?" |
| Ahead of schedule | "🎉 You're ahead! Keep going or take an extra review day?" |

> **Rule:** All adjustments are **suggestions**. The user accepts or dismisses. Nothing changes automatically.

### No Penalties
- Streak counts **total active days**, not consecutive
- Progress bar never goes backward
- Missed days silently absorbed — plan recalculates
- Returning after a gap triggers a gentle review-first session
