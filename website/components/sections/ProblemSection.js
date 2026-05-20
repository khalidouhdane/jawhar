"use client";
import ScrollReveal from "../shared/ScrollReveal";
import styles from "./ProblemSection.module.css";

const painPoints = [
  {
    quote: "Hifz is mostly revision. Most tools only count progress.",
    detail:
      "A memorization journey does not fail because the user forgot to mark a page. It fails when today's review is unclear.",
  },
  {
    quote: "A verse can be repeated many times and still feel distant.",
    detail:
      "Meaning is not extra. It is the anchor that helps a verse become familiar, connected, and remembered.",
  },
  {
    quote: "The interface should not compete with the Quran.",
    detail:
      "Jawhar keeps the system quiet: clear plans, precise context, and enough structure to support the work without taking over.",
  },
];

export default function ProblemSection() {
  return (
    <section className="section" id="problem">
      <div className="container">
        <ScrollReveal>
          <p className="mono-label" style={{ textAlign: "center", marginBottom: 16 }}>
            The Problem
          </p>
          <h2
            className="heading-sub"
            style={{ textAlign: "center", maxWidth: 720, margin: "0 auto" }}
          >
            Memorization needs more than a counter.
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
            The app disappears. The Quran appears.
          </p>
        </ScrollReveal>
      </div>
    </section>
  );
}
