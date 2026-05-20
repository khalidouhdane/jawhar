"use client";
import { useState } from "react";
import Link from "next/link";
import { Menu, X } from "lucide-react";
import ThemeToggle from "../shared/ThemeToggle";
import styles from "./Navbar.module.css";

export default function Navbar() {
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <nav className={styles.nav}>
      <div className={`container ${styles.inner}`}>
        {/* Logo / brand */}
        <Link href="/" className={styles.brand}>
          <svg
            width="95"
            height="24"
            viewBox="0 0 99 25"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            className={styles.logo}
          >
            <path d="M28.213 14.6645L28.1915 13.792H30.9381V14.8611C30.9381 16.7352 32.1793 17.8259 34.0564 17.8259C35.9336 17.8259 37.2393 16.7352 37.2393 14.8611V7.29727H35.1041V4.79031H39.9644V14.6645C39.9644 18.1515 37.6325 20.3328 34.1455 20.3328H34.038C30.551 20.3328 28.2192 18.1515 28.2192 14.6645H28.213Z" fill="currentColor"/>
            <path d="M52.1058 14.6429V20.05H49.4914V19.0024C48.9691 19.6783 47.8569 20.2436 46.2655 20.2436C43.1042 20.2436 40.8369 17.9763 40.8369 14.5968C40.8369 11.2173 43.1042 8.993 46.4621 8.993C49.8201 8.993 52.1089 11.2603 52.1089 14.6398L52.1058 14.6429ZM46.4836 11.3924C44.6526 11.3924 43.4544 12.5906 43.4544 14.6183C43.4544 16.646 44.6526 17.8441 46.4836 17.8441C48.3147 17.8441 49.4914 16.646 49.4914 14.6183C49.4914 12.5906 48.2932 11.3924 46.4836 11.3924Z" fill="currentColor"/>
            <path d="M51.8017 9.14991H54.6128L57.2734 16.5387L59.9339 9.14991H62.745L61.9401 11.2851L63.8142 16.5387L66.4748 9.14991H69.2859L65.166 20.0503H62.4624L60.5453 14.9503L58.6282 20.0503H55.9247L51.8048 9.14991H51.8017Z" fill="currentColor"/>
            <path d="M72.5547 9.91175C73.1876 9.32188 74.0817 8.95321 75.3013 8.95321C78.5487 8.95321 79.965 11.6568 79.965 13.5524V20.0471H77.3505V13.6169C77.3505 12.0685 76.2169 11.3711 74.9542 11.3711C73.6915 11.3711 72.5547 12.0685 72.5547 13.6169V20.0471H69.9403V4.78725H72.5547V9.90868V9.91175Z" fill="currentColor"/>
            <path d="M92.2172 14.6429V20.05H89.6027V19.0024C89.0804 19.6783 87.9683 20.2436 86.3769 20.2436C83.2155 20.2436 80.9482 17.9763 80.9482 14.5968C80.9482 11.2173 83.2155 8.993 86.5735 8.993C89.9314 8.993 92.2203 11.2603 92.2203 14.6398L92.2172 14.6429ZM86.595 11.3924C84.7639 11.3924 83.5657 12.5906 83.5657 14.6183C83.5657 16.646 84.7639 17.8441 86.595 17.8441C88.426 17.8441 89.6027 16.646 89.6027 14.6183C89.6027 12.5906 88.4045 11.3924 86.595 11.3924Z" fill="currentColor"/>
            <path d="M98.9331 8.9532V11.3496C97.1881 11.3496 96.1435 12.2006 96.1435 13.9425V20.0471H93.529V13.9425C93.529 10.6276 95.6212 8.95013 98.9362 8.95013L98.9331 8.9532Z" fill="currentColor"/>
            <path d="M14.2411 13.2149C15.3592 14.4667 16.0383 16.1097 16.0383 17.9085V17.9178C16.0365 19.9559 15.1622 21.7936 13.7683 23.0862C12.5845 24.1803 11.0274 24.885 9.30332 24.987C9.17388 24.9944 9.04255 25 8.91123 25C8.77991 25 8.64858 24.9944 8.51913 24.987C6.79692 24.885 5.23793 24.1803 4.05602 23.0862C2.66024 21.7936 1.78787 19.9559 1.786 17.9178V17.9085C1.786 16.1079 2.46325 14.4667 3.58138 13.2149L4.46499 12.3822L14.7983 4.09836L12.8434 2.25131H5.2398L3.28308 4.09836L7.70118 8.27275L5.92268 9.69513L0 4.09836L4.33742 0H13.7458L18.0851 4.09836L5.78573 14.2404C5.6394 14.3647 5.50057 14.4945 5.37112 14.6336C4.55504 15.4959 4.05789 16.6549 4.05789 17.9289C4.05789 20.5549 6.17783 22.6912 8.81743 22.758C8.83994 22.758 8.8587 22.758 8.88121 22.758C8.92249 22.758 8.96563 22.758 9.0069 22.758C11.6465 22.6912 13.7664 20.5549 13.7664 17.9289C13.7664 16.6549 13.2693 15.4959 12.4532 14.6336L14.2392 13.2168L14.2411 13.2149Z" fill="currentColor"/>
            <path d="M9.04255 16.0597L7.41039 17.9772L9.04255 19.8947L10.6747 17.9772L9.04255 16.0597Z" fill="currentColor"/>
          </svg>
        </Link>

        {/* Desktop links */}
        <div className={styles.links}>
          <Link href="/#problem" className={styles.link}>Struggle</Link>
          <Link href="/#read-section" className={styles.link}>Read & Listen</Link>
          <Link href="/#understand-section" className={styles.link}>Understand</Link>
          <Link href="/#memorize-section" className={styles.link}>Memorize</Link>
          <Link href="/#strategy" className={styles.link}>Strategy</Link>
        </div>

        {/* Right side: theme toggle + CTA */}
        <div className={styles.actions}>
          <ThemeToggle />
          <Link href="/download" className={`btn btn-primary ${styles.cta}`}>
            Download
          </Link>
        </div>

        {/* Mobile toggle */}
        <button
          className={styles.mobileToggle}
          onClick={() => setMobileOpen(!mobileOpen)}
          aria-label={mobileOpen ? "Close menu" : "Open menu"}
        >
          {mobileOpen ? <X size={20} /> : <Menu size={20} />}
        </button>
      </div>

      {/* Mobile menu */}
      {mobileOpen && (
        <div className={styles.mobileMenu}>
          <Link href="/#problem" className={styles.mobileLink} onClick={() => setMobileOpen(false)}>
            Struggle
          </Link>
          <Link href="/#read-section" className={styles.mobileLink} onClick={() => setMobileOpen(false)}>
            Read & Listen
          </Link>
          <Link href="/#understand-section" className={styles.mobileLink} onClick={() => setMobileOpen(false)}>
            Understand
          </Link>
          <Link href="/#memorize-section" className={styles.mobileLink} onClick={() => setMobileOpen(false)}>
            Memorize
          </Link>
          <Link href="/#strategy" className={styles.mobileLink} onClick={() => setMobileOpen(false)}>
            Strategy
          </Link>
          <div className={styles.mobileActions}>
            <ThemeToggle />
            <Link href="/download" className="btn btn-primary" style={{ marginTop: 8 }}>
              Download
            </Link>
          </div>
        </div>
      )}
    </nav>
  );
}
