import 'dart:async';

import 'package:quran_app/services/auth_service.dart';
import 'package:quran_app/services/cloud_sync_service.dart';

/// Coordinates one initial cloud sync for each signed-in Firebase user.
///
/// Syncs are serialized: if the signed-in user changes while a sync is still
/// running, the new user is synced after the current one finishes. This means a
/// rapid account switch (A → B before A's sync resolves) can never leave the
/// second account un-synced — which a fire-and-forget call to
/// [CloudSyncService.performInitialSync] would, since it drops overlapping
/// calls while one is already active.
class AuthSyncCoordinator {
  final AuthService _authService;
  final CloudSyncService _cloudSyncService;

  /// The last UID we have actually completed an initial sync for.
  String? _lastSyncedUid;

  /// The UID that currently wants to be synced (latest auth state).
  String? _pendingUid;

  /// Whether the drain loop is currently running.
  bool _pumping = false;

  bool _disposed = false;

  AuthSyncCoordinator(this._authService, this._cloudSyncService) {
    _authService.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  void _handleAuthChanged() {
    if (_disposed) return;

    final uid = _authService.uid;
    if (!_authService.isSignedIn || uid == null) {
      // Signed out: forget the synced UID so a later re-sign-in re-syncs, and
      // clear any pending request.
      _lastSyncedUid = null;
      _pendingUid = null;
      return;
    }

    _pendingUid = uid;
    unawaited(_pump());
  }

  /// Drains [_pendingUid], syncing each newly-signed-in user exactly once and
  /// serializing overlapping requests so none is silently dropped.
  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (!_disposed &&
          _pendingUid != null &&
          _pendingUid != _lastSyncedUid) {
        final uid = _pendingUid!;
        // performInitialSync swallows its own errors and clears its busy flag
        // in a finally, so this await always completes and never overlaps.
        await _cloudSyncService.performInitialSync(uid);
        _lastSyncedUid = uid;
      }
    } finally {
      _pumping = false;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _authService.removeListener(_handleAuthChanged);
  }
}
