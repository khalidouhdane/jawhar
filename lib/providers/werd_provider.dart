import 'package:flutter/material.dart';
import 'package:quran_app/models/werd_models.dart';
import 'package:quran_app/services/local_storage_service.dart';

/// Manages the daily recitation (werd) state and persistence.
class WerdProvider extends ChangeNotifier {
  final LocalStorageService _storage;
  WerdConfig? _config;

  WerdProvider(this._storage) {
    _load();
  }

  /// Current werd configuration, or null if not set.
  WerdConfig? get config => _config;

  /// Whether the user has a werd configured.
  bool get hasWerd => _config != null && _config!.isEnabled;

  /// Load from storage and auto-reset if the day has changed.
  void _load() {
    _config = _storage.getWerdConfig();
    if (_config != null) {
      _autoResetIfNewDay();
    }
  }

  /// If the last reset was on a previous day, reset today's progress.
  void _autoResetIfNewDay() {
    if (_config == null) return;
    final now = DateTime.now();
    final last = _config!.lastResetDate;
    if (now.year != last.year ||
        now.month != last.month ||
        now.day != last.day) {
      _config = _config!.copyWith(pagesReadToday: 0, lastResetDate: now);
      _storage.saveWerdConfig(_config!);
    }
  }

  /// Save a new or updated werd configuration.
  void updateWerd(WerdConfig newConfig) {
    _config = newConfig;
    _storage.saveWerdConfig(newConfig);
    notifyListeners();
  }

  /// Increment today's pages-read counter.
  void incrementProgress([int pages = 1]) {
    if (_config == null) return;
    _config = _config!.copyWith(
      pagesReadToday: _config!.pagesReadToday + pages,
    );
    _storage.saveWerdConfig(_config!);
    notifyListeners();
  }

  /// Disable the werd without deleting it (can be re-enabled).
  void disableWerd() {
    if (_config == null) return;
    _config = _config!.copyWith(isEnabled: false);
    _storage.saveWerdConfig(_config!);
    notifyListeners();
  }

  /// Re-enable the werd.
  void enableWerd() {
    if (_config == null) return;
    _config = _config!.copyWith(isEnabled: true);
    _storage.saveWerdConfig(_config!);
    notifyListeners();
  }

  /// Remove the werd entirely.
  void resetWerd() {
    _config = null;
    _storage.clearWerdConfig();
    notifyListeners();
  }
}
