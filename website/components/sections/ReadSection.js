import { BookOpen, Mic, Moon } from 'lucide-react';
import styles from './StorySections.module.css';

export default function ReadSection() {
  return (
    <section id="read-section" className={`${styles.section} ${styles.readSection}`}>
      <div className={styles.content}>
        <h2 className={styles.title}>Read, beautifully.</h2>
        <p className={styles.description}>
          Experience the Quran like never before. With the full Madani layout for both Hafs and Warsh, dark mode, and over 40 reciters with verse-level sync, every reading session is a moment of peace.
        </p>

        <div className={styles.grid}>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><BookOpen size={24} /></div>
            <h3 className={styles.featureTitle}>Full Mushaf</h3>
            <p className={styles.featureText}>604 pages of the pristine Madani layout, dynamically switching between Hafs and Warsh rewayas.</p>
          </div>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><Mic size={24} /></div>
            <h3 className={styles.featureTitle}>40+ Reciters</h3>
            <p className={styles.featureText}>Seamless audio with verse-level highlighting to keep your eyes and ears perfectly synchronized.</p>
          </div>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><Moon size={24} /></div>
            <h3 className={styles.featureTitle}>Focus Mode</h3>
            <p className={styles.featureText}>Distraction-free dark mode, bookmarks, and daily Werd tracking to build an unbreakable habit.</p>
          </div>
        </div>
      </div>
    </section>
  );
}
