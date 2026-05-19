"use client";

import { Globe, BookOpen, Info } from "lucide-react";
import ScrollReveal from "../shared/ScrollReveal";
import PhoneMockup from "../shared/PhoneMockup";
import FloatingWidget from "./FloatingWidget";
import styles from "./StorySections.module.css";

export default function UnderstandSection() {
  return (
    <section id="understand-section" className={`${styles.section} ${styles.layoutRight}`}>
      <div className={styles.content}>
        {/* Phone group — RIGHT (via layoutRight flex-direction: row-reverse) */}
        <div className={styles.phoneGroup}>
          <ScrollReveal variant="slide-right" delay={0.1}>
            <PhoneMockup />
          </ScrollReveal>
          <ScrollReveal variant="slide-right" delay={0.25}>
            <div className={styles.phoneSecondary}>
              <PhoneMockup size="small" />
            </div>
          </ScrollReveal>

          {/* Floating widgets */}
          <FloatingWidget
            type="lang-switch"
            delay={0.5}
            style={{ top: "12%", left: "-20px" }}
          />
          <FloatingWidget
            type="tafsir-mode"
            delay={0.6}
            style={{ bottom: "30%", left: "-30px" }}
          />
          <FloatingWidget
            type="verse-translation"
            delay={0.7}
            style={{ top: "45%", right: "-40px" }}
          />
        </div>

        {/* Copy + stacked cards — LEFT */}
        <div className={styles.copyGroup}>
          <ScrollReveal>
            <h2 className={styles.title}>Understand every verse.</h2>
            <p className={styles.description}>
              Meaning is not an add-on. Translation, tafsir, reasons of
              revelation, and surah introductions sit beside the verse so
              memory has context.
            </p>
          </ScrollReveal>

          <div className={styles.featureStack}>
            <ScrollReveal delay={0.15}>
              <div className={styles.featureCard}>
                <div className={styles.featureIcon}>
                  <Globe size={18} />
                </div>
                <div className={styles.featureBody}>
                  <h3 className={styles.featureTitle}>Translations</h3>
                  <p className={styles.featureText}>
                    A clear first layer of meaning, available without leaving
                    the page or session.
                  </p>
                </div>
              </div>
            </ScrollReveal>
            <ScrollReveal delay={0.25}>
              <div className={styles.featureCard}>
                <div className={styles.featureIcon}>
                  <BookOpen size={18} />
                </div>
                <div className={styles.featureBody}>
                  <h3 className={styles.featureTitle}>Tafsir</h3>
                  <p className={styles.featureText}>
                    Brief and detailed explanations support recall without
                    turning memorization into browsing.
                  </p>
                </div>
              </div>
            </ScrollReveal>
            <ScrollReveal delay={0.35}>
              <div className={styles.featureCard}>
                <div className={styles.featureIcon}>
                  <Info size={18} />
                </div>
                <div className={styles.featureBody}>
                  <h3 className={styles.featureTitle}>Asbab al-Nuzul</h3>
                  <p className={styles.featureText}>
                    Reasons of revelation and curated surah introductions give
                    the verse a place in the larger whole.
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
