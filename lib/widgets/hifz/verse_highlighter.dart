import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/providers/audio_provider.dart';

/// Audio helper utilities for Hifz session reading mode (Phase 4).
///
/// Verse-level highlighting is already handled by [ReadingCanvas]:
/// it checks `AudioProvider.activeVerseKey` and applies a highlight
/// background color automatically. This class provides convenience
/// methods to start and control audio playback scoped to the session's
/// assigned content.
///
/// Usage:
/// ```dart
/// SessionAudioHelper.playPageAudio(audioProvider, verses);
/// SessionAudioHelper.playFromVerse(audioProvider, verses, 'Al-Baqarah:5');
/// ```
class SessionAudioHelper {
  SessionAudioHelper._(); // Prevent instantiation

  /// Start audio playback for all verses on the assigned page.
  ///
  /// Calls [AudioProvider.playVerseList] starting from the first verse,
  /// which loads the full chapter audio and seeks to the correct position.
  /// The [ReadingCanvas] will automatically highlight the active verse.
  static Future<void> playPageAudio(
    AudioProvider audioProvider,
    List<Verse> verses,
  ) async {
    if (verses.isEmpty) return;
    await audioProvider.playVerseList(verses, startIndex: 0);
  }

  /// Start audio playback from a specific verse key (e.g. "2:5").
  ///
  /// Finds the verse in the list and starts playback from there.
  /// Falls back to the first verse if the key is not found.
  static Future<void> playFromVerse(
    AudioProvider audioProvider,
    List<Verse> verses,
    String verseKey,
  ) async {
    if (verses.isEmpty) return;

    final index = verses.indexWhere((v) => v.verseKey == verseKey);
    await audioProvider.playVerseList(
      verses,
      startIndex: index >= 0 ? index : 0,
    );
  }

  /// Toggle audio play/pause.
  ///
  /// If no audio is loaded yet, starts playback from the first verse
  /// of the provided verse list. Otherwise toggles the current state.
  static Future<void> togglePlayPause(
    AudioProvider audioProvider,
    List<Verse> verses,
  ) async {
    if (audioProvider.activeVerseKey == null && verses.isNotEmpty) {
      await playPageAudio(audioProvider, verses);
    } else {
      await audioProvider.togglePlay();
    }
  }

  /// Check if audio is currently playing a verse on the given page.
  ///
  /// Returns true if [AudioProvider.activeVerseKey] matches any verse
  /// in the provided list.
  static bool isPlayingOnPage(
    AudioProvider audioProvider,
    List<Verse> verses,
  ) {
    final activeKey = audioProvider.activeVerseKey;
    if (activeKey == null) return false;
    return verses.any((v) => v.verseKey == activeKey);
  }
}
