import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/services/auth_service.dart';
import 'package:quran_app/services/cloud_sync_service.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/services/write_path_store.dart';
import 'package:quran_app/utils/app_logger.dart';

/// Manages the active Hifz profile and profile CRUD operations.
/// Replaces the old HifzProvider (which tracked surah-level progress).
class HifzProfileProvider extends ChangeNotifier {
  final HifzDatabaseService _db;
  final AuthService _auth;
  final CloudSyncService _sync;
  final WritePathStore? _writePathStore;

  MemoryProfile? _activeProfile;
  List<MemoryProfile> _allProfiles = [];
  StreakData _streakData = const StreakData();
  bool _isLoading = true;

  int _profileGen = 0;
  bool _disposed = false;

  HifzProfileProvider(
    this._db,
    this._auth,
    this._sync, {
    WritePathStore? writePathStore,
  }) : _writePathStore = writePathStore {
    unawaited(_init());
  }

  bool _isCurrent(int generation) => !_disposed && generation == _profileGen;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ── Getters ──

  /// Whether a hifz profile exists and is active.
  bool get hasActiveProfile => _activeProfile != null;

  /// The currently active profile (null if none).
  MemoryProfile? get activeProfile => _activeProfile;

  /// All profiles on this device.
  List<MemoryProfile> get allProfiles => _allProfiles;

  /// Streak data for the active profile.
  StreakData get streak => _streakData;

  /// Whether initial load is still happening.
  bool get isLoading => _isLoading;

  /// Number of profiles.
  int get profileCount => _allProfiles.length;

  // ── Initialization ──

  Future<void> _init() async {
    final generation = ++_profileGen;
    try {
      final profiles = await _db.getAllProfiles();
      if (!_isCurrent(generation)) return;
      var activeProfile = await _db.getActiveProfile();
      if (!_isCurrent(generation)) return;

      if (activeProfile == null && profiles.isNotEmpty) {
        await _db.switchProfile(profiles.first.id);
        if (!_isCurrent(generation)) return;
        activeProfile = profiles.first;
      }

      var streak = const StreakData();
      if (activeProfile != null) {
        streak = await _db.getStreak(activeProfile.id);
        if (!_isCurrent(generation)) return;
      }

      _allProfiles = profiles;
      _activeProfile = activeProfile;
      _streakData = streak;
    } catch (error) {
      AppLogger.info('HifzProfile', 'Profile initialization failed: $error');
    } finally {
      if (_isCurrent(generation)) {
        _isLoading = false;
        _safeNotify();
      }
    }
  }

  // ── Profile CRUD ──

  /// Create a new profile and set it as active.
  Future<void> createProfile(MemoryProfile profile) async {
    final generation = ++_profileGen;
    await _db.createProfile(profile);
    if (!_isCurrent(generation)) return;
    final profiles = await _db.getAllProfiles();
    if (!_isCurrent(generation)) return;
    _activeProfile = profile;
    _allProfiles = profiles;
    _streakData = const StreakData();
    _safeNotify();
  }

  /// Switch to a different profile.
  Future<void> switchProfile(String profileId) async {
    final gen = ++_profileGen;
    await _db.switchProfile(profileId);
    if (gen != _profileGen) return;
    _activeProfile = await _db.getActiveProfile();
    if (gen != _profileGen) return;
    if (_activeProfile != null) {
      _streakData = await _db.getStreak(_activeProfile!.id);
      if (gen != _profileGen) return;
    }
    _safeNotify();
  }

  /// Update the active profile's settings.
  Future<void> updateProfile(MemoryProfile updatedProfile) async {
    final generation = ++_profileGen;
    await _db.updateProfile(updatedProfile);
    if (!_isCurrent(generation)) return;
    final profiles = await _db.getAllProfiles();
    if (!_isCurrent(generation)) return;
    if (_activeProfile?.id == updatedProfile.id) {
      _activeProfile = updatedProfile;
    }
    _allProfiles = profiles;
    _safeNotify();

    // Cloud sync (fire-and-forget)
    if (_auth.isSignedIn) {
      unawaited(_sync.syncProfile(_auth.uid!, updatedProfile));
    }
  }

  /// Delete a profile. If it's the active one, try to activate another.
  Future<void> deleteProfile(String profileId) async {
    final generation = ++_profileGen;
    await _db.deleteProfile(profileId);
    if (!_isCurrent(generation)) return;
    final profiles = await _db.getAllProfiles();
    if (!_isCurrent(generation)) return;
    _allProfiles = profiles;
    if (_activeProfile?.id == profileId) {
      if (_allProfiles.isNotEmpty) {
        await _db.switchProfile(_allProfiles.first.id);
        if (!_isCurrent(generation)) return;
        _activeProfile = _allProfiles.first;
        _streakData = await _db.getStreak(_activeProfile!.id);
        if (!_isCurrent(generation)) return;
      } else {
        _activeProfile = null;
        _streakData = const StreakData();
      }
    }
    _safeNotify();
  }

  // ── Streak ──

  /// Record today as an active day for the current profile.
  Future<void> recordActiveDay() async {
    final profile = _activeProfile;
    if (profile == null) return;
    final generation = ++_profileGen;
    await _db.recordActiveDay(profile.id);
    if (!_isCurrent(generation)) return;
    final streak = await _db.getStreak(profile.id);
    if (!_isCurrent(generation)) return;
    _streakData = streak;
    _safeNotify();

    // Legacy cloud sync (fire-and-forget) — skipped for "facts" users.
    // NOTE: a standalone active-day has no fact kind in the §5 contract
    // (streak is derived from session facts); for facts users this event
    // stays in the optimistic local counter only.
    if (_auth.isSignedIn &&
        !(_writePathStore?.isFactsUser(_auth.uid) ?? false)) {
      unawaited(_sync.syncStreak(_auth.uid!, _streakData));
    }
  }

  /// Get missed days for the current profile (excluding rest days).
  Future<int> getMissedDays() async {
    if (_activeProfile == null) return 0;
    return _db.getMissedDays(
      _activeProfile!.id,
      activeDays: _activeProfile!.activeDays,
    );
  }

  // ── Convenience ──

  /// Refresh all data from the database.
  Future<void> refresh() async {
    final generation = ++_profileGen;
    final profiles = await _db.getAllProfiles();
    if (!_isCurrent(generation)) return;
    final activeProfile = await _db.getActiveProfile();
    if (!_isCurrent(generation)) return;
    var streak = const StreakData();
    if (activeProfile != null) {
      streak = await _db.getStreak(activeProfile.id);
      if (!_isCurrent(generation)) return;
    }
    _allProfiles = profiles;
    _activeProfile = activeProfile;
    _streakData = streak;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _profileGen++;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
