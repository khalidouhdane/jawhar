"use client";

import { ListTodo, Timer, RefreshCcw } from "lucide-react";
import ScrollReveal from "../shared/ScrollReveal";
import PhoneMockup from "../shared/PhoneMockup";
import FloatingWidget from "./FloatingWidget";
import styles from "./StorySections.module.css";

export default function MemorizeSection() {
  return (
    <section id="memorize-section" className={`${styles.section} ${styles.layoutLeft}`}>
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
            type="streak"
            delay={0.5}
            style={{ top: "10%", right: "-20px" }}
          />
          <FloatingWidget
            type="timer"
            delay={0.6}
            style={{ bottom: "20%", right: "-30px" }}
          />
          <FloatingWidget
            type="progress-ring"
            delay={0.7}
            style={{ top: "50%", left: "-20px" }}
          />
        </div>

        {/* Copy + stacked cards — RIGHT */}
        <div className={styles.copyGroup}>
          <ScrollReveal>
            <h2 className={styles.title}>Memorize it, forever.</h2>
            <p className={styles.description}>
              Jawhar turns understanding into a daily rhythm: what to learn,
              what to review, and how to return to older pages before they
              fade.
            </p>
          </ScrollReveal>

          <div className={styles.featureStack}>
            <ScrollReveal delay={0.15}>
              <div className={styles.featureCard}>
                <div className={styles.featureIcon}>
                  <ListTodo size={18} />
                </div>
                <div className={styles.featureBody}>
                  <h3 className={styles.featureTitle}>Adaptive Plans</h3>
                  <p className={styles.featureText}>
                    Daily plans balance sabaq, sabqi, and manzil around the
                    user&apos;s pace and available time.
                  </p>
                </div>
              </div>
            </ScrollReveal>
            <ScrollReveal delay={0.25}>
              <div className={styles.featureCard}>
                <div className={styles.featureIcon}>
                  <Timer size={18} />
                </div>
                <div className={styles.featureBody}>
                  <h3 className={styles.featureTitle}>Structured Sessions</h3>
                  <p className={styles.featureText}>
                    Timers, repetition counters, audio, and self-assessment
                    support both physical and digital sessions.
                  </p>
                </div>
              </div>
            </ScrollReveal>
            <ScrollReveal delay={0.35}>
              <div className={styles.featureCard}>
                <div className={styles.featureIcon}>
                  <RefreshCcw size={18} />
                </div>
                <div className={styles.featureBody}>
                  <h3 className={styles.featureTitle}>Smart Flashcards</h3>
                  <p className={styles.featureText}>
                    Six review card types and mutashabihat practice strengthen
                    the pages already memorized.
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
