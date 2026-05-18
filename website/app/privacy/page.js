import styles from "../legal.module.css";

export const metadata = {
  title: "Privacy Policy - Jawhar",
  description:
    "How Jawhar handles waitlist, app, account, and usage data while the app is in private development.",
};

export default function PrivacyPage() {
  return (
    <main className={styles.main}>
      <section className="section">
        <div className={`container ${styles.hero}`}>
          <p className="mono-label">Privacy</p>
          <h1 className="display-hero">Privacy Policy</h1>
          <p className={`body-large ${styles.updated}`}>
            Last updated May 18, 2026
          </p>
        </div>
      </section>

      <div className="section-divider" />

      <section className="section section-alt">
        <div className={`container ${styles.content}`}>
          <div className={`card ${styles.block}`}>
            <h2>Our position</h2>
            <p>
              Jawhar is built for Quran reading, understanding, and
              memorization. We do not sell personal information, we do not run
              ads, and we do not use habit mechanics that require invasive
              tracking.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>Information you provide</h2>
            <ul>
              <li>
                Waitlist email: if you join the waitlist on this demo site, the
                email is stored locally in your browser until a production
                waitlist service is connected.
              </li>
              <li>
                Account data: if you sign in inside the app, authentication is
                optional and used to sync your own settings and progress.
              </li>
              <li>
                Memorization data: profiles, plans, sessions, flashcards,
                bookmarks, and progress are stored locally first. Sync, when
                enabled, is tied to your account.
              </li>
            </ul>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>How data is used</h2>
            <p>
              Data is used to provide the product: reading state, bookmarks,
              daily plans, session history, progress analytics, and optional
              cloud sync. We do not use memorization data for advertising.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>Third-party services</h2>
            <p>
              Jawhar uses the Quran Foundation API for Quran content and may use
              Firebase services for optional authentication and sync. Downloads
              may be distributed through GitHub Releases while the app is in
              private development.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>Log data and cookies</h2>
            <p>
              The website may receive standard server logs such as IP address,
              browser type, pages visited, and timestamps. Jawhar does not use
              advertising cookies. Any necessary cookies or local storage are
              used for basic site or app functionality.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>Your choices</h2>
            <ul>
              <li>You can use the app without signing in.</li>
              <li>You can clear local browser waitlist data at any time.</li>
              <li>You can disable optional sync by staying signed out.</li>
              <li>
                If you have an account, you may request deletion of synced data
                when account deletion is available in the app.
              </li>
            </ul>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>External policies</h2>
            <p>
              Quran content and account flows may also be subject to the
              policies of the services they come from, including{" "}
              <a className={styles.link} href="https://quran.com/privacy">
                Quran.com
              </a>
              .
            </p>
          </div>
        </div>
      </section>
    </main>
  );
}
