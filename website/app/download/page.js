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
    action: "Download ZIP",
    href: "https://github.com/khalidouhdane/jawhar/releases/latest/download/jawhar-windows.zip",
    available: true,
  },
  {
    icon: Smartphone,
    name: "Android",
    action: "Download APK",
    href: "https://github.com/khalidouhdane/jawhar/releases/latest/download/app-release.apk",
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
    action: "Join TestFlight",
    href: "https://testflight.apple.com/join/XYY6tqxC",
    available: true,
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
  if (/iPhone|iPad|iPod/.test(ua)) return "iOS";
  if (/Android/.test(ua)) return "Android";
  if (/Windows/.test(ua)) return "Windows";
  if (/Mac/.test(ua)) return "macOS";
  if (/Linux/.test(ua)) return "Linux";
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

      {/* Release Channel card */}
      <section className="section">
        <div className="container" style={{ maxWidth: 600, textAlign: "center" }}>
          <ScrollReveal>
            <div className={`card ${styles.openSource}`}>
              <LockKeyhole size={24} strokeWidth={1.5} />
              <h3 className="heading-card" style={{ marginTop: 12 }}>
                Release Channel
              </h3>
              <p style={{ color: "var(--text-secondary)", fontSize: 15, marginTop: 8 }}>
                Every time we commit to main, GitHub Actions automatically builds and releases updates to the downloads above, keeping the app synced.
              </p>
              <a
                href="https://github.com/khalidouhdane/jawhar/releases"
                target="_blank"
                rel="noopener noreferrer"
                className="btn btn-ghost"
                style={{ marginTop: 16 }}
              >
                View Changelog
                <ArrowRight size={14} />
              </a>
            </div>
          </ScrollReveal>
        </div>
      </section>
    </main>
  );
}
