import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/models/hifz_models.dart';

/// Manages memorization state for all 114 surahs.
/// Persists data via SharedPreferences.
class HifzProvider extends ChangeNotifier {
  static const _keyPrefix = 'hifz_surah_';
  static const _keyStreak = 'hifz_streak';
  static const _keyLongestStreak = 'hifz_longest_streak';
  static const _keyLastActiveDay = 'hifz_last_active_day';

  final SharedPreferences _prefs;

  // In-memory cache of all 114 surah records
  final Map<int, MemorizationRecord> _records = {};

  // Streak
  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastActiveDay;

  HifzProvider(this._prefs) {
    _loadFromPrefs();
  }

  // ── Getters ──

  MemorizationRecord getRecord(int surahId) {
    return _records[surahId] ?? MemorizationRecord(surahId: surahId);
  }

  List<MemorizationRecord> get allRecords {
    return List.generate(114, (i) => getRecord(i + 1));
  }

  /// Surahs currently being learned (Sabaq)
  List<MemorizationRecord> get sabaqSurahs =>
      allRecords.where((r) => r.status == HifzStatus.learning).toList();

  /// Surahs recently memorized, needing review (Sabqi)
  List<MemorizationRecord> get sabqiSurahs =>
      allRecords.where((r) => r.status == HifzStatus.reviewing).toList();

  /// Solidly memorized surahs (Manzil)
  List<MemorizationRecord> get manzilSurahs =>
      allRecords.where((r) => r.status == HifzStatus.memorized).toList();

  int get totalMemorized =>
      allRecords.where((r) => r.status != HifzStatus.none).length;

  double get overallProgress => totalMemorized / 114.0;

  StreakData get streak => StreakData(
    currentStreak: _currentStreak,
    longestStreak: _longestStreak,
    lastActiveDay: _lastActiveDay,
  );

  // ── Mutations ──

  /// Set the memorization status for a surah.
  void setStatus(int surahId, HifzStatus status) {
    final existing = getRecord(surahId);
    _records[surahId] = existing.copyWith(status: status);
    _saveRecord(surahId);
    notifyListeners();
  }

  /// Mark a surah as reviewed today.
  void markReviewed(int surahId) {
    final existing = getRecord(surahId);
    _records[surahId] = existing.copyWith(
      lastReviewed: DateTime.now(),
      reviewCount: existing.reviewCount + 1,
    );
    _saveRecord(surahId);
    _updateStreak();
    notifyListeners();
  }

  /// Cycle through statuses: none → learning → reviewing → memorized → none
  void cycleStatus(int surahId) {
    final current = getRecord(surahId).status;
    final nextIndex = (current.index + 1) % HifzStatus.values.length;
    setStatus(surahId, HifzStatus.values[nextIndex]);
  }

  // ── Persistence ──

  void _loadFromPrefs() {
    for (int i = 1; i <= 114; i++) {
      final data = _prefs.getString('$_keyPrefix$i');
      if (data != null) {
        _records[i] = MemorizationRecord.fromStorageString(i, data);
      }
    }
    _currentStreak = _prefs.getInt(_keyStreak) ?? 0;
    _longestStreak = _prefs.getInt(_keyLongestStreak) ?? 0;
    final lastMs = _prefs.getInt(_keyLastActiveDay);
    _lastActiveDay = lastMs != null
        ? DateTime.fromMillisecondsSinceEpoch(lastMs)
        : null;
  }

  void _saveRecord(int surahId) {
    final record = getRecord(surahId);
    _prefs.setString('$_keyPrefix$surahId', record.toStorageString());
  }

  void _updateStreak() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (_lastActiveDay != null) {
      final lastDate = DateTime(
        _lastActiveDay!.year,
        _lastActiveDay!.month,
        _lastActiveDay!.day,
      );
      final diff = todayDate.difference(lastDate).inDays;
      if (diff == 0) {
        // Already counted today
        return;
      } else if (diff == 1) {
        _currentStreak++;
      } else {
        _currentStreak = 1; // Reset streak
      }
    } else {
      _currentStreak = 1;
    }

    _lastActiveDay = todayDate;
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }

    _prefs.setInt(_keyStreak, _currentStreak);
    _prefs.setInt(_keyLongestStreak, _longestStreak);
    _prefs.setInt(_keyLastActiveDay, todayDate.millisecondsSinceEpoch);
  }
}
