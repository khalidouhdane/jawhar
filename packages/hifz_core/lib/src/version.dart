/// Semver of the shared domain core.
///
/// Carried as `coreVersion` on every fact and as the
/// `X-Client-Core-Version` header on every `/v1` mutation (roadmap §5),
/// so the server can log client/server algorithm skew.
/// Keep in sync with `packages/hifz_core/pubspec.yaml`.
const String hifzCoreVersion = '1.0.0';
