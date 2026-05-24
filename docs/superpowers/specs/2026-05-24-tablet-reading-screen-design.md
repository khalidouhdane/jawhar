# Tablet Reading Screen Adaptive Two-Page Layout Design Spec

This document details the architectural design and implementation plan for introducing a responsive, premium two-page reading layout for tablets and desktops, while maintaining the mobile single-page experience.

## Objective

Enhance the Quran reading experience on large screens (tablets in landscape, desktop apps, and web browsers) by leveraging the available horizontal space. 
The screen will automatically adapt depending on the active mode:
1. **Read Mode**: Display two pages side-by-side, mimicking a physical book spread (facing pages).
2. **Tafsir Mode**: Display the active page on the right and its translation/tafsir detail panel on the left, enabling side-by-side study.

## Target Breakpoint

* **Threshold**: Screen width `>= 900px` (standard desktop browsers and landscape tablet viewports).
* **Behavior**:
  * Width `< 900px`: Render the existing single-page layout (perfect for phones and portrait tablets).
  * Width `>= 900px`: Render the new `TabletReadingView` (side-by-side/split layout).

---

## Architectural & Grid Layout

The tablet reading experience is encapsulated in a new widget: `TabletReadingView`. The core screen layout in `ReadingScreen` switches conditionally based on the viewport width:

```dart
final isWide = MediaQuery.of(context).size.width >= 900;
if (isWide) {
  return TabletReadingView(initialPage: widget.initialPage);
} else {
  return MobileReadingView(...); // Existing single-page implementation
}
```

### TabletReadingView Grid Structure
* Constrained horizontally to a maximum of `1360px` (2x the `680px` constraint of the single-page layout) to maintain readability on ultra-wide desktop monitors.
* Organized as a visual `Row` containing two columns:
  * **Right Column**: Displays the primary reading canvas (`_QuranPage`).
  * **Left Column**: Switches dynamically:
    * In **Read Mode**: Displays the adjacent facing page (`_QuranPage`).
    * In **Tafsir Mode**: Displays a translation list, tafsir reader, and revelation context (`Asbab al-Nuzul`) panel.

---

## Index & Page Mapping Math

To preserve the book's right-to-left layout:
* Total Quran pages = 604.
* Total spreads (facing page pairs) = 302.
* For PageView index `idx` (0 to 301), the spread index is `S = 302 - idx` (1 to 302).
* The paired pages are calculated as:
  * **Right Page (Odd/Recto)**: `2 * S - 1`
  * **Left Page (Even/Verso)**: `2 * S`

### Mapping Jump Requests
When jumping to a specific page `p` (e.g. from the bottom slider or search):
1. Resolve the spread: `S = (p + 1) ~/ 2`
2. Resolve PageView index: `idx = 302 - S`
3. Execute `controller.jumpToPage(idx)`

---

## State Synchronization

### 1. Active Page Tracking
* The `QuranReadingProvider` holds a single `activePage` state.
* In two-page mode, scrolling to a spread automatically updates `activePage` to the Right Page (`2 * S - 1`).
* Tapping/interacting with the Left Page updates `activePage` to `2 * S`, ensuring the top bar and bottom dock show the correct page metadata.

### 2. Audio Playback Turn-Page Behavior
* In **Read Mode**: If the audio player transitions to a page that is part of the currently visible spread (e.g. from Page 9 to Page 10), the screen **does not scroll**. It only triggers a page-turn if the audio plays a verse on a page outside the current spread (e.g. Page 11).
* In **Tafsir Mode**: Pages turn immediately when the active verse crosses the page boundary.

### 3. Global Verse Selection
* Verse selection state is lifted to the `TabletReadingView` state.
* The selection key (`selectedVerseKey`) is passed down to both left and right page canvases.
* Selecting a verse on one page automatically deselects any verse on the other, maintaining a single clean contextual menu.

---

## Components

### 1. Central Spine Divider
In **Read Mode**, a central spine divider runs vertically down the middle of the two pages. It contains:
* A subtle double-gradient shadow cast outwards (simulating page depth).
* Customizable opacity matching the current active theme.

### 2. Side-by-Side Tafsir Pane
In **Tafsir Mode**, the Left Column renders a Scrollable translation panel containing:
* The translation of all verses on the active page.
* Interactivity to expand Tafsir sheets or play audio directly from a verse.

---

## Verification Plan

### Automated Verification
* Unit tests for index mapping helper functions:
  * Verify `pageToSpreadIndex(1)` maps to `301`.
  * Verify `pageToSpreadIndex(2)` maps to `301`.
  * Verify `pageToSpreadIndex(604)` maps to `0`.
  * Verify `spreadIndexToPages(301)` yields `(1, 2)`.

### Manual & UI Verification
* **Responsive Switch**: Resize the window above and below `900px` to verify seamless layouts.
* **Navigation Sync**: Verify bottom dock page selector correctly turns spreads.
* **Audio Playback**: Confirm page flips only happen when audio crosses the double-page boundary in Read mode.
* **Theme Adaptability**: Verify page margins, central spine shadow, and background colors dynamically follow theme changes.
