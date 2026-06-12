# Decision record — compiled-in QF content secret stays as the signed-out fallback

**Date:** 2026-06-12 (Wave 3, Phase 7) · **Status:** Accepted deviation, revisit-triggered
**Scope:** `QURAN_API_CLIENT_SECRET` (QF Content API client-credentials secret)
**Roadmap anchor:** `docs/CLOUD_FIRST_MIGRATION_ROADMAP.md` §8 Phase 7 deviation record (gitignored on some checkouts — this file is the committable record)

---

## Decision

`POST /v1/content/token` on jawhar-api is live and is the client's **primary**
source of QF content tokens (secret server-side in Secret Manager, per-uid
rate-limited). However, the Phase 7 exit criterion — *no quran.foundation
secret in any client artifact* — is **deliberately not met**: the compiled-in
direct client-credentials exchange in `lib/services/quran_auth_service.dart`
**stays in every binary on purpose**, as the signed-out/outage fallback
(server path first, direct exchange second).

## Rationale

1. `POST /v1/content/token` requires a **Firebase ID token**, but Firebase
   sign-in is **optional** in Jawhar. Signed-out reading (Quran text/audio)
   must keep working — it is part of the offline-first product contract.
2. Evicting the secret today would break all signed-out content loading, or
   force account creation as a precondition for reading the Quran. Neither is
   acceptable.
3. The blast radius is bounded: the QF content token grants **read access to
   public Quran content only**. The secret is treated as **semi-public** until
   eviction.

## Verified consequences (2026-06-12)

- Built artifacts under `.dart_tool/flutter_build/` contain the literal
  `clientId:clientSecret` pair (and so do release binaries built with the
  `.env` dart-defines).
- The Vercel proxy's `shouldForwardAuthHeaders` is correspondingly **not yet
  narrowed** to `apis.quran.foundation` — the client still speaks to
  `oauth2.quran.foundation` on the fallback path, so that forwarding must
  survive until eviction.
- Strand 2 (QF preprod user-mirror secret) is fully deleted; strand 3
  (desktop OAuth installed-app re-registration) tracks separately. This
  record covers the content secret only.

## Revisit trigger (eviction precondition)

Evict the compiled-in exchange **only after** a signed-out-capable server
path exists, one of:

- an **unauthenticated, rate-limited** token route on jawhar-api
  (IP/device-bucketed limits instead of per-uid), or
- **proxy-attached tokens** on the Vercel proxy (the proxy injects the
  bearer token server-side; clients never hold one).

## Eviction release checklist (when triggered)

1. Ship the signed-out-capable path; verify signed-out reading on Android,
   Windows, and web.
2. Remove the direct exchange from `quran_auth_service.dart`; strip
   `QURAN_API_CLIENT_SECRET` from `.env` / workflow dart-defines.
3. **Rotate the QF content credentials in the same release** — every
   historical tester binary embeds the current pair, so eviction without
   rotation evicts nothing.
4. Narrow the Vercel proxy auth-forwarding to exactly
   `apis.quran.foundation` (+ prelive twin); retire `oauth2.quran.foundation`
   forwarding.
5. Re-run the Phase 7 secret grep gate over built artifacts (see
   `docs/PHASE8_LOCKDOWN_RUNBOOK.md`, step 7) — must come back empty.

## Operator follow-ups

- Exclude `.dart_tool/` and `build/` from OneDrive sync (roadmap R11) so
  secret-bearing build artifacts do not replicate to cloud storage.

## Sign-off

- Owner: Khalid Ouhdane — signed off: ____________________ date: __________
