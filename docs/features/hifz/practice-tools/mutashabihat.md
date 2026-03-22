# 📿 Mutashabihat — Similar Verses Practice

> **Purpose:** Define how the app handles mutashabihat (similar verses) — the biggest challenge for advanced memorizers.

---

## What Are Mutashabihat?

Verses across different surahs that are nearly identical except for:
- A single word change
- Different word order
- A different ending
- An extra or missing word

These are the **#1 cause** of mistakes during recitation for intermediate and advanced huffaz.

---

## Example

| Surah | Verse | Text |
|---|---|---|
| Al-Baqarah 2:58 | ادْخُلُوا هَٰذِهِ الْقَرْيَةَ فَكُلُوا | "Enter this town and eat" |
| Al-A'raf 7:161 | اسْكُنُوا هَٰذِهِ الْقَرْيَةَ وَكُلُوا | "Dwell in this town and eat" |

The difference: ادخلوا **فكلوا** vs. اسكنوا **وكلوا** — two small word changes that trip up even experienced memorizers.

---

## 4 Digital Practice Modes

### 1. 🔎 Spot the Difference
- Two similar verses shown side by side
- Differences highlighted with color (one color per occurrence)
- User studies the comparison
- Then one verse is hidden — user must recall the specific differences
- Most visual and accessible mode

### 2. 🔗 Context Anchoring
- Shows the similar verse with surrounding context (2 ayahs before and after)
- Teaches the user to rely on contextual flow rather than memorizing in isolation
- Optional tafsir snippets explaining *why* the wording differs (theological meaning)
- Helps build "logical anchors" — understanding *why* reduces confusion

### 3. 📋 Quick Quiz
- "This verse appears in two surahs."
- "In Surah Al-Baqarah, the word is ___. In Surah Al-A'raf, the word is ___."
- Fill-in-the-blank with tap-to-reveal
- Trains active recall of the specific distinguishing words

### 4. 📚 Mutashabihat Collection
- Browsable database of all known mutashabihat groups
- Each group:
  - Lists all occurrences (which surahs, which ayahs)
  - Highlights the exact differences in color
  - Shows frequency (how often each pair causes errors)
- User can mark groups as:
  - ✅ **Mastered** — won't appear frequently
  - 🔄 **Needs practice** — will appear in flashcard decks and quizzes
  - ❌ **Not yet studied** — excluded until they memorize those surahs

---

## Integration with Flashcards

When a user is reviewing a surah that contains known mutashabihat:
- Automatically inject **Mutashabihat Duel** cards into their flashcard deck
- Show a "⚠️ Similar verse alert" when they're about to memorize a new ayah that has a match elsewhere
- After marking a review as "Weak", check if it was a mutashabihat verse — if so, suggest focused practice

---

## Data Source

### 🎉 Ready-Made Dataset Found!

**[Waqar144/Quran_Mutashabihat_Data](https://github.com/Waqar144/Quran_Mutashabihat_Data)** — A curated JSON dataset of mutashabihat verse pairs:
- Based on the work of **Qari Idrees Al Asim** + practical hafiz experience
- **JSON format:** `{ "src": { "ayah": 3733 }, "muts": [{ "ayah": 3753 }, { "ayah": 3757 }] }`
- Includes a `ctx` flag for pairs needing surrounding context
- **Scripts written in Dart** (our language!) — can be run directly
- **Free license** — asks only for attribution
- Focus: most commonly confused pairs for huffaz (not exhaustive, but practical)

This solves our data source problem entirely for MVP. We can:
1. Import the JSON directly
2. Enrich with our category/difficulty metadata
3. Add verse text from our existing Quran API

### Enriched Format (Our Extension)
```
groupId: "mut_001"
src: { surahId: 2, ayahNumber: 58, text: "..." }
muts: [{ surahId: 7, ayahNumber: 161, text: "..." }]
uniqueWords: { src: ["ادخلوا", "فكلوا"], mut: ["اسكنوا", "وكلوا"] }
category: "word_swap"     // word_swap, word_order, extra_word, ending_change
difficulty: "medium"
needsContext: true         // from the ctx flag
```

### Categories of Mutashabihat

| Category | Description | Example |
|---|---|---|
| `word_swap` | One or more words replaced | ادخلوا ↔ اسكنوا |
| `word_order` | Same words, different sequence | — |
| `extra_word` | One version has an additional word | Incrementals pattern |
| `ending_change` | Same verse body, different ending | Different rhyme/فاصلة |
| `pronoun_change` | Masculine ↔ feminine, singular ↔ plural | — |

### Expansion
- Start with the most impactful 100 pairs
- Can be expanded from scholarly references over time
- Community contributions could be added later (users flag confusing pairs)
- Data stored locally in SQLite alongside hifz data

---

## When to Surface Mutashabihat Practice

| Trigger | Action |
|---|---|
| User memorizes a surah with known mutashabihat | Alert: "This surah has similar verses with Surah X" |
| User reviews and self-rates "Weak" on a mutashabihat ayah | Auto-add to flashcard deck, suggest focused practice |
| User completes daily session | Optional: "5-min mutashabihat practice?" |
| User explicitly opens Mutashabihat screen | Full browsable collection with all practice modes |
