"use client";
import { useEffect, useState } from "react";
import { ArrowRight, Monitor, Smartphone, Laptop, Globe } from "lucide-react";
import ScrollReveal from "../../components/shared/ScrollReveal";
import styles from "./download.module.css";

/* Inline SVG for GitHub icon */
function GithubIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" />
    </svg>
  );
}

const platforms = [
  {
    icon: Monitor,
    name: "Windows",
    action: "Download .exe",
    href: "https://github.com/khalidouhdane/le-quran/releases/latest",
    available: true,
  },
  {
    icon: Smartphone,
    name: "Android",
    action: "Download APK",
    href: "https://github.com/khalidouhdane/le-quran/releases/latest",
    available: true,
  },
  {
    icon: Laptop,
    name: "macOS",
    action: "Coming soon",
    available: false,
  },
  {
    icon: Monitor,
    name: "Linux",
    action: "Coming soon",
    available: false,
  },
  {
    icon: Smartphone,
    name: "iOS",
    action: "Coming soon",
    available: false,
  },
  {
    icon: Globe,
    name: "Web",
    action: "Coming soon",
    available: false,
  },
];

function detectOS() {
  if (typeof navigator === "undefined") return null;
  const ua = navigator.userAgent;
  if (/Windows/.test(ua)) return "Windows";
  if (/Android/.test(ua)) return "Android";
  if (/Mac/.test(ua)) return "macOS";
  if (/Linux/.test(ua)) return "Linux";
  if (/iPhone|iPad/.test(ua)) return "iOS";
  return null;
}

export default function DownloadPage() {
  const [userOS, setUserOS] = useState(null);

  useEffect(() => {
    setUserOS(detectOS());
  }, []);

  const primary = platforms.find((p) => p.name === userOS && p.available);

  return (
    <main style={{ paddingTop: "var(--nav-height)" }}>
      {/* Hero */}
      <section className="section">
        <div className="container" style={{ textAlign: "center" }}>
          <ScrollReveal>
            <p className="mono-label" style={{ marginBottom: 16 }}>Download</p>
            <h1 className="display-hero">Get Jawhar</h1>
            <p className="body-large" style={{ color: "var(--text-secondary)", marginTop: 16, maxWidth: 420, margin: "16px auto 0" }}>
              Free, open source, and always will be.
              <br />
              No ads. No tracking. No subscriptions.
            </p>
          </ScrollReveal>

          {primary && (
            <ScrollReveal delay={0.15}>
              <div style={{ marginTop: 32 }}>
                <a href={primary.href} className="btn btn-primary btn-large">
                  Download for {primary.name}
                  <ArrowRight size={16} />
                </a>
              </div>
            </ScrollReveal>
          )}
        </div>
      </section>

      <div className="section-divider" />

      {/* All platforms grid */}
      <section className="section section-alt">
        <div className="container">
          <ScrollReveal>
            <h2 className="heading-card" style={{ textAlign: "center", marginBottom: 40 }}>
              All Platforms
            </h2>
          </ScrollReveal>

          <div className={styles.grid}>
            {platforms.map((platform, i) => {
              const Icon = platform.icon;
              const isDetected = platform.name === userOS;
              return (
                <ScrollReveal key={i} delay={0.08 + i * 0.06} variant="scale">
                  <div className={`card ${styles.item} ${!platform.available ? styles.unavailable : ""}`}>
                    {isDetected && <span className={styles.badge}>Your OS</span>}
                    <Icon size={28} strokeWidth={1.5} />
                    <span className={styles.name}>{platform.name}</span>
                    {platform.available ? (
                      <a href={platform.href} className="btn btn-primary" style={{ fontSize: 13 }}>
                        {platform.action}
                      </a>
                    ) : (
                      <span className={styles.soonText}>{platform.action}</span>
                    )}
                  </div>
                </ScrollReveal>
              );
            })}
          </div>
        </div>
      </section>

      <div className="section-divider" />

      {/* Open source card */}
      <section className="section">
        <div className="container" style={{ maxWidth: 600, textAlign: "center" }}>
          <ScrollReveal>
            <div className={`card ${styles.openSource}`}>
              <GithubIcon />
              <h3 className="heading-card" style={{ marginTop: 12 }}>
                Open Source
              </h3>
              <p style={{ color: "var(--text-secondary)", fontSize: 15, marginTop: 8 }}>
                Jawhar is fully open source. Audit the code, contribute, or build your own.
              </p>
              <a
                href="https://github.com/khalidouhdane/le-quran"
                target="_blank"
                rel="noopener noreferrer"
                className="btn btn-ghost"
                style={{ marginTop: 16 }}
              >
                View on GitHub
                <ArrowRight size={14} />
              </a>
            </div>
          </ScrollReveal>
        </div>
      </section>
    </main>
  );
}
