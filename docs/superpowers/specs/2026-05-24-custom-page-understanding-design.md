# Design Spec: Custom Page Understanding & Redesigned Progress Cards

## Goal Description
Improve user retention and understanding during the Quran memorization journey by:
1. Redesigning the Home Tab progress widget into dynamic, stats-rich cards that move right under the active daily plan once the user makes actual progress (rather than remaining at the bottom).
2. Simplifying the context-related cards on both the Home Tab and the Understand Tab into a single, high-value visual button.
3. Creating a new immersive, verse-by-verse `PageUnderstandingScreen` that provides a 360-degree context of today's Sabaq page, linking translation, brief/detailed Tafseer, Reasons of Revelation (Asbab al-Nuzul), and matching curated thematic stories.

---

## User Review Required
No major architectural blockers are anticipated. The implementation will follow existing providers (`PlanProvider`, `HifzProfileProvider`, `ContextProvider`, `QuranReadingProvider`). All verse references will strictly comply with the formatting rules defined in [AGENTS.md](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/.agents).

---

## Proposed Changes

### 1. Progress Card Component Redesign
#### [MODIFY] [progress_strip.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/widgets/dashboard/progress_strip.dart)
* Redesign `ProgressStrip` to display three stats columns:
  * **Streak:** `totalActiveDays` with flame icon.
  * **Memorized Pages:** count with open-book icon.
  * **Sessions:** total sessions count with history icon.
* A touchable bar at the bottom with a chevron pointing to the full progress page.
* Accept a boolean `isCompact` or style dynamically depending on position.

#### [MODIFY] [profile_dashboard.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/widgets/dashboard/profile_dashboard.dart)
* Read streak info, memorized page counts, and session counts.
* Determine if the user has "actual progress" (defined as `streak.totalActiveDays > 0 || memorizedCount > 0 || sessionHistoryCount > 0`).
* Adjust layout dynamically:
  * If progress exists: Render `ProgressStrip` directly under the `PlanCard` or `RestDayCard` (index 2.5), and hide it from the bottom.
  * If progress is zero: Keep `ProgressStrip` at the bottom (index 6).

---

### 2. Context Card Redesign
#### [MODIFY] [understanding_spotlight.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/widgets/dashboard/understanding_spotlight.dart)
* Redesign `UnderstandingSpotlight` on the Home Tab to match the premium border design with a 4dp left-edge Pink border (`SemanticColors.pillarUnderstand.fg(theme.isDark)`).
* Display localized sabaq page info using `VerseRefFormatter` and a single primary button: **"Explore Today's Page" / "فهم الصفحة اليوم"** to push the new screen.

#### [MODIFY] [today_context_card.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/widgets/understand/today_context_card.dart)
* Simplify `TodayContextCard` on the Understand Tab to feature a single action button: **"Explore Today's Sabaq Context" / "فهم سياق السبق اليوم"** which navigates to the new `PageUnderstandingScreen`.

---

### 3. New Verse-by-Verse Understanding Screen
#### [NEW] [page_understanding_screen.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/screens/hifz/page_understanding_screen.dart)
* A full screen `PageUnderstandingScreen` accepting `sabaqPage` in its constructor.
* **Header:** Back button (top left) and page header title (e.g. `Surah Yusuf, Page 582`).
* **Top Toggle Navigation:** Scrollable horizontal strip showing all verses on that page. Text formatted via `VerseRefFormatter.format(verse.verseKey, locale: locale, tier: VerseRefFormat.compact)`. Active verse pill highlighted in Pink.
* **PageView:** Horizontal sliding page view showing:
  * Large Arabic Amiri-font verse block.
  * Side arrow buttons (Prev/Next) for accessible desktop/mouse navigation.
  * **Tabs Section:**
    * **Translation Tab:** Localized translation text.
    * **Tafseer Tab:** Displays brief tafseer with an expandable inline action button to toggle/load detailed tafseer (Ibn Kathir).
    * **Asbab al-Nuzul Tab:** Dynamically displayed only if `asbabService.hasOccasionByKey(verse.verseKey)` is true. Displays reasons of revelation.
  * **Related Topics:** Under the tabs, filters `prophetStories` and `quranThemes` using `topic.surahIds.contains(surahId)`. Renders a horizontal card row. Tapping pushes `TopicDetailScreen(topic: topic)`.

---

## Verification Plan

### Automated Tests
* None required for visual layouts, but verify compile safety using static analysis:
  ```powershell
  flutter analyze
  ```

### Manual Verification
* Run the application and check:
  * When progress is zero, `ProgressStrip` displays at the bottom. When a session is logged/streak active, it moves below the Today's Plan card.
  * Context card on Home tab has the Pink side border.
  * Pushing the "Explore Today's Page" navigates to `PageUnderstandingScreen`.
  * Navigating between verses updates the top active verse pill.
  * Detailed Tafseer toggles dynamically.
  * The Asbab al-Nuzul tab appears/hides based on actual data presence.
  * Tapping related topics opens the proper details screen.
