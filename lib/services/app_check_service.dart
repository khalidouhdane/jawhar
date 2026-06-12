import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:quran_app/utils/app_logger.dart';

/// Firebase App Check, LOG-ONLY wave (roadmap §8 Phase 8 task 3 / §9).
///
/// Platform matrix — deliberately Android-only for now:
/// - **Android**: Play Integrity on release builds, the debug provider on
///   debug builds (debug tokens are registered in the Firebase console).
/// - **iOS**: NOT activated — App Attest stays log-only-indefinitely until a
///   real iOS tester exists (§8 Phase 8 task 3); activating before the
///   debug-screen round-trip has run on a real device risks bricking the
///   first iOS tester at the final step.
/// - **Web**: NOT activated — reCAPTCHA Enterprise is log-only indefinitely
///   per §8; no site key is provisioned yet.
/// - **Windows/desktop: documented EXEMPTION — no attestation provider
///   exists for the platform.** The real wall there is ID-token auth + the
///   per-uid rate limiting already on the server (§9). Server-side, Windows
///   traffic simply logs `appCheck: absent` forever.
///
/// The server NEVER rejects on any verdict in this wave (enforcement is a
/// post-soak runbook step), so every path in this class is fail-open: an
/// activation or token failure must never break the app or block sync.
class AppCheckService {
  AppCheckService._();

  static bool _activated = false;

  /// Whether this platform participates in App Check at all.
  static bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Activates App Check on supported platforms. Safe to call on every
  /// platform and on startup retries; never throws.
  static Future<void> activate() async {
    if (!isSupportedPlatform || _activated) return;
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kReleaseMode
            ? AndroidProvider.playIntegrity
            : AndroidProvider.debug,
      );
      _activated = true;
      AppLogger.info(
        'AppCheck',
        'Activated (${kReleaseMode ? 'playIntegrity' : 'debug'} provider)',
      );
    } catch (e) {
      // Log-only wave: attestation failing must never break startup.
      AppLogger.warn('AppCheck', 'Activation failed (continuing without): $e');
    }
  }

  /// Current App Check token for the `X-Firebase-AppCheck` header, or null
  /// when unsupported/inactive/failing. Bounded so a slow Play Integrity
  /// round-trip can never stall an outbox drain.
  static Future<String?> getToken() async {
    if (!_activated) return null;
    try {
      final token = await FirebaseAppCheck.instance
          .getToken()
          .timeout(const Duration(seconds: 4));
      return (token == null || token.isEmpty) ? null : token;
    } catch (e) {
      AppLogger.warn('AppCheck', 'Token fetch failed (sending without): $e');
      return null;
    }
  }
}
