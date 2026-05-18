import styles from "./Footer.module.css";
import Link from "next/link";

/* Inline SVG icons for social links (Lucide dropped brand icons) */
function TwitterIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
    </svg>
  );
}

function InstagramIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
      <path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z" />
    </svg>
  );
}

export default function Footer() {
  return (
    <footer className={styles.footer}>
      <div className={`container ${styles.inner}`}>
        <div className={styles.top}>
          {/* Brand column */}
          <div className={styles.brandCol}>
            <div className={styles.brand}>
              <svg width="16" height="16" viewBox="0 0 200 200" fill="none">
                <path
                  d="M100,12 L155,50 L170,85 L145,100 L135,140 L100,190 L65,140 L55,100 L30,85 L45,50 Z"
                  fill="var(--text-primary)"
                  opacity="0.85"
                />
              </svg>
              <span className={styles.brandName}>jawhar</span>
            </div>
            <p className={styles.tagline}>Memorize with Meaning.</p>
          </div>

          {/* Nav columns */}
          <div className={styles.navCol}>
            <span className={styles.colTitle}>Product</span>
            <Link href="/#read-section" className={styles.footerLink}>Features</Link>
            <Link href="/download" className={styles.footerLink}>Download</Link>
            <Link href="/struggles" className={styles.footerLink}>Struggles</Link>
          </div>

          <div className={styles.navCol}>
            <span className={styles.colTitle}>Resources</span>
            <Link href="/privacy" className={styles.footerLink}>Privacy</Link>
            <Link href="/terms" className={styles.footerLink}>Terms</Link>
          </div>
        </div>

        {/* Bottom bar */}
        <div className={styles.bottom}>
          <p className={styles.credits}>
            Built with the <a href="https://quran.com" className={styles.inlineLink} target="_blank" rel="noopener noreferrer">Quran Foundation API</a>
            {" "}· Closed source for now · Privacy-first · Free forever
          </p>

          <div className={styles.socials}>
            <a
              href="https://x.com"
              target="_blank"
              rel="noopener noreferrer"
              className={styles.socialLink}
              aria-label="Twitter / X"
            >
              <TwitterIcon />
            </a>
            <a
              href="https://instagram.com"
              target="_blank"
              rel="noopener noreferrer"
              className={styles.socialLink}
              aria-label="Instagram"
            >
              <InstagramIcon />
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
