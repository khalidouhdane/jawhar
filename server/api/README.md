# jawhar-api

Dart `shelf` service for Cloud Run (roadmap §3/§8 Phase 2). Wave 1 scaffold:
`/health` (and `/healthz` for local use), Firebase ID-token auth middleware (injectable `TokenVerifier`),
structured JSON logging, Sentry (no-op without DSN), `FirestoreGateway`
(firebase_admin_sdk, sole Firestore access point), AOT Dockerfile.

## Environment

| Var | Meaning | Default |
|---|---|---|
| `PORT` | listen port (Cloud Run injects) | `8080` |
| `GIT_SHA` | deployed git SHA surfaced by `/health` | `unknown` |
| `GEMINI_MODEL` | model id surfaced by `/health`, used by Phase 3 AI handlers | `gemini-3.5-flash` |
| `GOOGLE_CLOUD_PROJECT` | project id / required token audience | `quran-app-e5e86` |
| `SENTRY_DSN` | enables Sentry when set | unset → no-op |
| `CORS_ALLOWED_ORIGINS` | comma-separated CORS allow-list; entries are exact origins or `scheme://host:*` any-port wildcards; setting it REPLACES the default (localhost entries included) | Vercel web app + `http://localhost:*` + `http://127.0.0.1:*` |
| `FIRESTORE_EMULATOR_HOST` | routes all Firestore traffic to the emulator, credential-free | unset → production + ADC |

## Develop

```powershell
dart pub get
dart analyze
dart test
dart run bin/server.dart   # http://localhost:8080/health
```

Local emulator loop (roadmap §10): from the repo root,
`firebase emulators:start --only firestore --project demo-jawhar-spike`,
then run with `FIRESTORE_EMULATOR_HOST=localhost:8080`. Requires JDK 21+
(firebase-tools 15.18.0 refuses anything older — Temurin 21 installed
machine-wide 2026-06-11 via `winget install EclipseAdoptium.Temurin.21.JDK`).
The emulator loads the repo's `firestore.rules`; the Admin SDK (and any raw
REST call carrying `Authorization: Bearer owner`) bypasses them, as production
Admin SDK access does.

## R1 spike (Phase 2 risk retirement) — run 2026-06-11

Manual scripts under `tool/spike/` — see headers for inputs:

- `spike_token_verify.dart` — items (a) ID-token verify positive/negative and
  (d) `auth.deleteUser`.
- `spike_firestore_emulator.dart` — items (b) transactions via the gateway and
  (c) `FIRESTORE_EMULATOR_HOST` honored.

Verdicts from the 2026-06-11 run (`firebase_admin_sdk` 0.5.x):

| Item | Verdict | Evidence |
|---|---|---|
| (a) ID-token verification | PASS (negative-path) | Google securetoken certs fetched (2 kids); forged-but-well-formed RS256 JWT with correct iss/aud/exp rejected with `auth/argument-error: "kid" claim does not correspond to a known public key` (proves kid resolution against Google certs); garbage token rejected. Positive path NOT run: all self-serve sign-up providers are disabled on quran-app-e5e86 (`OPERATION_NOT_ALLOWED`) and every local Google credential needs interactive reauth (`invalid_rapt`). Rerun after `gcloud auth login me@heykhalid.com` with `GCLOUD_ACCESS_TOKEN` set. |
| (b) Transactions via FirestoreGateway | PASS | read-modify-write + multi-doc atomic write; 10 concurrent transactional increments -> n=10 (no lost updates). |
| (c) FIRESTORE_EMULATOR_HOST honored | PASS | zero credentials configured; data written through the SDK read back over the emulator's REST endpoint. |
| (d) auth.deleteUser | PASS (API surface) | compile-time typed tear-off `Future<void> Function(String uid)`; real call blocked by the same credential reauth. |

Overall: **PASS — adopt `firebase_admin_sdk`**; the REST-via-`googleapis`
fallback (roadmap R1) is not needed on current evidence. Residual before
Phase 2 exit: one positive-path token verification + one real `deleteUser`
once a human reauthenticates gcloud.

## Follow-ups owned by other streams

- Add `server/api` to the root pub workspace (`workspace:` in the root
  `pubspec.yaml`) and switch this package to `resolution: workspace`.
- `deploy-api.yml` CI workflow (Phase 2 task 10).
- `minSupportedBuild` / `datasetEpoch` on `/health` arrive with Wave 2 state.
