"use client";

import { useState } from "react";
import { ArrowRight, Check } from "lucide-react";
import styles from "./WaitlistSection.module.css";

export default function WaitlistSection() {
  const [email, setEmail] = useState("");
  const [submitted, setSubmitted] = useState(false);

  function handleSubmit(event) {
    event.preventDefault();
    const normalizedEmail = email.trim().toLowerCase();
    if (!normalizedEmail) return;

    const saved = JSON.parse(window.localStorage.getItem("jawhar-waitlist") || "[]");
    const next = Array.from(new Set([...saved, normalizedEmail]));
    window.localStorage.setItem("jawhar-waitlist", JSON.stringify(next));
    setSubmitted(true);
  }

  return (
    <section id="waitlist" className="section">
      <div className={`container ${styles.inner}`}>
        <div className={styles.copy}>
          <p className="mono-label">Early Access</p>
          <h2 className="heading-sub">Follow Jawhar as it opens.</h2>
          <p className="body-large">
            Jawhar is in private development for now. Join the early access list
            for release notes, test builds, and the first public launch window.
          </p>
        </div>

        <form className={`card ${styles.form}`} onSubmit={handleSubmit}>
          <label className={styles.label} htmlFor="waitlist-email">
            Email address
          </label>
          <div className={styles.inputRow}>
            <input
              id="waitlist-email"
              className={styles.input}
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="you@example.com"
              autoComplete="email"
              required
            />
            <button className="btn btn-primary" type="submit">
              Join
              <ArrowRight size={14} />
            </button>
          </div>

          {submitted ? (
            <p className={styles.status}>
              <Check size={14} />
              You are on the local early access list for this demo.
            </p>
          ) : (
            <p className={styles.note}>
              No spam. No ads. Just meaningful product updates.
            </p>
          )}
        </form>
      </div>
    </section>
  );
}
