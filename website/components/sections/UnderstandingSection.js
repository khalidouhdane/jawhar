"use client";
import ScrollReveal from "../shared/ScrollReveal";
import PhoneMockup from "../shared/PhoneMockup";
import styles from "./UnderstandingSection.module.css";

const features = [
  "Translations",
  "Tafsir (Brief + Detailed)",
  "Reasons of Revelation",
  "Surah Introductions",
];

export default function UnderstandingSection() {
  return (
    <section className="section section-alt" id="understanding">
      <div className="container">
        <ScrollReveal>
          <p className="mono-label" style={{ textAlign: "center", marginBottom: 16 }}>
            The Understanding
          </p>
          <h2 className="heading-sub" style={{ textAlign: "center", maxWidth: 600, margin: "0 auto" }}>
            Every verse you memorize, you understand.
          </h2>
        </ScrollReveal>

        <div className={styles.split}>
          {/* Phone mockup with verse */}
          <ScrollReveal delay={0.2} variant="slide-left">
            <PhoneMockup>
              <div className={styles.mockupContent}>
                {/* Fake status bar */}
                <div className={styles.statusBar}>
                  <span>9:41</span>
                  <span className={styles.pageLabel}>Page 42</span>
                </div>

                {/* Arabic verse */}
                <div className={styles.verseArea}>
                  <p className={styles.verseArabic}>
                    ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ
                    ٱلْحَىُّ ٱلْقَيُّومُ ۚ
                    لَا تَأْخُذُهُۥ سِنَةٌ وَلَا نَوْمٌ ۚ
                    لَّهُۥ مَا فِى ٱلسَّمَـٰوَٰتِ
                    وَمَا فِى ٱلْأَرْضِ ۗ
                  </p>
                  <p className={styles.verseRef}>2:255 · Ayat al-Kursi</p>
                </div>

                {/* Overlay card inside phone */}
                <div className={styles.overlayCard}>
                  <span className={styles.overlayLabel}>Translation</span>
                  <p className={styles.overlayText}>
                    Allah — there is no deity except Him, the
                    Ever-Living, the Sustainer of existence…
                  </p>
                </div>
              </div>
            </PhoneMockup>
          </ScrollReveal>

          {/* Context cards */}
          <div className={styles.contextSide}>
            <ScrollReveal delay={0.3} variant="slide-right">
              <div className={`card ${styles.contextCard}`}>
                <span className="mono-label">Translation</span>
                <p className={styles.contextText}>
                  Allah — there is no deity except Him, the Ever-Living, the
                  Sustainer of existence. Neither drowsiness overtakes Him nor
                  sleep. To Him belongs whatever is in the heavens and whatever
                  is on the earth.
                </p>
              </div>
            </ScrollReveal>

            <ScrollReveal delay={0.4} variant="slide-right">
              <div className={`card ${styles.contextCard}`}>
                <span className="mono-label">Brief Tafsir</span>
                <p className={styles.contextText}>
                  Ayat al-Kursi — the greatest verse of the Quran. It
                  establishes Allah&apos;s absolute sovereignty, omniscience, and
                  the incomprehensibility of His knowledge to creation.
                </p>
              </div>
            </ScrollReveal>

            <ScrollReveal delay={0.5} variant="slide-right">
              <div className={`card ${styles.contextCard}`}>
                <span className="mono-label">Reason of Revelation</span>
                <p className={styles.contextText}>
                  The Prophet ﷺ said: &ldquo;The greatest verse in the Book of
                  Allah is Ayat al-Kursi.&rdquo; — Sahih Muslim
                </p>
              </div>
            </ScrollReveal>
          </div>
        </div>

        <ScrollReveal delay={0.6}>
          <div className={styles.chips}>
            {features.map((feat) => (
              <span key={feat} className="badge">
                {feat}
              </span>
            ))}
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
}
