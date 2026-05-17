"use client";
import ScrollReveal from "../../components/shared/ScrollReveal";
import { ArrowRight } from "lucide-react";
import styles from "./struggles.module.css";

const struggles = [
  {
    id: "next-verse",
    title: 'The "Next Verse" Problem',
    problem: 'You can recite a whole page — but only if you start from the beginning. Ask for a random verse and you freeze. The chain breaks because you memorized a sequence, not meaning.',
    why: "Sequential memory is brittle. Without understanding context — why a verse was revealed, what it means — your brain has no anchor points. The chain of words exists in isolation.",
    solution: "Jawhar pairs every verse with its translation, tafsir (brief + detailed), and reason of revelation. When you understand why a verse exists, you can recall it from any starting point.",
  },
  {
    id: "forgetting",
    title: "Forgetting Previously Memorized Portions",
    problem: '"I memorized 5 juz last year. I can barely recall 2 now." The exponential growth of review material overwhelms every student who doesn\'t have a systematic plan.',
    why: "Without structured revision, the forgetting curve is merciless. New memorization pushes old material out. Most apps let you mark pages but never tell you what to review today.",
    solution: "The Sabaq-Sabqi-Manzil system: new memorization daily, recent review (last 7 days), and long-term rotation across your entire collection. Jawhar generates this plan automatically.",
  },
  {
    id: "mutashabihat",
    title: "Mutashabihat — Similar Verse Confusion",
    problem: '"وَقَالُوا" appears dozens of times with slight variations. You start one verse and end up reciting a completely different one. Similar verses are the #1 source of errors.',
    why: "The Quran contains hundreds of verse groups that share nearly identical wording but differ in subtle ways. Without explicit practice, your brain merges them.",
    solution: "Dedicated Mutashabihat practice: Spot the Difference, Context Recall, and Quiz modes. Jawhar automatically identifies similar verse groups from your memorized content.",
  },
  {
    id: "motivation",
    title: "Loss of Motivation & Burnout",
    problem: '"I was consistent for 3 months, then life happened. I missed a week and never came back." The guilt of falling behind becomes a barrier to restarting.',
    why: "Fixed schedules break on contact with reality. Without adaptive planning that adjusts to your pace and missed days, every gap feels like failure.",
    solution: "Missed Day dialog with a gentle re-engagement flow. Jawhar auto-adjusts your plan based on what you actually completed — no guilt, no accumulated backlog.",
  },
  {
    id: "rushing",
    title: "Rushing New Memorization",
    problem: '"I want to finish the whole Quran as fast as possible." Students take on too many new pages and build on a weak foundation that collapses later.',
    why: "Without pace projection, students can't see the long-term consequences of their daily choices. More new pages today means exponentially more review tomorrow.",
    solution: "Pace projection shows exactly when you'll finish at your current rate. The plan generation algorithm caps new memorization based on your review performance.",
  },
  {
    id: "self-assessment",
    title: "No Self-Assessment Framework",
    problem: '"Did I actually memorize this page well, or am I just reading it one more time?" Students can\'t distinguish between recognition and true recall.',
    why: "Most apps track binary state: memorized or not. Real memorization exists on a spectrum from shaky recognition to fluent recall without prompting.",
    solution: "After each session, rate your recall quality. Jawhar uses this self-assessment to calibrate future plans — pages rated weak get scheduled sooner.",
  },
  {
    id: "isolation",
    title: "Learning in Isolation",
    problem: '"I have no teacher, no study partner, no one to check my progress." Solo learners lack accountability and have no way to verify their quality.',
    why: "Traditional Hifz is inherently social — you recite to a teacher who corrects you. Digital tools removed the social layer without replacing it.",
    solution: "Accountability partners, progress sharing, and Teacher Mode — generate shareable progress reports that a mentor can review remotely.",
  },
  {
    id: "understanding",
    title: "Memorizing Without Understanding",
    problem: '"I can recite Surah Al-Baqarah start to finish. I don\'t understand a single verse." Memorization without meaning is the most common regret of experienced Huffaz.',
    why: "Speed-focused Hifz programs prioritize quantity over comprehension. The verses become sounds — beautiful sounds — but sounds without anchors.",
    solution: "Jawhar's core thesis: every verse you memorize, you understand. Translation overlays, tafsir sheets, Asbab al-Nuzul cards — all accessible within the reading experience.",
  },
  {
    id: "timing",
    title: "Poor Session Structure",
    problem: '"I sit down to memorize and either spend 3 hours or 10 minutes. There\'s no structure." Without a framework, practice time is inconsistent and unfocused.',
    why: "Unstructured sessions lead to either burnout (too long) or insufficient practice (too short). Students don't know how to allocate time across new memorization and review.",
    solution: "Structured sessions with timer, rep counter, and phase progression. Each session moves through Sabaq → Sabqi → Manzil with time allocations based on your plan.",
  },
  {
    id: "retention",
    title: "No Spaced Repetition System",
    problem: '"I review the same pages every day while others get neglected for weeks." Manual review scheduling is inconsistent and cognitively taxing.',
    why: "The human brain follows predictable forgetting curves. Without algorithmic scheduling, students either over-review easy material or under-review difficult material.",
    solution: "SM-2 spaced repetition engine for flashcards. 6 card types (First Word, Last Word, Fill in the Blank, Verse Order, Translation Match, Context Recall) auto-generated from memorized content.",
  },
  {
    id: "tracking",
    title: "Inadequate Progress Tracking",
    problem: '"I have no idea if I\'m improving or just treading water." Without analytics, students can\'t see patterns in their performance.',
    why: "Most apps show a percentage bar. Real progress tracking requires longitudinal data: session quality over time, retention rates, pace trends.",
    solution: "Weekly analytics reports with session quality trends, retention rates, pace projection, and adaptive suggestion cards that recommend what to focus on next.",
  },
];

export default function StrugglesPage() {
  return (
    <main style={{ paddingTop: "var(--nav-height)" }}>
      {/* Header */}
      <section className="section">
        <div className="container" style={{ textAlign: "center" }}>
          <ScrollReveal>
            <p className="mono-label" style={{ marginBottom: 16 }}>
              Research-Backed Solutions
            </p>
            <h1 className="display-hero">
              11 Hifz Struggles
              <br />& How Jawhar Solves Them
            </h1>
            <p
              className="body-large"
              style={{
                color: "var(--text-secondary)",
                maxWidth: 520,
                margin: "24px auto 0",
              }}
            >
              From 60+ sources — Reddit communities, Hifz academies, research
              papers, and real experiences of people memorizing the Quran.
            </p>
          </ScrollReveal>
        </div>
      </section>

      {/* Table of Contents */}
      <div className={styles.tocWrapper}>
        <div className={`container ${styles.toc}`}>
          {struggles.map((s, i) => (
            <a key={s.id} href={`#${s.id}`} className={styles.tocPill}>
              <span className={styles.tocNum}>{String(i + 1).padStart(2, "0")}</span>
              {s.title}
            </a>
          ))}
        </div>
      </div>

      {/* Struggles */}
      {struggles.map((s, i) => (
        <section
          key={s.id}
          id={s.id}
          className={`section ${i % 2 === 0 ? "" : "section-alt"}`}
        >
          <div className="container">
            <ScrollReveal>
              <div className={styles.struggle}>
                <div className={styles.header}>
                  <span className={styles.number}>
                    {String(i + 1).padStart(2, "0")}
                  </span>
                  <h2 className="heading-card">{s.title}</h2>
                </div>

                <div className={styles.grid}>
                  <div className={`card ${styles.block}`}>
                    <span className="mono-label">The Problem</span>
                    <p className={styles.blockText}>{s.problem}</p>
                  </div>

                  <div className={`card ${styles.block}`}>
                    <span className="mono-label">Why It Happens</span>
                    <p className={styles.blockText}>{s.why}</p>
                  </div>

                  <div className={`card ${styles.block} ${styles.solutionBlock}`}>
                    <span className="mono-label">How Jawhar Solves It</span>
                    <p className={styles.blockText}>{s.solution}</p>
                  </div>
                </div>
              </div>
            </ScrollReveal>
          </div>
        </section>
      ))}

      <div className="section-divider" />

      {/* CTA */}
      <section className="section">
        <div className="container" style={{ textAlign: "center" }}>
          <ScrollReveal>
            <h2 className="heading-sub">
              Ready to memorize differently?
            </h2>
            <p
              className="body-large"
              style={{
                color: "var(--text-secondary)",
                marginTop: 16,
                maxWidth: 400,
                margin: "16px auto 0",
              }}
            >
              Free, open source, no ads. Start today.
            </p>
            <div style={{ marginTop: 32 }}>
              <a href="/download" className="btn btn-primary btn-large">
                Download Jawhar
                <ArrowRight size={16} />
              </a>
            </div>
          </ScrollReveal>
        </div>
      </section>
    </main>
  );
}
