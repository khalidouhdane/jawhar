"use client";
import ScrollReveal from "../shared/ScrollReveal";
import { Monitor, Smartphone, Apple, Globe, Laptop } from "lucide-react";
import styles from "./PlatformSection.module.css";

const platforms = [
  { icon: Monitor, name: "Windows", available: true },
  { icon: Smartphone, name: "Android", available: true },
  { icon: Laptop, name: "macOS", soon: true },
  { icon: Monitor, name: "Linux", soon: true },
  { icon: Apple, name: "iOS", soon: true },
  { icon: Globe, name: "Web", soon: true },
];

export default function PlatformSection() {
  return (
    <section className="section section-alt" id="platforms">
      <div className="container">
        <ScrollReveal>
          <p className="mono-label" style={{ textAlign: "center", marginBottom: 16 }}>
            Platforms
          </p>
          <h2 className="heading-sub" style={{ textAlign: "center" }}>
            Available everywhere you study
          </h2>
          <p
            className="body-large"
            style={{
              textAlign: "center",
              color: "var(--text-secondary)",
              maxWidth: 400,
              margin: "16px auto 0",
            }}
          >
            Desktop-first. Cross-platform. No compromises.
          </p>
        </ScrollReveal>

        <div className={styles.grid}>
          {platforms.map((platform, i) => {
            const Icon = platform.icon;
            return (
              <ScrollReveal key={i} delay={0.1 + i * 0.06} variant="scale">
                <div
                  className={`${styles.item} ${
                    platform.available ? styles.available : styles.soon
                  }`}
                >
                  <Icon size={28} strokeWidth={1.5} />
                  <span className={styles.name}>{platform.name}</span>
                  {platform.soon && (
                    <span className={styles.soonLabel}>Soon</span>
                  )}
                </div>
              </ScrollReveal>
            );
          })}
        </div>

        <ScrollReveal delay={0.5}>
          <div style={{ textAlign: "center", marginTop: 48 }}>
            <a href="/download" className="btn btn-primary btn-large">
              Download for your platform →
            </a>
          </div>
        </ScrollReveal>
      </div>
    </section>
  );
}
