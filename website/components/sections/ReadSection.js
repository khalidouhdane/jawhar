"use client";

import { BookOpen, Mic, Moon } from "lucide-react";
import ScrollReveal from "../shared/ScrollReveal";
import PhoneMockup from "../shared/PhoneMockup";
import FloatingWidget from "./FloatingWidget";
import styles from "./StorySections.module.css";

export default function ReadSection() {
  return (
    <section id="read-section" className={`${styles.section} ${styles.layoutLeft}`}>
      <div className={styles.content}>
        {/* Phone group — LEFT */}
        <div className={styles.phoneGroup}>
          <ScrollReveal variant="slide-left" delay={0.1}>
            <PhoneMockup />
          </ScrollReveal>
          <ScrollReveal variant="slide-left" delay={0.25}>
            <div className={styles.phoneSecondary}>
              <PhoneMockup size="small" />
            </div>
          </ScrollReveal>

          {/* Floating widgets */}
          <FloatingWidget
            type="audio-pill"
            delay={0.5}
            style={{ bottom: "25%", right: "-30px" }}
          />
          <FloatingWidget
            type="verse-badge"
            delay={0.6}
            style={{ top: "15%", right: "40%" }}
          />
          <FloatingWidget
            type="bookmark-dot"
            delay={0.7}
            style={{ top: "60%", left: "-10px" }}
          />
        </div>

        {/* Copy + stacked cards — RIGHT */}
        <div className={styles.copyGroup}>
          <ScrollReveal>
            <h2 className={styles.title}>Read, beautifully.</h2>
            <p className={styles.description}>
              Begin with the Mushaf itself: Hafs or Warsh, the full Madani
              page, and recitation that follows the verse you are reading.
            </p>
          </ScrollReveal>

          <div className={styles.featureStack}>
            <ScrollReveal delay={0.15}>
              <div className={styles.featureCard}>
                <div className={styles.featureIcon}>
                  <BookOpen size={18} />
                </div>
                <div className={styles.featureBody}>
                  <h3 className={styles.featureTitle}>Full Mushaf</h3>
                  <p className={styles.featureText}>
                    604 pages in the Madani layout, with Hafs and Warsh
                    available from the same reading flow.
                  </p>
                </div>
              </div>
            </ScrollReveal>
            <ScrollReveal delay={0.25}>
              <div className={styles.featureCard}>
                <div className={styles.featureIcon}>
                  <Mic size={18} />
                </div>
                <div className={styles.featureBody}>
                  <h3 className={styles.featureTitle}>40+ Reciters</h3>
                  <p className={styles.featureText}>
                    Full-chapter audio with verse-level highlighting, so
                    listening stays attached to the page.
                  </p>
                </div>
              </div>
            </ScrollReveal>
            <ScrollReveal delay={0.35}>
              <div className={styles.featureCard}>
                <div className={styles.featureIcon}>
                  <Moon size={18} />
                </div>
                <div className={styles.featureBody}>
                  <h3 className={styles.featureTitle}>Focus Mode</h3>
                  <p className={styles.featureText}>
                    Dark mode, bookmarks, and daily werd tracking remain
                    present without crowding the text.
                  </p>
                </div>
              </div>
            </ScrollReveal>
          </div>
        </div>
      </div>
    </section>
  );
}
