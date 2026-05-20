"use client";

import { useRef } from "react";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import DepthRings from "./DepthRings";
import Link from "next/link";
import styles from "./ClosingSection.module.css";

export default function ClosingSection() {
  const resolutionRef = useRef(null);

  function handleRingsComplete() {
    if (!resolutionRef.current) return;
    gsap.fromTo(
      resolutionRef.current,
      { opacity: 0, y: 20 },
      { opacity: 1, y: 0, duration: 0.8, ease: "power2.out" }
    );
  }

  // Set resolution hidden initially
  useGSAP(() => {
    if (resolutionRef.current) {
      gsap.set(resolutionRef.current, { opacity: 0, y: 20 });
    }
  });

  return (
    <section id="closing" className="section">
      <div className="container">
        <p className="mono-label" style={{ textAlign: "center", marginBottom: 24 }}>
          Your journey
        </p>

        <DepthRings onAnimationComplete={handleRingsComplete} />

        <div className={styles.resolution} ref={resolutionRef}>
          <h2 className="heading-sub" style={{ textAlign: "center" }}>
            The app disappears. The Quran appears.
          </h2>
          <p className={`body-large ${styles.subtitle}`}>
            One companion for the entire journey — from your first page to your last.
          </p>

          <div className={styles.formWrap}>
            <Link href="/download" className="btn btn-primary btn-large">
              Download Jawhar
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M5 12h14"/>
                <path d="m12 5 7 7-7 7"/>
              </svg>
            </Link>
          </div>

          <p className={styles.trust}>
            Windows · Android · iOS (TestFlight)
          </p>
        </div>
      </div>
    </section>
  );
}
