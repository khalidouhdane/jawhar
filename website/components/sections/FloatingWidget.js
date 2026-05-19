"use client";

import { Play, Bookmark } from "lucide-react";
import ScrollReveal from "../shared/ScrollReveal";
import styles from "./FloatingWidget.module.css";

/**
 * FloatingWidget — Small UI fragments that float near phone frames.
 *
 * Props:
 *   - type: widget content type
 *   - style: position overrides (top, left, right, bottom)
 *   - delay: ScrollReveal delay
 *   - className: additional CSS class
 */
export default function FloatingWidget({ type, style, delay = 0.3, className = "" }) {
  return (
    <ScrollReveal delay={delay} className={`${styles.widget} ${className}`}>
      <div className={styles.inner} style={style}>
        {renderWidget(type)}
      </div>
    </ScrollReveal>
  );
}

function renderWidget(type) {
  switch (type) {
    case "audio-pill":
      return (
        <div className={`${styles.pill} ${styles.audioPill}`}>
          <Play size={10} fill="currentColor" />
          <span>Mishary al-Afasy</span>
        </div>
      );

    case "verse-badge":
      return <div className={styles.verseBadge}>2:255</div>;

    case "bookmark-dot":
      return (
        <div className={styles.bookmarkDot}>
          <Bookmark size={10} fill="var(--link-blue)" stroke="var(--link-blue)" />
        </div>
      );

    case "lang-switch":
      return (
        <div className={styles.pill}>
          <span className={styles.switchActive}>EN</span>
          <span className={styles.switchDivider}>│</span>
          <span className={styles.switchInactive}>AR</span>
        </div>
      );

    case "tafsir-mode":
      return (
        <div className={styles.pill}>
          <span className={styles.switchActive}>Brief</span>
          <span className={styles.switchDivider}>│</span>
          <span className={styles.switchInactive}>Detailed</span>
        </div>
      );

    case "verse-translation":
      return (
        <div className={styles.translationCard}>
          <span className={styles.translationKey}>55:13</span>
          <span className={styles.translationText}>
            So which of the favors of your Lord would you deny?
          </span>
        </div>
      );

    case "streak":
      return (
        <div className={styles.pill}>
          <span>🔥</span>
          <span>12 days</span>
        </div>
      );

    case "timer":
      return (
        <div className={`${styles.pill} ${styles.timerPill}`}>
          <span className={styles.timerDot} />
          <span>15:00</span>
        </div>
      );

    case "progress-ring":
      return (
        <div className={styles.progressWidget}>
          <svg width="36" height="36" viewBox="0 0 36 36">
            <circle
              cx="18" cy="18" r="15"
              fill="none"
              stroke="var(--card-border)"
              strokeWidth="2"
            />
            <circle
              cx="18" cy="18" r="15"
              fill="none"
              stroke="var(--text-tertiary)"
              strokeWidth="2"
              strokeDasharray={2 * Math.PI * 15}
              strokeDashoffset={2 * Math.PI * 15 * (1 - 0.67)}
              strokeLinecap="round"
              transform="rotate(-90 18 18)"
            />
          </svg>
          <span className={styles.progressLabel}>67%</span>
        </div>
      );

    default:
      return null;
  }
}
