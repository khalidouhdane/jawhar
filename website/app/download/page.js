"use client";
import { useSyncExternalStore } from "react";
import { ArrowRight, Monitor, Smartphone, Laptop, Globe, LockKeyhole, Apple } from "lucide-react";
import ScrollReveal from "../../components/shared/ScrollReveal";
import styles from "./download.module.css";

const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.alphafoundr.jawhar";

const availablePlatforms = [
  {
    icon: Monitor,
    name: "Windows",
    action: "Install for Windows",
    href: "https://github.com/khalidouhdane/jawhar/releases/latest/download/jawhar-setup.exe",
    gradient: "gradientWindows",
  },
  {
    icon: Smartphone,
    name: "Android",
    action: "Get it on Google Play",
    href: PLAY_STORE_URL,
    sideload: "https://github.com/khalidouhdane/jawhar/releases/latest/download/app-release.apk",
    gradient: "gradientAndroid",
  },
  {
    icon: Apple,
    name: "iOS",
    action: "Join TestFlight",
    href: "https://testflight.apple.com/join/XYY6tqxC",
    gradient: "gradientIos",
  },
];

const comingSoonPlatforms = [
  { icon: Laptop, name: "macOS" },
  { icon: Monitor, name: "Linux" },
  { icon: Globe, name: "Web" },
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

  return (
    <main style={{ paddingTop: "var(--nav-height)" }}>
      {/* Hero & Grid */}
      <section className="section">
        <div className="container">
          <div style={{ textAlign: "center", marginBottom: 48 }}>
            <ScrollReveal>
              <p className="mono-label" style={{ marginBottom: 16 }}>Download</p>
              <h1 className="display-hero">Get Jawhar</h1>
              <p className="body-large" style={{ color: "var(--text-secondary)", marginTop: 16, maxWidth: 420, margin: "16px auto 0" }}>
                Free to use. Closed source for now.
                <br />
                No ads. No tracking. No subscriptions.
              </p>
            </ScrollReveal>
          </div>

          <div className={styles.sectionHeader}>
            <h2 className={styles.sectionTitle}>Download now</h2>
            <p className={styles.sectionSubtitle}>Get Jawhar on your device today.</p>
          </div>

          <div className={styles.availableGrid}>
            {availablePlatforms.map((platform, i) => {
              const Icon = platform.icon;
              const isDetected = platform.name === userOS;
              return (
                <ScrollReveal key={platform.name} delay={0.08 + i * 0.06} variant="scale">
                  <div
                    className={`card ${styles.availableCard} ${styles[platform.gradient]} ${
                      isDetected ? styles.detected : ""
                    }`}
                  >
                    {isDetected && (
                      <span className={styles.detectedBadge}>Recommended</span>
                    )}
                    <div className={styles.iconWrapper}>
                      <Icon size={28} strokeWidth={1.5} />
                    </div>
                    <span className={styles.platformName}>{platform.name}</span>
                    <a
                      href={platform.href}
                      target="_blank"
                      rel="noopener noreferrer"
                      className={`btn ${isDetected ? "btn-primary" : "btn-ghost"}`}
                      style={{ fontSize: 14, width: "100%", justifyContent: "center" }}
                    >
                      {platform.action}
                    </a>
                    {platform.sideload && (
                      <a
                        href={platform.sideload}
                        target="_blank"
                        rel="noopener noreferrer"
                        className={styles.sideload}
                      >
                        or sideload the APK
                      </a>
                    )}
                  </div>
                </ScrollReveal>
              );
            })}
          </div>

          <div className={styles.comingSoonSection}>
            <div className={styles.sectionHeader}>
              <h2 className={styles.sectionTitle}>Coming soon</h2>
              <p className={styles.sectionSubtitle}>More platforms are on the way.</p>
            </div>

            <div className={styles.comingSoonRows}>
              {comingSoonPlatforms.map((platform, i) => {
                const Icon = platform.icon;
                const isDetected = platform.name === userOS;
                return (
                  <ScrollReveal key={platform.name} delay={0.2 + i * 0.06} variant="fade">
                    <div
                      className={`card ${styles.comingSoonRow} ${
                        isDetected ? styles.comingSoonDetected : ""
                      }`}
                    >
                      <div className={styles.comingSoonLeft}>
                        <Icon size={22} strokeWidth={1.5} />
                        <span className={styles.comingSoonName}>{platform.name}</span>
                      </div>
                      <div className={styles.comingSoonRight}>
                        {isDetected && (
                          <span className={styles.comingSoonNote}>
                            You&apos;re on {platform.name} — Jawhar for {platform.name} is on the way.
                          </span>
                        )}
                        <span className={styles.comingSoonBadge}>Coming soon</span>
                      </div>
                    </div>
                  </ScrollReveal>
                );
              })}
            </div>
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
                Every time we commit to main, GitHub Actions automatically builds and ships updates — Android rolls out through Google Play review, while Windows and sideload builds update straight from GitHub — keeping every platform in sync.
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
