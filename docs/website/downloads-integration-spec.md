# Design Specification: Downloads Integration & Waitlist Migration

This design document outlines the transition of the Jawhar marketing website from a private waitlist model to a direct public download/testing model for Windows, Android, and iOS.

---

## 1. Objectives

- **Direct Actionable Downloads**: Replace all references to joining the "waitlist" with links to get the application.
- **Dynamic Asset Links**: Point Windows and Android downloads directly to the latest built assets from the GitHub releases page using redirects.
- **External Testing Integration**: Link the iOS CTA directly to the active Apple TestFlight public invitation.
- **Restore Homepage Climax**: Re-integrate the `ClosingSection` and `DepthRings` animation on the landing page, solving the broken `#closing` anchor and satisfying the `check:content` validation constraints.
- **Clean Codebase**: Remove the deprecated `WaitlistForm` component and related data collections.

---

## 2. Target Deliverables

### A. Dedicated `/download` Page (`website/app/download/page.js`)
- Update the platform items array:
  - **Windows**: Point `href` to `https://github.com/khalidouhdane/jawhar/releases/latest/download/jawhar-windows.zip` (action: "Download ZIP").
  - **Android**: Point `href` to `https://github.com/khalidouhdane/jawhar/releases/latest/download/app-release.apk` (action: "Download APK").
  - **iOS**: Mark as `available: true`, point `href` to `https://testflight.apple.com/join/XYY6tqxC` (action: "Join TestFlight").
  - **macOS, Linux, Web**: Keep as `available: false` (action: "Coming soon").
- Reorder `detectOS()` checks to evaluate iOS (`iPhone|iPad|iPod`) first, avoiding false-positive matches for macOS.

### B. Homepage Scroll Story (`website/components/sections/ScrollStory.js`)
- Import and render `<ClosingSection />` at the bottom of the landing page, immediately following `<StrategySection />`.

### C. Hero CTA (`website/components/explore/EssenceFlowHero.js`)
- Keep pointing the primary button to `#closing` to scroll the user to the climax, but change the text to `Get Jawhar` or `Download App`.

### D. Homepage Closing Section (`website/components/sections/ClosingSection.js`)
- Remove the `<WaitlistForm />` import and element.
- Replace it with a premium download CTA:
  - Centered primary button: **`Download Jawhar`** (pointing to `/download`).
  - Sleek text below listing supported platforms: `Windows · Android · iOS (TestFlight)`.

### E. Hackathon Appendix Page (`website/app/hackathon/page.js`)
- Replace the secondary button `Join Early Access` pointing to `/#waitlist` with a `Download App` button pointing to `/download`.

### F. Privacy Policy Cleanup (`website/app/privacy/page.js`)
- Remove or rewrite section mentions of waitlist email database collection, since the waitlist form is no longer utilized.

### G. Code Cleanup
- Delete `website/components/shared/WaitlistForm.js` and `website/components/shared/WaitlistForm.module.css`.

---

## 3. Verification Plan

### Automated Checks
- Run `npm run check:content` to verify all content assertions pass.
- Run `npm run build` to verify the Next.js site compiles successfully.

### Manual Verification
- Access `/download` in the browser and verify the OS badge detects the correct operating system.
- Verify download links point to the latest GitHub redirect release URLs.
