import { ListTodo, Timer, RefreshCcw } from 'lucide-react';
import styles from './StorySections.module.css';

export default function MemorizeSection() {
  return (
    <section id="memorize-section" className={`${styles.section} ${styles.memorizeSection}`}>
      <div className={styles.content}>
        <h2 className={styles.title}>Memorize it, forever.</h2>
        <p className={styles.description}>
          Jawhar turns understanding into a daily rhythm: what to learn, what to review, and how to return to older pages before they fade.
        </p>

        <div className={styles.grid}>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><ListTodo size={24} /></div>
            <h3 className={styles.featureTitle}>Adaptive Plans</h3>
            <p className={styles.featureText}>Daily plans balance sabaq, sabqi, and manzil around the user&apos;s pace and available time.</p>
          </div>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><Timer size={24} /></div>
            <h3 className={styles.featureTitle}>Structured Sessions</h3>
            <p className={styles.featureText}>Timers, repetition counters, audio, and self-assessment support both physical and digital sessions.</p>
          </div>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><RefreshCcw size={24} /></div>
            <h3 className={styles.featureTitle}>Smart Flashcards</h3>
            <p className={styles.featureText}>Six review card types and mutashabihat practice strengthen the pages already memorized.</p>
          </div>
        </div>

        <div className={styles.spacer}></div>
      </div>
    </section>
  );
}
