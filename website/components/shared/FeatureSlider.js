"use client";

import { AnimatePresence, motion, useScroll, useTransform } from "framer-motion";
import { useEffect, useRef, useState } from "react";
import IPhoneMockup from "./IPhoneMockup";
import styles from "./FeatureSlider.module.css";

/**
 * A premium interactive feature showcase slider.
 * Layout splits features list on one side and a parallax 3D phone group on the other.
 * Supports:
 *  - Autoplay with visual progress indicators on active cards
 *  - Click-to-switch cards
 *  - Dragging/swiping on phone mockups to change slides
 *  - Vertical parallax offsets on scroll (one phone goes up, one goes down)
 */
export default function FeatureSlider({
  sectionId,
  title,
  description,
  layout = "left", // 'left' means phones on the left, copy on the right
  features = [],
  slides = [], // Array of { left: string, right: string }
  autoplayInterval = 6000,
  accentColor = "#d4af37" // Default brand gold/yellow
}) {
  const [activeIndex, setActiveIndex] = useState(0);
  const [direction, setDirection] = useState(0); // -1 for prev, 1 for next
  const [isHovered, setIsHovered] = useState(false);
  const sectionRef = useRef(null);

  // Helper to convert hex to rgb triplet
  const hexToRgb = (hex) => {
    const cleaned = hex.replace("#", "");
    const r = parseInt(cleaned.substring(0, 2), 16);
    const g = parseInt(cleaned.substring(2, 4), 16);
    const b = parseInt(cleaned.substring(4, 6), 16);
    return `${r}, ${g}, ${b}`;
  };

  const primaryRgb = hexToRgb(accentColor);

  // Track scroll position of the section for vertical parallax offsets
  const { scrollYProgress } = useScroll({
    target: sectionRef,
    offset: ["start end", "end start"]
  });

  // Left phone moves up, right phone moves down as we scroll
  const leftPhoneY = useTransform(scrollYProgress, [0, 1], [-40, 40]);
  const rightPhoneY = useTransform(scrollYProgress, [0, 1], [40, -40]);

  // Autoplay loop
  useEffect(() => {
    if (isHovered) return;

    const timer = setInterval(() => {
      setDirection(1);
      setActiveIndex((prev) => (prev + 1) % slides.length);
    }, autoplayInterval);

    return () => clearInterval(timer);
  }, [isHovered, slides.length, autoplayInterval]);

  const handleCardClick = (index) => {
    setDirection(index > activeIndex ? 1 : -1);
    setActiveIndex(index);
  };

  const handleDragEnd = (event, info) => {
    const swipeThreshold = 50;
    if (info.offset.x < -swipeThreshold) {
      // Swipe Left -> Next
      setDirection(1);
      setActiveIndex((prev) => (prev + 1) % slides.length);
    } else if (info.offset.x > swipeThreshold) {
      // Swipe Right -> Prev
      setDirection(-1);
      setActiveIndex((prev) => (prev - 1 + slides.length) % slides.length);
    }
  };

  // Slide transition animation definitions
  const slideVariants = {
    enter: (dir) => ({
      x: dir > 0 ? 120 : -120,
      opacity: 0,
      scale: 0.95
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
      x: dir > 0 ? -120 : 120,
      opacity: 0,
      scale: 0.95,
      transition: {
        x: { type: "spring", stiffness: 300, damping: 30 },
        opacity: { duration: 0.3 },
        scale: { duration: 0.3 }
      }
    })
  };

  const isLeftLayout = layout === "left";

  return (
    <section
      id={sectionId}
      ref={sectionRef}
      className={`${styles.section} ${isLeftLayout ? styles.layoutLeft : styles.layoutRight}`}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      style={{
        "--color-primary": accentColor,
        "--color-primary-rgb": primaryRgb
      }}
    >
      <div className={styles.container}>
        
        {/* Phones Area (Left or Right) */}
        <div className={`${styles.phoneSection} ${isLeftLayout ? styles.orderFirst : styles.orderLast}`}>
          
          <div className={styles.phoneGroup}>
            <AnimatePresence initial={false} custom={direction} mode="popLayout">
              {/* Primary Phone Mockup (rotated clockwise) */}
              <motion.div
                key={`left-phone-${activeIndex}`}
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
              {/* Secondary Phone Mockup (rotated counterclockwise) */}
              <motion.div
                key={`right-phone-${activeIndex}`}
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

            {/* Subtle light/glow orb behind phones */}
            <div className={styles.glowOrb} />
          </div>
        </div>

        {/* Copy & Feature Cards Area */}
        <div className={styles.copySection}>
          <div className={styles.header}>
            <h2 className={styles.sectionTitle}>{title}</h2>
            <p className={styles.sectionDesc}>{description}</p>
          </div>

          <div className={styles.featureCards}>
            {features.map((feature, idx) => {
              const isActive = idx === activeIndex;
              const Icon = feature.icon;

              return (
                <div
                  key={idx}
                  className={`${styles.card} ${isActive ? styles.cardActive : ""}`}
                  onClick={() => handleCardClick(idx)}
                >
                  <div className={styles.cardHeader}>
                    {Icon && (
                      <div className={`${styles.iconWrapper} ${isActive ? styles.iconActive : ""}`}>
                        <Icon size={20} />
                      </div>
                    )}
                    <h3 className={styles.cardTitle}>{feature.title}</h3>
                  </div>

                  <p className={styles.cardText}>{feature.description}</p>

                  {/* Dynamic Progress Bar Outline */}
                  <div className={styles.progressBarBg}>
                    <motion.div
                      className={styles.progressBar}
                      initial={{ width: "0%" }}
                      animate={{
                        width: isActive && !isHovered ? "100%" : "0%"
                      }}
                      transition={{
                        duration: isActive ? autoplayInterval / 1000 : 0,
                        ease: "linear"
                      }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>

      </div>
    </section>
  );
}
