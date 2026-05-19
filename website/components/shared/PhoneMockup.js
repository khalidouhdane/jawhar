import styles from "./PhoneMockup.module.css";

/**
 * SVG iPhone mockup frame.
 * Renders children inside the "screen" area.
 * 
 * Props:
 *   - videoSrc: optional path to a .webm video to autoplay in the screen
 *   - size: "default" | "small" — small is 250px wide for secondary phone use
 *   - children: fallback content when no videoSrc is provided
 *   - className: additional CSS class on the outer wrapper
 */
export default function PhoneMockup({ videoSrc, size = "default", children, className = "" }) {
  const frameClass = `${styles.frame} ${size === "small" ? styles.frameSmall : ""}`;

  return (
    <div className={`${styles.phone} ${className}`}>
      {/* Device frame */}
      <div className={frameClass}>
        {/* Notch / Dynamic Island */}
        <div className={styles.notch} />

        {/* Screen content */}
        <div className={styles.screen}>
          {videoSrc ? (
            <video
              autoPlay
              muted
              loop
              playsInline
              src={videoSrc}
              className={styles.video}
            />
          ) : children ? (
            children
          ) : (
            <div className={styles.placeholder}>
              <svg
                width="32"
                height="32"
                viewBox="0 0 200 200"
                fill="none"
                className={styles.placeholderIcon}
              >
                <path
                  d="M100,12 L155,50 L170,85 L145,100 L135,140 L100,190 L65,140 L55,100 L30,85 L45,50 Z"
                  fill="currentColor"
                />
              </svg>
            </div>
          )}
        </div>

        {/* Home indicator */}
        <div className={styles.homeBar} />
      </div>
    </div>
  );
}
