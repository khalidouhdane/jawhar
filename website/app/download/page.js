"use client";
import { useSyncExternalStore } from "react";
import Link from "next/link";
import { ArrowRight, Monitor, Smartphone, Laptop, Globe, LockKeyhole } from "lucide-react";
import ScrollReveal from "../../components/shared/ScrollReveal";
import styles from "./download.module.css";

const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.alphafoundr.jawhar";

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
    action: "Get it on Google Play",
    href: PLAY_STORE_URL,
    sideload: "https://github.com/khalidouhdane/jawhar/releases/latest/download/app-release.apk",
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

          <div className={styles.grid}>
            {platforms.map((platform, i) => {
              const Icon = platform.icon;
              const isDetected = platform.name === userOS;
              const showHighlight = isDetected && platform.available;
              return (
                <ScrollReveal key={i} delay={0.08 + i * 0.06} variant="scale">
                  <div className={`card ${styles.item} ${!platform.available ? styles.unavailable : ""} ${showHighlight ? styles.highlighted : ""}`}>
                    {showHighlight && (
                      <span className={styles.detectedBadge}>Recommended</span>
                    )}
                    <Icon size={28} strokeWidth={1.5} />
                    <span className={styles.name}>{platform.name}</span>
                    {platform.available ? (
                      <>
                        <a href={platform.href} target={platform.href.startsWith("http") ? "_blank" : undefined} rel={platform.href.startsWith("http") ? "noopener noreferrer" : undefined} className={`btn ${showHighlight ? "btn-primary" : "btn-ghost"}`} style={{ fontSize: 13, width: "100%", justifyContent: "center" }}>
                          {platform.action}
                        </a>
                        {platform.sideload && (
                          <a href={platform.sideload} target="_blank" rel="noopener noreferrer" className={styles.sideload}>
                            or sideload the APK
                          </a>
                        )}
                      </>
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
