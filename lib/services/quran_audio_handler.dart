import 'package:audio_service/audio_service.dart';

/// A [BaseAudioHandler] that bridges Android/iOS media notifications
/// (lock screen, notification shade, Android Auto) to our [AudioProvider].
///
/// This handler does NOT play audio itself — it delegates every action
/// to [AudioProvider] via callbacks set at runtime.
class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  // ── Callbacks set by AudioProvider ──────────────────────────────
  Future<void> Function()? onPlay;
  Future<void> Function()? onPause;
  Future<void> Function()? onSkipToNext;
  Future<void> Function()? onSkipToPrevious;
  Future<void> Function(Duration position)? onSeek;
  Future<void> Function()? onStop;

  QuranAudioHandler() {
    // Start with an idle playback state
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  // ── Media session actions (called from notification / lock screen) ──

  @override
  Future<void> play() async {
    await onPlay?.call();
  }

  @override
  Future<void> pause() async {
    await onPause?.call();
  }

  @override
  Future<void> skipToNext() async {
    await onSkipToNext?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    await onSkipToPrevious?.call();
  }

  @override
  Future<void> seek(Duration position) async {
    await onSeek?.call(position);
  }

  @override
  Future<void> stop() async {
    await onStop?.call();
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
    await super.stop();
  }

  // ── Called by AudioProvider to keep notification in sync ─────────

  /// Update the media item shown in the notification (surah name, reciter, art).
  void setMediaMetadata({
    required String surahName,
    required String reciterName,
    Uri? artUri,
    Duration duration = Duration.zero,
  }) {
    mediaItem.add(
      MediaItem(
        id: surahName,
        title: surahName,
        artist: reciterName,
        artUri: artUri,
        duration: duration,
      ),
    );
  }

  /// Update the playback state shown in the notification.
  void updatePlaybackState({
    required bool playing,
    required Duration position,
    Duration bufferedPosition = Duration.zero,
    AudioProcessingState processingState = AudioProcessingState.ready,
  }) {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: playing,
        updatePosition: position,
        bufferedPosition: bufferedPosition,
      ),
    );
  }
}
