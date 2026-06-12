# Jawhar — Quran Foundation User API Reference

> **⚠ OBSOLETE (2026-06-12).** The QF user-sync mirror was DELETED in
> migration Phase 7 (roadmap §8, "delete branch" decided 2026-06-10):
> `qf_user_auth_service.dart` / `qf_user_api_service.dart` and every call
> site are gone, and the `QURAN_PREPROD_*` credentials were stripped from
> `.env`/dart-defines. This document is kept for historical reference only —
> do not build against it. The placeholder `{QURAN_PREPROD_CLIENT_ID}`
> below is a key NAME, not a value. Outstanding operator actions: regenerate
> the `ENV_FILE` GitHub Actions secret without the `QURAN_PREPROD_*` lines,
> and rotate/revoke the preprod OAuth client with Quran Foundation (the
> secret shipped in historical tester binaries).

> **Environment:** Pre-live (for development). Switch to production by swapping credentials only.
> **Source:** [api-docs.quran.foundation](https://api-docs.quran.foundation)
> **Last updated:** May 13, 2026

---

## Environments

| Environment | OAuth2 Base | API Base | Auth Docs |
|-------------|------------|----------|-----------|
| **Production** | `https://oauth2.quran.foundation` | `https://apis.quran.foundation` | [Production docs](https://api-docs.quran.foundation/docs/user_related_apis_versioned/1.0.0/user-related-apis/) |
| **Pre-live** | `https://prelive-oauth2.quran.foundation` | `https://prelive-apis.quran.foundation` | [Pre-live docs](https://api-docs.quran.foundation/docs/user_related_apis_prelive/user-related-apis/) |

> ⚠️ **Never mix environments.** Pre-live auth tokens cannot access production APIs and vice versa.

---

## OAuth2 Authorization Code + PKCE Flow

### OIDC Discovery (Pre-live)

From `https://prelive-oauth2.quran.foundation/.well-known/openid-configuration`:

| Endpoint | URL |
|----------|-----|
| **Authorization** | `https://prelive-oauth2.quran.foundation/oauth2/auth` |
| **Token** | `https://prelive-oauth2.quran.foundation/oauth2/token` |
| **UserInfo** | `https://prelive-oauth2.quran.foundation/userinfo` |
| **Revocation** | `https://prelive-oauth2.quran.foundation/oauth2/revoke` |
| **End Session** | `https://prelive-oauth2.quran.foundation/oauth2/sessions/logout` |
| **JWKS** | `https://prelive-oauth2.quran.foundation/.well-known/jwks.json` |

### Supported Features

- **Grant types:** `authorization_code`, `implicit`, `client_credentials`, `refresh_token`
- **Response types:** `code`, `code id_token`, `id_token`, `token id_token`, `token`
- **PKCE methods:** `plain`, `S256` (use S256)
- **Token auth methods:** `client_secret_post`, `client_secret_basic`, `private_key_jwt`, `none`
- **ID token signing:** RS256

### Flow Steps (for Flutter desktop/mobile)

```
1. Generate PKCE: code_verifier (43-128 chars) → SHA-256 → base64url = code_challenge
2. Generate random `state` + `nonce` values
3. Build authorization URL:
   GET {auth_endpoint}?
     client_id={QURAN_PREPROD_CLIENT_ID}
     &redirect_uri=http://localhost:{port}/callback  (desktop)
     &response_type=code
     &scope=openid offline_access bookmark reading_session goal streak
     &code_challenge={code_challenge}
     &code_challenge_method=S256
     &state={state}
     &nonce={nonce}
4. Open in system browser
5. User signs in on QF hosted login page
6. Redirect to redirect_uri with ?code={auth_code}&state={state}
7. Verify state matches
8. Exchange code for tokens:
   POST {token_endpoint}
     grant_type=authorization_code
     &code={auth_code}
     &redirect_uri={redirect_uri}
     &code_verifier={code_verifier}
     &client_id={client_id}
     &client_secret={client_secret}  (confidential clients)
9. Receive: access_token, refresh_token, id_token
10. Use access_token in x-auth-token header for User API calls
```

### Important Notes

- **Confidential client:** Our pre-prod client likely requires `client_secret` on token exchange (same as our existing `desktop_google_auth.dart` pattern)
- **Token refresh:** Use `grant_type=refresh_token` with the refresh_token
- **sub claim:** The `sub` field in id_token is the stable user identifier — use as foreign key
- **Desktop redirect:** Use `http://localhost:{random_port}/callback` (same loopback pattern we already use for Google OAuth)

---

## OAuth2 Scopes

Request only what we need:

| Scope | Access | We Need? |
|-------|--------|----------|
| `openid` | Required for OIDC id_token | ✅ Yes |
| `offline_access` | Enables refresh_token | ✅ Yes |
| `bookmark` | Read/write bookmarks | ✅ Yes |
| `reading_session` | Read/write reading sessions | ✅ Yes |
| `goal` | Read/write goals | ✅ Yes |
| `streak` | Read/write streaks | ✅ Yes |
| `content` | Content API access | ✅ Already have (production) |
| `collection` | Read/write collections | ❌ Not yet |
| `preference` | Read/write preferences | ❌ Not yet |
| `user` | User profile data | ❓ Maybe |

**Minimum scope string:** `openid offline_access bookmark reading_session goal streak`

---

## User API Endpoints

Base URL: `https://prelive-apis.quran.foundation/auth/v1`

Headers required on every request:
```
x-auth-token: {access_token}
x-client-id: {client_id}
```

### Bookmarks

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/bookmarks` | List user bookmarks |
| `POST` | `/bookmarks` | Create a bookmark |
| `DELETE` | `/bookmarks/{id}` | Delete a bookmark |

### Reading Sessions

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/reading-sessions` | Record a reading session |
| `GET` | `/reading-sessions` | List reading sessions |

### Goals

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/goals` | Create a reading goal |
| `GET` | `/goals` | List goals |
| `PATCH` | `/goals/{id}` | Update a goal |

### Streaks

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/streaks` | Get streak data |
| `POST` | `/streaks` | Update streak |

### Pagination

Cursor-based pagination using:
- `first` + `after` — forward pagination
- `last` + `before` — backward pagination

Example: `GET /bookmarks?first=10&after=xyz`

---

## Integration with Existing Jawhar Architecture

### What we already have (reusable patterns)

| Existing code | Reusable for QF User API? |
|--------------|--------------------------|
| `QuranAuthService` (client_credentials) | ❌ Different flow — need new service |
| `DesktopGoogleAuth` (loopback + PKCE) | ✅ **Same pattern!** Reuse for QF OAuth |
| `CloudSyncService` (Firestore sync) | ✅ Add QF API as second sync target |
| `QuranApiService` (headers + error handling) | ✅ Reuse header pattern (`x-auth-token` + `x-client-id`) |

### New files needed

| File | Purpose |
|------|---------|
| `services/qf_user_auth_service.dart` | OAuth2 PKCE flow for QF User API |
| `services/qf_user_api_service.dart` | User API client (bookmarks, sessions, goals, streaks) |

### Files to modify

| File | Change |
|------|--------|
| `providers/bookmark_provider.dart` | Add QF bookmarks sync alongside Firestore |
| `providers/session_provider.dart` | Post reading sessions to QF API |
| `providers/hifz_profile_provider.dart` | Sync streaks with QF API |
| `providers/werd_provider.dart` | Sync goals with QF API |
| `screens/profile_screen.dart` | Add "Sign in with Quran Foundation" option |
| `.env` | Already has pre-prod keys ✅ |

---

## Reference Links

- [User APIs Quickstart](https://api-docs.quran.foundation/docs/tutorials/oidc/user-apis-quickstart/)
- [OAuth2 Tutorial (PKCE)](https://api-docs.quran.foundation/docs/tutorials/oidc/getting-started-with-oauth2/)
- [Web Integration Example](https://api-docs.quran.foundation/docs/tutorials/oidc/example-integration/)
- [OAuth2 Client Configuration](https://api-docs.quran.foundation/docs/tutorials/oidc/client-setup/)
- [OAuth2 Scopes](https://api-docs.quran.foundation/docs/user_related_apis_versioned/scopes/)
- [Pre-live User APIs Reference](https://api-docs.quran.foundation/docs/user_related_apis_prelive/user-related-apis/)
- [Production User APIs Reference](https://api-docs.quran.foundation/docs/user_related_apis_versioned/1.0.0/user-related-apis/)
- [OAuth2 Example Repo](https://github.com/quran/quran-oauth2-client-example)
- [OpenID Connect Guide](https://api-docs.quran.foundation/docs/tutorials/oidc/openid-connect/)
- [Machine-readable OpenAPI specs](https://api-docs.quran.foundation/llms.txt)
