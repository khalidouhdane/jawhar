"use client";
import ScrollReveal from "../shared/ScrollReveal";
import { Check, Minus } from "lucide-react";
import styles from "./DifferenceSection.module.css";

const rows = [
  { feature: "Adaptive daily plans", others: false, jawhar: true },
  { feature: "Session mode with timer", others: false, jawhar: true },
  { feature: "Tafsir & understanding", others: false, jawhar: true },
  { feature: "SRS flashcards + Mutashabihat", others: false, jawhar: true },
  { feature: "Desktop support", others: false, jawhar: true },
  { feature: "Free, no ads", others: "partial", jawhar: true },
];

function StatusIcon({ value }) {
  if (value === true) {
    return (
      <span className={styles.iconYes}>
        <Check size={15} strokeWidth={2.5} />
      </span>
    );
  }
  return (
    <span className={styles.iconNo}>
      <Minus size={15} strokeWidth={2} />
    </span>
  );
}

export default function DifferenceSection() {
  return (
    <section className="section" id="difference">
      <div className="container">
        <ScrollReveal>
          <p className="mono-label" style={{ textAlign: "center", marginBottom: 16 }}>
            How Jawhar compares
          </p>
          <h2 className="heading-sub" style={{ textAlign: "center" }}>
            Built different, on purpose.
          </h2>
        </ScrollReveal>

        <ScrollReveal delay={0.15}>
          <div className={styles.tableWrap}>
            <table className={styles.table}>
              <thead>
                <tr>
                  <th className={styles.thFeature}>Feature</th>
                  <th className={styles.thStatus}>Others</th>
                  <th className={styles.thStatus}>Jawhar</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row, i) => (
                  <tr key={i} className={styles.row}>
                    <td className={styles.tdFeature}>{row.feature}</td>
                    <td className={styles.tdStatus}>
                      <StatusIcon value={row.others} />
                    </td>
                    <td className={styles.tdStatus}>
                      <StatusIcon value={row.jawhar} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
}
