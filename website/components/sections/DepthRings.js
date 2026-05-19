"use client";

import { useRef } from "react";
import gsap from "gsap";
import { ScrollTrigger } from "gsap/ScrollTrigger";
import { useGSAP } from "@gsap/react";
import styles from "./DepthRings.module.css";

gsap.registerPlugin(ScrollTrigger);

const RINGS = [
  {
    label: "Read & Listen",
    features: "Mushaf · Reciters · Audio · Bookmarks",
    r: 160,
    opacity: 0.6,
  },
  {
    label: "Understand",
    features: "Translations · Tafsir · Asbab al-Nuzul",
    r: 220,
    opacity: 0.45,
  },
  {
    label: "Memorize",
    features: "Plans · Sessions · Progress",
    r: 280,
    opacity: 0.3,
  },
  {
    label: "Master",
    features: "Flashcards · Mutashabihat · Analytics",
    r: 340,
    opacity: 0.2,
  },
];

// Mobile horizontal bars — widths as percentages
const BAR_WIDTHS = ["45%", "60%", "78%", "100%"];

export default function DepthRings({ onAnimationComplete }) {
  const containerRef = useRef(null);

  useGSAP(
    () => {
      const container = containerRef.current;
      if (!container) return;

      // ── Desktop ring animation ──
      const desktopRings = container.querySelector(`.${styles.desktop}`);
      if (desktopRings) {
        const tl = gsap.timeline({
          scrollTrigger: {
            trigger: container,
            start: "top 70%",
            once: true,
          },
          onComplete: onAnimationComplete,
        });

        // Diamond scales in
        tl.fromTo(
          container.querySelector(`.${styles.diamond}`),
          { scale: 0, opacity: 0 },
          { scale: 1, opacity: 1, duration: 0.8, ease: "back.out(1.5)" }
        );

        // Each ring draws + label appears
        RINGS.forEach((_, i) => {
          const ring = container.querySelector(`.ring-${i}`);
          const label = container.querySelector(`.label-${i}`);
          if (!ring || !label) return;

          const circumference = 2 * Math.PI * RINGS[i].r;
          gsap.set(ring, { strokeDasharray: circumference, strokeDashoffset: circumference });
          gsap.set(label, { opacity: 0, x: 10 });

          tl.to(
            ring,
            { strokeDashoffset: 0, duration: 1.0, ease: "power2.inOut" },
            i === 0 ? "-=0.3" : "-=0.5"
          ).to(
            label,
            { opacity: 1, x: 0, duration: 0.5, ease: "power2.out" },
            "-=0.4"
          );
        });
      }

      // ── Mobile bar animation ──
      const mobileBars = container.querySelector(`.${styles.mobile}`);
      if (mobileBars) {
        const tl = gsap.timeline({
          scrollTrigger: {
            trigger: container,
            start: "top 75%",
            once: true,
          },
          onComplete: onAnimationComplete,
        });

        tl.fromTo(
          container.querySelector(`.${styles.mobileDiamond}`),
          { scale: 0, opacity: 0 },
          { scale: 1, opacity: 1, duration: 0.6, ease: "back.out(1.5)" }
        );

        RINGS.forEach((_, i) => {
          const bar = container.querySelector(`.bar-${i}`);
          const label = container.querySelector(`.bar-label-${i}`);
          if (!bar || !label) return;

          gsap.set(bar, { width: 0 });
          gsap.set(label, { opacity: 0, y: 8 });

          tl.to(
            bar,
            { width: BAR_WIDTHS[i], duration: 0.8, ease: "power2.out" },
            i === 0 ? "-=0.2" : "-=0.3"
          ).to(
            label,
            { opacity: 1, y: 0, duration: 0.4, ease: "power2.out" },
            "-=0.2"
          );
        });
      }
    },
    { scope: containerRef }
  );

  return (
    <div className={styles.container} ref={containerRef}>
      {/* ── Desktop: SVG concentric circles ── */}
      <div className={styles.desktop}>
        <div className={styles.ringsWrap}>
          <svg viewBox="0 0 800 800" className={styles.svg}>
            {RINGS.map((ring, i) => (
              <circle
                key={i}
                className={`${styles.ring} ring-${i}`}
                cx="400"
                cy="400"
                r={ring.r}
                style={{ opacity: ring.opacity }}
              />
            ))}
          </svg>

          {/* Diamond center */}
          <div className={styles.diamond}>
            <svg width="28" height="28" viewBox="0 0 200 200" fill="none">
              <path
                d="M100,12 L155,50 L170,85 L145,100 L135,140 L100,190 L65,140 L55,100 L30,85 L45,50 Z"
                fill="var(--text-primary)"
                opacity="0.85"
              />
            </svg>
          </div>

          {/* Labels at right edge of each ring */}
          {RINGS.map((ring, i) => (
            <div
              key={i}
              className={`${styles.label} label-${i}`}
              style={{
                top: `${((400 - ring.r) / 800) * 100}%`,
                right: `${((400 - ring.r) / 800) * 100 - 2}%`,
              }}
            >
              <span className={styles.ringName}>{ring.label}</span>
              <span className={styles.ringFeatures}>{ring.features}</span>
            </div>
          ))}
        </div>
      </div>

      {/* ── Mobile: Vertical expanding bars ── */}
      <div className={styles.mobile}>
        <div className={styles.mobileDiamond}>
          <svg width="24" height="24" viewBox="0 0 200 200" fill="none">
            <path
              d="M100,12 L155,50 L170,85 L145,100 L135,140 L100,190 L65,140 L55,100 L30,85 L45,50 Z"
              fill="var(--text-primary)"
              opacity="0.85"
            />
          </svg>
        </div>

        {RINGS.map((ring, i) => (
          <div key={i} className={styles.barGroup}>
            <div
              className={`${styles.bar} bar-${i}`}
              style={{ opacity: ring.opacity }}
            />
            <div className={`${styles.barLabel} bar-label-${i}`}>
              <span className={styles.ringName}>{ring.label}</span>
              <span className={styles.ringFeatures}>{ring.features}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
