# Phase 8 lockdown & demolition runbook

**Roadmap anchor:** `docs/CLOUD_FIRST_MIGRATION_ROADMAP.md` §8 Phase 8 (+ Phase 3 soak rule, §9 end-state, §10 pipelines)
**Written:** 2026-06-12 · **Owner/executor:** Khalid (solo)
**Status: GATED — do not execute any step below the gates until BOTH gates are signed off.**

Each numbered step is an **independent deploy/commit**, landed **in order**,
each only after a tester release cycle on the preceding state (roadmap §8
Phase 8 preamble). Rollback for every step is listed inline. Resets, if any,
follow the **tester reset protocol** (§8: announce ≥48h, state what is lost,
state min build, confirm receipt, bump `datasetEpoch` only after the window).

Command conventions (verified, roadmap §2.10 / Appendix):

- every `gcloud` command: `--project quran-app-e5e86 --account me@heykhalid.com --quiet`
- every `firebase` command: `--project quran-app-e5e86` (there is no `.firebaserc` dependency to rely on)
- Firestore emulator locally needs `JAVA_HOME="C:\Program Files\Eclipse Adoptium\jdk-21.0.11.10-hotspot"`
- canonical liveness path is **`/health`** — Google's frontend swallows the
  literal path `/healthz` on `*.run.app` hosts.

State as of 2026-06-12 (re-verify before executing):

- jawhar-api live in europe-southwest1 (`https://jawhar-api-556087735735.europe-southwest1.run.app`); Sentry pipeline proven live (canary event `bd8ce7e4b0e44bc28eb319f53fdd9f4c`).
- `kUseApiV1Ai` + `kUseApiV1Analytics` default-on and soaking (`lib/config/api_config.dart`, `lib/services/analytics_snapshot_client.dart`).
- First facts user: uid `umGkhCabN4YLfQixYqqW6qnnupE2` is `writePath: facts` (exactly-once verified live).
- Legacy callables still deployed: `generateDailyPlan`, `generateCalibration` (GEN_2, ACTIVE) — demolition is steps 4–5 of THIS runbook.
- Firebase Hosting serving already disabled (step 6 is a check-off).
- App Check: **not enforced anywhere**; log-only is the pre-runbook ceiling.

---

## GATE 1 — soak week clean (AI/analytics flags + facts user)

**Criterion:** one full week with `kUseApiV1Ai` (and `kUseApiV1Analytics`)
default-on at error rate ≈ baseline, AND the facts-writePath user(s) clean —
no facts-transaction errors, no derived-state complaints, no Sentry regressions.

**Verification:**

```bash
# Server errors over the soak window (expect: none attributable to /v1 AI,
# analytics, or facts handlers):
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="jawhar-api" AND severity>=ERROR AND timestamp>="<SOAK_START_ISO>"' \
  --project quran-app-e5e86 --account me@heykhalid.com --quiet --limit 100 \
  --format="value(timestamp,severity,jsonPayload.message,textPayload)"
```

- Sentry dashboard (jawhar-api project): no new issue groups in the window
  beyond the known canary event.
- Facts user spot check: `GET /v1/me/bootstrap` for uid
  `umGkhCabN4YLfQixYqqW6qnnupE2` serves `writePath: facts` and derived state
  matches the device (debug screen).

**Sign-off:** ____________________ date: __________

## GATE 2 — whole fleet on facts + forced update

**Criterion:** ALL testers flipped to `writePath: facts`, `minSupportedBuild`
bumped to the **first facts-only build number**, and force-update confirmed
(every active tester on a build ≥ that number).

**Actions:**

```bash
# Per-tester flip (admin endpoint; ADMIN_UIDS env must contain your uid),
# or via Firestore console: users/{uid}/meta/server -> writePath: "facts".
curl -sS -X POST \
  -H "Authorization: Bearer <ADMIN_FIREBASE_ID_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"writePath":"facts"}' \
  https://jawhar-api-556087735735.europe-southwest1.run.app/v1/admin/users/<TESTER_UID>/writePath

# Bump the sync gate (blocks SYNC ONLY, never the offline loop — §5):
gcloud run services update jawhar-api --region europe-southwest1 \
  --update-env-vars MIN_SUPPORTED_BUILD=<FIRST_FACTS_ONLY_BUILD> \
  --project quran-app-e5e86 --account me@heykhalid.com --quiet
```

- Force-update the cohort via the in-app update channel
  (`docs/features/in-app-updates/`), with the reset-protocol announcement.

**Verification:** every tester's bootstrap returns `writePath: facts`; Cloud
Logging shows no legacy direct-Firestore client writes for ≥1 release cycle
(Firestore audit/usage metrics + absence of rules-allowed writes); update
receipts confirmed on the tester channel.

**Sign-off:** ____________________ date: __________

> **Dependency note for step 7:** the Phase 7 secret-eviction gate is
> additionally blocked by the accepted deviation in
> `docs/decisions/2026-06-12-content-token-fallback.md` (compiled-in QF
> content secret stays until a signed-out-capable server path exists, then
> **rotate credentials in the eviction release**). Steps 1–6 do not depend
> on it; step 7's "no compiled-in secrets" grep can only pass after that
> eviction ships.

> **PRECONDITION (Wave 4) — `PUT /v1/me/profiles/{profileId}` client wiring
> must NOT ship before a refold step exists.** Session facts for a non-root
> profile that arrive BEFORE the profile is upserted take the lossless path
> (dedup log + session doc, no derivation). After the profile doc is created
> they are unrecoverable by ANY existing mechanism: replays short-circuit on
> the dedup log (`applied:false`, no fold), the debug-screen reconcile
> re-enqueues the same fact ids and hits the same short-circuit, and the
> admin reconcile covers writePath flips only — `GET /v1/me/plan` then
> generates that profile's plan from EMPTY plural progress (silently wrong,
> not absent). Required before client wiring: on first-time creation of a
> plural profile doc (in `profilePutHandler` or an admin endpoint), query
> `users/{uid}/facts` for session facts with that `profileId` and fold them
> chronologically into `profiles/{profileId}/progress` + plan. Pinned in
> `server/api/lib/handlers/profiles.dart`.

> **OPERATOR NOTE (Wave 4) — fallback-path account deletions leave
> server-only docs.** When `DELETE /v1/me` is unreachable, the client-side
> cascade (`cloud_sync_service.dart`) deletes only what the rules allow it
> to touch: `facts`, `srs_placeholders`, plural `profiles/*`,
> `meta/manzil_rotation`, and `meta/server` survive, permanently orphaned
> once `user.delete()` succeeds. Cleanup (until step 1's deny-all flip makes
> the client fallback moot and `DELETE /v1/me` the only path):
>
> ```bash
> firebase firestore:delete "users/<DELETED_UID>" --recursive --force --project quran-app-e5e86
> ```

---

## Step 1 — Flip `firestore.rules` to deny-all

**Own commit, own deploy.** Replace the ENTIRE contents of `firestore.rules`
(177 lines of per-collection validators at time of writing) with exactly:

```text
rules_version = '2';

// Phase 8 lockdown (roadmap §8 Phase 8 task 1, §9): clients have NO direct
// Firestore access. jawhar-api (Admin SDK, which bypasses rules) is the sole
// reader and writer. Validation lives in the typed Dart handlers
// (server/api/lib/handlers/), where cross-field constraints are expressible.
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

Deploy (CI path: pushing the commit triggers `deploy-backend.yml` —
`firestore.rules` is a trigger path; manual fallback):

```bash
firebase deploy --only firestore:rules --project quran-app-e5e86
```

**Verification:**

- Rules tests (step 2, same PR) prove denial in the emulator.
- Live: from a signed-in client/device, any direct Firestore read or write
  → `permission-denied` (use a straggler build or a one-off script with the
  client SDK).
- Server unaffected (Admin SDK bypasses rules):
  `curl -sS https://jawhar-api-556087735735.europe-southwest1.run.app/health`
  → 200; authenticated `GET /v1/me/bootstrap` returns data; one facts write
  round-trips.

**Rollback:** redeploy the previous ruleset from git — revert the commit and
push (CI redeploys), or from the pre-flip checkout run the manual deploy
above. Independent of every other step.

## Step 2 — Rules tests assert denial

Rewrite `functions/test/firestore.rules.test.js` so every collection the old
ruleset allowed (progress, sessions, flashcards, flashcard_reviews, profiles,
settings, daily_plans, …) now **asserts denial** for both read and write, as
owner and as stranger. Keep `functions/test/security.test.js` consistent.

> The rules-test harness (`functions/package.json` `test:rules` +
> `functions/test/firestore.rules.test.js`) **survives the step-5 source
> demolition** — roadmap §8 Phase 8 task 1: it "lives on post-Phase-3 for
> exactly this." Step 5 deletes deployed-function sources and deploy steps,
> not this harness (relocating it to e.g. `tool/rules-tests/` is acceptable
> if `functions/` must go entirely — keep the CI job green either way).

**Verification (local or CI):**

```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-21.0.11.10-hotspot"
cd functions; npm run test:rules
```

**Rollback:** revert with step 1 (same PR is fine — they are one logical
change; the deploy itself is what step 1 isolates).

## Step 3 — App Check enforcement (Android ONLY)

Pre-runbook ceiling is log-only. Demolition-day actions (roadmap §8 Phase 8
task 3, §9):

1. Ensure the API is enabled and the Android app is registered with the
   **Play Integrity** provider (Firebase console → App Check →
   `jawhar-android`; requires the Play App Signing SHA-256 already registered):

```bash
gcloud services enable firebaseappcheck.googleapis.com \
  --project quran-app-e5e86 --account me@heykhalid.com --quiet
```

2. Run **log-only for one full release**: Cloud Run middleware verifies
   `X-Firebase-AppCheck` and logs verdicts without rejecting.
   ⚠ Re-verify the middleware's actual env contract at execution time
   (`server/api/lib/middleware/` — the enforcement mode must be a runtime env
   var so the flip is a `gcloud run services update`, not a build).
3. After one clean log-only release (zero false negatives for real Android
   testers in the logs), flip enforcement **for Android tokens only**:

```bash
gcloud run services update jawhar-api --region europe-southwest1 \
  --update-env-vars APP_CHECK_MODE=enforce-android \
  --project quran-app-e5e86 --account me@heykhalid.com --quiet
```

   - iOS (App Attest): **log-only indefinitely** until a real iOS tester
     exists and the debug-screen round-trip has run on a real iOS device.
   - Web (reCAPTCHA Enterprise): log-only indefinitely.
   - **Windows desktop: documented exemption** — no attestation provider
     exists; the real wall is ID-token auth + per-uid rate limiting (§9).

**Verification:** real Android tester requests succeed; a synthetic `/v1`
request with a valid ID token but **no** App Check token, claiming Android,
is rejected (403); Windows/web clients unaffected.

**Rollback:** one env-var flip back to log-only
(`--update-env-vars APP_CHECK_MODE=log`) — instant, no build.

## Step 4 — Delete the legacy callables FROM PROD (before source removal)

Order is load-bearing: non-interactive `firebase deploy` **aborts** when a
deployed function disappears from source (firebase-tools 15.x,
`prompts.js:59–67`) — delete from prod first, remove from source second.

```bash
firebase functions:delete generateDailyPlan generateCalibration \
  --project quran-app-e5e86 --force
```

**Verification:**

```bash
gcloud functions list --project quran-app-e5e86 --account me@heykhalid.com \
  --quiet --format="value(name,state)"
# expect: neither generateDailyPlan nor generateCalibration listed
```

Client impact check: AI plan + calibration still work on a tester device
(they ride `/v1` — `kUseApiV1Ai` has been default-on since 2026-06-12; the
callable path is only reachable on builds compiled with the flag off, which
GATE 2's `minSupportedBuild` bump has already locked out of sync — and the
deterministic offline fallback is unaffected either way).

**Rollback:** source is still in git AND still in the working tree (step 5
has not run yet):
`cd functions && npm ci && npm run build && firebase deploy --only functions --project quran-app-e5e86`

## Step 5 — Source demolition (one commit, after step 4 is verified live)

**Server/repo side:**

- delete `functions/src/**` and the functions **deploy** half of
  `.github/workflows/deploy-backend.yml` (keep the rules+indexes deploy and
  the rules-test job — see step 2 note);
- remove the `"functions"` block from `firebase.json`.

**Client side (the "migration done" signal — roadmap §3 disposition table):**

- `pubspec.yaml`: remove `cloud_functions: 5.6.2` and `cloud_firestore: 5.6.12`;
- delete `lib/services/cloud_sync_service.dart`;
- shrink `lib/services/auth_sync_coordinator.dart` to outbox-trigger +
  bootstrap duty only;
- purge remaining `cloud_firestore`/`cloud_functions`/`CloudSyncService`
  references — full file list at time of writing (re-grep at execution:
  `grep -rln "cloud_firestore\|cloud_functions\|CloudSyncService\|cloud_sync_service" lib/`):
  - `lib/main.dart`
  - `lib/services/ai_plan_service.dart` (drop the callable transport + retire `kUseApiV1Ai`)
  - `lib/services/ai_calibration_service.dart` (same)
  - `lib/services/auth_service.dart`
  - `lib/services/write_path_store.dart`
  - `lib/screens/profile_screen.dart`
  - `lib/providers/bookmark_provider.dart`
  - `lib/providers/hifz_profile_provider.dart`
  - `lib/providers/plan_provider.dart`
  - `lib/providers/flashcard_provider.dart`
  - `lib/providers/session_provider.dart`
- ship `DELETE /v1/me` if not already live (scope per the Phase 2 spike
  result — roadmap §5 #11).

**Verification:** `flutter analyze` clean; full test suite green; release
build succeeds on Android + Windows + web; built binary contains **no
Firestore/Functions SDK** (grep the APK/exe for `com.google.firebase.firestore`
/ `cloud_firestore`); fresh install → sign-in → bootstrap hydrates; offline
loop + outbox flush still work end-to-end (airplane-mode script, §10).

**Rollback:** `git revert` of the demolition commit. Cloud state is
unaffected — the prod deletion already happened (and was verified) in step 4.

## Step 6 — Firebase Hosting serving disabled ✅ (done 2026-06-12)

Already executed in Wave 4:

- [x] `firebase hosting:disable --project quran-app-e5e86 --force`
- [x] hosting block removed from `firebase.json` (`deploy-backend.yml` does
      not trigger on `firebase.json` — confirmed)
- [x] verified: `https://quran-app-e5e86.web.app/` → HTTP 404 "Site Not Found"
- The default site cannot be deleted, only disabled; the `web.app` domain
  stays reserved. The `firebaseapp.com` authDomain is Auth infrastructure
  and is unaffected. Web lives on Vercel, full stop.

Re-check on demolition day:

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://quran-app-e5e86.web.app/   # expect 404
```

**Rollback (if ever needed):** `firebase deploy --only hosting` from a
checkout that still has the hosting block (pre-`ab92d27` history).

## Step 7 — Final secret grep gates over built artifacts

**Blocked-by:** the content-token eviction precondition
(`docs/decisions/2026-06-12-content-token-fallback.md`) — until the
signed-out-capable server path ships and QF credentials are rotated, the
QF content secret is **expected** to be present and this gate cannot pass.

Build all release artifacts (Android, Windows, web), then — never echoing
secret values — assert all of these come back CLEAN:

```bash
# QF content secret (from Secret Manager, value never printed):
S=$(gcloud secrets versions access latest --secret QURAN_API_CLIENT_SECRET \
  --project quran-app-e5e86 --account me@heykhalid.com --quiet)
grep -rc --binary-files=text -- "$S" build/ && echo "FAIL: secret in artifacts" || echo CLEAN

# QF preprod secret + desktop OAuth secret: take values from the historical
# .env (both already deleted from defines — this proves they stayed deleted),
# same grep pattern. Also assert no Web-type Google OAuth secret of the form:
grep -rEc --binary-files=text "GOCSPX-[A-Za-z0-9_-]+" build/ && echo "FAIL" || echo CLEAN

# And no secrets in the workflow defines:
grep -rn "QURAN_API_CLIENT_SECRET\|QURAN_PREPROD_CLIENT_SECRET\|DESKTOP_OAUTH_CLIENT_SECRET" .github/workflows/ .env 2>/dev/null
```

**Verification = the gate itself.** Content loading must still work on all
platforms via `POST /v1/content/token` (+ the signed-out path that unblocked
this step). **Rollback:** n/a (read-only gate); a FAIL blocks the v1.9.0 tag.

## Step 8 — Docs + tag

- Update `docs/architecture.md` and `docs/api-reference.md` to the end-state
  (server-private Firestore, deny-all rules, `/v1` as the only write path).
- Update the MEMORY release checklist; mark the migration complete.
- Roadmap §8 Phase 8 task 5 (optional Firestore schema redesign behind a
  sanctioned reset) is explicitly **not** on this runbook's critical path —
  schedule separately if ever.
- Tag: `git tag v1.9.0 && git push origin v1.9.0` — **only after steps 1–7
  are verified and the exit criteria below hold.**

## Exit criteria (roadmap §8 Phase 8)

- [ ] Client binary contains no Firestore/Functions SDK and no compiled-in
      secrets (step 7 gate passed post-eviction).
- [ ] Rules tests prove deny-all (step 2).
- [ ] App Check enforced on Android with zero tester breakage (step 3).
- [ ] Reset protocol on file and exercised at least once (Phase 5 rotation
      reset).
- [ ] `docs/architecture.md` / `docs/api-reference.md` updated; v1.9.0 tagged.
