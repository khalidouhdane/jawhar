import styles from "../legal.module.css";

export const metadata = {
  title: "Terms - Jawhar",
  description:
    "Terms for using Jawhar, a Quran reading, understanding, and memorization companion.",
};

export default function TermsPage() {
  return (
    <main className={styles.main}>
      <section className="section">
        <div className={`container ${styles.hero}`}>
          <p className="mono-label">Terms</p>
          <h1 className="display-hero">Terms of Use</h1>
          <p className={`body-large ${styles.updated}`}>
            Last updated May 18, 2026
          </p>
        </div>
      </section>

      <div className="section-divider" />

      <section className="section section-alt">
        <div className={`container ${styles.content}`}>
          <div className={`card ${styles.block}`}>
            <h2>Using Jawhar</h2>
            <p>
              Jawhar is a Quran companion for reading, listening,
              understanding, and memorization. By using the website or app, you
              agree to use it lawfully and respectfully.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>Private development</h2>
            <p>
              Jawhar is closed source for now. The website, app experience,
              availability, and download links may change while the product is
              being prepared for broader release.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>Quran content</h2>
            <p>
              Quran text, translations, tafsir, audio, and related resources may
              come from the Quran Foundation API and other credited sources.
              Those resources remain subject to their own licenses and terms.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>Educational use</h2>
            <p>
              Jawhar helps structure memorization and understanding, but it does
              not replace a qualified teacher, scholar, or recitation review.
              Users remain responsible for verifying recitation and religious
              questions with trusted people of knowledge.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>Accounts and sync</h2>
            <p>
              Authentication is optional. If you sign in, you are responsible
              for keeping your account secure. Sync features are provided to
              preserve your own progress and settings across devices.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>Acceptable use</h2>
            <ul>
              <li>Do not misuse the service or attempt to disrupt it.</li>
              <li>Do not upload or submit unlawful, harmful, or misleading data.</li>
              <li>Do not claim Jawhar content or branding as your own.</li>
              <li>Do not use the app in a way that violates third-party terms.</li>
            </ul>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>No warranties</h2>
            <p>
              Jawhar is provided as-is during development. We work carefully,
              but we do not guarantee uninterrupted access, error-free content,
              or suitability for every individual memorization program.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>External links</h2>
            <p>
              The website may link to third-party services, including{" "}
              <a
                className={styles.link}
                href="https://quran.com/terms-and-conditions"
              >
                Quran.com
              </a>
              . Their terms apply when you use their services.
            </p>
          </div>
        </div>
      </section>
    </main>
  );
}
