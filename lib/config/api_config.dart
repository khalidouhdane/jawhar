/// Compile-time configuration for the jawhar-api (`/v1`) transport.
///
/// Values are baked in at build time via `--dart-define`:
///
/// ```
/// flutter build apk \
///   --dart-define=USE_API_V1_AI=true \
///   --dart-define=JAWHAR_API_BASE_URL=https://jawhar-api-<hash>.a.run.app
/// ```
///
/// An empty [kJawharApiBaseUrl] means the API transport is OFF regardless of
/// [kUseApiV1Ai]. The default base URL points at the live Cloud Run service;
/// the transport stays inert until [kUseApiV1Ai] is flipped (post tablet
/// canary), so behavior remains identical to today by default.
library;

/// Whether AI plan/calibration calls should try the `/v1` API before the
/// legacy Firebase callable (roadmap §8 Phase 3 task 5). Rollback is a
/// rebuild with the flag off — the callables stay deployed during the soak.
/// Default ON since 2026-06-12: the authenticated Android canary passed
/// (health + bootstrap + plan:enhance round-trip verified in server logs).
const bool kUseApiV1Ai = bool.fromEnvironment(
  'USE_API_V1_AI',
  defaultValue: true,
);

/// Base URL of the jawhar-api Cloud Run service, without a trailing slash
/// and without the `/v1` suffix (e.g. `https://jawhar-api-xyz.a.run.app`).
const String kJawharApiBaseUrl = String.fromEnvironment(
  'JAWHAR_API_BASE_URL',
  defaultValue: 'https://jawhar-api-556087735735.europe-southwest1.run.app',
);
