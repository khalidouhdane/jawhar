import styles from "./PhoneMockup.module.css";

/**
 * SVG iPhone mockup frame.
 * Renders children inside the "screen" area.
 */
export default function PhoneMockup({ children }) {
  return (
    <div className={styles.phone}>
      {/* Device frame */}
      <div className={styles.frame}>
        {/* Notch / Dynamic Island */}
        <div className={styles.notch} />

        {/* Screen content */}
        <div className={styles.screen}>{children}</div>

        {/* Home indicator */}
        <div className={styles.homeBar} />
      </div>
    </div>
  );
}
