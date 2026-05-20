"use client";

import { motion, useMotionValue, useSpring, useTransform } from "framer-motion";
import { useEffect, useRef } from "react";
import styles from "./IPhoneMockup.module.css";

/**
 * Premium 3D iPhone 15 Pro mockup wrapper with interactive mouse-tilt,
 * realistic hardware details (Dynamic Island, stainless steel bezel, glare),
 * and status bar indicators.
 */
export default function IPhoneMockup({
  imgSrc,
  tilt = "flat",
  scale = 1,
  parallaxY = 0,
  glare = true,
  className = "",
  style = {},
  hideStatusBar = true,
  hideHomeIndicator = true
}) {
  const containerRef = useRef(null);

  // Mouse tilt animation states
  const mouseX = useMotionValue(0);
  const mouseY = useMotionValue(0);

  // Spring settings for ultra-smooth buttery response
  const springConfig = { damping: 30, stiffness: 200, mass: 0.5 };
  const rotateX = useSpring(mouseY, springConfig);
  const rotateY = useSpring(mouseX, springConfig);
  const glareX = useSpring(useTransform(mouseX, [-15, 15], [0, 100]), springConfig);
  const glareY = useSpring(useTransform(mouseY, [-15, 15], [0, 100]), springConfig);

  // Set base rotations depending on the requested hardware tilt deviation
  useEffect(() => {
    if (tilt === "left") {
      mouseX.set(-10);
      mouseY.set(5);
    } else if (tilt === "right") {
      mouseX.set(10);
      mouseY.set(5);
    } else {
      mouseX.set(0);
      mouseY.set(0);
    }
  }, [tilt, mouseX, mouseY]);

  // Track mouse move for active tilt effect
  const handleMouseMove = (e) => {
    if (!containerRef.current) return;
    const rect = containerRef.current.getBoundingClientRect();
    const width = rect.width;
    const height = rect.height;
    
    // Calculate normalized position from center (-0.5 to 0.5)
    const x = (e.clientX - rect.left) / width - 0.5;
    const y = (e.clientY - rect.top) / height - 0.5;
    
    // Scale to degrees of rotation (max 15 degrees tilt)
    const baseRotationX = tilt === "left" ? 5 : tilt === "right" ? 5 : 0;
    const baseRotationY = tilt === "left" ? -10 : tilt === "right" ? 10 : 0;
    
    mouseX.set(baseRotationY + x * 20);
    mouseY.set(baseRotationX - y * 20);
  };

  const handleMouseLeave = () => {
    // Reset back to base tilt
    if (tilt === "left") {
      mouseX.set(-10);
      mouseY.set(5);
    } else if (tilt === "right") {
      mouseX.set(10);
      mouseY.set(5);
    } else {
      mouseX.set(0);
      mouseY.set(0);
    }
  };

  return (
    <motion.div
      ref={containerRef}
      className={`${styles.container} ${className}`}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      style={{
        y: parallaxY,
        scale,
        ...style
      }}
    >
      <motion.div
        className={styles.phoneWrapper}
        style={{
          rotateX,
          rotateY,
          transformStyle: "preserve-3d"
        }}
      >
        {/* Device Shadow */}
        <div className={styles.phoneShadow} />

        {/* Stainless Steel Frame (Chassis) */}
        <div className={styles.chassis}>
          {/* Side Buttons (Antennas / Volume / Power) */}
          <div className={`${styles.hardwareButton} ${styles.volumeUp}`} />
          <div className={`${styles.hardwareButton} ${styles.volumeDown}`} />
          <div className={`${styles.hardwareButton} ${styles.powerBtn}`} />

          {/* Screen Bezel (Screen border) */}
          <div className={styles.bezel}>
            {/* Screen Content Wrapper */}
            <div className={styles.screen}>
              
              {/* iOS Status Bar (Incredibly authentic detail) */}
              {!hideStatusBar && (
                <div className={styles.statusBar}>
                  <span className={styles.time}>9:41</span>
                  
                  {/* Dynamic Island */}
                  <div className={styles.dynamicIsland}>
                    <div className={styles.cameraDot} />
                  </div>

                  <div className={styles.indicators}>
                    {/* Signal bars */}
                    <svg className={styles.signalIcon} viewBox="0 0 18 12" fill="currentColor">
                      <rect x="0" y="8" width="2" height="4" rx="0.5" />
                      <rect x="4" y="6" width="2" height="6" rx="0.5" />
                      <rect x="8" y="4" width="2" height="8" rx="0.5" />
                      <rect x="12" y="2" width="2" height="10" rx="0.5" opacity="0.4" />
                      <rect x="16" y="0" width="2" height="12" rx="0.5" opacity="0.4" />
                    </svg>
                    {/* Wifi */}
                    <svg className={styles.wifiIcon} viewBox="0 0 16 12" fill="currentColor">
                      <path d="M8 12a2 2 0 1 1 0-4 2 2 0 0 1 0 4Z" />
                      <path d="M8 6.5a4.5 4.5 0 0 1 3.18 1.32c.3.3.77.3 1.06 0s.3-.77 0-1.06A6 6 0 0 0 8 5a6 6 0 0 0-4.24 1.76c-.3.3-.3.77 0 1.06s.77.3 1.06 0A4.5 4.5 0 0 1 8 6.5Z" />
                      <path d="M8 3a8 8 0 0 1 5.66 2.34c.3.3.77.3 1.06 0s.3-.77 0-1.06A9.5 9.5 0 0 0 8 1.5a9.5 9.5 0 0 0-6.72 2.78c-.3.3-.3.77 0 1.06s.77.3 1.06 0A8 8 0 0 1 8 3Z" />
                    </svg>
                    {/* Battery */}
                    <div className={styles.batteryContainer}>
                      <div className={styles.batteryBody}>
                        <div className={styles.batteryFill} />
                      </div>
                      <div className={styles.batteryCap} />
                    </div>
                  </div>
                </div>
              )}

              {/* Screenshot Image */}
              {imgSrc ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={imgSrc}
                  alt="App Screenshot"
                  className={styles.screenshot}
                  loading="eager"
                  draggable={false}
                />
              ) : (
                <div className={styles.screenPlaceholder}>
                  <div className={styles.logoMark} />
                </div>
              )}

              {/* Dynamic screen glare reflection */}
              {glare && (
                <motion.div
                  className={styles.screenGlare}
                  style={{
                    background: useTransform(
                      [glareX, glareY],
                      ([x, y]) => `radial-gradient(circle at ${x}% ${y}%, rgba(255,255,255,0.15) 0%, rgba(255,255,255,0) 60%)`
                    )
                  }}
                />
              )}

              {/* iOS Home Indicator Bar */}
              {!hideHomeIndicator && <div className={styles.homeIndicator} />}
            </div>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );
}
