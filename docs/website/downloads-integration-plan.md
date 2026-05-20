# Downloads Integration & Waitlist Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transition the website from a private waitlist model to a direct public download/testing model for Windows, Android, and iOS.

**Architecture:** Update the landing page to restore the climax section, replace the waitlist form with a direct downloads CTA, configure the dedicated downloads page with direct GitHub releases download links and the Apple TestFlight invite URL, and remove waitlist-related assets.

**Tech Stack:** Next.js, React, Vanilla CSS.

---

### Task 1: Update Dedicated Downloads Page

**Files:**
- Modify: [page.js](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/website/app/download/page.js)

- [ ] **Step 1: Update platform links and availability**
  Modify the `platforms` array at the top of the file to point Windows and Android to the direct redirect release links, make iOS available with the active TestFlight invite link, and update their action strings:
  ```javascript
  const platforms = [
    {
      icon: Monitor,
      name: "Windows",
      action: "Download ZIP",
      href: "https://github.com/khalidouhdane/jawhar/releases/latest/download/jawhar-windows.zip",
      available: true,
    },
    {
      icon: Smartphone,
      name: "Android",
      action: "Download APK",
      href: "https://github.com/khalidouhdane/jawhar/releases/latest/download/app-release.apk",
      available: true,
    },
    {
      icon: Laptop,
      name: "macOS",
      action: "Coming soon",
      available: false,
    },
    {
      icon: Monitor,
      name: "Linux",
      action: "Coming soon",
      available: false,
    },
    {
      icon: Smartphone,
      name: "iOS",
      action: "Join TestFlight",
      href: "https://testflight.apple.com/join/XYY6tqxC",
      available: true,
    },
    {
      icon: Globe,
      name: "Web",
      action: "Coming soon",
      available: false,
    },
  ];
  ```

- [ ] **Step 2: Update `detectOS()` function to prioritize iOS**
  Rearrange `detectOS()` inside the same file to prevent iOS devices from hitting macOS or generic fallbacks:
  ```javascript
  function detectOS() {
    if (typeof navigator === "undefined") return null;
    const ua = navigator.userAgent;
    if (/iPhone|iPad|iPod/.test(ua)) return "iOS";
    if (/Android/.test(ua)) return "Android";
    if (/Windows/.test(ua)) return "Windows";
    if (/Mac/.test(ua)) return "macOS";
    if (/Linux/.test(ua)) return "Linux";
    return null;
  }
  ```

---

### Task 2: Restore Homepage Climax & Update Sections

**Files:**
- Modify: [ScrollStory.js](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/website/components/sections/ScrollStory.js)
- Modify: [ClosingSection.js](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/website/components/sections/ClosingSection.js)
- Modify: [PlatformSection.js](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/website/components/sections/PlatformSection.js)
- Modify: [EssenceFlowHero.js](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/website/components/explore/EssenceFlowHero.js)

- [ ] **Step 1: Re-add `ClosingSection` to homepage**
  Modify [ScrollStory.js](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/website/components/sections/ScrollStory.js) to import and render `<ClosingSection />`:
  ```javascript
  "use client";
  
  import EssenceFlowHero from '../explore/EssenceFlowHero';
  import ProblemSection from './ProblemSection';
  import ReadSection from './ReadSection';
  import UnderstandSection from './UnderstandSection';
  import MemorizeSection from './MemorizeSection';
  import StrategySection from './StrategySection';
  import ClosingSection from './ClosingSection';
  
  export default function ScrollStory() {
    return (
      <div style={{ position: 'relative' }}>
        <div style={{ position: 'relative', zIndex: 1 }}>
          <EssenceFlowHero />
          <ProblemSection />
          <ReadSection />
          <UnderstandSection />
          <MemorizeSection />
          <StrategySection />
          <ClosingSection />
        </div>
      </div>
    );
  }
  ```

- [ ] **Step 2: Replace Waitlist form with downloads link in `ClosingSection`**
  Modify [ClosingSection.js](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/website/components/sections/ClosingSection.js):
  - Remove `import WaitlistForm from "../shared/WaitlistForm";`
  - Replace `<WaitlistForm />` with a direct Link to the downloads page.
  - Update `trust` caption and imports.
  ```javascript
  "use client";
  
  import { useRef } from "react";
  import gsap from "gsap";
  import { useGSAP } from "@gsap/react";
  import Link from "next/link";
  import DepthRings from "./DepthRings";
  import styles from "./ClosingSection.module.css";
  
  export default function ClosingSection() {
    const resolutionRef = useRef(null);
  
    function handleRingsComplete() {
      if (!resolutionRef.current) return;
      gsap.fromTo(
        resolutionRef.current,
        { opacity: 0, y: 20 },
        { opacity: 1, y: 0, duration: 0.8, ease: "power2.out" }
      );
    }
  
    useGSAP(() => {
      if (resolutionRef.current) {
        gsap.set(resolutionRef.current, { opacity: 0, y: 20 });
      }
    });
  
    return (
      <section id="closing" className="section">
        <div className="container">
          <p className="mono-label" style={{ textAlign: "center", marginBottom: 24 }}>
            Your journey
          </p>
  
          <DepthRings onAnimationComplete={handleRingsComplete} />
  
          <div className={styles.resolution} ref={resolutionRef}>
            <h2 className="heading-sub" style={{ textAlign: "center" }}>
              The app disappears. The Quran appears.
            </h2>
            <p className={`body-large ${styles.subtitle}`}>
              One companion for the entire journey — from your first page to your last.
            </p>
  
            <div className={styles.formWrap}>
              <Link href="/download" className="btn btn-primary btn-large">
                Download Jawhar
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M5 12h14"/>
                  <path d="m12 5 7 7-7 7"/>
                </svg>
              </Link>
            </div>
  
            <p className={styles.trust}>
              Windows · Android · iOS (TestFlight)
            </p>
          </div>
        </div>
      </section>
    );
  }
  ```

- [ ] **Step 3: Update `PlatformSection.js` availability**
  Modify the `platforms` list inside `PlatformSection.js` to set iOS as available:
  ```javascript
  const platforms = [
    { icon: Monitor, name: "Windows", available: true },
    { icon: Smartphone, name: "Android", available: true },
    { icon: Laptop, name: "macOS", soon: true },
    { icon: Monitor, name: "Linux", soon: true },
    { icon: Apple, name: "iOS", available: true },
    { icon: Globe, name: "Web", soon: true },
  ];
  ```

- [ ] **Step 4: Update Hero button to say "Download Jawhar"**
  Modify [EssenceFlowHero.js](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/website/components/explore/EssenceFlowHero.js) around line 653:
  ```javascript
          <div className={styles.ctas}>
            <a href="#closing" className="btn btn-primary btn-large">
              Download Jawhar
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
            </a>
          </div>
  ```

---

### Task 3: Update Secondary Pages (Hackathon & Privacy)

**Files:**
- Modify: [page.js](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/website/app/hackathon/page.js)
- Modify: [page.js](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/website/app/privacy/page.js)

- [ ] **Step 1: Replace early access link on Hackathon page**
  Modify [page.js](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/website/app/hackathon/page.js) lines 30-33:
  ```javascript
              <Link href="/download" className="h-12 px-8 rounded-full border border-white/20 flex items-center gap-2 font-medium hover:bg-white/5 transition-colors">
                <ArrowRight className="w-5 h-5" />
                Download App
              </Link>
  ```

- [ ] **Step 2: Clean up privacy policy waitlist references**
  Modify [page.js](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/website/app/privacy/page.js) to remove mentions of waitlist email databases since email collection is no longer done on the website.

---

### Task 4: Clean Up & Verification

- [ ] **Step 1: Remove waitlist components**
  Delete [WaitlistForm.js](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/website/components/shared/WaitlistForm.js) and [WaitlistForm.module.css](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/website/components/shared/WaitlistForm.module.css) from the filesystem.

- [ ] **Step 2: Run validation suite**
  Run: `npm run check:content`
  Expected: Success without assertion errors.

- [ ] **Step 3: Run production build**
  Run: `npm run build`
  Expected: Success, verified clean Next.js production output.
