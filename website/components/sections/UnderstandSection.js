import { Globe, BookOpen, Info } from 'lucide-react';
import styles from './StorySections.module.css';

export default function UnderstandSection() {
  return (
    <section id="understand-section" className={`${styles.section} ${styles.understandSection}`}>
      <div className={styles.content}>
        <h2 className={styles.title}>Understand every verse.</h2>
        <p className={styles.description}>
          Memorization without understanding is incomplete. Jawhar brings the depth of traditional scholarship directly to your fingertips, bridging the gap between reading and encoding.
        </p>

        <div className={styles.grid}>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><Globe size={24} /></div>
            <h3 className={styles.featureTitle}>Translations</h3>
            <p className={styles.featureText}>Accessible in over 20 languages, seamlessly integrated into your reading flow.</p>
          </div>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><BookOpen size={24} /></div>
            <h3 className={styles.featureTitle}>Tafsir</h3>
            <p className={styles.featureText}>Dive into the meaning with brief and detailed tafsir for every single verse.</p>
          </div>
          <div className={styles.featureCard}>
            <div className={styles.featureIcon}><Info size={24} /></div>
            <h3 className={styles.featureTitle}>Asbab al-Nuzul</h3>
            <p className={styles.featureText}>Understand the context. Learn the reasons of revelation (Asbab al-Nuzul) and read curated Surah introductions.</p>
          </div>
        </div>
      </div>
    </section>
  );
}
