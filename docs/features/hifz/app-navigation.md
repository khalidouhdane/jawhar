# App Navigation — Depth-First Redesign

> **Decision:** Home is an adaptive hub. Bottom nav is 5 tabs. Each Beat has a home.

---

## Bottom Navigation — Final Decision

```
  Home      Read     Understand    Practice    Profile
   🏠        📖          💡           🧠          👤
```

| Tab | Content | Beat |
|-----|---------|------|
| **Home** | Adaptive dashboard: today's plan (with profile), werd + CTA (without profile), progress, understanding spotlight, suggestions | — |
| **Read** | Mushaf + surah/juz/hizb index + audio library + reciter browsing. Unified reading & listening experience | Beat 1 |
| **Understand** | Surah introductions, tafsir explorer, asbab al-nuzul collection, daily spotlight. Browsable study experience | Beat 2 |
| **Practice** | Flashcard categories (6 types), mutashabihat practice, review stats. Fun and casual — accessible to all users | Beat 3 |
| **Profile** | Settings, profile management, theme, bookmarks, notifications, account, about | — |

---

## Understand Tab — Layout

```
┌─────────────────────────────────────┐
│  Understand                          │
│                                      │
│  ┌───────────────────────────────┐   │
│  │ 💡 Today's Spotlight          │   │
│  │ Surah Al-Mulk — Why this     │   │
│  │ surah is called "The         │   │
│  │ Protector"...                 │   │
│  └───────────────────────────────┘   │
│                                      │
│  Browse by Surah                     │
│  ┌─────┬─────┬─────┬─────┐          │
│  │Al-  │An-  │Al-  │Ya-  │  →       │
│  │Mulk │Naba │Kahf │Sin  │          │
│  └─────┴─────┴─────┴─────┘          │
│                                      │
│  ┌───────────────────────────────┐   │
│  │ 📖 Surah Introductions       │   │
│  │ Themes, context, key stories │   │
│  └───────────────────────────────┘   │
│                                      │
│  ┌───────────────────────────────┐   │
│  │ 📜 Asbab al-Nuzul            │   │
│  │ Reasons of revelation        │   │
│  └───────────────────────────────┘   │
│                                      │
│  ┌───────────────────────────────┐   │
│  │ 🔍 Tafsir Explorer           │   │
│  │ Browse tafsir by surah       │   │
│  └───────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

## Dashboard (Home) — Layout

### For users WITH a profile:
```
┌──────────────────────────────────────┐
│  jawhar · contextual status line     │
│                                      │
│  ╔══════════════════════════════╗    │
│  ║  TODAY'S PLAN                ║    │
│  ║  📖 Sabaq: Page 45          ║    │
│  ║  🔄 Sabqi: Pages 40-44      ║    │
│  ║  📚 Manzil: Juz 30 (6 pgs)  ║    │
│  ║  🃏 12 cards due             ║    │
│  ║                              ║    │
│  ║  [ Start Session ▶ ]        ║    │
│  ╚══════════════════════════════╝    │
│                                      │
│  ┌────────┬────────┬────────────┐    │
│  │Continue│Practice│  Weekly    │    │
│  │Reading │12 cards│  Report    │    │
│  └────────┴────────┴────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  UNDERSTANDING SPOTLIGHT     │    │
│  │  Today's sabaq context...    │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  PROGRESS STRIP              │    │
│  │  6.3% · Juz 30 · 14 days    │    │
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
│  jawhar                              │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  Continue Reading → Page 45  │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  📖 Werd: 3/5 pages today   │    │
│  │  Continue →                  │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  ✨ Ayah of the Day          │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │  Start Your Hifz Journey →   │    │
│  │  (Subtle, not pushy)         │    │
│  └──────────────────────────────┘    │
└──────────────────────────────────────┘
```

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
