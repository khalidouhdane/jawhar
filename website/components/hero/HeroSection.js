"use client";
import { motion } from "framer-motion";
import { ArrowRight, ChevronDown } from "lucide-react";
import DiamondAnimation from "./DiamondAnimation";
import styles from "./HeroSection.module.css";

export default function HeroSection() {
  return (
    <section className={styles.hero}>
      {/* Arabic calligraphy texture — very subtle */}
      <div className={styles.arabicTexture} aria-hidden="true">
        بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ
      </div>

      <div className={`container ${styles.inner}`}>
        {/* Diamond */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
        >
          <DiamondAnimation />
        </motion.div>

        {/* Wordmark */}
        <motion.p
          className={styles.wordmark}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.6, delay: 0.6 }}
        >
          jawhar
        </motion.p>

        {/* Tagline */}
        <motion.h1
          className={`display-hero ${styles.tagline}`}
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 0.8, ease: [0.22, 1, 0.36, 1] }}
        >
          Memorize with Meaning
        </motion.h1>

        {/* Subtitle */}
        <motion.p
          className={`body-large ${styles.subtitle}`}
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 1.0, ease: [0.22, 1, 0.36, 1] }}
        >
          The first Quran memorization companion built on understanding.
        </motion.p>

        {/* CTAs */}
        <motion.div
          className={styles.ctas}
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, delay: 1.2, ease: [0.22, 1, 0.36, 1] }}
        >
          <a href="/download" className="btn btn-primary btn-large">
            Download
            <ArrowRight size={16} />
          </a>
          <a href="#problem" className="btn btn-ghost btn-large">
            Learn More
          </a>
        </motion.div>
      </div>

      {/* Scroll indicator */}
      <motion.a
        href="#problem"
        className={styles.scrollIndicator}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 2.0, duration: 0.6 }}
        aria-label="Scroll to content"
      >
        <ChevronDown size={20} />
      </motion.a>
    </section>
  );
}
