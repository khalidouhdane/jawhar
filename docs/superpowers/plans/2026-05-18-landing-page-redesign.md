# Landing Page Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the Jawhar landing page with a hero spotlight cycle, phone-frame product sections, activated comparison table, and a closing section with animated depth rings + waitlist.

**Architecture:** Modify existing section components to use dual phone frames with floating widgets, replace continuous conveyor animation with a spotlight cycle, add a new ClosingSection with SVG ring-draw animation, and extract the waitlist form into a reusable component.

**Tech Stack:** Next.js 16, React 19, GSAP 3 (+ ScrollTrigger), Framer Motion, Lucide React, CSS Modules

**Spec:** [`docs/superpowers/specs/2026-05-18-landing-page-redesign-design.md`](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/docs/superpowers/specs/2026-05-18-landing-page-redesign-design.md)

---

## Task 1: Extract WaitlistForm + Enhance PhoneMockup

**Files:**
- Create: `website/components/shared/WaitlistForm.js`
- Create: `website/components/shared/WaitlistForm.module.css`
- Modify: `website/components/shared/PhoneMockup.js`
- Modify: `website/components/shared/PhoneMockup.module.css`

### Steps

- [ ] **1.1: Create WaitlistForm component**
  Extract the form logic from `WaitlistSection.js` into a standalone `WaitlistForm.js`. Move the email state, handleSubmit (localStorage), input+button markup, and success/note text. Move the form-specific styles from `WaitlistSection.module.css` into `WaitlistForm.module.css`. The component takes no props — it's self-contained.

- [ ] **1.2: Enhance PhoneMockup with video support**
  Add optional `videoSrc` prop to `PhoneMockup.js`. When provided, render `<video autoplay muted loop playsinline src={videoSrc} />` inside `.screen`. When absent, show the existing children or a placeholder (solid `var(--bg-subtle)` with centered diamond SVG at 10% opacity). Add optional `size` prop (`"default" | "small"`). Small variant: `.frame { width: 250px }`, `.screen { min-height: 400px }`.

- [ ] **1.3: Verify build**
  Run `npm run build` in `website/`. Expected: passes. No components consume these yet, so no visual change.

- [ ] **1.4: Commit**
  `feat(website): extract WaitlistForm, enhance PhoneMockup with video support`

---

## Task 2: Create FloatingWidget Component

**Files:**
- Create: `website/components/sections/FloatingWidget.js`
- Create: `website/components/sections/FloatingWidget.module.css`

### Steps

- [ ] **2.1: Create FloatingWidget component**
  A small absolute-positioned UI fragment. Props: `type` (string — determines content), `style` (for position overrides), `className`. Wrap in `ScrollReveal` with configurable `delay`.

  Widget types to implement:
  - `"audio-pill"` — pill shape with play icon + "Mishary al-Afasy" text
  - `"verse-badge"` — circle with verse key like "2:255"
  - `"bookmark-dot"` — small colored circle
  - `"lang-switch"` — pill with "EN │ AR"
  - `"tafsir-mode"` — pill with "Brief │ Detailed"
  - `"verse-translation"` — small card with verse key + translation snippet
  - `"streak"` — pill with "🔥 12 days"
  - `"timer"` — pill with "15:00"
  - `"progress-ring"` — small circular SVG ring at 67%

  Each type renders its specific markup inside a shared container styled with `var(--card-bg)`, `var(--shadow-card)`, `border-radius: var(--radius-pill)` (or `--radius-lg` for cards), `font-size: 12px`, `padding: 6px 12px`.

- [ ] **2.2: Verify build**
  Run `npm run build`. Expected: passes.

- [ ] **2.3: Commit**
  `feat(website): add FloatingWidget component with 9 widget types`

---

## Task 3: Redesign Three Beats Sections (Read, Understand, Memorize)

**Files:**
- Modify: `website/components/sections/ReadSection.js`
- Modify: `website/components/sections/UnderstandSection.js`
- Modify: `website/components/sections/MemorizeSection.js`
- Modify: `website/components/sections/StorySections.module.css`

### Steps

- [ ] **3.1: Rewrite StorySections.module.css layout system**
  Replace the current single-column layout with a two-column flex system:
  - `.content` becomes `display: flex; align-items: center; gap: 4rem`
  - `.layoutLeft .phoneGroup` is `order: 1`, `.copyGroup` is `order: 2`
  - `.layoutRight .phoneGroup` is `order: 2`, `.copyGroup` is `order: 1` (via `flex-direction: row-reverse`)
  - `.phoneGroup`: `position: relative; display: flex; gap: 20px; align-items: flex-start; flex: 1`
  - `.copyGroup`: `flex: 1`
  - `.phoneSecondary`: `margin-top: 80px` (offset lower)
  - `.featureStack`: `display: flex; flex-direction: column; gap: 12px` (replaces grid)
  - `.featureCardCompact`: reduced padding (`1rem 1.25rem`), icon 32px, title `1rem`, text `0.875rem`
  - Responsive: at `<=1024px` stack vertically, hide secondary phone. At `<=768px` hide floating widgets.

- [ ] **3.2: Rewrite ReadSection.js**
  Structure: two-column layout with `layoutLeft` class.
  - Left: `phoneGroup` with two `PhoneMockup` components (no videoSrc for now — placeholder state), plus `FloatingWidget` components for `audio-pill`, `verse-badge`, `bookmark-dot` positioned to intersect phone frame edges.
  - Right: `copyGroup` with h2 "Read, beautifully.", description paragraph, and 3 feature cards in `featureStack` (same content: Full Mushaf, 40+ Reciters, Focus Mode — but using compact card style).
  - Wrap major groups in `ScrollReveal`.

- [ ] **3.3: Rewrite UnderstandSection.js**
  Same structure as ReadSection but with `layoutRight` class (phones on RIGHT, copy on LEFT).
  - Floating widgets: `lang-switch`, `tafsir-mode`, `verse-translation`
  - Copy: h2 "Understand every verse.", same 3 feature cards (Translations, Tafsir, Asbab) in compact stack.

- [ ] **3.4: Rewrite MemorizeSection.js**
  Same structure as ReadSection with `layoutLeft` class.
  - Floating widgets: `streak`, `timer`, `progress-ring`
  - Copy: h2 "Memorize it, forever.", same 3 feature cards (Adaptive Plans, Structured Sessions, Smart Flashcards) in compact stack.
  - Remove the `.spacer` div (no longer needed).

- [ ] **3.5: Verify visually**
  Run dev server, scroll through all three sections. Verify:
  - Alternating layout (L-R-L)
  - Phone frames render with placeholder state
  - Floating widgets appear with stagger
  - Feature cards are stacked and compact
  - Responsive: at 768px, single phone + stacked cards, no widgets

- [ ] **3.6: Commit**
  `feat(website): redesign Three Beats sections with phone frames and floating widgets`

---

## Task 4: Create DepthRings + ClosingSection

**Files:**
- Create: `website/components/sections/DepthRings.js`
- Create: `website/components/sections/DepthRings.module.css`
- Create: `website/components/sections/ClosingSection.js`
- Create: `website/components/sections/ClosingSection.module.css`

### Steps

- [ ] **4.1: Create DepthRings component (desktop)**
  SVG-based concentric circles with GSAP ScrollTrigger stroke-draw animation.
  - SVG `viewBox="0 0 800 800"`, 4 `<circle>` elements at `cx=400 cy=400`:
    - Ring 1 (Read): `r=160`, `stroke-dasharray=1005`, opacity 0.6
    - Ring 2 (Understand): `r=220`, `stroke-dasharray=1382`, opacity 0.45
    - Ring 3 (Memorize): `r=280`, `stroke-dasharray=1759`, opacity 0.3
    - Ring 4 (Master): `r=340`, `stroke-dasharray=2136`, opacity 0.2
  - All rings start with `stroke-dashoffset` = their `stroke-dasharray` (hidden)
  - Center: static diamond icon (reuse SVG from Navbar, not the sprite)
  - Labels: 4 absolutely-positioned divs at right edge of each ring. Each has ring name (`mono-label` style) + feature chips (`13px`, `var(--text-tertiary)`, dot-separated).
  - GSAP timeline triggered by `ScrollTrigger` (`start: "top 70%"`, `once: true`):
    1. Diamond scales in (0.8s, `back.out`)
    2. Ring 1 draws + label fades in (1.0s, overlap -0.3)
    3. Ring 2 draws + label (1.0s, overlap -0.5)
    4. Ring 3 draws + label (1.0s, overlap -0.5)
    5. Ring 4 draws + label (1.0s, overlap -0.5)
  - Container max-width: 600px, centered.
  - Ring label content per spec: Read & Listen (Mushaf · Reciters · Audio · Bookmarks), Understand (Translations · Tafsir · Asbab al-Nuzul), Memorize (Plans · Sessions · Progress), Master (Flashcards · Mutashabihat · Analytics).

- [ ] **4.2: Add mobile fallback to DepthRings**
  At `<768px`, hide the SVG circles and show a vertical stack of horizontal bars instead:
  - 4 bars of increasing width, each with a ring name and features below
  - Same GSAP timeline but animating `width` from 0 → target and label fade-in
  - Use CSS `display: none` / `display: block` media queries to toggle between desktop SVG and mobile bars.

- [ ] **4.3: Create ClosingSection component**
  Compose `DepthRings` + resolution copy + `WaitlistForm`:
  - `<section id="closing" className="section">`
  - `mono-label`: "Your journey"
  - `<DepthRings />`
  - Resolution div with:
    - `h2.heading-sub`: "The app disappears. The Quran appears."
    - `p.body-large`: "Jawhar is free, private, and built for one purpose: to help you carry every verse with its meaning."
    - `<WaitlistForm />`
    - Trust signals: `mono-label` style, "Free forever · Privacy-first · Open roadmap"
  - Resolution copy fades in via GSAP after rings complete (the DepthRings timeline can dispatch a callback, or ClosingSection runs its own timeline with a delay matching ring duration).

- [ ] **4.4: Verify build**
  Run `npm run build`. Expected: passes.

- [ ] **4.5: Commit**
  `feat(website): add ClosingSection with animated depth rings and waitlist`

---

## Task 5: Update ScrollStory + Activate DifferenceSection

**Files:**
- Modify: `website/components/sections/ScrollStory.js`
- Modify: `website/components/sections/DifferenceSection.js`
- Delete: `website/components/sections/WaitlistSection.js`
- Delete: `website/components/sections/WaitlistSection.module.css`

### Steps

- [ ] **5.1: Update DifferenceSection copy**
  - Change `mono-label` text from "The Difference" → "How Jawhar compares"
  - Change `heading-sub` text from "What makes Jawhar different" → "Built different, on purpose."

- [ ] **5.2: Update ScrollStory.js**
  - Remove `WaitlistSection` import
  - Add `DifferenceSection` import
  - Add `ClosingSection` import
  - New section order: `WisprFlowHero → ProblemSection → ReadSection → UnderstandSection → MemorizeSection → DifferenceSection → ClosingSection`
  - Keep `section-divider` divs between each section.

- [ ] **5.3: Delete WaitlistSection files**
  Delete `WaitlistSection.js` and `WaitlistSection.module.css` — their functionality is now in `WaitlistForm` + `ClosingSection`.

- [ ] **5.4: Verify full page flow**
  Load the site, scroll through entire page. Verify:
  - All 7 sections render in correct order
  - DifferenceSection shows updated copy
  - ClosingSection rings animate on scroll entry
  - Waitlist form works (submit → localStorage → success message)
  - Footer renders after closing section

- [ ] **5.5: Commit**
  `feat(website): wire up full page flow with comparison table and closing section`

---

## Task 6: Hero Spotlight Cycle

**Files:**
- Modify: `website/components/explore/WisprFlowHero.js`
- Modify: `website/components/explore/WisprFlow.module.css`

### Steps

- [ ] **6.1: Add spotlight CSS states**
  In `WisprFlow.module.css`, add:
  - `.drifting .verseCard, .drifting .featureCard` — `opacity: 0.3; filter: brightness(0.7)` with `transition: opacity 0.6s, filter 0.6s, transform 0.6s, box-shadow 0.6s`
  - `.spotlit` — `opacity: 1 !important; filter: brightness(1) !important; transform: scale(1.05); box-shadow: 0 0 24px rgba(255,255,255,0.08); z-index: 10`

- [ ] **6.2: Add data-spotlight-group attributes**
  In `WisprFlowHero.js`, add `data-spotlight-group` attributes to verse/feature cards:
  - Group 0: Row 0 verse cards ↔ Row 0 feature cards (Fatiha ↔ Translation/Tafsir/Context)
  - Group 1: Row 1 verse cards ↔ Row 1 feature cards (Baqarah ↔ Plan/Session/Reciter)
  - Group 2: Row 2 verse cards ↔ Row 2 feature cards (Rahman ↔ Mutashabihat/Flashcard/Progress)

- [ ] **6.3: Implement spotlight cycle logic**
  Add spotlight cycle to the `useGSAP` hook after entrance animation completes:
  - Reduce conveyor speeds: `leftSpeeds = [15, 20, 18]`, `rightSpeeds = [14, 18, 16]`
  - After entrance timeline completes, start a `setInterval(8000)` cycle:
    1. Add `.drifting` class to stage container
    2. Query all cards matching current `data-spotlight-group` value
    3. Add `.spotlit` class to matching cards
    4. Pulse diamond: GSAP `scale: 1 → 1.05 → 1` over 0.6s
    5. After 3s, remove `.spotlit` from all, remove `.drifting`
    6. After 5s drift, advance `spotlightIndex` (0→1→2→0) and repeat
  - Clean up interval on unmount via `useEffect` return.

- [ ] **6.4: Verify hero animation**
  Load the site, observe:
  - Entrance animation plays normally
  - After entrance, conveyors slow down
  - Every ~8s: cards dim, one group spotlights, diamond pulses, then returns to drift
  - Cycle repeats across all 3 groups

- [ ] **6.5: Commit**
  `feat(website): add spotlight cycle to hero conveyor animation`

---

## Task 7: Footer Fix + Final Polish

**Files:**
- Modify: `website/components/layout/Footer.js`

### Steps

- [ ] **7.1: Update social links**
  Change placeholder `href="https://x.com"` and `href="https://instagram.com"` to actual Jawhar accounts, or remove the social links section entirely if no accounts exist yet.

- [ ] **7.2: Full visual review**
  Test at 4 viewports (1440px, 1024px, 768px, 375px):
  - Hero spotlight cycle
  - Problem section (unchanged)
  - Three Beats phone frame layouts + floating widgets
  - Comparison table
  - Closing section rings animation + waitlist
  - Footer
  - Light/dark mode toggle on every section

- [ ] **7.3: Final build check**
  Run `npm run build` and `npm run lint`. Both must pass.

- [ ] **7.4: Commit**
  `fix(website): update footer social links, final polish`

---

## Execution Order & Dependencies

```
Task 1 (WaitlistForm + PhoneMockup) ─┐
Task 2 (FloatingWidget)              ├─→ Task 3 (Three Beats sections)
                                     │
Task 1 (WaitlistForm) ───────────────┼─→ Task 4 (DepthRings + ClosingSection)
                                     │
                                     └─→ Task 5 (ScrollStory + DifferenceSection)
                                         ↓
                                     Task 6 (Hero spotlight) ← independent
                                         ↓
                                     Task 7 (Footer + polish)
```

Tasks 1+2 can run in parallel. Task 3 depends on both. Task 4 depends on Task 1. Task 5 depends on Tasks 3+4. Task 6 is independent. Task 7 is last.
