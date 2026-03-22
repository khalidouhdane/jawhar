import 'package:flutter/material.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/services/hifz_database_service.dart';

/// Manages the active Hifz profile and profile CRUD operations.
/// Replaces the old HifzProvider (which tracked surah-level progress).
class HifzProfileProvider extends ChangeNotifier {
  final HifzDatabaseService _db;

  MemoryProfile? _activeProfile;
  List<MemoryProfile> _allProfiles = [];
  StreakData _streakData = const StreakData();
  bool _isLoading = true;

  HifzProfileProvider(this._db) {
    _init();
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
    _allProfiles = await _db.getAllProfiles();
    _activeProfile = await _db.getActiveProfile();

    // Auto-recovery: if profiles exist but none is marked active,
    // activate the first one. This handles edge cases where isActive
    // was cleared by a failed operation (e.g. delete crashed mid-way).
    if (_activeProfile == null && _allProfiles.isNotEmpty) {
      await _db.switchProfile(_allProfiles.first.id);
      _activeProfile = _allProfiles.first;
    }

    if (_activeProfile != null) {
      _streakData = await _db.getStreak(_activeProfile!.id);
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Profile CRUD ──

  /// Create a new profile and set it as active.
  Future<void> createProfile(MemoryProfile profile) async {
    await _db.createProfile(profile);
    _activeProfile = profile;
    _allProfiles = await _db.getAllProfiles();
    _streakData = const StreakData();
    notifyListeners();
  }

  /// Switch to a different profile.
  Future<void> switchProfile(String profileId) async {
    await _db.switchProfile(profileId);
    _activeProfile = await _db.getActiveProfile();
    if (_activeProfile != null) {
      _streakData = await _db.getStreak(_activeProfile!.id);
    }
    notifyListeners();
  }

  /// Update the active profile's settings.
  Future<void> updateProfile(MemoryProfile updatedProfile) async {
    await _db.updateProfile(updatedProfile);
    if (_activeProfile?.id == updatedProfile.id) {
      _activeProfile = updatedProfile;
    }
    _allProfiles = await _db.getAllProfiles();
    notifyListeners();
  }

  /// Delete a profile. If it's the active one, try to activate another.
  Future<void> deleteProfile(String profileId) async {
    await _db.deleteProfile(profileId);
    _allProfiles = await _db.getAllProfiles();
    if (_activeProfile?.id == profileId) {
      if (_allProfiles.isNotEmpty) {
        await _db.switchProfile(_allProfiles.first.id);
        _activeProfile = _allProfiles.first;
        _streakData = await _db.getStreak(_activeProfile!.id);
      } else {
        _activeProfile = null;
        _streakData = const StreakData();
      }
    }
    notifyListeners();
  }

  // ── Streak ──

  /// Record today as an active day for the current profile.
  Future<void> recordActiveDay() async {
    if (_activeProfile == null) return;
    await _db.recordActiveDay(_activeProfile!.id);
    _streakData = await _db.getStreak(_activeProfile!.id);
    notifyListeners();
  }

  /// Get missed days for the current profile.
  Future<int> getMissedDays() async {
    if (_activeProfile == null) return 0;
    return _db.getMissedDays(_activeProfile!.id);
  }

  // ── Convenience ──

  /// Refresh all data from the database.
  Future<void> refresh() async {
    _allProfiles = await _db.getAllProfiles();
    _activeProfile = await _db.getActiveProfile();
    if (_activeProfile != null) {
      _streakData = await _db.getStreak(_activeProfile!.id);
    }
    notifyListeners();
  }
}
