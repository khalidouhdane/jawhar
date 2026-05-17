"use client";
import ScrollReveal from "../shared/ScrollReveal";
import styles from "./ProblemSection.module.css";

const painPoints = [
  {
    quote: "Hifz is 80% revision. No app plans it.",
    detail:
      "Every app lets you track pages. None of them tell you what to revise today, or manage the exponential growth of review material.",
  },
  {
    quote: "I memorized Juz 30 but can't explain a single verse.",
    detail:
      "Memorization without understanding leads to fragile memory. The meaning is the anchor that makes verses stick.",
  },
  {
    quote: "The same app design, over and over.",
    detail:
      "Green backgrounds, gold accents, basic counters. 500+ Quran apps — but the same experience recycled endlessly.",
  },
];

export default function ProblemSection() {
  return (
    <section className="section section-alt" id="problem">
      <div className="container">
        <ScrollReveal>
          <p className="mono-label" style={{ textAlign: "center", marginBottom: 16 }}>
            The Problem
          </p>
          <h2
            className="heading-sub"
            style={{ textAlign: "center", maxWidth: 720, margin: "0 auto" }}
          >
            500+ Quran apps. None help you understand what you memorize.
          </h2>
        </ScrollReveal>

        <div className={styles.cards}>
          {painPoints.map((point, i) => (
            <ScrollReveal key={i} delay={0.12 + i * 0.12}>
              <div className={`card ${styles.card}`}>
                <blockquote className={styles.quote}>
                  &ldquo;{point.quote}&rdquo;
                </blockquote>
                <p className={styles.detail}>{point.detail}</p>
              </div>
            </ScrollReveal>
          ))}
        </div>

        <ScrollReveal delay={0.5}>
          <p className={styles.source}>
            — from Reddit r/islam, r/Quran, app store reviews
          </p>
        </ScrollReveal>
      </div>
    </section>
  );
}
