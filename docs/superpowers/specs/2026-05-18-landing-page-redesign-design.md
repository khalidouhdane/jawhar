# Landing Page Redesign — Design Spec

> **Date:** 2026-05-18
> **Status:** Approved for implementation
> **Scope:** `website/` directory only — no Flutter app changes

---

## Overview

Redesign the Jawhar landing page to strengthen the storytelling, add product evidence, and close the page with a visual representation of the depth-first product model.

### Design goals

1. **Hero:** Turn the conveyor animation from "lots of features" into a meaningful spotlight cycle — "verse in, meaning out"
2. **Three Beats sections:** Replace identical card grids with dual phone frames (video-ready), floating UI widgets, and smaller stacked feature cards
3. **Comparison table:** Activate the existing `DifferenceSection` in the scroll flow
4. **Closing:** Merge concentric rings (product depth model) with thesis bookend and inline waitlist

### Page flow (final)

```
WisprFlowHero        — spotlight cycle conveyors + diamond pulse
ProblemSection       — unchanged
ReadSection          — phone frames LEFT, stacked cards RIGHT
UnderstandSection    — phone frames RIGHT, stacked cards LEFT
MemorizeSection      — phone frames LEFT, stacked cards RIGHT
DifferenceSection    — comparison table (activated, softer copy)
ClosingSection       — depth rings animation + thesis + waitlist
Footer               — existing (update social link hrefs)
```

---

## 1. Hero — Spotlight Cycle

### File: `components/explore/WisprFlowHero.js`

**Change type:** Modify animation logic (same DOM structure)

### Current behavior

All 18 cards (9 verse, 9 feature) stream continuously across 6 conveyor rows at speeds of 35–80px/s. All cards are equally visible. The diamond rotates at 24fps continuously.

### New behavior

Two alternating modes:

**Drift mode (ambient):**
- All cards move at reduced speed (~15–20px/s)
- All cards dimmed: `opacity: 0.3`, `filter: brightness(0.7)`
- Diamond rotates quietly at reduced fps (~12fps)

**Spotlight mode (every ~5s, holds for ~3s):**
- One verse card on the left pauses and brightens to `opacity: 1` with subtle `scale: 1.05` and `box-shadow` glow
- Diamond pulses once: `scale: 1.0 → 1.05 → 1.0` over 0.6s
- 2–3 corresponding feature cards on the right pause and brighten
- After ~3s hold, all cards return to drift state
- Next cycle picks a different verse-feature pairing

### Spotlight pairings

| Cycle | Left verse | Right features |
|-------|-----------|----------------|
| 1 | Al-Fatiha 1:1 `بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ` | Translation card + Brief Tafsir card + Context card |
| 2 | Al-Baqarah 2:255 `اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ` | Daily Plan card + Session card + Reciter card |
| 3 | Al-Rahman 55:13 `فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ` | Mutashabihat card + Flashcard card + Progress card |

### Implementation approach

- Add a `spotlightIndex` state that cycles 0 → 1 → 2 → 0 via `setInterval(8000)` (5s drift + 3s hold)
- Each card gets a data attribute: `data-spotlight-group="0|1|2"`
- GSAP tweens apply `.spotlit` class to matching cards and dim others
- Diamond pulse: a GSAP tween triggered on each spotlight transition
- Conveyor speeds reduced: change `leftSpeeds` to `[15, 20, 18]`, `rightSpeeds` to `[14, 18, 16]`
- Conveyors do NOT pause entirely — spotlit cards just slow further (or use GSAP `timeScale` to smoothly decelerate their track)
- No new DOM elements, no structural changes

### CSS additions (in `WisprFlow.module.css`)

```css
/* Drift state — default for all cards */
.verseCard,
.featureCard {
  transition: opacity 0.6s ease, filter 0.6s ease, transform 0.6s ease, box-shadow 0.6s ease;
}

/* When a spotlight is active, non-spotlit cards dim */
.drifting .verseCard,
.drifting .featureCard {
  opacity: 0.3;
  filter: brightness(0.7);
}

/* Spotlit card */
.spotlit {
  opacity: 1 !important;
  filter: brightness(1) !important;
  transform: scale(1.05);
  box-shadow: 0 0 24px rgba(255, 255, 255, 0.08);
  z-index: 10;
}
```

---

## 2. Three Beats Sections — Phone Frames + Floating Widgets

### Files modified

- `components/sections/ReadSection.js` — rewrite
- `components/sections/UnderstandSection.js` — rewrite
- `components/sections/MemorizeSection.js` — rewrite
- `components/sections/StorySections.module.css` — rewrite
- `components/shared/PhoneMockup.js` — minor enhancement (video support)

### Files new

- `components/sections/FloatingWidget.js` — reusable floating widget component
- `components/sections/FloatingWidget.module.css`

### Layout per section

Each Beat section uses this structure:

```
<section>
  <div class="content">

    <!-- Side A: Phone group -->
    <div class="phone-group">
      <PhoneMockup video="read-1.webm" class="phone-primary" />
      <PhoneMockup video="read-2.webm" class="phone-secondary" />
      <FloatingWidget type="audio-pill" />
      <FloatingWidget type="verse-badge" />
      <FloatingWidget type="bookmark-dot" />
    </div>

    <!-- Side B: Copy + stacked cards -->
    <div class="copy-group">
      <h2>Read, beautifully.</h2>
      <p>Begin with the Mushaf itself...</p>
      <div class="feature-stack">
        <FeatureCard ... />
        <FeatureCard ... />
        <FeatureCard ... />
      </div>
    </div>

  </div>
</section>
```

### Alternating layout

| Section | Side A (phones) | Side B (cards) | CSS class |
|---------|----------------|----------------|-----------|
| Read | LEFT | RIGHT | `.layout-left` |
| Understand | RIGHT | LEFT | `.layout-right` |
| Memorize | LEFT | RIGHT | `.layout-left` |

Achieved via CSS `flex-direction: row` vs `row-reverse` on the `.content` container.

### Phone frame specs

**`PhoneMockup` enhancement:**
- Accept optional `videoSrc` prop. When provided, render `<video autoplay muted loop playsinline>` inside `.screen`
- When no video: show solid `var(--bg-subtle)` with centered diamond SVG at 10% opacity (placeholder state)

**Primary phone:**
- Width: 290px (existing `PhoneMockup` default)
- Natural flow position

**Secondary phone:**
- Width: 250px (new `size="small"` prop on PhoneMockup → `.frame { width: 250px }`)
- Offset: `margin-top: 80px` (lower than primary)
- Parallax: `data-speed="0.85"` — scroll speed factor applied via GSAP ScrollTrigger `scrub`

**Phone group container:**
- `position: relative` (anchor for floating widgets)
- `display: flex; gap: 20px; align-items: flex-start`

### Floating widgets

Reusable `<FloatingWidget>` component. Each widget is a small UI fragment styled to look like it drifted out of the phone screen.

**Props:**
- `type` — determines content and styling
- `position` — `{ top, left, right, bottom }` values for absolute positioning
- `parallaxSpeed` — scroll offset factor (default: `0.9`)

**Widget types per section:**

| Section | Widget 1 | Widget 2 | Widget 3 |
|---------|----------|----------|----------|
| **Read** | Audio pill: reciter name + play icon, pill shape | Verse badge: `2:255` in circle | Bookmark dot: colored circle with tooltip |
| **Understand** | Language switcher: `EN │ AR` toggle pill | Tafsir mode: `Brief │ Detailed` pill | Verse key: `55:13` + translation snippet |
| **Memorize** | Streak counter: `🔥 12 days` | Session timer: `15:00` countdown | Progress ring: circular SVG, 67% |

**Widget styling:**
- `position: absolute` within phone group container
- `background: var(--card-bg)`
- `box-shadow: var(--shadow-card)` (Geist shadow-as-border)
- `border-radius: var(--radius-pill)` for pills, `var(--radius-lg)` for cards
- `font-size: 12px`, `padding: 6px 12px`
- Positioned to **intersect phone frame edges** (partially overlapping)

**Widget animation:**
- `ScrollReveal` with staggered delays (0.3, 0.5, 0.7s)
- Parallax: GSAP `ScrollTrigger` with `scrub: true`, `y` offset based on `parallaxSpeed`

### Feature cards (stacked)

Replace the 3-column grid with a single-column vertical stack:

```css
.featureStack {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.featureCardCompact {
  padding: 1rem 1.25rem;
}

.featureCardCompact .featureIcon {
  width: 32px;
  height: 32px;
  border-radius: 8px;
}

.featureCardCompact .featureTitle {
  font-size: 1rem;
}

.featureCardCompact .featureText {
  font-size: 0.875rem;
}
```

### Responsive

| Viewport | Layout |
|----------|--------|
| >1024px | Side-by-side: phones + cards |
| 768–1024px | Stack: phones on top, cards below. Secondary phone hidden. |
| <768px | Single phone centered, cards stacked below. All floating widgets hidden. |

---

## 3. Comparison Table — Activated

### File: `components/sections/DifferenceSection.js`

**Change type:** Minor copy edit + add to `ScrollStory.js`

### Changes

1. **Add to scroll flow** — Insert `<DifferenceSection />` in `ScrollStory.js` between `<MemorizeSection />` and `<ClosingSection />`

2. **Soften copy:**
   - `mono-label`: change "The Difference" → "How Jawhar compares"
   - `heading-sub`: change "What makes Jawhar different" → "Built different, on purpose."

3. **No structural changes** — The existing 6-row table with `StatusIcon` components is clean and sufficient.

---

## 4. Closing Section — Depth Rings + Thesis + Waitlist

### Files new

- `components/sections/ClosingSection.js` — main component
- `components/sections/ClosingSection.module.css`
- `components/sections/DepthRings.js` — SVG rings + scroll-triggered animation
- `components/sections/DepthRings.module.css`
- `components/shared/WaitlistForm.js` — extracted from current `WaitlistSection.js`
- `components/shared/WaitlistForm.module.css`

### Files retired

- `components/sections/WaitlistSection.js` — form logic extracted to `WaitlistForm`, section replaced by `ClosingSection`
- `components/sections/WaitlistSection.module.css`

### ClosingSection layout

```jsx
<section id="closing" className="section">
  <div className="container">
    <p className="mono-label">Your journey</p>

    {/* Depth rings animation */}
    <DepthRings />

    {/* Thesis + waitlist */}
    <div className={styles.resolution}>
      <h2 className="heading-sub">
        The app disappears. The Quran appears.
      </h2>
      <p className="body-large">
        Jawhar is free, private, and built for one purpose:
        to help you carry every verse with its meaning.
      </p>
      <WaitlistForm />
      <p className={styles.trust}>
        Free forever · Privacy-first · Open roadmap
      </p>
    </div>
  </div>
</section>
```

### DepthRings component

SVG-based concentric circles with scroll-triggered stroke-draw animation.

**Structure:**

```jsx
<div className={styles.ringsContainer} ref={containerRef}>
  <svg viewBox="0 0 800 800" className={styles.ringsSvg}>
    {/* Ring 4 (outermost): Master */}
    <circle cx="400" cy="400" r="340" className={styles.ring4} />
    {/* Ring 3: Memorize */}
    <circle cx="400" cy="400" r="280" className={styles.ring3} />
    {/* Ring 2: Understand */}
    <circle cx="400" cy="400" r="220" className={styles.ring2} />
    {/* Ring 1 (innermost): Read & Listen */}
    <circle cx="400" cy="400" r="160" className={styles.ring1} />
  </svg>

  {/* Diamond at center — static, no rotation */}
  <div className={styles.centerDiamond}>
    <DiamondIcon />  {/* The SVG from Navbar, not the sprite */}
  </div>

  {/* Labels — positioned absolutely at right edge of each ring */}
  <div className={styles.label} style={{ top: ringY(160), right: labelX(160) }}>
    <span className={styles.ringName}>Read & Listen</span>
    <span className={styles.ringFeatures}>Mushaf · Reciters · Audio · Bookmarks</span>
  </div>
  {/* ... labels for rings 2, 3, 4 */}
</div>
```

**SVG ring styling:**

```css
.ring1, .ring2, .ring3, .ring4 {
  fill: none;
  stroke-linecap: round;
}

.ring1 {
  stroke: var(--text-tertiary);
  opacity: 0.6;
  stroke-width: 1;
  stroke-dasharray: /* 2πr = 2 × π × 160 ≈ 1005 */;
  stroke-dashoffset: 1005; /* starts hidden */
}

.ring2 {
  stroke: var(--text-tertiary);
  opacity: 0.45;
  stroke-width: 1;
  stroke-dasharray: /* 2πr ≈ 1382 */;
  stroke-dashoffset: 1382;
}

.ring3 {
  stroke: var(--text-tertiary);
  opacity: 0.3;
  stroke-width: 1;
  stroke-dasharray: /* 2πr ≈ 1759 */;
  stroke-dashoffset: 1759;
}

.ring4 {
  stroke: var(--text-tertiary);
  opacity: 0.2;
  stroke-width: 1;
  stroke-dasharray: /* 2πr ≈ 2136 */;
  stroke-dashoffset: 2136;
}
```

**Animation (GSAP + ScrollTrigger):**

```js
useGSAP(() => {
  const tl = gsap.timeline({
    scrollTrigger: {
      trigger: containerRef.current,
      start: "top 70%",
      once: true,
    }
  });

  // 1. Diamond fades in
  tl.fromTo(diamondRef.current,
    { scale: 0, opacity: 0 },
    { scale: 1, opacity: 1, duration: 0.8, ease: "back.out(1.5)" }
  )
  // 2. Ring 1 draws (Read & Listen)
  .to('.ring1', {
    strokeDashoffset: 0,
    duration: 1.0,
    ease: "power2.inOut"
  }, "-=0.3")
  .fromTo('.label-1', { opacity: 0, x: 10 }, { opacity: 1, x: 0, duration: 0.5 }, "-=0.4")

  // 3. Ring 2 draws (Understand)
  .to('.ring2', {
    strokeDashoffset: 0,
    duration: 1.0,
    ease: "power2.inOut"
  }, "-=0.5")
  .fromTo('.label-2', { opacity: 0, x: 10 }, { opacity: 1, x: 0, duration: 0.5 }, "-=0.4")

  // 4. Ring 3 draws (Memorize)
  .to('.ring3', {
    strokeDashoffset: 0,
    duration: 1.0,
    ease: "power2.inOut"
  }, "-=0.5")
  .fromTo('.label-3', { opacity: 0, x: 10 }, { opacity: 1, x: 0, duration: 0.5 }, "-=0.4")

  // 5. Ring 4 draws (Master)
  .to('.ring4', {
    strokeDashoffset: 0,
    duration: 1.0,
    ease: "power2.inOut"
  }, "-=0.5")
  .fromTo('.label-4', { opacity: 0, x: 10 }, { opacity: 1, x: 0, duration: 0.5 }, "-=0.4")

  // 6. Resolution copy fades in
  .fromTo(resolutionRef.current,
    { opacity: 0, y: 20 },
    { opacity: 1, y: 0, duration: 0.8, ease: "power2.out" },
    "-=0.2"
  );
}, { scope: containerRef });
```

**Ring label content:**

| Ring | Name | Features |
|------|------|----------|
| 1 (innermost) | Read & Listen | Mushaf · Reciters · Audio · Bookmarks |
| 2 | Understand | Translations · Tafsir · Asbab al-Nuzul |
| 3 | Memorize | Plans · Sessions · Progress |
| 4 (outermost) | Master | Flashcards · Mutashabihat · Analytics |

**Ring label positioning:**
- Each label is positioned at the **right edge** of its ring
- Vertically centered with the ring's horizontal midpoint
- `ringName` uses `mono-label` styling (12px, uppercase, monospace)
- `ringFeatures` uses `13px`, `var(--text-tertiary)`, dot-separated

**Sizing:**

| Viewport | SVG viewBox | Container max-width | Ring radii |
|----------|-------------|--------------------|----|
| Desktop | 800×800 | 600px | 160, 220, 280, 340 |
| Tablet | 600×600 | 450px | Scaled proportionally |
| Mobile | Replace with vertical bars (see below) | Full width | N/A |

### Mobile fallback (< 768px)

Replace circles with a vertical stack of expanding horizontal bars:

```
◇ diamond (small, centered)

━━━━━━━━━━━━━━━━━  Read & Listen
                   Mushaf · Reciters · Audio

━━━━━━━━━━━━━━━━━━━━━━━  Understand
                         Translations · Tafsir · Asbab

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  Memorize
                               Plans · Sessions · Progress

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  Master
                                     Flashcards · Analytics
```

Each bar animates its `width` from 0 → target using the same staggered GSAP timeline. Bars are styled as `1px` height lines using `var(--shadow-ring)`, label below each bar.

**Implementation:** Conditionally render `<DepthRingsMobile />` vs `<DepthRings />` based on viewport width (CSS media query with display toggle, or a `useMediaQuery` hook).

### WaitlistForm extraction

Extract the form logic from `WaitlistSection.js` into a standalone `WaitlistForm.js`:

```jsx
// components/shared/WaitlistForm.js
export default function WaitlistForm() {
  const [email, setEmail] = useState("");
  const [submitted, setSubmitted] = useState(false);

  function handleSubmit(event) {
    event.preventDefault();
    const normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail) return;
    const saved = JSON.parse(localStorage.getItem("jawhar-waitlist") || "[]");
    const next = Array.from(new Set([...saved, normalizedEmail]));
    localStorage.setItem("jawhar-waitlist", JSON.stringify(next));
    setSubmitted(true);
  }

  return (
    <form onSubmit={handleSubmit}>
      {/* Same markup as current WaitlistSection form */}
    </form>
  );
}
```

> **Note:** The form still uses `localStorage` for now. Backend integration is a separate future task.

---

## 5. ScrollStory Update

### File: `components/sections/ScrollStory.js`

```jsx
import WisprFlowHero from '../explore/WisprFlowHero';
import ProblemSection from './ProblemSection';
import ReadSection from './ReadSection';
import UnderstandSection from './UnderstandSection';
import MemorizeSection from './MemorizeSection';
import DifferenceSection from './DifferenceSection';
import ClosingSection from './ClosingSection';

export default function ScrollStory() {
  return (
    <div style={{ position: 'relative' }}>
      <div style={{ position: 'relative', zIndex: 1 }}>
        <WisprFlowHero />
        <div className="section-divider" />
        <ProblemSection />
        <div className="section-divider" />
        <ReadSection />
        <div className="section-divider" />
        <UnderstandSection />
        <div className="section-divider" />
        <MemorizeSection />
        <div className="section-divider" />
        <DifferenceSection />
        <div className="section-divider" />
        <ClosingSection />
      </div>
    </div>
  );
}
```

---

## 6. Footer — Minor Fix

### File: `components/layout/Footer.js`

Update placeholder social links:
- `href="https://x.com"` → actual Jawhar account (or remove if no account exists)
- `href="https://instagram.com"` → actual Jawhar account (or remove)

---

## 7. Dependencies

No new npm dependencies needed. Everything uses existing packages:
- `gsap` + `@gsap/react` — hero spotlight, ring animations, parallax
- `framer-motion` — `ScrollReveal` component (unchanged)
- `lucide-react` — icons for feature cards and floating widgets

GSAP `ScrollTrigger` plugin needs to be registered if not already:

```js
import { ScrollTrigger } from 'gsap/ScrollTrigger';
gsap.registerPlugin(ScrollTrigger);
```

---

## 8. File Change Summary

| Action | File | Description |
|--------|------|-------------|
| MODIFY | `components/explore/WisprFlowHero.js` | Spotlight cycle logic |
| MODIFY | `components/explore/WisprFlow.module.css` | Drift/spotlight states |
| MODIFY | `components/sections/ScrollStory.js` | Updated section order |
| MODIFY | `components/sections/ReadSection.js` | Phone frames + widgets layout |
| MODIFY | `components/sections/UnderstandSection.js` | Phone frames + widgets (mirrored) |
| MODIFY | `components/sections/MemorizeSection.js` | Phone frames + widgets |
| MODIFY | `components/sections/StorySections.module.css` | New layout system |
| MODIFY | `components/sections/DifferenceSection.js` | Softer copy |
| MODIFY | `components/shared/PhoneMockup.js` | Video support prop |
| MODIFY | `components/shared/PhoneMockup.module.css` | Small size variant |
| MODIFY | `components/layout/Footer.js` | Social link hrefs |
| NEW | `components/sections/ClosingSection.js` | Depth rings + thesis + waitlist |
| NEW | `components/sections/ClosingSection.module.css` | Closing section styles |
| NEW | `components/sections/DepthRings.js` | SVG ring animation |
| NEW | `components/sections/DepthRings.module.css` | Ring styles |
| NEW | `components/sections/FloatingWidget.js` | Reusable floating widget |
| NEW | `components/sections/FloatingWidget.module.css` | Widget styles |
| NEW | `components/shared/WaitlistForm.js` | Extracted form component |
| NEW | `components/shared/WaitlistForm.module.css` | Form styles |
| DELETE | `components/sections/WaitlistSection.js` | Replaced by ClosingSection |
| DELETE | `components/sections/WaitlistSection.module.css` | Replaced by ClosingSection |

**Total:** 11 modified, 8 new, 2 deleted = 21 files

---

## 9. Verification Plan

### Visual testing (browser)

1. Load `localhost:3001` — verify hero spotlight cycle plays correctly (drift → spotlight → drift)
2. Scroll through all sections — verify alternating phone frame layouts (L-R-L)
3. Verify floating widgets appear with stagger and parallax offset
4. Verify DifferenceSection renders between Memorize and Closing
5. Scroll to closing — verify ring draw animation triggers once
6. Verify waitlist form submits to localStorage
7. Test light/dark mode toggle on all new sections
8. Test at 1440px, 1024px, 768px, 375px viewports

### Automated

- `npm run build` passes without errors
- `npm run lint` passes
- `node scripts/check-landing-content.mjs` passes (if content checks are updated)
