"use client";
import ScrollReveal from "../shared/ScrollReveal";
import styles from "./ProblemSection.module.css";

const painPoints = [
  {
    quote: "I revise every day but it still fades.",
    detail:
      "Hifz is 80% revision — yet most apps only track what's new. Without a system for what to review today, older pages silently decay.",
  },
  {
    quote: "I can recite it, but I don't know what it means.",
    detail:
      "Repetition without meaning produces fragile memory. A verse understood is a verse that stays.",
  },
  {
    quote: "I open three apps just to study one page.",
    detail:
      "A Mushaf here, a tafsir app there, a planner somewhere else. The tools exist — they just don't talk to each other.",
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
            Every Hifz app asks how many pages you memorized. None asks if you understood them.
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
            Jawhar was built to solve all three.
          </p>
        </ScrollReveal>
      </div>
    </section>
  );
}
