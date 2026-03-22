# App Navigation — Hifz-Centric Redesign

> **Decision:** Home becomes the Hifz Dashboard. Bottom nav gets revamped entirely.

---

## Dashboard (Home) — Layout

### For users WITH a profile:
```
┌──────────────────────────────────────┐
│  Assalamu Alaykum, Khalid  ☀️       │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  TODAY'S PLAN                │    │
│  │  📖 Sabaq: Page 45          │    │
│  │  🔄 Sabqi: Pages 40-44      │    │
│  │  📚 Manzil: Juz 30 (6 pgs)  │    │
│  │  🃏 12 cards due             │    │
│  │                              │    │
│  │  [ Start Session ▶ ]        │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  PROGRESS                    │    │
│  │  Juz 30: ████████░░ 82%     │    │
│  │  Pages memorized: 18/20     │    │
│  │  🔥 14 active days           │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  WERD (Daily Reading)        │    │
│  │  3/5 pages · Continue →      │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  ✨ Ayah of the Day          │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

### For users WITHOUT a profile:
```
┌──────────────────────────────────────┐
│  Assalamu Alaykum ☀️                │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  🌟 Start Your Hifz Journey  │    │
│  │                              │    │
│  │  Create a personalized       │    │
│  │  memorization plan designed  │    │
│  │  for your memory and pace.   │    │
│  │                              │    │
│  │  [ Create Profile → ]       │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  WERD (Daily Reading)        │    │
│  │  3/5 pages · Continue →      │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  ✨ Ayah of the Day          │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

---

## Bottom Navigation — Final Decision

```
  Dashboard    Practice    Read    Listen    Profile
     🏠          🃏         📖      🎧        👤
```

| Tab | Content |
|---|---|
| **Dashboard** | Hifz dashboard, today's plan, progress, start session, CTA for profile creation |
| **Practice** | Flashcards + Mutashabihat drills. Dedicated tab for daily practice |
| **Read** | Reading screen + surah index. Merged reading experience |
| **Listen** | Audio library, reciter browsing, standalone listening |
| **Profile** | Profile management, settings, multiple profiles, reassessment. Name TBD (could be Settings/More) |

---

## Progress Visualization

### Primary: Pages (Juz-grouped)
```
  Juz 30 ███████████████████░ 95%
  Juz 29 ████████░░░░░░░░░░░░ 40%
  Juz 28 ░░░░░░░░░░░░░░░░░░░░  0%
```

### Detail: Page-level heatmap
Each cell = 1 page. Color = status.
```
  🟢 Memorized    🟡 Learning    🔵 Reviewing    ⚪ Not started
```

### Tab: Surah view
For context — which surahs have been covered.

---

## Starting Point

During profile creation, after the assessment:
```
┌──────────────────────────────────────┐
│  Where would you like to start?      │
│                                      │
│  Suggested:                          │
│  ⭐ Juz 30 (Juz 'Amma) — Most common│
│  ⭐ Surah Al-Baqarah — From start    │
│                                      │
│  Or pick your own:                   │
│  [ Browse Surahs ]  [ Pick a Page ]  │
└──────────────────────────────────────┘
```

Full freedom with gentle suggestions.
