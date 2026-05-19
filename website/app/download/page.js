"use client";
import { useSyncExternalStore } from "react";
import Link from "next/link";
import { ArrowRight, Monitor, Smartphone, Laptop, Globe, LockKeyhole } from "lucide-react";
import ScrollReveal from "../../components/shared/ScrollReveal";
import styles from "./download.module.css";

const platforms = [
  {
    icon: Monitor,
    name: "Windows",
    action: "Download .exe",
    href: "https://github.com/khalidouhdane/jawhar/releases/latest",
    available: true,
  },
  {
    icon: Smartphone,
    name: "Android",
    action: "Download APK",
    href: "https://github.com/khalidouhdane/jawhar/releases/latest",
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

function subscribeToOS() {
  return () => {};
}

function getOSSnapshot() {
  return detectOS();
}

function getServerOSSnapshot() {
  return null;
}

export default function DownloadPage() {
  const userOS = useSyncExternalStore(
    subscribeToOS,
    getOSSnapshot,
    getServerOSSnapshot
  );
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
              Free to use. Closed source for now.
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

      {/* Private development card */}
      <section className="section">
        <div className="container" style={{ maxWidth: 600, textAlign: "center" }}>
          <ScrollReveal>
            <div className={`card ${styles.openSource}`}>
              <LockKeyhole size={24} strokeWidth={1.5} />
              <h3 className="heading-card" style={{ marginTop: 12 }}>
                Private Development
              </h3>
              <p style={{ color: "var(--text-secondary)", fontSize: 15, marginTop: 8 }}>
                Jawhar is closed source for now while the product is being shaped
                for early learners, teachers, and hackathon review.
              </p>
              <Link
                href="/#waitlist"
                className="btn btn-ghost"
                style={{ marginTop: 16 }}
              >
                Join the Waitlist
                <ArrowRight size={14} />
              </Link>
            </div>
          </ScrollReveal>
        </div>
      </section>
    </main>
  );
}
