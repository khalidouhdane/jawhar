import { BookOpen, Mic, Moon } from 'lucide-react';
import styles from './StorySections.module.css';

export default function ReadSection() {
  return (
    <section id="read-section" className={`${styles.section} ${styles.readSection}`}>
      <div className={styles.content}>
        <h2 className={styles.title}>Read, beautifully.</h2>
        <p className={styles.description}>
          Begin with the Mushaf itself: Hafs or Warsh, the full Madani page, and recitation that follows the verse you are reading.
        </p>

        <div className={styles.grid}>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><BookOpen size={24} /></div>
            <h3 className={styles.featureTitle}>Full Mushaf</h3>
            <p className={styles.featureText}>604 pages in the Madani layout, with Hafs and Warsh available from the same reading flow.</p>
          </div>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><Mic size={24} /></div>
            <h3 className={styles.featureTitle}>40+ Reciters</h3>
            <p className={styles.featureText}>Full-chapter audio with verse-level highlighting, so listening stays attached to the page.</p>
          </div>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><Moon size={24} /></div>
            <h3 className={styles.featureTitle}>Focus Mode</h3>
            <p className={styles.featureText}>Dark mode, bookmarks, and daily werd tracking remain present without crowding the text.</p>
          </div>
        </div>
      </div>
    </section>
  );
}
