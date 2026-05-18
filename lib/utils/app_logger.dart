import 'package:flutter/foundation.dart';

/// Centralized logging utility for Jawhar.
///
/// Replaces scattered `debugPrint` calls with a single, togglable logger.
/// - In debug mode: only errors are printed by default.
/// - Set [verbose] to `true` to enable informational logs (for active debugging).
/// - In release mode: all logging is compiled out by the tree-shaker.
///
/// Usage:
/// ```dart
/// AppLogger.info('CloudSync', 'Pushing profile to Firestore');
/// AppLogger.error('ApiClient', 'Timeout on /verses', error);
/// ```
class AppLogger {
  /// Set to `true` to enable informational (non-error) logs.
  /// Keep `false` during normal development to eliminate console noise.
  static bool verbose = false;

  /// Log an informational message. Only prints when [verbose] is `true`.
  ///
  /// Use for: successful operations, state transitions, network responses.
  static void info(String tag, String message) {
    if (kReleaseMode) return;
    if (verbose) debugPrint('[$tag] $message');
  }

  /// Log a warning. Always prints in debug mode.
  ///
  /// Use for: non-fatal issues, fallback paths, degraded behavior.
  static void warn(String tag, String message) {
    if (kReleaseMode) return;
    debugPrint('[$tag] ⚠ $message');
  }

  /// Log an error. Always prints in debug mode.
  ///
  /// Use for: caught exceptions, failed operations, data integrity issues.
  static void error(String tag, String message, [Object? error]) {
    if (kReleaseMode) return;
    debugPrint('[$tag] ✖ $message${error != null ? ' ($error)' : ''}');
  }
}
