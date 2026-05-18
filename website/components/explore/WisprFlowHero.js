"use client";

import { useRef } from 'react';
import gsap from 'gsap';
import { useGSAP } from '@gsap/react';
import { 
  Globe, Mic, BookOpen, ArrowRightLeft, 
  RefreshCcw, ListTodo, Moon, PieChart, Timer 
} from 'lucide-react';
import styles from './WisprFlow.module.css';
import DiamondSprite from './DiamondSprite';

// ──────────────────────────────────────────────
// Data — Left: Verse Cards (3 rows × 3 cards)
// ──────────────────────────────────────────────
const VERSE_ROWS = [
  [
    { surah: "Al-Fatiha", num: "1:1", text: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ" },
    { surah: "Al-Baqarah", num: "2:255", text: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ" },
    { surah: "Al-Ikhlas", num: "112:1", text: "قُلْ هُوَ اللَّهُ أَحَدٌ" },
  ],
  [
    { surah: "Ya-Sin", num: "36:1", text: "يس" },
    { surah: "Al-Rahman", num: "55:13", text: "فَبِأَيِّ آلَاءِ رَبِّكُمَا تُكَذِّبَانِ" },
    { surah: "Al-Mulk", num: "67:1", text: "تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ" },
  ],
  [
    { surah: "Al-Kahf", num: "18:1", text: "الْحَمْدُ لِلَّهِ الَّذِي أَنزَلَ" },
    { surah: "Al-Naba", num: "78:1", text: "عَمَّ يَتَسَاءَلُونَ" },
    { surah: "Al-Falaq", num: "113:1", text: "قُلْ أَعُوذُ بِرَبِّ الْفَلَقِ" },
  ],
];

// ──────────────────────────────────────────────
// Data — Right: Feature Cards (3 rows × 3 cards)
// ──────────────────────────────────────────────
const FEATURE_ROWS = [
  [
    { type: "translation", label: "Translation", text: "In the name of Allah, the Entirely Merciful" },
    { type: "reciter", label: "Reciter", text: "Mishary al-Afasy", sub: "Warsh · Al-Fatiha" },
    { type: "tafsir", label: "Tafsir", text: "The Basmalah opens every surah except At-Tawbah" },
  ],
  [
    { type: "mutashabihat", label: "Mutashabihat", v1: "2:255 اللَّهُ", v2: "3:2 اللَّهُ" },
    { type: "flashcard", label: "Flashcard", text: "What does الرَّحْمَٰنِ mean?" },
    { type: "plan", label: "Daily Plan", text: "Sabaq: p.305–306 · Manzil: p.1–10" },
  ],
  [
    { type: "asbab", label: "Asbab al-Nuzul", text: "Revealed in Mecca, 5th year of prophecy" },
    { type: "progress", label: "Progress", text: "Juz 1 — 72% memorized" },
    { type: "session", label: "Session", text: "15 min · 5 reps · Self-assessed: Good" },
  ],
];

const FEATURE_ICONS = {
  translation: <Globe size={14} />, reciter: <Mic size={14} />, tafsir: <BookOpen size={14} />,
  mutashabihat: <ArrowRightLeft size={14} />, flashcard: <RefreshCcw size={14} />, plan: <ListTodo size={14} />,
  asbab: <Moon size={14} />, progress: <PieChart size={14} />, session: <Timer size={14} />,
};



// ──────────────────────────────────────────────
// Sub-components
// ──────────────────────────────────────────────
function VerseCard({ surah, num, text }) {
  return (
    <div className={styles.verseCard}>
      <div className={styles.verseBadge}>{num}</div>
      <div className={styles.verseBody}>
        <span className={styles.verseText}>{text}</span>
        <span className={styles.verseSurah}>{surah}</span>
      </div>
    </div>
  );
}

function FeatureCard({ type, label, text, sub, v1, v2 }) {
  if (type === "mutashabihat") {
    return (
      <div className={styles.featureCard}>
        <div className={styles.featureIcon}>{FEATURE_ICONS[type]}</div>
        <div className={styles.featureBody}>
          <span className={styles.featureLabel}>{label}</span>
          <div className={styles.mutaPair}>
            <span className={styles.mutaVerse}>{v1}</span>
            <span className={styles.mutaDivider}>≈</span>
            <span className={styles.mutaVerse}>{v2}</span>
          </div>
        </div>
      </div>
    );
  }

  if (type === "reciter") {
    return (
      <div className={styles.featureCard}>
        <div className={styles.reciterAvatar}>MA</div>
        <div className={styles.featureBody}>
          <span className={styles.featureLabel}>{label}</span>
          <span className={styles.featureText}>{text}</span>
          {sub && <span className={styles.featureSub}>{sub}</span>}
        </div>
      </div>
    );
  }

  return (
    <div className={styles.featureCard}>
      <div className={styles.featureIcon}>{FEATURE_ICONS[type]}</div>
      <div className={styles.featureBody}>
        <span className={styles.featureLabel}>{label}</span>
        <span className={styles.featureText}>{text}</span>
        {sub && <span className={styles.featureSub}>{sub}</span>}
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────
// Conveyor Row — renders cards duplicated for seamless loop
// ──────────────────────────────────────────────
function ConveyorRow({ cards, side, trackClass, renderCard }) {
  return (
    <div className={styles.conveyorRow}>
      <div className={`${styles.conveyorTrack} ${trackClass}`}>
        {/* Original set */}
        {cards.map((c, i) => renderCard(c, `a-${i}`))}
        {/* Duplicate for seamless loop */}
        {cards.map((c, i) => renderCard(c, `b-${i}`))}
        {/* Triple for wide screens */}
        {cards.map((c, i) => renderCard(c, `c-${i}`))}
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────
// Main Component
// ──────────────────────────────────────────────
export default function WisprFlowHero() {
  const containerRef = useRef();

  // Entrance & Conveyor belt animation
  useGSAP(() => {
    const container = containerRef.current;
    if (!container) return;

    // --- Entrance Animation ---
    const tl = gsap.timeline();

    // Target global nav and footer from root layout
    const navbar = document.querySelector('nav');
    const footer = document.querySelector('footer');
    const localDiamond = container.querySelector(`.${styles.diamond}`);

    // Initially hide everything
    gsap.set(navbar, { y: -60, opacity: 0 });
    if (footer) gsap.set(footer, { opacity: 0 });
    if (localDiamond) gsap.set(localDiamond, { scale: 0, opacity: 0 });
    
    gsap.set(container.querySelectorAll(`.${styles.conveyorRow}`), { 
      opacity: 0, 
      x: (i) => i < 3 ? -100 : 100 
    });
    gsap.set('.split-char', { y: 40, opacity: 0 });
    gsap.set(container.querySelectorAll(`.${styles.copy} > p`), { y: 15, opacity: 0 });
    gsap.set(container.querySelectorAll(`.${styles.ctas}`), { y: 10, opacity: 0 });

    // 1. Diamond scales in from center (the star of the show)
    if (localDiamond) {
      tl.to(localDiamond, {
        scale: 1,
        opacity: 1,
        duration: 1.5,
        ease: "power3.out"
      });
    }

    // 2. Navbar slides down from top
    tl.to(navbar, {
      y: 0,
      opacity: 1,
      duration: 0.8,
      ease: "power2.out"
    }, "-=0.6")
    // 2. Conveyors slide in from sides
    .to(container.querySelectorAll(`.${styles.conveyorRow}`), {
      opacity: 1,
      x: 0,
      duration: 1.2,
      stagger: 0.1,
      ease: "power2.out"
    }, "-=0.4")
    // 4. Hero headline — character by character, quick and smooth
    .to('.split-char', {
      y: 0,
      opacity: 1,
      duration: 0.5,
      stagger: 0.03,
      ease: "power2.out"
    }, "-=0.8")
    // 5. Subtitle
    .to(container.querySelectorAll(`.${styles.copy} > p`), {
      y: 0,
      opacity: 1,
      duration: 0.5,
      stagger: 0.08,
      ease: "power2.out"
    }, "-=0.3")
    // 6. CTAs — simple slide up + fade
    .to(container.querySelectorAll(`.${styles.ctas}`), {
      y: 0,
      opacity: 1,
      duration: 0.4,
      ease: "power2.out"
    }, "-=0.2")
    // 7. Footer fades in (subtle, after everything else)
    .to(footer, {
      opacity: 1,
      duration: 0.6,
      ease: "power1.out"
    }, "-=0.3");

    // --- Continuous Conveyor Animations ---
    const leftSpeeds = [40, 60, 80];
    const rightSpeeds = [35, 55, 70];

    // Left side
    container.querySelectorAll('.left-track').forEach((track, i) => {
      const setWidth = track.scrollWidth / 3;
      if (setWidth === 0) return;
      gsap.fromTo(track,
        { x: -setWidth },
        { x: 0, duration: setWidth / leftSpeeds[i], ease: "none", repeat: -1 }
      );
    });

    // Right side
    container.querySelectorAll('.right-track').forEach((track, i) => {
      const setWidth = track.scrollWidth / 3;
      if (setWidth === 0) return;
      gsap.fromTo(track,
        { x: -setWidth },
        { x: 0, duration: setWidth / rightSpeeds[i], ease: "none", repeat: -1 }
      );
    });
  }, { scope: containerRef });

  return (
    <section className={styles.section} ref={containerRef}>
      <div className={styles.stage}>

        {/* Ambient glow */}
        <div className={styles.glow} />

        {/* ── Left: Verse Conveyor ── */}
        <div className={styles.conveyorLeft}>
          {VERSE_ROWS.map((row, ri) => (
            <ConveyorRow
              key={`vr-${ri}`}
              cards={row}
              side="left"
              trackClass={`left-track`}
              renderCard={(c, key) => (
                <VerseCard key={key} surah={c.surah} num={c.num} text={c.text} />
              )}
            />
          ))}
        </div>

        {/* ── Center Space: Diamond ── */}
        <div className={styles.diamond}>
          <DiamondSprite />
        </div>

        {/* ── Right: Feature Conveyor ── */}
        <div className={styles.conveyorRight}>
          {FEATURE_ROWS.map((row, ri) => (
            <ConveyorRow
              key={`fr-${ri}`}
              cards={row}
              side="right"
              trackClass={`right-track`}
              renderCard={(c, key) => (
                <FeatureCard key={key} {...c} />
              )}
            />
          ))}
        </div>

      </div>

      {/* ── Hero copy ── */}
      <div className={styles.copy}>
        <p className={styles.wordmark}>jawhar</p>
        <h1 className={styles.headline}>
          {"Memorize with Meaning.".split('').map((char, i) => (
            <span
              key={i}
              style={{ display: 'inline-block', overflow: 'hidden' }}
            >
              <span
                className="split-char"
                style={{ display: 'inline-block', whiteSpace: 'pre' }}
              >
                {char === ' ' ? '\u00A0' : char}
              </span>
            </span>
          ))}
        </h1>
        <p className={styles.subtitle}>
          The first Quran companion built on understanding.<br/>
          Closed source for now. Free forever.
        </p>
        <div className={styles.ctas}>
          <a href="#waitlist" className="btn btn-primary btn-large">
            Join the Waitlist
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
          </a>
        </div>
      </div>
    </section>
  );
}
