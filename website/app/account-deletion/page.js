import styles from "../legal.module.css";

export const metadata = {
  title: "Account Deletion - Jawhar",
  description:
    "How to delete your Jawhar account and synced data, in the app or by email request.",
};

export default function AccountDeletionPage() {
  return (
    <main className={styles.main}>
      <section className="section">
        <div className={`container ${styles.hero}`}>
          <p className="mono-label">Your data</p>
          <h1 className="display-hero">Delete your account</h1>
          <p className={`body-large ${styles.updated}`}>
            Applies to Jawhar by ALPHAFOUNDR LLC
          </p>
        </div>
      </section>

      <div className="section-divider" />

      <section className="section section-alt">
        <div className={`container ${styles.content}`}>
          <div className={`card ${styles.block}`}>
            <h2>Delete in the app (instant)</h2>
            <ul>
              <li>Open Jawhar and go to the Profile tab.</li>
              <li>Choose Delete Account and confirm.</li>
            </ul>
            <p>
              This permanently deletes your cloud-synced memorization data
              (plans, sessions, flashcards, bookmarks, progress) and your
              account record, including the Google account link. It cannot be
              undone.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>Request deletion by email</h2>
            <p>
              If you no longer have the app installed, email{" "}
              <a
                className={styles.link}
                href="mailto:khalid@alphafoundr.com?subject=Account%20deletion%20request"
              >
                khalid@alphafoundr.com
              </a>{" "}
              with the subject “Account deletion request” from the email
              address you used to sign in. We verify the request and complete
              the deletion within 30 days.
            </p>
          </div>

          <div className={`card ${styles.block}`}>
            <h2>What is deleted, what remains</h2>
            <ul>
              <li>
                Deleted: all cloud-synced data tied to your account, and the
                account itself.
              </li>
              <li>
                Remains on your device: locally stored app data, until you
                uninstall the app or clear its storage.
              </li>
              <li>
                Expires automatically: crash diagnostics already collected,
                which age out on a rolling basis and are not tied to your
                account profile.
              </li>
            </ul>
            <p>
              For more detail on what we collect and why, see our{" "}
              <a className={styles.link} href="/privacy">
                Privacy Policy
              </a>
              .
            </p>
          </div>
        </div>
      </section>
    </main>
  );
}
