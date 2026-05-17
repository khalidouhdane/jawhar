"use client";
import ScrollReveal from "../shared/ScrollReveal";
import { BookOpen, RefreshCw, Shield } from "lucide-react";
import styles from "./SystemSection.module.css";

const phases = [
  {
    icon: BookOpen,
    name: "Sabaq",
    label: "New Memorization",
    description:
      "Fresh verses. Your daily assignment — carefully sized to match your pace and capacity.",
  },
  {
    icon: RefreshCw,
    name: "Sabqi",
    label: "Recent Review",
    description:
      "Last 7 days of memorization. The critical window where new verses either solidify or fade.",
  },
  {
    icon: Shield,
    name: "Manzil",
    label: "Long-term Retention",
    description:
      "Everything you've memorized. Rotating review across your entire collection — one Juz at a time.",
  },
];

export default function SystemSection() {
  return (
    <section className="section" id="system">
      <div className="container">
        <ScrollReveal>
          <p className="mono-label" style={{ textAlign: "center", marginBottom: 16 }}>
            The System
          </p>
          <h2 className="heading-sub" style={{ textAlign: "center" }}>
            Not a tracker. A system.
          </h2>
          <p
            className="body-large"
            style={{
              textAlign: "center",
              color: "var(--text-secondary)",
              maxWidth: 480,
              margin: "16px auto 0",
            }}
          >
            The methodology your teacher uses — now in your pocket.
          </p>
        </ScrollReveal>

        <div className={styles.pipeline}>
          {phases.map((phase, i) => {
            const Icon = phase.icon;
            return (
              <div key={i} className={styles.step}>
                <ScrollReveal delay={0.15 + i * 0.18}>
                  <div className={`card ${styles.phaseCard}`}>
                    <div className={styles.iconWrap}>
                      <Icon size={22} strokeWidth={1.5} />
                    </div>
                    <h3 className={styles.phaseName}>{phase.name}</h3>
                    <span className="mono-label">{phase.label}</span>
                    <p className={styles.phaseDesc}>{phase.description}</p>
                  </div>
                </ScrollReveal>

                {/* Connector */}
                {i < phases.length - 1 && (
                  <div className={styles.connector} aria-hidden="true">
                    <svg width="48" height="2" viewBox="0 0 48 2">
                      <line
                        x1="0" y1="1" x2="40" y2="1"
                        stroke="var(--gray-100)"
                        strokeWidth="1"
                      />
                      <polygon
                        points="40,0 48,1 40,2"
                        fill="var(--gray-100)"
                      />
                    </svg>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
