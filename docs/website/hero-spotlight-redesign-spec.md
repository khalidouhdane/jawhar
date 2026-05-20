# Hero Spotlight Redesign Design Specification

## Overview
Redesign the homepage hero section (`EssenceFlowHero.js` and `EssenceFlow.module.css`) to use perfectly consistent card sizes (`270px` by `200px`) on both the left and right sides. Implement an interactive spotlight animation where left-side "Verse Cards" are clickable, triggering SVG gradient line drawing animations through a central diamond to three dynamic "Feature Cards" on the right. 

During the page load entrance, the first left card and its connecting line will build simultaneously with the diamond's entrance, creating a seamless transition from load to the first active state.

---

## Architectural Details

### 1. State Management
We will manage the active spotlight state in `EssenceFlowHero.js` using:
* `activeIndex` (0, 1, 2): index of the highlighted pair.
* `isAutoRotating`: boolean to control whether the auto-rotation loop is active.
* `manualOverrideTimeout`: ref for tracking the timer to resume auto-rotation after manual clicks.

### 2. SVG Line and Light Flow Path Coordinates
We will define an SVG viewport (`viewBox="0 0 1440 600"`) spanning the width and height of the desktop stage:
* **Center (Diamond):** `(720, 240)`
* **Left Card 0 (Top Left):** `(380, 120)`
* **Left Card 1 (Middle Left):** `(320, 290)`
* **Left Card 2 (Bottom Left):** `(380, 460)`
* **Right Card 0 (Top Right):** `(1060, 120)`
* **Right Card 1 (Middle Right):** `(1120, 290)`
* **Right Card 2 (Bottom Right):** `(1060, 460)`

Lines will be rendered as SVG `<path>` elements using cubic or quadratic bezier curves for organic smoothness, rather than simple straight lines.

#### Drawing & Glow Animation:
* Framer Motion's `pathLength` will animate from `0` to `1` to build the lines.
* Overlaid glow paths will use a moving gradient (or a `strokeDasharray` offset) to create traveling pulses of light in the active theme color.

---

## Card Designs

### Left Cards (Verse Cards)
All three cards have identical styling: `width: 270px`, `height: 200px`, padding `20px`, shadow-as-border `var(--shadow-card)`.
* **Left Card 0 (Al-Kawthar 108:1):**
  * *Theme Accent:* Develop Blue (`#0a72ef`)
  * *Arabic Text:* `"إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ"` (Large Amiri font)
  * *Translation:* `"Indeed, We have granted you Al-Kawthar."`
* **Left Card 1 (Al-Qadr 97:1):**
  * *Theme Accent:* Preview Pink (`#de1d8d`)
  * *Arabic Text:* `"إِنَّا أَنزَلْنَاهُ فِي لَيْلَةِ الْقَدْرِ"`
  * *Translation:* `"Indeed, We sent the Quran down during the Night of Decree."`
* **Left Card 2 (Al-Mulk 67:1):**
  * *Theme Accent:* Ship Red (`#ff5b4f`)
  * *Arabic Text:* `"تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ"`
  * *Translation:* `"Blessed is He in whose hand is the dominion."`

### Right Cards (Feature Cards)
Three cards whose content changes dynamically based on the active index:

#### Right Cards for State 0 (Al-Kawthar — Read & Listen):
* **Card 0 (Read):** Mini-Mushaf rendering, active word highlighted in blue, and a small toggle label for `Hafs / Warsh`.
* **Card 1 (Listen):** Audio player mockup with a play button, a scrubber bar, and a waveform showing `Reciter: Mishary Al-Afasy`.
* **Card 2 (Sync):** Visual showing verse-level sync, with timestamps (`0:04 / 0:15`) and a pulsing blue equalizer.

#### Right Cards for State 1 (Al-Qadr — Understand):
* **Card 0 (Translation):** Side-by-side Arabic words and English translations, showcasing the word-by-word translation overlay.
* **Card 1 (Tafsir):** Card showing the Brief Tafsir text for Al-Qadr, explaining the "Night of Decree".
* **Card 2 (Asbab al-Nuzul):** Reasons for revelation context block, showing when and why the surah was revealed.

#### Right Cards for State 2 (Al-Mulk — Memorize):
* **Card 0 (SRS Flashcard):** Flashcard recall prompt showing a missing verse, with 4 rating buttons below (`Forgot`, `Weak`, `OK`, `Strong`).
* **Card 1 (Daily Plan):** A Hifz plan timeline showing the today's phases: `Sabaq` (New), `Sabqi` (Recent), and `Manzil` (Review) with checkmarks.
* **Card 2 (Analytics):** Visual calendar streak showing `7 Day Streak` and a mini line chart showing memorization pace projection.

---

## Timeline & Sequence Flow

### A. Entrance Animation Sequence (On Page Load)
1. **At `0.0s`:** The Diamond starts scaling in from the center (grows to scale `1`).
2. **Simultaneously at `0.0s`:** Left Card 0 starts fading in, and the line from Left Card 0 to the Diamond begins drawing.
3. **At `0.8s`:** The Diamond finishes scaling in, just as the Left Line lands at the Diamond.
4. **At `0.8s – 1.6s`:** The Diamond glows blue. The three right lines draw from the Diamond to the Right Cards.
5. **At `1.2s – 1.6s`:** The three right cards pop in with a staggered animation (R0 at `1.2s`, R1 at `1.35s`, R2 at `1.5s`).

### B. Standard Spotlight Loop (6s interval per state)
1. **Highlight Card:** Left Card `i` lights up (opacity `1`, subtle border glow in accent color); others dim to `0.25`.
2. **Left Line Draws (0.0s – 0.8s):** SVG line builds from Left Card `i` to the Diamond.
3. **Diamond Pulse (0.8s):** The Diamond glows in accent color.
4. **Right Lines Draw (0.8s – 1.6s):** SVG lines build from Diamond to the 3 Right Cards.
5. **Right Cards Pop (1.2s – 1.6s):** Right Cards display content for State `i` and animate scale/fade-in with a stagger.
6. **Active Hold (1.6s – 5.2s):** System fully lit.
7. **Fade Out (5.2s – 6.0s):** SVG lines and right cards fade out to transition.
8. **Next State (6.0s):** Increment `activeIndex = (activeIndex + 1) % 3` and repeat.

---

## Interactive Overrides
* Hovering over any Left Card scales it up (`scale(1.02)`) and shows a pointer cursor.
* Clicking Left Card `k`:
  * Clears auto-rotation timer.
  * Sets `activeIndex = k`.
  * Instantly triggers the line building and card popping sequence.
  * Sets an 8-second timeout; if no further clicks occur, auto-rotation resumes.
