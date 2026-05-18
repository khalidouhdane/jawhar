import { ListTodo, Timer, RefreshCcw } from 'lucide-react';
import styles from './StorySections.module.css';

export default function MemorizeSection() {
  return (
    <section id="memorize-section" className={`${styles.section} ${styles.memorizeSection}`}>
      <div className={styles.content}>
        <h2 className={styles.title}>Memorize it, forever.</h2>
        <p className={styles.description}>
          Your daily plan, your session structure, your understanding — all in one app. Jawhar&apos;s adaptive intelligence builds a customized path to mastery.
        </p>

        <div className={styles.grid}>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><ListTodo size={24} /></div>
            <h3 className={styles.featureTitle}>Adaptive Plans</h3>
            <p className={styles.featureText}>Adaptive daily plans covering Sabaq, Sabqi, and Manzil, with pace projection and weekly analytics.</p>
          </div>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><Timer size={24} /></div>
            <h3 className={styles.featureTitle}>Structured Sessions</h3>
            <p className={styles.featureText}>A dedicated digital mode with built-in timers, repetition counters, and self-assessment tracking.</p>
          </div>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><RefreshCcw size={24} /></div>
            <h3 className={styles.featureTitle}>Smart Flashcards</h3>
            <p className={styles.featureText}>6 unique types of flashcards powered by a spaced-repetition algorithm, plus Mutashabihat practice modes.</p>
          </div>
        </div>
        
        {/* Extra spacing at the bottom to ensure the diamond animation has room to settle */}
        <div className={styles.spacer}></div>
      </div>
    </section>
  );
}
