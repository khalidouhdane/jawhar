# AGENTS.md — Agent Instructions for the Jawhar Repository

Read this before changing anything. It is the distilled, hard-won context from
the 2026-06 cloud-first migration (v1.9) plus the project's standing
conventions. The commit history is detailed; this file is the map.

---

## 1. Architecture snapshot (post-v1.9 migration, June 2026)

**Jawhar is cloud-first: the Flutter app is UI + local cache; the backend owns
truth.**

```
Flutter app (Android / iOS / Windows / Web)
  • UI + SQLite cache (hifz_data.db) + uid-partitioned outbox
  • packages/hifz_core runs locally as the offline fallback
        │  HTTPS /v1 + Firebase ID token
        ▼
jawhar-api — Dart shelf on Cloud Run (europe-southwest1)
  • single write path: POST /v1/me/facts (transactional, per-fact idempotent)
  • plan/SRS/streak/analytics derived server-side via hifz_core
  • Vertex AI (service-account auth, NO API keys) for AI plan/calibration
  • QF content tokens served server-side (POST /v1/content/token)
        ▼  Admin SDK
Firestore (project quran-app-e5e86)
```

Key directories:

| Path | What it is |
|---|---|
| `packages/hifz_core/` | Pure-Dart shared brain: SRS engine, plan generation, fact DTOs, derivations. Used by BOTH app and server. The JSON golden fixtures in `test/fixtures/` are the cross-language parity spec — never break them casually. |
| `server/api/` | The jawhar-api Cloud Run service (shelf). All `/v1` handlers, FirestoreGateway, middleware (auth, rate limit, App Check log-only, CORS, body limit). |
| `lib/services/outbox_service.dart`, `sync_worker.dart`, `write_path_store.dart` | Client outbox: facts queue, drains, backfill, per-user `writePath` gating. |
| `functions/` | **Legacy TS callables — FROZEN.** Still deployed as the AI rollback path during the soak. Do not modify; demolition is runbook-gated. |
| `website/` | Next.js marketing site, auto-deploys to Vercel on push to main. Download links use `releases/latest/download/*` (version-independent). |
| `docs/PHASE8_LOCKDOWN_RUNBOOK.md` | The gated demolition-day checklist (deny-all rules, functions deletion, App Check enforcement, v1.9.0 tag). |
| `docs/decisions/` | Committable architecture decision records. |

The detailed migration roadmap (`docs/CLOUD_FIRST_MIGRATION_ROADMAP.md`) is
**deliberately gitignored** (contains operator/billing identifiers); ask the
repo owner for it when working on this machine.

## 2. Current state & hard gates (as of 2026-06-12)

- v1.9.0-rc1 shipped on Android (GitHub Releases), Windows (same release),
  iOS (TestFlight). The **soak week** is running: the new AI transport
  (`kUseApiV1Ai`, default on) and the facts write path prove themselves on
  real devices before old systems are deleted.
- **FROZEN until the runbook says otherwise:** `functions/**`,
  `firestore.rules` (the deny-all flip is a runbook step), App Check
  enforcement (log-only is the ceiling), the final `v1.9.0` tag.
- The first user runs `writePath: facts` (flag lives at
  `users/{uid}/meta/server.writePath`; rollback = set it back to `legacy`).
  Other users remain on `legacy` until rollout.
- Versioning: **this architecture era is v1.9.x. v2.0 is reserved for the
  design/UX overhaul** (admin panel, analytics dashboards, possible native
  Compose/Swift clients on this same backend).

## 3. Invariants — violate these and things break in production

1. **The offline core loop is sacred.** Memorization, reviews, reading, and
   plan generation must work with zero network. Anything that blocks offline
   (including the `minSupportedBuild` force-update gate) may block **sync
   only**, never the loop.
2. **`/health`, never `/healthz`.** Google Front End intercepts the literal
   path `/healthz` on `*.run.app` hosts and returns its own 404 before the
   container sees it. Never name an endpoint `/healthz`.
3. **Facts are idempotent and uid-scoped.** uid comes ONLY from the verified
   ID token, never the body. Byte-identical replay returns `applied: false`.
   Numeric bounds (page 1–604, status 0–3, rating 0–3) are enforced in the
   typed handlers — they replaced the Firestore rules validators.
4. **Deploying server/api requires the staged build context** (vendor
   `packages/hifz_core`, append a `dependency_overrides` path, strip
   `resolution: workspace` with CRLF-tolerant seds). The canonical recipe is
   the "Stage build context" step in `.github/workflows/deploy-api.yml`.
   A bare `gcloud run deploy --source server/api` cannot resolve hifz_core.
5. **Cloud Run env discipline:** deploys use `--update-env-vars` /
   `--update-secrets` (never `--set-`), so out-of-band vars (SENTRY_DSN,
   GEMINI_MODEL, the QF content secret mount) survive.
6. **Manzil rotation** is server-persisted; mutate it only via
   `OutboxService.replaceRotationAndEnqueue` (the raw DB mutators bypass
   sync). **`PUT /v1/me/profiles` must not get client callers** until the
   facts-refold precondition in the runbook is implemented.
7. **Build/run flags:** every `flutter run/build/test` needs
   `--dart-define-from-file=.env` (see §6).
8. Windows builds: `windows/CMakeLists.txt` carries the MSVC
   experimental-coroutine silencer and CI sets
   `CMAKE_POLICY_VERSION_MINIMUM=3.5` — both compensate for runner-image
   drift; remove only when the Firebase C++ SDK / plugins catch up.
9. iOS CI: fastlane is **pinned in `ios/Gemfile`** (2.236.0 corrupted ASC
   keys — fastlane/fastlane#30065) and **cocoapods must stay in that
   Gemfile** (`pod` breaks under `bundle exec` otherwise). The lane revokes
   all distribution certs each run by design (ephemeral keychains).

## 4. Testing & CI map

| Suite | Command | Gate |
|---|---|---|
| App | `flutter test` (root) | 5% coverage floor (`tool/check_coverage.dart`) |
| hifz_core | `dart test` in `packages/hifz_core` | **80% coverage gate** — domain logic lives here |
| Server | `dart test` in `server/api`; full suite via `firebase emulators:exec --only firestore "cd server/api && dart test"` | Contract tests incl. replay/kill-mid-drain/A→B isolation |
| Local emulator | needs JDK 21+ (`JAVA_HOME` → Temurin, not the Android Studio JBR) | |

Workflows: `quality.yml` (every push: analyze + all suites),
`deploy-backend.yml` (functions+rules+indexes via WIF), `deploy-api.yml`
(jawhar-api → Cloud Run, gated by a post-deploy `/health` git-SHA check),
`android/ios/windows.yml` (tag-triggered releases).

**Releases: use ONE plain `v*` tag** (e.g. `v1.9.0`) so all three platform
workflows attach artifacts to a single GitHub release — the website's
`releases/latest/download/*` links depend on every asset living in one
release. Platform-suffixed tags (`v*-android` etc.) exist for single-platform
respins only and require manual asset consolidation afterwards.

Secrets plumbing (GitHub Actions): `ENV_FILE` is the **raw** `.env` text
(BOM-free, LF). When setting secrets from Windows, write the value to a
no-trailing-newline temp file and `gh secret set NAME < file` from bash —
PowerShell pipes append `\r` and corrupt them.

## 5. Verse reference formatting (UX standard)

Never display raw verse references (`12:87`) to users. Always use
`VerseRefFormatter.format(...)` from
`lib/utils/verse_ref_formatter.dart`, passing the current locale
(`AppLocalizations.of(context)!.localeName`):

- `VerseRefFormat.full` — `Surah Yusuf, Verse 87` / `سورة يوسف، الآية ٨٧`
  (share sheets, titles, long descriptions)
- `VerseRefFormat.standard` — `Yusuf · Verse 87` / `يوسف · الآية ٨٧`
  (cards, list subtitles, snackbars)
- `VerseRefFormat.compact` — `Yusuf · 87` / `يوسف · ٨٧`
  (badges, overlays, player labels)

## 6. Environment configuration

Core auth, APIs, and services configure via `.env` at the repo root
(gitignored). **Every** compile/run/test must pass
`--dart-define-from-file=.env`:

```bash
flutter run --dart-define-from-file=.env
flutter build apk --dart-define-from-file=.env
flutter test --dart-define-from-file=.env
```

Missing the flag breaks authentication, cloud sync, and content loading.
Secrets policy: QF preprod credentials are deleted (do not reintroduce);
the QF content secret's compiled-in fallback exists only for signed-out
reading (see `docs/decisions/2026-06-12-content-token-fallback.md`); the
desktop Google OAuth client is installed-app type (id is a plain constant
by design).
