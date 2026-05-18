import { Globe, BookOpen, Info } from 'lucide-react';
import styles from './StorySections.module.css';

export default function UnderstandSection() {
  return (
    <section id="understand-section" className={`${styles.section} ${styles.understandSection}`}>
      <div className={styles.content}>
        <h2 className={styles.title}>Understand every verse.</h2>
        <p className={styles.description}>
          Meaning is not an add-on. Translation, tafsir, reasons of revelation, and surah introductions sit beside the verse so memory has context.
        </p>

        <div className={styles.grid}>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><Globe size={24} /></div>
            <h3 className={styles.featureTitle}>Translations</h3>
            <p className={styles.featureText}>A clear first layer of meaning, available without leaving the page or session.</p>
          </div>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><BookOpen size={24} /></div>
            <h3 className={styles.featureTitle}>Tafsir</h3>
            <p className={styles.featureText}>Brief and detailed explanations support recall without turning memorization into browsing.</p>
          </div>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><Info size={24} /></div>
            <h3 className={styles.featureTitle}>Asbab al-Nuzul</h3>
            <p className={styles.featureText}>Reasons of revelation and curated surah introductions give the verse a place in the larger whole.</p>
          </div>
        </div>
      </div>
    </section>
  );
}
