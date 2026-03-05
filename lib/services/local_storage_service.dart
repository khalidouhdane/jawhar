import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/models/werd_models.dart';

/// Persists user reading state using SharedPreferences.
class LocalStorageService {
  static const _keyLastPage = 'last_read_page';
  static const _keyLastSurah = 'last_read_surah';
  static const _keyLastVerseKey = 'last_read_verse_key';
  static const _keyLastTimestamp = 'last_read_timestamp';
  static const _keyHasReadingHistory = 'has_reading_history';
  static const _keyWerdConfig = 'werd_config';
  static const _keyRewaya = 'user_rewaya';
  static const _keyOnboardingComplete = 'onboarding_complete';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  /// Save the user's current reading position.
  void saveLastRead({
    required int page,
    required String surahName,
    String? verseKey,
  }) {
    _prefs.setInt(_keyLastPage, page);
    _prefs.setString(_keyLastSurah, surahName);
    if (verseKey != null) _prefs.setString(_keyLastVerseKey, verseKey);
    _prefs.setInt(_keyLastTimestamp, DateTime.now().millisecondsSinceEpoch);
    _prefs.setBool(_keyHasReadingHistory, true);
  }

  /// Returns the last read position, or null if none saved.
  LastReadPosition? getLastRead() {
    final page = _prefs.getInt(_keyLastPage);
    final surah = _prefs.getString(_keyLastSurah);
    if (page == null || surah == null) return null;

    return LastReadPosition(
      page: page,
      surahName: surah,
      verseKey: _prefs.getString(_keyLastVerseKey),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        _prefs.getInt(_keyLastTimestamp) ?? 0,
      ),
    );
  }

  /// Whether the user has ever read something.
  bool get hasReadingHistory => _prefs.getBool(_keyHasReadingHistory) ?? false;

  // ── Rewaya (Qira'at) Preference ──

  /// Save the user's preferred rewaya (1 = Hafs, 2 = Warsh).
  void saveRewaya(int rewaya) => _prefs.setInt(_keyRewaya, rewaya);

  /// Returns the saved rewaya, or null if not yet set.
  int? get savedRewaya => _prefs.getInt(_keyRewaya);

  // ── Onboarding ──

  /// Whether the user has completed the onboarding flow.
  bool get hasCompletedOnboarding =>
      _prefs.getBool(_keyOnboardingComplete) ?? false;

  /// Mark onboarding as complete.
  void setOnboardingComplete() => _prefs.setBool(_keyOnboardingComplete, true);

  // ── Werd (Daily Recitation) ──

  /// Save the user's werd configuration.
  void saveWerdConfig(WerdConfig config) {
    _prefs.setString(_keyWerdConfig, config.encode());
  }

  /// Returns the saved werd configuration, or null if none set.
  WerdConfig? getWerdConfig() {
    return WerdConfig.decode(_prefs.getString(_keyWerdConfig));
  }

  /// Clear the saved werd configuration.
  void clearWerdConfig() {
    _prefs.remove(_keyWerdConfig);
  }
}

/// Simple data class for last read position.
class LastReadPosition {
  final int page;
  final String surahName;
  final String? verseKey;
  final DateTime timestamp;

  const LastReadPosition({
    required this.page,
    required this.surahName,
    this.verseKey,
    required this.timestamp,
  });

  /// Friendly time description (e.g. "2 hours ago", "Yesterday").
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }

  /// Localized version of timeAgo using app localizations.
  String timeAgoLocalized(dynamic l) {
    final diff = DateTime.now().difference(timestamp);
    try {
      if (diff.inMinutes < 1) return l.t('home_just_now');
      if (diff.inMinutes < 60) return '${diff.inMinutes}${l.t('home_min_ago')}';
      if (diff.inHours < 24) return '${diff.inHours}${l.t('home_hour_ago')}';
      if (diff.inDays == 1) return l.t('home_yesterday');
      return '${diff.inDays} ${l.t('home_days_ago')}';
    } catch (_) {
      return timeAgo;
    }
  }
}
