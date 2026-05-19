"use client";

import { useRef, useEffect } from 'react';
import gsap from 'gsap';
import { useGSAP } from '@gsap/react';
import { 
  Globe, Mic, BookOpen, ArrowRightLeft, 
  RefreshCcw, ListTodo, Moon, PieChart, Timer 
} from 'lucide-react';
import styles from './WisprFlow.module.css';
import DiamondSprite from './DiamondSprite';


// ──────────────────────────────────────────────
// Data — The 3 Spotlight Pairings
// ──────────────────────────────────────────────
const SPOTLIGHT_PAIRS = [
  {
    // Pair 1: Understand (Tafsir)
    verse: { surah: "Al-Kawthar", num: "108:1", text: "إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ" },
    app: {
      type: "tafsir",
      translation: "Indeed, We have granted you al-Kawthar",
      note: "Al-Kawthar refers to a river in Paradise, revealed as a profound comfort to the Prophet ﷺ during a time of immense grief and loss."
    }
  },
  {
    // Pair 2: Practice (Flashcard)
    verse: { surah: "Al-Qadr", num: "97:1", text: "إِنَّا أَنزَلْنَاهُ فِي لَيْلَةِ الْقَدْرِ" },
    app: {
      type: "flashcard",
      instruction: "Recall the next verse",
      answer: "وَمَا أَدْرَاكَ مَا لَيْلَةُ الْقَدْرِ"
    }
  },
  {
    // Pair 3: Plan (Structured Hifz)
    verse: { surah: "Al-Mulk", num: "67:1", text: "تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ" },
    app: {
      type: "plan",
      title: "Today's Plan",
      phase: "Sabaq",
      desc: "Surah Al-Mulk (1-12)",
      time: "15m"
    }
  }
];



// ──────────────────────────────────────────────
// Sub-components
// ──────────────────────────────────────────────
function VerseCard({ surah, num, text, spotlightGroup, positionClass }) {
  return (
    <div className={`${styles.verseCard} ${styles.absNode} ${positionClass}`} data-spotlight-group={spotlightGroup}>
      <div className={styles.verseBadge}>{num}</div>
      <div className={styles.verseBody}>
        <span className={styles.verseText}>{text}</span>
        <span className={styles.verseSurah}>{surah}</span>
      </div>
    </div>
  );
}

function AppCard({ data, spotlightGroup, positionClass }) {
  const { type } = data;

  if (type === "tafsir") {
    return (
      <div className={`${styles.appCard} ${styles.absNode} ${positionClass}`} data-spotlight-group={spotlightGroup}>
        <div className={styles.tafsirHeader}>
          <BookOpen size={14} className={styles.tafsirIcon} />
          <span>Brief Tafsir</span>
        </div>
        <div className={styles.tafsirTranslation}>{data.translation}</div>
        <div className={styles.tafsirNote}>{data.note}</div>
      </div>
    );
  }

  if (type === "flashcard") {
    return (
      <div className={`${styles.appCard} ${styles.absNode} ${positionClass}`} data-spotlight-group={spotlightGroup}>
        <div className={styles.fcBadge}>Flashcard</div>
        <div className={styles.fcInstruction}>{data.instruction}</div>
        <div className={styles.fcAnswer}>{data.answer}</div>
        <div className={styles.fcRatings}>
          <div className={styles.fcRatingBtn}>
            <div className={styles.fcRatingBox}>1</div>
            <span className={styles.fcRatingLabel}>Forgot</span>
          </div>
          <div className={styles.fcRatingBtn}>
            <div className={styles.fcRatingBox}>2</div>
            <span className={styles.fcRatingLabel}>Weak</span>
          </div>
          <div className={styles.fcRatingBtn}>
            <div className={styles.fcRatingBox}>3</div>
            <span className={styles.fcRatingLabel}>OK</span>
          </div>
          <div className={styles.fcRatingBtn}>
            <div className={styles.fcRatingBox}>4</div>
            <span className={styles.fcRatingLabel}>Strong</span>
          </div>
        </div>
      </div>
    );
  }

  if (type === "plan") {
    return (
      <div className={`${styles.appCard} ${styles.absNode} ${positionClass}`} data-spotlight-group={spotlightGroup}>
        <div className={styles.planHeader}>
          <span className={styles.planTitle}>{data.title}</span>
          <div className={styles.planTimePill}>
            <Timer size={10} /> {data.time}
          </div>
        </div>
        <div className={styles.planPhase}>
          <div className={styles.planPhaseName}>{data.phase}</div>
          <div className={styles.planPhaseDesc}>{data.desc}</div>
        </div>
        <div className={styles.planCta}>
          Start Session
        </div>
      </div>
    );
  }

  return null;
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
    
    gsap.set(container.querySelectorAll(`.${styles.verseCard}, .${styles.appCard}`), { 
      opacity: 0, 
      scale: 0.8
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
    // 3. Cards pop in
    .to(container.querySelectorAll(`.${styles.verseCard}, .${styles.appCard}`), {
      opacity: 1,
      scale: 1,
      duration: 1.0,
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


  }, { scope: containerRef });

  // --- Spotlight Cycle ---
  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    let spotlightIndex = 0;
    let isSpotlit = false;

    function applySpotlight() {
      const stage = container.querySelector(`.${styles.stage}`);
      if (!stage) return;

      // Add drifting class to dim all cards
      stage.classList.add(styles.drifting);

      // Spotlight matching group
      const cards = container.querySelectorAll(`[data-spotlight-group="${spotlightIndex}"]`);
      cards.forEach((card) => card.classList.add(styles.spotlit));

      // Activate corresponding SVG path
      const paths = container.querySelectorAll(`.${styles.beamLine}`);
      paths.forEach((p, idx) => {
        if (idx === spotlightIndex) {
          p.classList.add(styles.activePath);
        } else {
          p.classList.remove(styles.activePath);
        }
      });

      // Diamond pulse
      const diamond = container.querySelector(`.${styles.diamond}`);
      if (diamond) {
        gsap.fromTo(diamond,
          { scale: 1 },
          { scale: 1.1, duration: 0.4, yoyo: true, repeat: 1, ease: "power2.inOut" }
        );
      }

      isSpotlit = true;
    }

    function removeSpotlight() {
      const stage = container.querySelector(`.${styles.stage}`);
      if (!stage) return;

      stage.classList.remove(styles.drifting);
      container.querySelectorAll(`.${styles.spotlit}`).forEach((card) => {
        card.classList.remove(styles.spotlit);
      });
      container.querySelectorAll(`.${styles.activePath}`).forEach((path) => {
        path.classList.remove(styles.activePath);
      });

      isSpotlit = false;
      spotlightIndex = (spotlightIndex + 1) % 3;
    }

    // Start cycle after entrance animation (~4s)
    const startDelay = setTimeout(() => {
      applySpotlight();
    }, 4500);

    // More precise timing: use alternating timeouts
    let timeout;
    function cycle() {
      if (isSpotlit) {
        removeSpotlight();
        timeout = setTimeout(cycle, 4000); // drift for 4s
      } else {
        applySpotlight();
        timeout = setTimeout(cycle, 3000); // hold for 3s
      }
    }
    const cycleStart = setTimeout(() => {
      cycle();
    }, 4500);

    return () => {
      clearTimeout(startDelay);
      clearTimeout(cycleStart);
      clearTimeout(timeout);
    };
  }, []);

  return (
    <section className={styles.section} ref={containerRef}>
      <div className={styles.stage}>

        {/* Ambient glow */}
        <div className={styles.glow} />

        {/* ── Background SVG Beams ── */}
        <svg className={styles.beams} preserveAspectRatio="none">
          <defs>
            <linearGradient id="beamGradLeft" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="rgba(255,255,255,0)" />
              <stop offset="100%" stopColor="rgba(200,200,200,0.8)" />
            </linearGradient>
            <linearGradient id="beamGradRight" x1="0%" y1="0%" x2="100%" y2="0%">
              <stop offset="0%" stopColor="rgba(200,200,200,0.8)" />
              <stop offset="100%" stopColor="rgba(255,255,255,0)" />
            </linearGradient>
          </defs>
          
          <g className={styles.beamLine}>
            <line x1="42%" y1="5%" x2="50%" y2="50%" stroke="url(#beamGradLeft)" />
            <line x1="50%" y1="50%" x2="58%" y2="5%" stroke="url(#beamGradRight)" />
          </g>
          
          <g className={styles.beamLine}>
            <line x1="32%" y1="40%" x2="50%" y2="50%" stroke="url(#beamGradLeft)" />
            <line x1="50%" y1="50%" x2="68%" y2="40%" stroke="url(#beamGradRight)" />
          </g>
          
          <g className={styles.beamLine}>
            <line x1="42%" y1="75%" x2="50%" y2="50%" stroke="url(#beamGradLeft)" />
            <line x1="50%" y1="50%" x2="58%" y2="75%" stroke="url(#beamGradRight)" />
          </g>
        </svg>

        {/* ── Left: Verse Constellation ── */}
        <div className={styles.constellationLeft}>
          {SPOTLIGHT_PAIRS.map((pair, idx) => (
            <VerseCard 
              key={`v-${idx}`} 
              surah={pair.verse.surah} 
              num={pair.verse.num} 
              text={pair.verse.text} 
              spotlightGroup={idx} 
              positionClass={styles[`nodeL${idx}`]}
            />
          ))}
        </div>

        {/* ── Center Space: Diamond ── */}
        <div className={styles.diamond}>
          <DiamondSprite />
        </div>

        {/* ── Right: App Constellation ── */}
        <div className={styles.constellationRight}>
          {SPOTLIGHT_PAIRS.map((pair, idx) => (
            <AppCard 
              key={`a-${idx}`} 
              data={pair.app} 
              spotlightGroup={idx} 
              positionClass={styles[`nodeR${idx}`]}
            />
          ))}
        </div>

      </div>

      {/* ── Hero copy ── */}
      <div className={styles.copy}>
        <p className={styles.wordmark}>jawhar</p>
        <p className={styles.lensLine}>Verse in. Meaning out.</p>
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
          Meaning becomes the anchor. The plan follows.<br/>
          Read, understand, and review with one quiet system.
        </p>
        <div className={styles.ctas}>
          <a href="#closing" className="btn btn-primary btn-large">
            Join the Waitlist
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>
          </a>
        </div>
      </div>
    </section>
  );
}
