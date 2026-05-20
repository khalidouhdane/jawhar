"use client";

import { AnimatePresence, motion, useScroll, useTransform } from "framer-motion";
import { useEffect, useRef, useState } from "react";
import { ListTodo, Timer, RefreshCcw, GitCompare } from "lucide-react";
import IPhoneMockup from "../shared/IPhoneMockup";
import styles from "./MemorizeSection.module.css";

export default function MemorizeSection() {
  const [activeIndex, setActiveIndex] = useState(0);
  const [direction, setDirection] = useState(0);
  const [isHovered, setIsHovered] = useState(false);
  const sectionRef = useRef(null);

  const autoplayInterval = 6000;

  // Autoplay effect
  useEffect(() => {
    if (isHovered) return;
    const timer = setInterval(() => {
      setDirection(1);
      setActiveIndex((prev) => (prev + 1) % 3);
    }, autoplayInterval);
    return () => clearInterval(timer);
  }, [isHovered]);

  const handleCardClick = (index) => {
    setDirection(index > activeIndex ? 1 : -1);
    setActiveIndex(index);
  };

  const handleDragEnd = (event, info) => {
    const swipeThreshold = 50;
    if (info.offset.x < -swipeThreshold) {
      setDirection(1);
      setActiveIndex((prev) => (prev + 1) % 3);
    } else if (info.offset.x > swipeThreshold) {
      setDirection(-1);
      setActiveIndex((prev) => (prev - 1 + 3) % 3);
    }
  };

  // Scroll parallax
  const { scrollYProgress } = useScroll({
    target: sectionRef,
    offset: ["start end", "end start"]
  });

  const leftPhoneY = useTransform(scrollYProgress, [0, 1], [-30, 30]);
  const rightPhoneY = useTransform(scrollYProgress, [0, 1], [30, -30]);

  const slideVariants = {
    enter: (dir) => ({
      x: dir > 0 ? 100 : -100,
      opacity: 0,
      scale: 0.96
    }),
    center: {
      x: 0,
      opacity: 1,
      scale: 1,
      transition: {
        x: { type: "spring", stiffness: 300, damping: 30 },
        opacity: { duration: 0.4 },
        scale: { duration: 0.4 }
      }
    },
    exit: (dir) => ({
      x: dir > 0 ? -100 : 100,
      opacity: 0,
      scale: 0.96,
      transition: {
        x: { type: "spring", stiffness: 300, damping: 30 },
        opacity: { duration: 0.3 },
        scale: { duration: 0.3 }
      }
    })
  };

  const slides = [
    { left: "/images/screenshots/hifz_dashboard_today_plan.png", right: "/images/screenshots/practice_home_flashcards.png" },
    { left: "/images/screenshots/active_session_timer.png", right: "/images/screenshots/session_complete_summary.png" },
    { left: "/images/screenshots/mutashabihat_verses_browser.png", right: "/images/screenshots/mutashabihat_spot_diff.png" }
  ];

  return (
    <section
      id="memorize-section"
      ref={sectionRef}
      className={styles.section}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      style={{
        "--color-primary": "#ff5b4f",
        "--color-primary-rgb": "255, 91, 79"
      }}
    >
      <div className={styles.container}>
        
        {/* Header (Top Center) */}
        <div className={styles.header}>
          <h2 className={styles.sectionTitle}>Memorize it, forever.</h2>
          <p className={styles.sectionDesc}>
            Jawhar turns understanding into a daily rhythm: what to learn, what to review, and how to return to older pages before they fade.
          </p>
        </div>

        {/* 3-Column Grid Layout */}
        <div className={styles.grid}>
          
          {/* Column 1: Left Features */}
          <div className={styles.columnFeatures}>
            {/* Feature 1: The Plan */}
            <div
              className={`${styles.card} ${activeIndex === 0 ? styles.cardActive : ""}`}
              onClick={() => handleCardClick(0)}
            >
              <div className={styles.cardHeader}>
                <div className={`${styles.iconWrapper} ${activeIndex === 0 ? styles.iconActive : ""}`}>
                  <ListTodo size={20} />
                </div>
                <h3 className={styles.cardTitle}>Adaptive Planning</h3>
              </div>
              <p className={styles.cardText}>
                Generate daily tasks for Sabaq (new memorization) and Sabqi (revision) customized to your pace.
              </p>
              <div className={styles.progressBarBg}>
                <motion.div
                  className={styles.progressBar}
                  animate={{ width: activeIndex === 0 && !isHovered ? "100%" : "0%" }}
                  transition={{ duration: activeIndex === 0 ? autoplayInterval / 1000 : 0, ease: "linear" }}
                />
              </div>
            </div>

            {/* Feature 2: Guided Sessions */}
            <div
              className={`${styles.card} ${activeIndex === 1 ? styles.cardActive : ""}`}
              onClick={() => handleCardClick(1)}
            >
              <div className={styles.cardHeader}>
                <div className={`${styles.iconWrapper} ${activeIndex === 1 ? styles.iconActive : ""}`}>
                  <Timer size={20} />
                </div>
                <h3 className={styles.cardTitle}>Guided Sessions</h3>
              </div>
              <p className={styles.cardText}>
                Stay focused with interactive step-by-step repetition timers and self-assessments.
              </p>
              <div className={styles.progressBarBg}>
                <motion.div
                  className={styles.progressBar}
                  animate={{ width: activeIndex === 1 && !isHovered ? "100%" : "0%" }}
                  transition={{ duration: activeIndex === 1 ? autoplayInterval / 1000 : 0, ease: "linear" }}
                />
              </div>
            </div>
          </div>

          {/* Column 2: Center Phone Mockups */}
          <div className={styles.columnPhones}>
            <div className={styles.phoneGroup}>
              <AnimatePresence initial={false} custom={direction} mode="popLayout">
                <motion.div
                  key={`mem-left-${activeIndex}`}
                  custom={direction}
                  variants={slideVariants}
                  initial="enter"
                  animate="center"
                  exit="exit"
                  className={styles.phonePrimary}
                  drag="x"
                  dragConstraints={{ left: 0, right: 0 }}
                  onDragEnd={handleDragEnd}
                >
                  <div style={{ transform: "rotate(15deg) translateX(-30px)", transformOrigin: "bottom center" }}>
                    <IPhoneMockup
                      imgSrc={slides[activeIndex]?.left}
                      tilt="left"
                      scale={0.84}
                      parallaxY={leftPhoneY}
                    />
                  </div>
                </motion.div>
              </AnimatePresence>
 
              <AnimatePresence initial={false} custom={direction} mode="popLayout">
                <motion.div
                  key={`mem-right-${activeIndex}`}
                  custom={direction}
                  variants={slideVariants}
                  initial="enter"
                  animate="center"
                  exit="exit"
                  className={styles.phoneSecondary}
                  drag="x"
                  dragConstraints={{ left: 0, right: 0 }}
                  onDragEnd={handleDragEnd}
                >
                  <div style={{ transform: "rotate(-15deg) translateX(30px) translateY(20px)", transformOrigin: "bottom center" }}>
                    <IPhoneMockup
                      imgSrc={slides[activeIndex]?.right}
                      tilt="right"
                      scale={0.84}
                      parallaxY={rightPhoneY}
                    />
                  </div>
                </motion.div>
              </AnimatePresence>

              <div className={styles.glowOrb} />
            </div>
          </div>

          {/* Column 3: Right Features */}
          <div className={styles.columnFeatures}>
            {/* Feature 3: Mutashabihat Practice */}
            <div
              className={`${styles.card} ${activeIndex === 2 ? styles.cardActive : ""}`}
              onClick={() => handleCardClick(2)}
            >
              <div className={styles.cardHeader}>
                <div className={`${styles.iconWrapper} ${activeIndex === 2 ? styles.iconActive : ""}`}>
                  <GitCompare size={20} />
                </div>
                <h3 className={styles.cardTitle}>Mutashabihat Practice</h3>
              </div>
              <p className={styles.cardText}>
                Compare similar verses side-by-side and play interactive 'Spot the Difference' quizzes.
              </p>
              <div className={styles.progressBarBg}>
                <motion.div
                  className={styles.progressBar}
                  animate={{ width: activeIndex === 2 && !isHovered ? "100%" : "0%" }}
                  transition={{ duration: activeIndex === 2 ? autoplayInterval / 1000 : 0, ease: "linear" }}
                />
              </div>
            </div>

            {/* Feature 4: Smart Flashcards */}
            <div
              className={`${styles.card} ${activeIndex === 0 ? styles.cardActive : ""}`}
              onClick={() => handleCardClick(0)}
            >
              <div className={styles.cardHeader}>
                <div className={`${styles.iconWrapper} ${activeIndex === 0 ? styles.iconActive : ""}`}>
                  <RefreshCcw size={20} />
                </div>
                <h3 className={styles.cardTitle}>Smart Flashcards</h3>
              </div>
              <p className={styles.cardText}>
                Strengthen retention using automatically generated, spaced repetition card decks.
              </p>
              <div className={styles.progressBarBg}>
                <motion.div
                  className={styles.progressBar}
                  animate={{ width: activeIndex === 0 && !isHovered ? "100%" : "0%" }}
                  transition={{ duration: activeIndex === 0 ? autoplayInterval / 1000 : 0, ease: "linear" }}
                />
              </div>
            </div>
          </div>

        </div>

      </div>
    </section>
  );
}
