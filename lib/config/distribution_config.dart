/// Compile-time distribution configuration.
///
/// The official channel is Google Play, where self-updating outside Play is
/// forbidden (Device & Network Abuse policy), so the GitHub-release updater
/// is OFF unless a build opts in:
///
/// ```
/// flutter build apk --dart-define=ENABLE_SELF_UPDATE=true ...
/// ```
///
/// Opt-in builds no longer hold REQUEST_INSTALL_PACKAGES (removed from the
/// manifest for Play), so the in-app installer falls back to opening the
/// GitHub release page in the browser.
library;

const bool kSelfUpdateEnabled = bool.fromEnvironment(
  'ENABLE_SELF_UPDATE',
  defaultValue: false,
);
