# Jawhar Website — Master Roadmap

> **Goal:** Build a premium marketing website for Jawhar that showcases the app, drives downloads, and establishes SEO presence — with a stunning animated hero.

---

## 🎯 Project Context

### What is Jawhar?
**Jawhar** (جوهر) — "Essence, jewel, substance." The first Quran memorization companion built on understanding.

- **Primary tagline:** "Memorize with Meaning" (accessible, for everyone)
- **Technical tagline:** "Encode the Essence" (dev/hackathon audience)
- **Descriptive:** "The Quran, understood and remembered"
- **Challenger:** "Not just memorized. Internalized."

### Brand Philosophy
- **Design:** "The app disappears. The Quran appears."
- **Voice:** Calm, confident, precise. NOT preachy, gamified, or casual.
- **Palette:** Pure black (#000) + Pure white (#FFF). No accent colors — the Quran text IS the accent.
- **Typography:** Geist Sans (UI) + Geist Mono (data) + Amiri (Arabic)
- **Icons:** Lucide
- **Motion:** Smooth, purposeful — no playful bounces

### Full Brand References
- **Brand strategy:** `docs/brand-strategy.md`
- **Design system:** `DESIGN.md`
- **Market research:** Available in conversation artifacts (230 sources across 3 deep research reports)
- **Hifz struggles:** `docs/features/hifz/research/hifz-struggles.md` (11 struggles with solutions)
- **Context research:** `docs/features/hifz/research/context-aware-memorization.md`

### Logo Concept
A **faceted diamond/jewel** mark — geometric, angular, suggesting Arabic letterforms and crystalline structure. Pure B&W, no gradients. Must work at 16×16 favicon and 1024×1024 app icon. The diamond is the central visual motif for the website animations.

---

## 🎨 Design Inspiration: Essence Flow

### What Essence Flow Does Well
Our custom Essence Flow design features:

1. **Hero Animation** — A fluid, scroll-triggered animation that demonstrates the product in action. Text morphs/flows as you scroll, creating a sense of transformation.
2. **Section Transitions** — Each section slides/fades in with scroll-based parallax, creating a cinematic storytelling flow.
3. **Video Embeds** — Product demos embedded mid-page with auto-play.
4. **Use Case Tabs** — Horizontal tab selector that switches content (Teams, Students, Developers, etc.) with smooth transitions.
5. **Testimonial Cards** — Social proof from notable figures with photos and quotes.
6. **Dark/light contrast** — Sections alternate between dark and light backgrounds.
7. **Platform badges** — Clear download CTAs with platform icons.

### How We Adapt This for Jawhar

| Design Pattern | Jawhar Adaptation |
|---|---|
| Hero text animation | **Diamond formation animation** — Arabic letters/particles flowing, converging, and crystallizing into the Jawhar diamond logo |
| Scroll-triggered sections | Same — each section (Problem → System → Understanding → Practice → Platforms) reveals with scroll |
| Use case tabs | **Persona tabs** — "Independent Learner" / "Returning Hafiz" / "Parent & Teacher" |
| Testimonials | **Struggle-to-solution stories** — real pain points from Reddit/forums mapped to features |
| Video demo | **App screen recordings** — embedded Lottie/video of session flow, flashcards, dashboard |
| Platform badges | Same — Windows, Android, iOS, macOS, Linux, Web |

---

## 🏗️ Tech Stack

| Layer | Technology | Why |
|---|---|---|
| **Framework** | Next.js 15 (App Router) | SSR/SSG for SEO, React ecosystem, Vercel deployment |
| **Styling** | Vanilla CSS + CSS Variables | Matches Vercel design system, maximum control |
| **3D / WebGL** | Three.js + React Three Fiber | Diamond logo animation, hero scene |
| **Scroll animations** | Framer Motion / GSAP ScrollTrigger | Scroll-triggered reveals, parallax effects |
| **SVG animations** | Framer Motion | Diamond facet animations, icon transitions |
| **Fonts** | Geist Sans + Geist Mono + Amiri | Brand consistency |
| **Icons** | Lucide React | Brand consistency |
| **Blog/Content** | MDX | Write articles in Markdown, render as React components |
| **Deployment** | Vercel | Perfect for Next.js, free tier, global CDN |
| **Analytics** | Vercel Analytics / Plausible | Privacy-first, no cookies |
| **Domain** | jawhar.app (preferred) | Or getjawhar.com, jawhar.io |

---

## 📄 Sitemap

```
jawhar.app/
├── /                          # Landing page (hero + features overview)
├── /features                  # Detailed feature breakdown
│   ├── /features/planning     # The Plan — adaptive daily plans
│   ├── /features/sessions     # The Session — structured practice
│   └── /features/understanding # The Understanding — tafsir, translations
├── /struggles                 # "11 Hifz Struggles & How Jawhar Solves Them"
├── /blog                      # SEO content hub
│   ├── /blog/memorize-quran-effectively
│   ├── /blog/sabaq-sabqi-manzil-explained
│   ├── /blog/mutashabihat-guide
│   └── ...
├── /download                  # Platform-specific download links
├── /about                     # Mission, team, story
├── /privacy                   # Privacy policy
├── /terms                     # Terms of service
└── /press                     # Media kit, screenshots, logo assets
```

---

## 🔷 Phase 1 — Hero & Landing Page (Priority: HIGHEST)

> **Goal:** A single stunning page that makes people want to download the app immediately.

### 1.1 Three.js Diamond Hero Scene
- [ ] Model the Jawhar diamond as a low-poly faceted gem in Three.js
- [ ] Materials: glass/crystal with subtle refraction, pure B&W palette
- [ ] **Entry animation:** Diamond assembles from scattered particles/Arabic letter fragments
- [ ] **Idle animation:** Slow rotation with light refracting through facets
- [ ] **Scroll-triggered:** Diamond transforms/dissolves as user scrolls into content sections
- [ ] Responsive: Fallback to SVG animation on mobile/low-GPU devices
- [ ] Performance: < 3s load, 60fps on mid-range hardware

### 1.2 Hero Section
- [ ] Jawhar wordmark (Geist Mono, lowercase)
- [ ] Primary tagline: "Memorize with Meaning"
- [ ] Subtitle: "The first Quran memorization companion built on understanding"
- [ ] CTA buttons: [Download] [Learn More]
- [ ] Arabic bismillah or verse fragment as subtle background texture

### 1.3 Problem Section (scroll-triggered)
- [ ] Headline: "500+ Quran apps. None help you understand what you memorize."
- [ ] 3 pain-point cards with fade-in animation:
  - "Hifz is 80% revision. No app plans it."
  - "I memorized Juz 30 but can't explain a single verse."
  - "The same app over and over."
- [ ] Source: Reddit, app store reviews (from `hifz-struggles.md`)

### 1.4 The System Section
- [ ] Visual: Sabaq → Sabqi → Manzil pipeline animation
- [ ] Three connected cards showing the flow
- [ ] Headline: "Not a tracker. A system."
- [ ] Subtext: "The methodology your teacher uses — now in your pocket."

### 1.5 The Understanding Section
- [ ] Split-screen mockup: Arabic verse (left) ↔ Translation + Tafsir + Asbab (right)
- [ ] Headline: "Every verse you memorize, you understand."
- [ ] Feature chips: Translations · Tafsir (Brief + Detailed) · Reasons of Revelation · Surah Introductions

### 1.6 The Difference Section
- [ ] Comparison table (animated row-by-row reveal):
  
  | Feature | Others | Jawhar |
  |---|---|---|
  | Adaptive daily plans | ❌ | ✅ |
  | Session mode with timer | ❌ | ✅ |
  | Tafsir & understanding | ❌ | ✅ |
  | SRS flashcards + Mutashabihat | ❌ | ✅ |
  | Desktop support | ❌ | ✅ |
  | Free, no ads | ⚠️ | ✅ |

### 1.7 Platform Section
- [ ] "Available everywhere you study"
- [ ] Platform icons: Windows · macOS · Linux · Android · iOS · Web
- [ ] Download buttons per platform

### 1.8 Footer
- [ ] "Built with the Quran Foundation API"
- [ ] "Open source · Privacy-first · Free forever"
- [ ] Links: GitHub, Twitter/X, Instagram, Discord
- [ ] Newsletter signup (optional)

---

## 🔷 Phase 2 — Features Pages

> **Goal:** Deep dives into each pillar for users who want to learn more.

### 2.1 Features Overview (`/features`)
- [ ] The three pillars presented as interactive cards
- [ ] Each card expands/links to its detail page
- [ ] App screenshots embedded as mockups

### 2.2 The Plan (`/features/planning`)
- [ ] How profile assessment works (9-screen wizard)
- [ ] How daily plans are generated (Sabaq/Sabqi/Manzil)
- [ ] Adaptive calibration based on performance
- [ ] Pace projection ("At this pace, you'll finish in X months")
- [ ] Animated diagram of the plan generation pipeline

### 2.3 The Session (`/features/sessions`)
- [ ] Physical Quran mode (timer, rep counter, self-assessment)
- [ ] Digital mode (in-app reading with verse highlighting)
- [ ] Phase progression: Sabaq → Sabqi → Manzil
- [ ] Session complete summary
- [ ] Video/GIF of session flow

### 2.4 The Understanding (`/features/understanding`)
- [ ] Translation overlay demo
- [ ] Tafsir sheet (Brief + Detailed + Occasions)
- [ ] Asbab al-Nuzul cards
- [ ] Surah introductions
- [ ] "Memorization without understanding is incomplete" — the thesis

### 2.5 Practice Tools (sub-section or separate page)
- [ ] 6 flashcard types with visual examples
- [ ] SM-2 SRS explanation (simplified for users)
- [ ] Mutashabihat practice modes
- [ ] Weekly analytics & progress tracking

---

## 🔷 Phase 3 — Content & SEO

> **Goal:** Drive organic traffic with high-value content about Hifz.

### 3.1 Struggles Page (`/struggles`)
- [ ] "11 Hifz Struggles & How Jawhar Solves Them"
- [ ] Each struggle is a section with:
  - The problem (with real quotes from Reddit/forums)
  - Why it happens (psychology/pedagogy)
  - How Jawhar solves it (feature mapping)
- [ ] Source content: `docs/features/hifz/research/hifz-struggles.md`
- [ ] This is THE SEO pillar page — targets: "how to memorize quran", "hifz tips", "quran memorization struggles"

### 3.2 Blog System (`/blog`)
- [ ] MDX-based blog with SEO metadata
- [ ] Article ideas (from research):
  - "The Sabaq-Sabqi-Manzil Method Explained"
  - "Why You Keep Forgetting What You Memorized"
  - "Mutashabihat: The Similar Verses That Trip Every Hafiz"
  - "How to Return to Hifz After a Long Break"
  - "The Science of Spaced Repetition for Quran Memorization"
  - "Why Understanding Beats Repetition: The Tafsir Advantage"
  - "Desktop Hifz: Why Screen Size Matters for Memorization"
- [ ] Each article links back to relevant Jawhar features

### 3.3 SEO Infrastructure
- [ ] `sitemap.xml` auto-generated
- [ ] `robots.txt` configured
- [ ] Open Graph + Twitter Card meta tags per page
- [ ] JSON-LD structured data (SoftwareApplication schema)
- [ ] Blog posts with proper heading hierarchy (H1 → H2 → H3)
- [ ] Image alt text and lazy loading
- [ ] Core Web Vitals optimization (LCP < 2.5s, CLS < 0.1)

---

## 🔷 Phase 4 — Advanced Animations & Polish

> **Goal:** Elevate from "good website" to "this is art."

### 4.1 Diamond Animation Library (SVG)
- [ ] Create reusable SVG diamond component with facet animations
- [ ] States: idle rotation, hover pulse, click shatter/reform, loading spinner
- [ ] These SVGs can later be ported to Flutter for the app UI

### 4.2 Three.js Diamond Exploration
- [ ] Interactive 3D diamond on a dedicated `/brand` or `/about` page
- [ ] User can rotate/zoom the diamond with mouse/touch
- [ ] Light passes through the crystal, creating rainbow refractions
- [ ] Arabic calligraphy etched into the facets (visible at certain angles)

### 4.3 Scroll Storytelling
- [ ] Full scroll-driven narrative: "Your Hifz journey, reimagined"
- [ ] Each scroll position maps to a stage of the journey:
  - Assessment → First session → First review → First milestone → Understanding unlocked
- [ ] Parallax layers with Arabic text flowing in the background

### 4.4 Micro-interactions
- [ ] Button hover effects (diamond facet shimmer)
- [ ] Navigation transitions (page-to-page morphing)
- [ ] Cursor effects on hero section
- [ ] Loading states with diamond rotation

### 4.5 Dark/Light Mode
- [ ] Default: Dark (black background, white text — matches app)
- [ ] Toggle with smooth transition
- [ ] Respect `prefers-color-scheme`

---

## 🔷 Phase 5 — Download & Distribution

### 5.1 Download Page (`/download`)
- [ ] Auto-detect OS and show primary CTA
- [ ] Manual platform selection below
- [ ] Version number and changelog link
- [ ] GitHub Releases integration (APK for Android sideload)

### 5.2 App Store Preparation
- [ ] App Store screenshots (from app running on device/emulator)
- [ ] Description copy (from `jawhar_brand_identity.md`)
- [ ] Keyword optimization
- [ ] Preview video (screen recording of key flows)

---

## 🔷 Phase 6 — Press & Media Kit

### 6.1 Press Page (`/press`)
- [ ] One-liner, short bio, long bio
- [ ] High-res logo downloads (SVG + PNG, black/white variants)
- [ ] App screenshots (curated, high-quality)
- [ ] Founder photo/bio (if desired)
- [ ] Press inquiries contact

---

## 📋 Priority Order for Hackathon (May 20)

Given the May 20 deadline, here's what to ship first:

| Priority | What | Time Estimate |
|---|---|---|
| 🔴 P0 | Phase 1 — Landing page with hero animation | 2-3 days |
| 🟡 P1 | Phase 3.1 — Struggles page (SEO pillar) | 1 day |
| 🟡 P1 | Phase 5.1 — Download page | 0.5 days |
| 🟢 P2 | Phase 2 — Features pages | 1-2 days |
| 🟢 P2 | Phase 4 — Advanced animations | Ongoing polish |
| ⚪ P3 | Phase 3.2 — Blog system | Post-hackathon |
| ⚪ P3 | Phase 6 — Press kit | Post-hackathon |

---

## 🔗 Key References

### Local Files
| File | What it contains |
|---|---|
| `docs/brand-strategy.md` | Full brand strategy, positioning, messaging, voice |
| `DESIGN.md` | Vercel/Geist design system spec |
| `docs/features/hifz/hifz-roadmap.md` | Complete feature roadmap (Phases 1-7) |
| `docs/features/hifz/research/hifz-struggles.md` | 11 struggles with solutions (content for /struggles page) |
| `docs/features/hifz/research/context-aware-memorization.md` | Tafsir, asbab al-nuzul research |
| `docs/features/hifz/methods-and-planning/methods-overview.md` | Sabaq/Sabqi/Manzil framework |
| `docs/features/hifz/methods-and-planning/session-design.md` | Session UX spec |
| `docs/features/hifz/user-flows.md` | 12 user flows |

### External References
| Resource | URL |
|---|---|
| Essence Flow (custom animation design) | https://vercel.com |
| Vercel.com (design inspiration) | https://vercel.com |
| Three.js | https://threejs.org |
| React Three Fiber | https://r3f.docs.pmnd.rs |
| Framer Motion | https://motion.dev |
| GSAP ScrollTrigger | https://gsap.com/docs/v3/Plugins/ScrollTrigger |
| Lucide Icons | https://lucide.dev |
| Geist Font | https://vercel.com/font |

### Market Data (for copy)
- **Market size:** 2B+ Muslims, 540M digital-native youth by 2030, $163B EdTech market
- **Pain points:** "Hifz is 80% revision but no app has revision logic", "Same app over and over", 56% post-Ramadan uninstall rate
- **Gap:** No competitor combines adaptive Hifz planning + deep content understanding
- **Competitors lacking:** None offers adaptive daily plan generation + digital session mode + mutashabihat practice + SRS flashcards in one app

### Competitor Comparison (for /features difference section)
| Competitor | Downloads | What They Lack |
|---|---|---|
| Tarteel AI | 15M+ | No plan generation, no session management, no revision scheduling |
| Mathani | 200K+ | Too restrictive, can't review full Juz, no page-level work |
| Retain Quran | 1M+ | Flashcard-only, no structured methodology, no session UX |
| Al Muhaffiz | 50K+ | Dated UI, crashes, no AI, no adaptive planning |
| **ALL of them** | — | None combines planning + sessions + understanding + practice |

---

## 🎯 Success Metrics

| Metric | Target |
|---|---|
| Lighthouse Performance | > 95 |
| Lighthouse SEO | 100 |
| First Contentful Paint | < 1.5s |
| Largest Contentful Paint | < 2.5s |
| Cumulative Layout Shift | < 0.1 |
| Time to Interactive | < 3.5s |
| Hero animation frame rate | 60fps |
| Mobile responsiveness | All breakpoints (320px → 2560px) |

---

*Created: May 13, 2026*
*Last updated: May 13, 2026*
