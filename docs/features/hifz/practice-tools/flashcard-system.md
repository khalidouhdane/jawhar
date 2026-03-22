# 🃏 Flashcard System

> **Purpose:** Define the flashcard types, SRS engine, and integration rules for hifz review.

---

## Core Principle

> Flashcards test **already-memorized content** — they are a review and strengthening tool, not a primary memorization tool.

The flashcard system pulls from the user's memorized and in-review material, generates cards, and schedules them using spaced repetition.

---

## Card Types

### 1. 📝 Verse Completion
- **Shows:** First part of a verse with ending blanked (1-3 words hidden)
- **Action:** Tap to reveal, or select from multiple choice
- **Difficulty scaling:**
  - Easy: 1 word hidden
  - Medium: 2-3 words hidden
  - Hard: second half of verse hidden
- **Example:** "بسم الله الرحمن ___" → الرحيم

### 2. ⏭️ Next Verse
- **Shows:** A complete verse
- **Asks:** "What comes next?"
- **Action:** User recites mentally → tap to reveal next verse → rate recall
- **Tests:** Sequential memory — critical for unbroken recitation

### 3. ⏮️ Previous Verse
- **Shows:** A verse
- **Asks:** "What came before?"
- **Action:** Same as above but backward
- **Harder** than next-verse — trains reverse recall, helps when getting "stuck"

### 4. 🔗 Connect the Sequence
- **Shows:** 3-4 verses in scrambled order
- **Action:** User drags to reorder correctly
- **Tests:** Structural understanding of passage flow

### 5. 🔍 Surah Detective
- **Shows:** A verse (without surah/verse reference)
- **Asks:** "Which surah is this from?"
- **Action:** Multiple choice from 4 plausible surahs
- **Useful for:** Mutashabihat practice, general familiarity

### 6. ⚔️ Mutashabihat Duel
- **Shows:** Two nearly identical verses side by side, differences highlighted
- **Asks:** "Which one is from Surah X?"
- **Tests:** Discrimination between similar passages
- **See also:** [mutashabihat.md](./mutashabihat.md)

---

## SRS Engine

Uses a modified SM-2 algorithm (same engine that powers the daily review schedule):

| User Rating | Effect on Interval |
|---|---|
| 💪 **Strong** (instant recall) | Interval × 2.5 |
| 🤔 **OK** (recalled with effort) | Interval × 1.5 |
| 😅 **Weak** (struggled, got it eventually) | Interval remains same |
| ❌ **Forgot** (couldn't recall) | Reset to 1 day |

Cards start at interval = 1 day and grow from there.

---

## Deck Generation Rules

| Rule | Logic |
|---|---|
| **Source material** | Only verses the user has marked as memorized or in-review |
| **Priority** | Cards from recent reviews rated "Weak" or "Forgot" appear first |
| **Freshness** | Newly memorized material gets more cards initially |
| **Mutashabihat** | If user is studying a surah with known similar verses, add duel cards |
| **Daily target** | 5-10 minutes recommended, ~15-25 cards |
| **Never from un-memorized content** | No spoilers — only test what they've already learned |

---

## Suggested Daily Integration

| Time Budget | When |
|---|---|
| Standalone | 5-10 min anytime during the day — waiting, commute, before bed |
| Post-session | Optional 5 min after completing a sabqi or manzil session |
| Warm-up | Before a sabaq session, review yesterday's cards as a warm-up |
