# Google Play launch checklist — Jawhar

Status as of 2026-06-12. Play Console **organization account verified**
(khalid@alphafoundr.com); app **"Jawhar: Quran Memorization"** created,
package ownership verified, v23 (1.8.2) uploaded to Internal testing with
Play App Signing active. Target: **open testing as the public beta**
(self-join link), then production.

## 1. Code readiness — DONE

- [x] `applicationId` / namespace: `com.alphafoundr.jawhar` (matches the
      `jawhar-android` Firebase app; `lib/firebase_options.dart` fixed in `ddf226f`).
- [x] Upload signing: `android/app/upload-keystore.jks` + `android/key.properties`
      (release build hard-fails if signing is unconfigured — no debug-signed releases).
- [x] `targetSdk 36` / `minSdk 24` (Flutter 3.44 defaults) — exceeds Play's
      API 35 requirement for new apps.
- [x] In-app APK self-updater **disabled for store builds** (2026-06-11):
      `REQUEST_INSTALL_PACKAGES` removed from the manifest (restricted permission +
      self-updating violates Device & Network Abuse policy). The GitHub-release
      updater now requires `--dart-define=ENABLE_SELF_UPDATE=true`
      (see `lib/config/distribution_config.dart`) and falls back to opening the
      release page in the browser since direct install needs the dropped permission.
      **Play builds: do NOT pass ENABLE_SELF_UPDATE.**
- [x] Global `usesCleartextTraffic` replaced with
      `res/xml/network_security_config.xml` — cleartext allowed only for
      `127.0.0.1`/`localhost` (audio proxy + OAuth loopback).
- [x] In-app account deletion exists (Profile → Delete Account: removes cloud
      data + auth user) — required since the app supports account creation.
- [x] Android developer verification passed (2026-06-11): package registered
      via proof APK containing `android/app/src/main/assets/adi-registration.properties`
      (keep this file).

## 2. Build & upload

```powershell
flutter build appbundle --dart-define-from-file=.env
# → build/app/outputs/bundle/release/app-release.aab
```

- `.env` carries QF API creds, desktop OAuth, Sentry DSN. Do **not** add
  `ENABLE_SELF_UPDATE` or `USE_API_V1_AI` (API transport stays off until the
  cloud-first migration flips it).
- Version is `pubspec.yaml` `version:` (currently `1.8.2+23`); every upload
  needs a higher `+versionCode`.

## 3. Play App Signing certs → Firebase — DONE 2026-06-12

App-signing SHA-1 (`35:77:...:7C:93`) and SHA-256 (`9A:74:...:1A:31`) registered
on `jawhar-android` via `firebase apps:android:sha:create`. Found in console
under **Protected with Play → App signing** (new location). Verify by testing
Google Sign-In on a Play-installed build.

<details><summary>Original instructions (for reference)</summary>

Play re-signs the bundle with its own key, so Google Sign-In will fail with
`ApiException: 10` on Play-delivered builds until:

1. Play Console → *Test and release → Setup → App integrity → App signing* →
   copy **App signing key certificate** SHA-1 **and** SHA-256.
2. Firebase: add both fingerprints to Android app `jawhar-android`
   (`1:556087735735:android:a1c43ec23234162a512432`) in project
   `quran-app-e5e86` (`firebase apps:android:sha:create` works).
3. Re-download `google-services.json` into `android/app/` and rebuild/re-upload
   if the OAuth client list changed.
4. Verify Google Sign-In on a device that installed from the Internal testing track.

(Same root cause as the 2026-06-10 sign-in incident — upload/debug SHAs are
already registered, the Play signing SHA is the missing one.)

</details>

## 4. Store listing & declarations

- [x] **Privacy policy URL** (2026-06-12, commit `6132c9f`):
      `https://jawhar.alphafoundr.com/privacy` — launch-grade (publisher =
      ALPHAFOUNDR LLC; covers Google Sign-In, Firestore sync, Sentry, AI
      processing; contact khalid@alphafoundr.com). Custom domain is live.
- [x] **Account-deletion web link** (2026-06-12):
      `https://jawhar.alphafoundr.com/account-deletion` — in-app steps +
      30-day email path. Use as the deletion URL in Data safety.
- [ ] Store assets: 512×512 icon, 1024×500 feature graphic, ≥2 phone
      screenshots, short (80 ch) + full (4000 ch) descriptions, EN + AR.
      The 6 captures in `assets/images/screenshots/` are 600×1298 (≈2.16:1) —
      Play rejects screenshots whose long side exceeds 2× the short side and
      recommends ≥1080 px; regenerate at 1080×1920 (or pad to 9:16) via the
      `device_preview_screenshot` pipeline.
- [ ] Declarations: App access (all functionality available), Ads (none),
      content rating (Reference/Educational; answer users-interact honestly re:
      accountability), target audience 13+ (never under-13 — avoids Families
      policy), News/Government/Financial/Health (all No).
- [ ] Category (Education or Books & Reference), support email
      khalid@alphafoundr.com.

## 5. Data safety form (draft answers)

| Question | Answer |
|---|---|
| Collects data? | Yes |
| Personal info | Name, email, user IDs (Google sign-in; account management; optional) |
| App activity | App interactions: memorization progress, plans, sessions (app functionality; optional) |
| App info & performance | Crash logs, diagnostics (Sentry; analytics; required) |
| Device or other IDs | Installation ID (Sentry; analytics; required) |
| Encrypted in transit? | Yes (TLS everywhere; cleartext only to localhost) |
| Deletion mechanism? | Yes — in-app + https://jawhar.alphafoundr.com/account-deletion |
| Data shared with third parties? | No (Sentry/Firebase are service providers, not "sharing" per Play definitions) |
| Ads? | No |

## 6. Functional launch gates (not Play paperwork)

- [ ] **AI generation still broken in prod** — `GEMINI_API_KEY` absent from the
      deployed callables (found 2026-06-10). Owned by the cloud-first migration
      work (jawhar-api on Cloud Run / Secret Manager fix). **Do not open the
      public beta until an AI plan generates end-to-end on an
      internal-testing build.**
- [ ] Smoke test on Play-delivered build: Google sign-in, Firestore sync, audio
      playback + background audio, notifications, AI plan, account deletion.
- [ ] Non-blocking: Cloud Functions on Node 20 (decommission 2026-10-30) —
      handled by migration; KGP deprecation warnings from Flutter 3.44 —
      plugin upgrades later.

## 7. Rollout sequence

1. Internal testing (live now) → App-signing SHAs → Firebase → smoke test on a
   Play-delivered install.
2. Complete declarations + store listing → submit **open testing** (public
   beta, self-join link; goes through Google review — days for a new app).
3. Production with staged rollout (10% → 50% → 100%).
4. After launch: GitHub releases remain for the Windows build only; Android
   updates flow through Play.

## Tooling

- Vercel CLI installed globally; official Vercel MCP (`mcp.vercel.com`,
  authenticate via /mcp) and Firebase MCP (`firebase mcp`) registered in the
  project-local Claude config.
- Play Console has no official CLI/MCP; release ops automation goes through
  the Play Developer API (service-account setup pending, see §3 of
  conversation plan: invite SA from quran-app-e5e86 in Users & permissions).
