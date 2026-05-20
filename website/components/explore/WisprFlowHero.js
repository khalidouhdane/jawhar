"use client";

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import gsap from 'gsap';
import { useGSAP } from '@gsap/react';
import { 
  Play, Check, BookOpen, Timer, 
  Sparkles, Volume2, Calendar 
} from 'lucide-react';
import styles from './WisprFlow.module.css';
import DiamondSprite from './DiamondSprite';

// ──────────────────────────────────────────────
// Data — The 3 Spotlight Verse Content
// ──────────────────────────────────────────────
const SPOTLIGHT_PAIRS = [
  {
    verse: { surah: "Surah Al-Kawthar", num: "108:1", text: "إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ" },
    translation: "Indeed, We have granted you Al-Kawthar.",
    accentColor: "#0a72ef", // Develop Blue
  },
  {
    verse: { surah: "Surah Al-Qadr", num: "97:1", text: "إِنَّا أَنزَلْنَاهُ فِي لَيْلَةِ الْقَدْرِ" },
    translation: "Indeed, We sent the Quran down during the Night of Decree.",
    accentColor: "#de1d8d", // Preview Pink
  },
  {
    verse: { surah: "Surah Al-Mulk", num: "67:1", text: "تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ" },
    translation: "Blessed is He in whose hand is the dominion.",
    accentColor: "#ff5b4f", // Ship Red
  }
];

// ──────────────────────────────────────────────
// Main Component
// ──────────────────────────────────────────────
export default function WisprFlowHero() {
  const containerRef = useRef();
  const [activeIndex, setActiveIndex] = useState(0);
  const [isAutoRotating, setIsAutoRotating] = useState(true);
  const autoRotateTimerRef = useRef(null);
  const manualTimeoutRef = useRef(null);

  // Auto rotation loop
  useEffect(() => {
    if (!isAutoRotating) return;

    autoRotateTimerRef.current = setInterval(() => {
      setActiveIndex((prev) => (prev + 1) % 3);
    }, 6000); // 6 second hold cycle

    return () => {
      if (autoRotateTimerRef.current) clearInterval(autoRotateTimerRef.current);
    };
  }, [isAutoRotating]);

  // Handle manual left card clicks
  const handleLeftCardClick = (index) => {
    setActiveIndex(index);
    setIsAutoRotating(false);

    // Reset previous timeouts
    if (autoRotateTimerRef.current) clearInterval(autoRotateTimerRef.current);
    if (manualTimeoutRef.current) clearTimeout(manualTimeoutRef.current);

    // Pulse center diamond on manual switch
    const diamond = containerRef.current?.querySelector(`.${styles.diamond}`);
    if (diamond) {
      gsap.fromTo(diamond,
        { scale: 1 },
        { scale: 1.08, duration: 0.3, yoyo: true, repeat: 1, ease: "power2.inOut" }
      );
    }

    // Set timeout to resume auto-rotation after 8s of inactivity
    manualTimeoutRef.current = setTimeout(() => {
      setIsAutoRotating(true);
    }, 8000);
  };

  // Entrance & Conveyor belt animation
  useGSAP(() => {
    const container = containerRef.current;
    if (!container) return;

    const tl = gsap.timeline();

    const navbar = document.querySelector('nav');
    const footer = document.querySelector('footer');
    const localDiamond = container.querySelector(`.${styles.diamond}`);
    
    // Set initial states for entrance stagger
    gsap.set(navbar, { y: -60, opacity: 0 });
    if (footer) gsap.set(footer, { opacity: 0 });
    if (localDiamond) gsap.set(localDiamond, { scale: 0, opacity: 0 });
    
    gsap.set(container.querySelectorAll(`.${styles.flowCard}`), { 
      opacity: 0, 
      scale: 0.8
    });
    gsap.set('.split-char', { y: 40, opacity: 0 });
    gsap.set(container.querySelectorAll(`.${styles.copy} > p`), { y: 15, opacity: 0 });
    gsap.set(container.querySelectorAll(`.${styles.ctas}`), { y: 10, opacity: 0 });

    // 1. Diamond and active left card entrance animates simultaneously
    if (localDiamond) {
      tl.to(localDiamond, {
        scale: 1,
        opacity: 1,
        duration: 1.2,
        ease: "power3.out"
      });
    }

    // 2. Navbar slides down
    tl.to(navbar, {
      y: 0,
      opacity: 1,
      duration: 0.8,
      ease: "power2.out"
    }, "-=0.8")
    // 3. Stagger-in all cards
    .to(container.querySelectorAll(`.${styles.flowCard}`), {
      opacity: 1,
      scale: 1,
      duration: 0.8,
      stagger: 0.08,
      ease: "power2.out"
    }, "-=0.6")
    // 4. Hero headline split-character reveal
    .to('.split-char', {
      y: 0,
      opacity: 1,
      duration: 0.5,
      stagger: 0.03,
      ease: "power2.out"
    }, "-=0.6")
    // 5. Hero Subtitle
    .to(container.querySelectorAll(`.${styles.copy} > p`), {
      y: 0,
      opacity: 1,
      duration: 0.5,
      stagger: 0.08,
      ease: "power2.out"
    }, "-=0.3")
    // 6. CTAs
    .to(container.querySelectorAll(`.${styles.ctas}`), {
      y: 0,
      opacity: 1,
      duration: 0.4,
      ease: "power2.out"
    }, "-=0.2")
    // 7. Footer
    .to(footer, {
      opacity: 1,
      duration: 0.6,
      ease: "power1.out"
    }, "-=0.3");

  }, { scope: containerRef });

  // Get active accent color
  const activeColor = SPOTLIGHT_PAIRS[activeIndex].accentColor;

  return (
    <section className={styles.section} ref={containerRef}>
      <div className={styles.stage}>

        {/* Ambient glow */}
        <div className={styles.glow} style={{ 
          background: `radial-gradient(circle, ${activeColor}15 0%, transparent 70%)`,
          transition: 'background 0.8s ease'
        }} />

        {/* ── Background SVG Beams with glow pulses ── */}
        <svg className={styles.beams} viewBox="0 0 1000 600" fill="none" preserveAspectRatio="none">
          {/* Static gray line tracks underneath */}
          <path d="M 210 90 Q 350 90 500 300" stroke="var(--card-border)" strokeWidth="1" fill="none" opacity="0.3" />
          <path d="M 160 270 Q 330 290 500 300" stroke="var(--card-border)" strokeWidth="1" fill="none" opacity="0.3" />
          <path d="M 210 450 Q 350 450 500 300" stroke="var(--card-border)" strokeWidth="1" fill="none" opacity="0.3" />
          
          <path d="M 500 300 Q 650 90 790 90" stroke="var(--card-border)" strokeWidth="1" fill="none" opacity="0.3" />
          <path d="M 500 300 Q 670 290 840 270" stroke="var(--card-border)" strokeWidth="1" fill="none" opacity="0.3" />
          <path d="M 500 300 Q 650 450 790 450" stroke="var(--card-border)" strokeWidth="1" fill="none" opacity="0.3" />

          {/* Left-to-Center active building drawing lines */}
          <motion.path
            d="M 210 90 Q 350 90 500 300"
            stroke="#0a72ef"
            strokeWidth="2"
            fill="none"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: activeIndex === 0 ? 1 : 0 }}
            transition={{ duration: 0.8, ease: "easeInOut" }}
          />
          <motion.path
            d="M 160 270 Q 330 290 500 300"
            stroke="#de1d8d"
            strokeWidth="2"
            fill="none"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: activeIndex === 1 ? 1 : 0 }}
            transition={{ duration: 0.8, ease: "easeInOut" }}
          />
          <motion.path
            d="M 210 450 Q 350 450 500 300"
            stroke="#ff5b4f"
            strokeWidth="2"
            fill="none"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: activeIndex === 2 ? 1 : 0 }}
            transition={{ duration: 0.8, ease: "easeInOut" }}
          />

          {/* Left-to-Center moving light pulses */}
          {activeIndex === 0 && (
            <motion.path
              d="M 210 90 Q 350 90 500 300"
              stroke="#0a72ef"
              strokeWidth="4"
              fill="none"
              strokeDasharray="20 100"
              animate={{ strokeDashoffset: [200, 0] }}
              transition={{ repeat: Infinity, duration: 1.5, ease: "linear" }}
              filter="blur(1px)"
            />
          )}
          {activeIndex === 1 && (
            <motion.path
              d="M 160 270 Q 330 290 500 300"
              stroke="#de1d8d"
              strokeWidth="4"
              fill="none"
              strokeDasharray="20 100"
              animate={{ strokeDashoffset: [200, 0] }}
              transition={{ repeat: Infinity, duration: 1.5, ease: "linear" }}
              filter="blur(1px)"
            />
          )}
          {activeIndex === 2 && (
            <motion.path
              d="M 210 450 Q 350 450 500 300"
              stroke="#ff5b4f"
              strokeWidth="4"
              fill="none"
              strokeDasharray="20 100"
              animate={{ strokeDashoffset: [200, 0] }}
              transition={{ repeat: Infinity, duration: 1.5, ease: "linear" }}
              filter="blur(1px)"
            />
          )}

          {/* Center-to-Right active lines drawing */}
          <motion.path
            d="M 500 300 Q 650 90 790 90"
            stroke={activeColor}
            strokeWidth="2"
            fill="none"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: 1 }}
            key={`r-line-0-${activeIndex}`}
            transition={{ duration: 0.8, delay: 0.6, ease: "easeInOut" }}
          />
          <motion.path
            d="M 500 300 Q 670 290 840 270"
            stroke={activeColor}
            strokeWidth="2"
            fill="none"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: 1 }}
            key={`r-line-1-${activeIndex}`}
            transition={{ duration: 0.8, delay: 0.6, ease: "easeInOut" }}
          />
          <motion.path
            d="M 500 300 Q 650 450 790 450"
            stroke={activeColor}
            strokeWidth="2"
            fill="none"
            initial={{ pathLength: 0 }}
            animate={{ pathLength: 1 }}
            key={`r-line-2-${activeIndex}`}
            transition={{ duration: 0.8, delay: 0.6, ease: "easeInOut" }}
          />

          {/* Center-to-Right moving light pulses (active stage only) */}
          <motion.path
            d="M 500 300 Q 650 90 790 90"
            stroke={activeColor}
            strokeWidth="4"
            fill="none"
            strokeDasharray="20 100"
            animate={{ strokeDashoffset: [200, 0] }}
            key={`r-pulse-0-${activeIndex}`}
            transition={{ repeat: Infinity, duration: 1.5, delay: 0.8, ease: "linear" }}
            filter="blur(1px)"
          />
          <motion.path
            d="M 500 300 Q 670 290 840 270"
            stroke={activeColor}
            strokeWidth="4"
            fill="none"
            strokeDasharray="20 100"
            animate={{ strokeDashoffset: [200, 0] }}
            key={`r-pulse-1-${activeIndex}`}
            transition={{ repeat: Infinity, duration: 1.5, delay: 0.8, ease: "linear" }}
            filter="blur(1px)"
          />
          <motion.path
            d="M 500 300 Q 650 450 790 450"
            stroke={activeColor}
            strokeWidth="4"
            fill="none"
            strokeDasharray="20 100"
            animate={{ strokeDashoffset: [200, 0] }}
            key={`r-pulse-2-${activeIndex}`}
            transition={{ repeat: Infinity, duration: 1.5, delay: 0.8, ease: "linear" }}
            filter="blur(1px)"
          />
        </svg>

        {/* ── Left: Verse Constellation (Verse Cards) ── */}
        <div className={styles.constellationLeft}>
          {SPOTLIGHT_PAIRS.map((pair, idx) => {
            const isActive = activeIndex === idx;
            const activeColorClass = idx === 0 
              ? styles.activeBlue 
              : idx === 1 
                ? styles.activePink 
                : styles.activeRed;

            return (
              <div 
                key={`v-${idx}`}
                className={`${styles.flowCard} ${styles.leftCard} ${styles[`nodeL${idx}`]} ${isActive ? `${styles.active} ${activeColorClass}` : styles.dimmed}`}
                onClick={() => handleLeftCardClick(idx)}
              >
                <div className={styles.cardHeader}>
                  <span>{pair.verse.surah}</span>
                  <span>{pair.verse.num}</span>
                </div>
                <div className={styles.arabicBody}>
                  {pair.verse.text}
                </div>
                <div className={styles.cardFooter}>
                  {pair.translation}
                </div>
              </div>
            );
          })}
        </div>

        {/* ── Center Space: Diamond ── */}
        <div className={styles.diamond} style={{
          filter: `drop-shadow(0 0 25px ${activeColor}25)`,
          transition: 'filter 0.8s ease'
        }}>
          <DiamondSprite />
        </div>

        {/* ── Right: App Constellation (3 Staggered Slots) ── */}
        <div className={styles.constellationRight}>
          
          {/* Card R0 (Top Right Slot) */}
          <AnimatePresence mode="wait">
            <motion.div
              key={`r0-${activeIndex}`}
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              transition={{ duration: 0.4, delay: 0.8 }}
              className={`${styles.flowCard} ${styles.nodeR0} ${styles.active}`}
            >
              {activeIndex === 0 && (
                <>
                  <div className={styles.cardHeader}>
                    <span>Read & Listen</span>
                    <span className={styles.fcBadge}>Mushaf</span>
                  </div>
                  <div className={styles.miniMushaf}>
                    <span>
                      إِنَّا أَعْطَيْنَاكَ <span className={styles.highlightWord}>الْكَوْثَرَ</span> فَصَلِّ لِرَبِّكَ وَانْحَرْ
                    </span>
                  </div>
                  <div className={styles.mushafHeader}>
                    <span>Page 602</span>
                    <span>Hafs / Warsh</span>
                  </div>
                </>
              )}
              {activeIndex === 1 && (
                <>
                  <div className={styles.cardHeader}>
                    <span>Understand</span>
                    <span className={styles.fcBadge}>Translations</span>
                  </div>
                  <div className={styles.miniMushaf} style={{ fontSize: '11px', direction: 'ltr', textAlign: 'center', opacity: 0.9 }}>
                    <div style={{ display: 'flex', gap: '8px', justifyContent: 'center', margin: '4px 0' }}>
                      <div style={{ background: 'var(--bg-subtle)', padding: '4px 8px', borderRadius: '4px' }}>
                        <div style={{ fontFamily: 'var(--font-arabic)', fontSize: '14px' }}>أَنزَلْنَاهُ</div>
                        <div style={{ fontSize: '9px', color: 'var(--text-tertiary)' }}>We sent it</div>
                      </div>
                      <div style={{ background: 'var(--bg-subtle)', padding: '4px 8px', borderRadius: '4px' }}>
                        <div style={{ fontFamily: 'var(--font-arabic)', fontSize: '14px' }}>فِي</div>
                        <div style={{ fontSize: '9px', color: 'var(--text-tertiary)' }}>in</div>
                      </div>
                    </div>
                  </div>
                  <div className={styles.cardFooter}>
                    Word-by-word structural definitions map key roots.
                  </div>
                </>
              )}
              {activeIndex === 2 && (
                <>
                  <div className={styles.cardHeader}>
                    <span>Practice</span>
                    <span className={styles.fcBadge}>Active Recall</span>
                  </div>
                  <div className={styles.fcInstruction}>Recall the next verse:</div>
                  <div className={styles.fcAnswer}>وَمَا أَدْرَاكَ مَا لَيْلَةُ الْقَدْرِ</div>
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
                </>
              )}
            </motion.div>
          </AnimatePresence>

          {/* Card R1 (Middle Right Slot) */}
          <AnimatePresence mode="wait">
            <motion.div
              key={`r1-${activeIndex}`}
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              transition={{ duration: 0.4, delay: 0.95 }}
              className={`${styles.flowCard} ${styles.nodeR1} ${styles.active}`}
            >
              {activeIndex === 0 && (
                <div className={styles.audioPlayer}>
                  <div className={styles.audioControls}>
                    <div className={styles.playBtn} style={{ background: activeColor }}>
                      <Play size={12} fill="currentColor" style={{ marginLeft: '1px' }} />
                    </div>
                    <div className={styles.trackInfo}>
                      <span className={styles.trackTitle}>Mishary Al-Afasy</span>
                      <span className={styles.trackMeta}>Al-Kawthar • Reciting</span>
                    </div>
                  </div>
                  <div className={styles.scrubberContainer}>
                    <div className={styles.scrubber}>
                      <div className={styles.scrubberFill} style={{ width: '38%', background: activeColor }} />
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '8px', color: 'var(--text-tertiary)' }}>
                      <span>0:03</span>
                      <span>0:09</span>
                    </div>
                  </div>
                </div>
              )}
              {activeIndex === 1 && (
                <div className={styles.tafsirContent}>
                  <span className={styles.tafsirLabel}>Brief Tafsir</span>
                  <p className={styles.tafsirText}>
                    Laylat al-Qadr (Decree) is better than a thousand months. In it, the Quran began its descent to the earth.
                  </p>
                </div>
              )}
              {activeIndex === 2 && (
                <>
                  <div className={styles.cardHeader}>
                    <span>Hifz Plan</span>
                    <span style={{ fontSize: '9px', color: '#ff5b4f' }}>Werd</span>
                  </div>
                  <div className={styles.planList}>
                    <div className={styles.planItem}>
                      <div className={styles.planItemLeft}>
                        <div className={`${styles.planItemCheck} ${styles.completed}`}>
                          <Check size={8} strokeWidth={3} />
                        </div>
                        <span className={styles.planItemName}>Sabaq (New)</span>
                      </div>
                      <span className={styles.planItemDesc}>Al-Mulk 1-12</span>
                    </div>
                    <div className={styles.planItem}>
                      <div className={styles.planItemLeft}>
                        <div className={styles.planItemCheck} />
                        <span className={styles.planItemName}>Sabqi (Review)</span>
                      </div>
                      <span className={styles.planItemDesc}>Juz 29 Werd</span>
                    </div>
                  </div>
                </>
              )}
            </motion.div>
          </AnimatePresence>

          {/* Card R2 (Bottom Right Slot) */}
          <AnimatePresence mode="wait">
            <motion.div
              key={`r2-${activeIndex}`}
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              transition={{ duration: 0.4, delay: 1.1 }}
              className={`${styles.flowCard} ${styles.nodeR2} ${styles.active}`}
            >
              {activeIndex === 0 && (
                <>
                  <div className={styles.cardHeader}>
                    <span>Audio Sync</span>
                    <span className={styles.fcBadge}>Reciter</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', width: '100%', margin: 'auto 0' }}>
                    <div className={styles.trackInfo}>
                      <span style={{ fontSize: '11px', fontWeight: '500' }}>Verse-Synced Recitations</span>
                      <span style={{ fontSize: '9px', color: 'var(--text-tertiary)' }}>No-gap transitions</span>
                    </div>
                    <div className={styles.equalizer}>
                      <div className={styles.eqBar} style={{ background: activeColor }} />
                      <div className={styles.eqBar} style={{ background: activeColor, animationDelay: '0.2s' }} />
                      <div className={styles.eqBar} style={{ background: activeColor, animationDelay: '0.4s' }} />
                    </div>
                  </div>
                  <div className={styles.cardFooter}>
                    High-fidelity background play using Hafs and Warsh segments.
                  </div>
                </>
              )}
              {activeIndex === 1 && (
                <div className={styles.tafsirContent}>
                  <span className={styles.tafsirLabel}>Occasion of Revelation</span>
                  <p className={styles.tafsirText}>
                    Announcing laylat al-qadr to highlight the immense value of this night, exceeding entire lifetimes in blessing.
                  </p>
                </div>
              )}
              {activeIndex === 2 && (
                <>
                  <div className={styles.cardHeader}>
                    <span>Analytics</span>
                    <span className={styles.fcBadge}>Maturity</span>
                  </div>
                  <div className={styles.analyticsContainer}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div>
                        <div className={styles.streakNumber}>7 Days</div>
                        <div className={styles.streakLabel}>Active Streak</div>
                      </div>
                      <div style={{ textAlign: 'right' }}>
                        <div style={{ fontSize: '11px', fontWeight: '600' }}>94%</div>
                        <span style={{ fontSize: '8px', color: 'var(--text-secondary)' }}>Recall Rate</span>
                      </div>
                    </div>
                    <div className={styles.miniChart}>
                      <div className={styles.chartBar} style={{ height: '30%' }} />
                      <div className={styles.chartBar} style={{ height: '50%' }} />
                      <div className={styles.chartBar} style={{ height: '80%' }} />
                      <div className={styles.chartBar} style={{ height: '70%' }} />
                      <div className={`${styles.chartBar} ${styles.activeBar}`} style={{ height: '100%' }} />
                    </div>
                  </div>
                </>
              )}
            </motion.div>
          </AnimatePresence>

        </div>

      </div>

      {/* ── Hero copy ── */}
      <div className={styles.copy}>
        <p className={styles.wordmark}>jawhar</p>
        <p className={styles.lensLine}>Memorize with Meaning.</p>
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
