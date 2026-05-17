"use client";
import { useState } from "react";
import { Menu, X } from "lucide-react";
import ThemeToggle from "../shared/ThemeToggle";
import styles from "./Navbar.module.css";

export default function Navbar() {
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <nav className={styles.nav}>
      <div className={`container ${styles.inner}`}>
        {/* Logo / brand */}
        <a href="/" className={styles.brand}>
          <svg
            width="24"
            height="24"
            viewBox="0 0 100 100"
            fill="none"
            stroke="currentColor"
            className={styles.logo}
          >
            {/* Outer Hexagon (Diamond base) */}
            <path
              d="M 50 95 L 12 50 L 25 25 L 50 5 L 75 25 L 88 50 Z"
              strokeWidth="5"
              strokeLinejoin="round"
              strokeLinecap="round"
            />
            {/* Inner Y-shape (Book covers and spine) */}
            <path
              d="M 25 25 L 50 40 L 75 25"
              strokeWidth="5"
              strokeLinejoin="round"
              strokeLinecap="round"
            />
            <path
              d="M 50 40 L 50 95"
              strokeWidth="5"
              strokeLinejoin="round"
              strokeLinecap="round"
            />
            {/* Left page block */}
            <path
              d="M 18 48 L 28 30 Q 40 37 50 40"
              strokeWidth="3"
              strokeLinejoin="round"
            />
            <path
              d="M 18 48 Q 35 65 50 80"
              strokeWidth="3"
              strokeLinejoin="round"
            />
            {/* Right page block */}
            <path
              d="M 82 48 L 72 30 Q 60 37 50 40"
              strokeWidth="3"
              strokeLinejoin="round"
            />
            <path
              d="M 82 48 Q 65 65 50 80"
              strokeWidth="3"
              strokeLinejoin="round"
            />
          </svg>
          <span className={styles.wordmark}>jawhar</span>
        </a>

        {/* Desktop links */}
        <div className={styles.links}>
          <a href="/#system" className={styles.link}>Features</a>
          <a href="/struggles" className={styles.link}>Struggles</a>
          <a href="/hackathon" className={styles.link}>Hackathon</a>
          <a href="/download" className={styles.link}>Download</a>
        </div>

        {/* Right side: theme toggle + CTA */}
        <div className={styles.actions}>
          <ThemeToggle />
          <a href="/download" className={`btn btn-primary ${styles.cta}`}>
            Download
          </a>
        </div>

        {/* Mobile toggle */}
        <button
          className={styles.mobileToggle}
          onClick={() => setMobileOpen(!mobileOpen)}
          aria-label={mobileOpen ? "Close menu" : "Open menu"}
        >
          {mobileOpen ? <X size={20} /> : <Menu size={20} />}
        </button>
      </div>

      {/* Mobile menu */}
      {mobileOpen && (
        <div className={styles.mobileMenu}>
          <a href="/#system" className={styles.mobileLink} onClick={() => setMobileOpen(false)}>
            Features
          </a>
          <a href="/struggles" className={styles.mobileLink} onClick={() => setMobileOpen(false)}>
            Struggles
          </a>
          <a href="/hackathon" className={styles.mobileLink} onClick={() => setMobileOpen(false)}>
            Hackathon
          </a>
          <a href="/download" className={styles.mobileLink} onClick={() => setMobileOpen(false)}>
            Download
          </a>
          <div className={styles.mobileActions}>
            <ThemeToggle />
            <a href="/download" className="btn btn-primary" style={{ marginTop: 8 }}>
              Download
            </a>
          </div>
        </div>
      )}
    </nav>
  );
}
