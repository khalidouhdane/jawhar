"use client";

import { useRef } from "react";
import gsap from "gsap";
import { useGSAP } from "@gsap/react";
import DepthRings from "./DepthRings";
import WaitlistForm from "../shared/WaitlistForm";
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
            Jawhar is free, private, and built for one purpose: to help you
            carry every verse with its meaning.
          </p>

          <div className={styles.formWrap}>
            <WaitlistForm />
          </div>

          <p className={styles.trust}>
            Free forever · Privacy-first · Open roadmap
          </p>
        </div>
      </div>
    </section>
  );
}
