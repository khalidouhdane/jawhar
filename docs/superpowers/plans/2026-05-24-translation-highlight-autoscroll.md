# Translation Mode Verse Highlighting & Auto-Scrolling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Highlight the currently playing or active verse in the translation view (using `theme.verseHighlight` to match the reading view) and automatically scroll/center the active verse as the reciter progresses.

**Architecture:** Maintain a persistent `ScrollController` in the state classes of both the mobile and tablet translation list views (`QuranPageState` and `_TabletReadingViewState`). Listen to `AudioProvider.activeVerseKey` changes using `context.select` for rebuilds, and auto-scroll/center the active playing verse using dynamic viewport-dimension math, preventing jumpy page resets by tracking the last scrolled verse key.

**Tech Stack:** Flutter, Dart, Provider (AudioProvider, ContextProvider, ThemeProvider)

---

## Proposed Changes

### Task 1: Enhance Mobile Translation View Highlighting & Scrolling

**Files:**
- Modify: [reading_screen.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/screens/reading_screen.dart)

- [ ] **Step 1: Declare controller and state variables**
  Add `ScrollController _tafsirScrollController` and `String? _lastScrolledVerseKey` to `QuranPageState`.
- [ ] **Step 2: Initialize and dispose the ScrollController**
  Initialize `_tafsirScrollController` in `initState()` and call `_tafsirScrollController.dispose()` in `dispose()`.
- [ ] **Step 3: Reset scrolled key on page load**
  Update `_loadPage()` to set `_lastScrolledVerseKey = null;`.
- [ ] **Step 4: Implement centering scroll helper**
  Add `_scrollToVerse(int index)` method to `QuranPageState` that estimates the position and centers it based on `viewportDimension` and `maxScrollExtent`.
- [ ] **Step 5: Watch active verse changes and scroll dynamically**
  In `_buildTafsirView`, resolve `activeVerseKey` via `context.select<AudioProvider, String?>((p) => p.activeVerseKey)`. Schedule `_scrollToVerse` if the active verse or highlighted verse changes.
- [ ] **Step 6: Update highlight styling and container padding**
  Change the highlight check to cover both `activeVerseKey` and `highlightKey`, apply `theme.verseHighlight`, and use a uniform `padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)` on the animated container.

---

### Task 2: Enhance Tablet Translation View Highlighting & Scrolling

**Files:**
- Modify: [tablet_reading_view.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/screens/tablet_reading_view.dart)

- [ ] **Step 1: Declare controller and state variables**
  Add `ScrollController _tafsirScrollController` and `String? _lastScrolledVerseKey` to `_TabletReadingViewState`.
- [ ] **Step 2: Initialize and dispose the ScrollController**
  Initialize `_tafsirScrollController` in `initState()` and call `_tafsirScrollController.dispose()` in `dispose()`.
- [ ] **Step 3: Reset scrolled key on page change**
  Update `_onTafsirPageChanged()` to reset `_lastScrolledVerseKey = null;`.
- [ ] **Step 4: Scroll dynamically on audio progress**
  Update `_onAudioChanged()` to scroll to the active verse on the same page.
- [ ] **Step 5: Implement centering scroll helper**
  Add `_scrollToVerse(int index)` method to `_TabletReadingViewState`.
- [ ] **Step 6: Watch active verse changes and scroll in panel build**
  In `_buildTafsirPanel`, watch `activeVerseKey` and schedule `_scrollToVerse` for initial builds on new pages.
- [ ] **Step 7: Update highlight styling and container padding**
  Apply `theme.verseHighlight` and a uniform `padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12)` on the animated container.

---

## Verification Plan

### Automated Tests
- Run: `flutter test` to ensure existing math and audio tests pass successfully.

### Manual Verification
- Start audio playback in translation mode (mobile or tablet) and verify that the verse card highlight updates as the reciter moves.
- Verify that the active verse automatically centers/scrolls into view on each verse transition.
- Verify that manual scrolling is still possible and does not immediately snap back to the playing verse until the next verse starts.
- Toggle between light and dark modes to verify the highlight color adapts properly.
