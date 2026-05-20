"use client";

import { useState, useEffect, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import ScrollReveal from "../shared/ScrollReveal";
import styles from "./StrategySection.module.css";

const steps = [
  {
    label: "Step 01 / Core",
    title: "Read & Listen",
    desc: "Every journey starts with the page. A clean Mushaf, synchronized audio, and a daily page goal keep you grounded in the text.",
  },
  {
    label: "Step 02 / Ring 1",
    title: "Understand with Depth",
    desc: "Understanding is what turns repetition into memory. Translations, tafsir, and reasons of revelation give every verse its weight.",
  },
  {
    label: "Step 03 / Ring 2",
    title: "Memorize & Master",
    desc: "Adaptive daily plans decide what to learn and what to review. Spaced repetition handles the rest. Not just memorized — internalized.",
  },
];

const colors = [
  { hex: "#0a72ef", rgb: "10, 114, 239" }, // Read (Blue)
  { hex: "#de1d8d", rgb: "222, 29, 141" }, // Understand (Pink)
  { hex: "#ff5b4f", rgb: "255, 91, 79" }   // Memorize (Orange/Red)
];

export default function StrategySection() {
  const [activeIndex, setActiveIndex] = useState(0);
  const [isHovered, setIsHovered] = useState(false);
  const autoplayInterval = 6000; // 6 seconds
  const timerRef = useRef(null);

  // Autoplay functionality
  useEffect(() => {
    if (isHovered) {
      if (timerRef.current) clearInterval(timerRef.current);
      return;
    }

    timerRef.current = setInterval(() => {
      setActiveIndex((prev) => (prev + 1) % steps.length);
    }, autoplayInterval);

    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [isHovered]);

  const handleStepClick = (index) => {
    setActiveIndex(index);
  };

  return (
    <section 
      className={styles.section} 
      id="strategy"
      style={{
        "--color-primary": colors[activeIndex].hex,
        "--color-primary-rgb": colors[activeIndex].rgb
      }}
    >
      <div className={styles.container}>
        
        {/* Column 1: Copy & Indicators */}
        <div className={styles.copyColumn}>
          <ScrollReveal>
            <div className={styles.header}>
              <p className="mono-label">Pillars of Hifz</p>
              <h2 className={styles.sectionTitle}>The Strategy Behind It</h2>
              <p className={styles.sectionDesc}>
                Three layers. One path. Start with reading, add understanding, build toward permanent memory.
              </p>
            </div>
          </ScrollReveal>

          {/* Diamond Step Indicator Row */}
          <ScrollReveal delay={0.1}>
            <div className={styles.indicatorRow}>
              {steps.map((_, i) => {
                const isActive = activeIndex === i;
                if (isActive) {
                  return (
                    <div 
                      key={i} 
                      className={styles.activeDiamondBox}
                      onClick={() => handleStepClick(i)}
                    >
                      <span className={styles.activeDiamondText}>{i + 1}</span>
                    </div>
                  );
                }
                return (
                  <div
                    key={i}
                    className={styles.inactiveDiamond}
                    onClick={() => handleStepClick(i)}
                  />
                );
              })}
            </div>
          </ScrollReveal>

          {/* Active Step Text Detail */}
          <ScrollReveal delay={0.2}>
            <div 
              className={styles.detailCard}
              onMouseEnter={() => setIsHovered(true)}
              onMouseLeave={() => setIsHovered(false)}
            >
              <AnimatePresence mode="wait">
                <motion.div
                  key={activeIndex}
                  initial={{ opacity: 0, y: 15 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: -15 }}
                  transition={{ duration: 0.35, ease: "easeInOut" }}
                  style={{ display: "flex", flexDirection: "column", gap: "10px" }}
                >
                  <span className={styles.stepLabel}>{steps[activeIndex].label}</span>
                  <h3 className={styles.stepTitle}>{steps[activeIndex].title}</h3>
                  <p className={styles.stepDesc}>{steps[activeIndex].desc}</p>
                </motion.div>
              </AnimatePresence>
            </div>
          </ScrollReveal>
        </div>

        {/* Column 2: Interactive SVG Funnel */}
        <div 
          className={styles.visualColumn}
          onMouseEnter={() => setIsHovered(true)}
          onMouseLeave={() => setIsHovered(false)}
        >
          {/* Background Glow */}
          <div className={styles.glowOrb} />

          {/* Background Rotating Wireframe Diamond */}
          <div className={styles.bgDiamondWrapper}>
            <svg 
              viewBox="0 0 360 360" 
              className={styles.rotatingDiamondSvg}
              fill="none" 
              xmlns="http://www.w3.org/2000/svg"
            >
              {/* Octahedron / Double-Pyramid Wireframe */}
              {/* Outer boundary diamond */}
              <path d="M180 20 L300 180 L180 340 L60 180 Z" stroke="rgba(255, 255, 255, 0.05)" strokeWidth="1" />
              
              {/* Inner frame diamond */}
              <path d="M180 20 L210 180 L180 340 L150 180 Z" stroke="rgba(255, 255, 255, 0.03)" strokeWidth="1" />
              <path d="M180 20 L240 180 L180 340 L120 180 Z" stroke="rgba(255, 255, 255, 0.04)" strokeWidth="1" />
              
              {/* Horizontal center alignments */}
              <line x1="60" y1="180" x2="300" y2="180" stroke="rgba(255, 255, 255, 0.03)" strokeWidth="0.5" />
              <line x1="180" y1="20" x2="180" y2="340" stroke="rgba(255, 255, 255, 0.03)" strokeWidth="0.5" />
              
              {/* Facet lines */}
              <line x1="180" y1="20" x2="150" y2="180" stroke="rgba(255, 255, 255, 0.05)" strokeWidth="1" />
              <line x1="180" y1="20" x2="210" y2="180" stroke="rgba(255, 255, 255, 0.05)" strokeWidth="1" />
              <line x1="180" y1="340" x2="150" y2="180" stroke="rgba(255, 255, 255, 0.05)" strokeWidth="1" />
              <line x1="180" y1="340" x2="210" y2="180" stroke="rgba(255, 255, 255, 0.05)" strokeWidth="1" />
            </svg>
          </div>

          {/* Interactive Ellipses Funnel */}
          <div className={styles.funnelContainer}>
            <svg 
              viewBox="0 0 480 500" 
              className={styles.funnelSvg}
              fill="none" 
              xmlns="http://www.w3.org/2000/svg"
            >
              <g>
                {/* Ellipse 3: Memorize (Top, Outer ring) */}
                <ellipse 
                  cx="240" 
                  cy="150" 
                  rx="210" 
                  ry="65" 
                  stroke="rgba(255, 255, 255, 0.12)" 
                  strokeWidth="1" 
                  className={`${styles.ellipsePath} ${activeIndex === 2 ? styles.ellipseActive : ""}`}
                  onClick={() => handleStepClick(2)}
                />
                <text 
                  x="240" 
                  y="154" 
                  fill="rgba(255, 255, 255, 0.3)" 
                  className={`${styles.ellipseText} ${activeIndex === 2 ? styles.textActive : ""}`}
                  onClick={() => handleStepClick(2)}
                >
                  Memorize
                </text>

                {/* Ellipse 2: Understand (Middle ring) */}
                <ellipse 
                  cx="240" 
                  cy="260" 
                  rx="160" 
                  ry="50" 
                  stroke="rgba(255, 255, 255, 0.12)" 
                  strokeWidth="1" 
                  className={`${styles.ellipsePath} ${activeIndex === 1 ? styles.ellipseActive : ""}`}
                  onClick={() => handleStepClick(1)}
                />
                <text 
                  x="240" 
                  y="264" 
                  fill="rgba(255, 255, 255, 0.3)" 
                  className={`${styles.ellipseText} ${activeIndex === 1 ? styles.textActive : ""}`}
                  onClick={() => handleStepClick(1)}
                >
                  Understand
                </text>

                {/* Ellipse 1: Read (Bottom, Core ring) */}
                <ellipse 
                  cx="240" 
                  cy="350" 
                  rx="105" 
                  ry="32" 
                  stroke="rgba(255, 255, 255, 0.12)" 
                  strokeWidth="1" 
                  className={`${styles.ellipsePath} ${activeIndex === 0 ? styles.ellipseActive : ""}`}
                  onClick={() => handleStepClick(0)}
                />
                <text 
                  x="240" 
                  y="354" 
                  fill="rgba(255, 255, 255, 0.3)" 
                  className={`${styles.ellipseText} ${activeIndex === 0 ? styles.textActive : ""}`}
                  onClick={() => handleStepClick(0)}
                >
                  Read
                </text>

                {/* Connection vertical flow dotted line */}
                <line 
                  x1="240" 
                  y1="85" 
                  x2="240" 
                  y2="380" 
                  stroke="rgba(255, 255, 255, 0.08)" 
                  strokeWidth="1" 
                  strokeDasharray="4 4" 
                />

                {/* Jawhar Brand Icon at the base of the funnel */}
                <g 
                  className={`${styles.logoGroup} ${activeIndex === 0 ? styles.logoGroupActive : ""}`}
                  transform="translate(218, 410) scale(2.2, 0.67)"
                >
                  {/* Outer Loop */}
                  <path 
                    d="M14.2411 13.2149C15.3592 14.4667 16.0383 16.1097 16.0383 17.9085V17.9178C16.0365 19.9559 15.1622 21.7936 13.7683 23.0862C12.5845 24.1803 11.0274 24.885 9.30332 24.987C9.17388 24.9944 9.04255 25 8.91123 25C8.77991 25 8.64858 24.9944 8.51913 24.987C6.79692 24.885 5.23793 24.1803 4.05602 23.0862C2.66024 21.7936 1.78787 19.9559 1.786 17.9178V17.9085C1.786 16.1079 2.46325 14.4667 3.58138 13.2149L4.46499 12.3822L14.7983 4.09836L12.8434 2.25131H5.2398L3.28308 4.09836L7.70118 8.27275L5.92268 9.69513L0 4.09836L4.33742 0H13.7458L18.0851 4.09836L5.78573 14.2404C5.6394 14.3647 5.50057 14.4945 5.37112 14.6336C4.55504 15.4959 4.05789 16.6549 4.05789 17.9289C4.05789 20.5549 6.17783 22.6912 8.81743 22.758C8.83994 22.758 8.8587 22.758 8.88121 22.758C8.92249 22.758 8.96563 22.758 9.0069 22.758C11.6465 22.6912 13.7664 20.5549 13.7664 17.9289C13.7664 16.6549 13.2693 15.4959 12.4532 14.6336L14.2392 13.2168L14.2411 13.2149Z" 
                    fill="currentColor"
                  />
                  {/* Center Diamond */}
                  <path 
                    d="M9.04255 16.0597L7.41039 17.9772L9.04255 19.8947L10.6747 17.9772L9.04255 16.0597Z" 
                    fill="currentColor"
                  />
                </g>
              </g>
            </svg>
          </div>
        </div>

      </div>
    </section>
  );
}
