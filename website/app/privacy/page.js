import styles from "../legal.module.css";

export const metadata = {
  title: "Privacy Policy - Jawhar",
  description:
    "How Jawhar handles account, memorization, and diagnostic data across Android, Windows, and the web.",
};

export default function PrivacyPage() {
  return (
    <main className={styles.main}>
      <section className="section">
        <div className={`container ${styles.hero}`}>
          <p className="mono-label">Privacy</p>
          <h1 className="display-hero">Privacy Policy</h1>
          <p className={`body-large ${styles.updated}`}>
            Last updated June 12, 2026
          </p>
        </div>
      </section>

      <div className="section-divider" />

      <section className="section section-alt">
        <div className={`container ${styles.content}`}>
          <div className={`card ${styles.block}`}>
            <h2>Who we are</h2>
            <p>
              Jawhar is a Quran reading, understanding, and memorization app
              published by ALPHAFOUNDR LLC (Wilmington, Delaware, USA). This
              policy covers the Jawhar app on Android (distributed through
              Google Play), Windows, and the web, as well as this website. We
              do not sell personal information, we do not run ads, and we do
              not track you across other apps or websites.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>Information we collect</h2>
            <ul>
              <li>
                Account data: signing in is optional and uses Google Sign-In.
                When you sign in we receive your name, email address, and
                profile photo, used to identify your account and sync your
                data.
              </li>
              <li>
                Memorization data: profiles, plans, sessions, flashcards,
                bookmarks, and progress. This data is stored on your device
                first; when you are signed in it is synced to our cloud
                database (Google Firebase Cloud Firestore).
              </li>
              <li>
                Diagnostics: crash reports and performance data (device model,
                operating system version, app version, and technical traces)
                collected through Sentry to find and fix defects.
              </li>
              <li>
                AI plan requests: when you use AI-assisted planning or
                calibration, your memorization context (such as progress and
                goals) is processed by our backend on Google Cloud to generate
                your plan. These requests are used only to provide the
                feature.
              </li>
            </ul>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>How data is used</h2>
            <p>
              Data is used to provide the product: reading state, bookmarks,
              daily plans, session history, progress analytics, optional cloud
              sync, AI-generated plans, and crash diagnosis. We do not use any
              of it for advertising, and we do not sell or rent it to anyone.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>Third-party services</h2>
            <p>
              Jawhar relies on the following service providers, which process
              data on our behalf under their own terms: Google Firebase
              (authentication, cloud database, backend functions), Google
              Cloud (backend hosting and AI processing), Sentry (crash
              reporting), and the Quran Foundation API (Quran text, audio, and
              tafsir content).
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>Security and retention</h2>
            <p>
              All data is encrypted in transit using TLS. Synced data is kept
              for as long as your account exists. Crash diagnostics expire
              automatically on a rolling basis. Local data stays on your
              device until you delete it or uninstall the app.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>Deleting your data</h2>
            <ul>
              <li>
                In the app: Profile → Delete Account permanently removes your
                cloud data and your account link.
              </li>
              <li>
                Without the app: follow the steps on our{" "}
                <a className={styles.link} href="/account-deletion">
                  account deletion page
                </a>{" "}
                to request deletion by email.
              </li>
            </ul>
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
            <h2>Children</h2>
            <p>
              Jawhar is a general-audience app and is not directed at children
              under 13. We do not knowingly collect personal information from
              children under 13.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>Changes and contact</h2>
            <p>
              We will update this page when our practices change and revise
              the date above. Questions or requests:{" "}
              <a
                className={styles.link}
                href="mailto:khalid@alphafoundr.com"
              >
                khalid@alphafoundr.com
              </a>
              . Quran content and account flows may also be subject to the
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
