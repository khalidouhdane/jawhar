"use client";

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import gsap from 'gsap';
import { useGSAP } from '@gsap/react';
import { 
  Play, Check, BookOpen, Timer, 
  Sparkles, Volume2, Calendar 
} from 'lucide-react';
import styles from './EssenceFlow.module.css';
import DiamondSprite from './DiamondSprite';

// ──────────────────────────────────────────────
// Data — The 3 Spotlight Verse Content
// ──────────────────────────────────────────────
const SPOTLIGHT_PAIRS = [
  {
    verse: { surah: "Surah Al-Kawthar", num: "108:1", text: "إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ" },
    translation: "Indeed, We have granted you Al-Kawthar.",
    accentColor: "#0a72ef", // Develop Blue
    rgb: "10, 114, 239"
  },
  {
    verse: { surah: "Surah Al-Qadr", num: "97:1", text: "إِنَّا أَنزَلْنَاهُ فِي لَيْلَةِ الْقَدْرِ" },
    translation: "Indeed, We sent the Quran down during the Night of Decree.",
    accentColor: "#de1d8d", // Preview Pink
    rgb: "222, 29, 141"
  },
  {
    verse: { surah: "Surah Al-Mulk", num: "67:1", text: "تَبَارَكَ الَّذِي بِيَدِهِ الْمُلْكُ" },
    translation: "Blessed is He in whose hand is the dominion.",
    accentColor: "#ff5b4f", // Ship Red
    rgb: "255, 91, 79"
  }
];

// ──────────────────────────────────────────────
// Main Component
// ──────────────────────────────────────────────
export default function EssenceFlowHero() {
  const containerRef = useRef();
  const stageRef = useRef(null);
  const [activeIndex, setActiveIndex] = useState(0);
  const [isAutoRotating, setIsAutoRotating] = useState(true);
  const [scale, setScale] = useState(1);
  const autoRotateTimerRef = useRef(null);
  const manualTimeoutRef = useRef(null);

  // Resize listener to scale the 1440x450 stage container dynamically
  useEffect(() => {
    const handleResize = () => {
      const width = window.innerWidth;
      if (width < 1440) {
        const newScale = Math.max(0.4, width / 1440);
        setScale(newScale);
      } else {
        setScale(1);
      }
    };
    window.addEventListener('resize', handleResize);
    handleResize();
    return () => window.removeEventListener('resize', handleResize);
  }, []);

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
      <div className={styles.stageWrapper} style={{ height: `${450 * scale}px` }}>
        <div 
          className={styles.stage} 
          ref={stageRef}
          style={{ 
            transform: `scale(${scale})`,
            transformOrigin: 'top center',
            width: '1440px',
            height: '450px',
            position: 'relative'
          }}
        >

          {/* Ambient glow */}
          <div className={styles.glow} style={{ 
            background: `radial-gradient(circle, ${activeColor}15 0%, transparent 70%)`,
            transition: 'background 0.8s ease'
          }} />

          {/* ── Background SVG Beams with glow pulses ── */}
          <svg className={styles.beams} viewBox="0 0 1440 450" fill="none">
            {/* Static gray line tracks underneath */}
            <path d="M 376 118 L 550 118 L 550 227 L 720 227" stroke="var(--card-border)" strokeWidth="1" fill="none" opacity="0.2" />
            <path d="M 499 227 L 720 227" stroke="var(--card-border)" strokeWidth="1" fill="none" opacity="0.2" />
            <path d="M 346 345 L 550 345 L 550 227 L 720 227" stroke="var(--card-border)" strokeWidth="1" fill="none" opacity="0.2" />
            
            <path d="M 720 227 L 890 227 L 890 118 L 1072 118" stroke="var(--card-border)" strokeWidth="1" fill="none" opacity="0.2" />
            <path d="M 720 227 L 930 227" stroke="var(--card-border)" strokeWidth="1" fill="none" opacity="0.2" />
            <path d="M 720 227 L 890 227 L 890 345 L 1115 345" stroke="var(--card-border)" strokeWidth="1" fill="none" opacity="0.2" />

            {/* Left-to-Center active building drawing lines */}
            <motion.path
              d={
                activeIndex === 0 ? "M 376 118 L 550 118 L 550 227 L 720 227" :
                activeIndex === 1 ? "M 499 227 L 720 227" :
                "M 346 345 L 550 345 L 550 227 L 720 227"
              }
              stroke={activeColor}
              strokeWidth="2"
              fill="none"
              initial={{ pathLength: 0 }}
              animate={{ pathLength: 1 }}
              key={`l-line-${activeIndex}`}
              transition={{ duration: 0.8, ease: "easeInOut" }}
            />

            {/* Left-to-Center moving light pulses */}
            <motion.path
              d={
                activeIndex === 0 ? "M 376 118 L 550 118 L 550 227 L 720 227" :
                activeIndex === 1 ? "M 499 227 L 720 227" :
                "M 346 345 L 550 345 L 550 227 L 720 227"
              }
              stroke={activeColor}
              strokeWidth="4"
              fill="none"
              strokeDasharray="20 100"
              animate={{ strokeDashoffset: [-120, 0] }}
              key={`l-pulse-${activeIndex}`}
              transition={{ repeat: Infinity, duration: 1.5, ease: "linear" }}
              filter="blur(1px)"
            />

            {/* Center-to-Right active lines drawing (all three animate when left is done, with a delay of 0.8s) */}
            <motion.path
              d="M 720 227 L 890 227 L 890 118 L 1072 118"
              stroke={activeColor}
              strokeWidth="2"
              fill="none"
              initial={{ pathLength: 0 }}
              animate={{ pathLength: 1 }}
              key={`r-line-0-${activeIndex}`}
              transition={{ duration: 0.8, delay: 0.8, ease: "easeInOut" }}
            />
            <motion.path
              d="M 720 227 L 930 227"
              stroke={activeColor}
              strokeWidth="2"
              fill="none"
              initial={{ pathLength: 0 }}
              animate={{ pathLength: 1 }}
              key={`r-line-1-${activeIndex}`}
              transition={{ duration: 0.8, delay: 0.8, ease: "easeInOut" }}
            />
            <motion.path
              d="M 720 227 L 890 227 L 890 345 L 1115 345"
              stroke={activeColor}
              strokeWidth="2"
              fill="none"
              initial={{ pathLength: 0 }}
              animate={{ pathLength: 1 }}
              key={`r-line-2-${activeIndex}`}
              transition={{ duration: 0.8, delay: 0.8, ease: "easeInOut" }}
            />

            {/* Center-to-Right moving light pulses (active stage only) */}
            <motion.path
              d="M 720 227 L 890 227 L 890 118 L 1072 118"
              stroke={activeColor}
              strokeWidth="4"
              fill="none"
              strokeDasharray="20 100"
              animate={{ strokeDashoffset: [-120, 0] }}
              key={`r-pulse-0-${activeIndex}`}
              transition={{ repeat: Infinity, duration: 1.5, delay: 1.0, ease: "linear" }}
              filter="blur(1px)"
            />
            <motion.path
              d="M 720 227 L 930 227"
              stroke={activeColor}
              strokeWidth="4"
              fill="none"
              strokeDasharray="20 100"
              animate={{ strokeDashoffset: [-120, 0] }}
              key={`r-pulse-1-${activeIndex}`}
              transition={{ repeat: Infinity, duration: 1.5, delay: 1.0, ease: "linear" }}
              filter="blur(1px)"
            />
            <motion.path
              d="M 720 227 L 890 227 L 890 345 L 1115 345"
              stroke={activeColor}
              strokeWidth="4"
              fill="none"
              strokeDasharray="20 100"
              animate={{ strokeDashoffset: [-120, 0] }}
              key={`r-pulse-2-${activeIndex}`}
              transition={{ repeat: Infinity, duration: 1.5, delay: 1.0, ease: "linear" }}
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
              transition={{ duration: 0.4, delay: 1.4 }}
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
                    Word-by-word translation mapping root meanings.
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
              transition={{ duration: 0.4, delay: 1.1 }}
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
                    Laylat al-Qadr (Decree) is better than a thousand months. The Quran began its descent here.
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
              transition={{ duration: 0.4, delay: 1.5 }}
              className={`${styles.flowCard} ${styles.nodeR2} ${styles.active}`}
            >
              {activeIndex === 0 && (
                <>
                  <div className={styles.cardHeader}>
                    <span>Audio Sync</span>
                    <span className={styles.fcBadge}>Reciter</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', width: '100%', flex: 1, marginTop: '4px' }}>
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
                    High-fidelity audio playback synced at the verse level.
                  </div>
                </>
              )}
              {activeIndex === 1 && (
                <div className={styles.tafsirContent}>
                  <span className={styles.tafsirLabel}>Occasion of Revelation</span>
                  <p className={styles.tafsirText}>
                    Revealed to honor laylat al-qadr and highlight its immense blessing exceeding a lifetime.
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
    </div>

      {/* Mobile-optimized visual block (only visible on mobile screens) */}
      <div className={styles.mobileVisual}>
        <div 
          className={styles.mobileDiamond}
          style={{
            filter: `drop-shadow(0 0 20px ${activeColor}30)`,
            transition: 'filter 0.8s ease'
          }}
        >
          <DiamondSprite />
        </div>
        
        <AnimatePresence mode="wait">
          <motion.div
            key={`mobile-card-${activeIndex}`}
            initial={{ opacity: 0, y: 10, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: -10, scale: 0.98 }}
            transition={{ duration: 0.35, ease: "easeInOut" }}
            className={`${styles.flowCard} ${styles.mobileActiveCard}`}
            style={{
              borderColor: activeColor,
              boxShadow: `0 0 0 2.5px ${activeColor}, 0 8px 30px rgba(${SPOTLIGHT_PAIRS[activeIndex].rgb}, 0.15)`
            }}
            onClick={() => setActiveIndex((prev) => (prev + 1) % 3)}
          >
            <div className={styles.cardHeader}>
              <span>{SPOTLIGHT_PAIRS[activeIndex].verse.surah}</span>
              <span>{SPOTLIGHT_PAIRS[activeIndex].verse.num}</span>
            </div>
            <div className={styles.arabicBody}>
              {SPOTLIGHT_PAIRS[activeIndex].verse.text}
            </div>
            <div className={styles.cardFooter}>
              {SPOTLIGHT_PAIRS[activeIndex].translation}
            </div>
            <div style={{ position: 'absolute', bottom: '4px', right: '8px', fontSize: '8px', color: 'var(--text-tertiary)', opacity: 0.7, fontFamily: 'var(--font-mono)' }}>
              Tap to Cycle
            </div>
          </motion.div>
        </AnimatePresence>
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
          Verse in. Meaning out.<br/>
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
