import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:just_audio/just_audio.dart' as ja;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/services/api_client.dart';
import 'package:quran_app/services/quran_audio_handler.dart';
import 'package:quran_app/services/mp3quran_service.dart';
import 'package:quran_app/services/audio_proxy_server.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:quran_app/utils/app_logger.dart';
import 'package:quran_app/utils/verse_ref_formatter.dart';

/// Repeat mode for audio playback
enum AudioRepeatMode { none, repeatVerse, repeatRange }

/// Quality of audio-verse synchronization for the current reciter.
enum AudioSyncQuality {
  /// Full timing data with accurate position reporting
  perfect,

  /// Timing data available but drift correction is active
  corrected,

  /// No timing data — verse highlighting disabled
  unavailable,
}

/// Audio playback using full chapter audio with verse timing data.
/// Plays the complete chapter mp3 and seeks to exact verse positions
/// using timestamp data from the API. This gives truly gapless playback
/// since it's a single continuous audio file.
///
/// Tracks the active verse by verseKey (e.g., "2:5") so highlighting
/// works across page boundaries without needing the page's verse list.
class AudioProvider extends ChangeNotifier {
  final ja.AudioPlayer _player = ja.AudioPlayer(
    useProxyForRequestHeaders: false,
  );
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _disposed = false;

  int _audioOffsetMs = 0;
  int get audioOffsetMs => _audioOffsetMs;

  Future<void> _loadSavedOffset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _audioOffsetMs = prefs.getInt('audio_offset_ms') ?? 0;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setAudioOffset(int offsetMs) async {
    if (_audioOffsetMs == offsetMs) return;
    _audioOffsetMs = offsetMs;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('audio_offset_ms', offsetMs);
    } catch (_) {}
  }

  /// Static end-time overrides for reciter/surah/verses with known
  /// database alignment errors. These should not move the seek start.
  static const Map<String, int> _timingEndOverrides = {
    '174:2:10': 1500, // Yasser Al-Dosari Surah 2 Verse 10 finishes 1.5s late.
  };

  static const int _androidSeekLeadInMs = 0;

  bool get _shouldProxy => Platform.isWindows;

  Future<void> initProxy() async {
    if (_shouldProxy) {
      await AudioProxyServer().start();
    }
  }

  /// Reference to the media notification handler.
  QuranAudioHandler? _audioHandler;

  /// Attach the audio handler (called once from main.dart).
  void attachAudioHandler(QuranAudioHandler handler) {
    _audioHandler = handler;
    handler.onPlay = () => togglePlay();
    handler.onPause = () => togglePlay();
    handler.onSkipToNext = () => skipToNextVerse();
    handler.onSkipToPrevious = () => skipToPreviousVerse();
    handler.onSeek = (pos) async {
      if (_activeVerseKey == null) return;
      final gen = _generation;
      await _seekIfCurrent(pos, gen);
    };
    handler.onStop = () => stop();
  }

  bool _isPlaying = false;
  String? _activeVerseKey; // e.g., "2:5" — works across pages
  int _reciterId = 7; // Default: Mishary Rashid Alafasy
  String _reciterName = "Mishary Rashid Alafasy";
  ApiSource _apiSource = ApiSource.quranDotCom;
  String? _serverUrl;
  int? _moshafId;

  bool _isIsolated = false;
  int? _isolatedEndTimeMs;

  final Mp3QuranService _mp3QuranService = Mp3QuranService();

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  /// Generation counter: incremented on every new play/setReciter call.
  /// If a callback sees _generation != its captured value, it aborts.
  int _generation = 0;

  // Playback speed
  double _playbackSpeed = 1.0;

  // Repeat mode
  AudioRepeatMode _repeatMode = AudioRepeatMode.none;
  String? _repeatRangeStart; // e.g., "2:1"
  String? _repeatRangeEnd; // e.g., "2:5"
  int _repeatCount = 0; // 0 = infinite
  int _currentRepeatIteration = 0;

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration {
    if (_verseTimings.isNotEmpty) {
      final timingDuration = Duration(
        milliseconds: _verseTimings.last.timestampTo,
      );
      // Use true timing duration if it's larger than player's buffered duration
      if (timingDuration > _totalDuration) {
        return timingDuration;
      }
    }
    return _totalDuration;
  }

  String? get activeVerseKey => _activeVerseKey;
  int get reciterId => _reciterId;
  String get reciterName => _reciterName;
  ApiSource get apiSource => _apiSource;
  String? get serverUrl => _serverUrl;
  double get playbackSpeed => _playbackSpeed;
  AudioRepeatMode get repeatMode => _repeatMode;
  String? get repeatRangeStart => _repeatRangeStart;
  String? get repeatRangeEnd => _repeatRangeEnd;
  int get repeatCount => _repeatCount;

  /// Whether verse-level timing data is available for the current chapter/reciter.
  /// When false, audio plays but verse highlighting cannot track position.
  bool get hasVerseTimings => _verseTimings.isNotEmpty;

  /// Current sync quality based on timing availability.
  AudioSyncQuality get syncQuality {
    if (_verseTimings.isEmpty) return AudioSyncQuality.unavailable;
    return AudioSyncQuality.perfect;
  }

  // Chapter audio data

  int? _currentChapter;
  List<_VerseTiming> _verseTimings = [];
  bool _isLoading = false;
  bool _isSeeking =
      false; // Guard: prevents onPositionChanged from overriding _activeVerseKey during seek
  String? _seekLockVerseKey;
  int? _seekLockUntilMs;

  // Cache: "reciterId:chapter" -> { audioUrl, timings }
  final Map<String, _ChapterAudioData> _chapterCache = {};

  AudioProvider() {
    unawaited(_loadSavedOffset());

    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        if (_isSeeking) return;
        final playing =
            state.playing &&
            state.processingState != ja.ProcessingState.completed;
        if (_isPlaying != playing) {
          _isPlaying = playing;
          _syncNotificationState();
          notifyListeners();
        }
      }),
    );

    _subscriptions.add(
      _player.positionStream.listen((position) {
        _currentPosition = position;

        // While seeking to a target verse, don't let intermediate positions
        // override _activeVerseKey — this prevents the wrong-verse flash.
        if (_isSeeking) {
          notifyListeners();
          return;
        }

        if (_seekLockVerseKey != null && _seekLockUntilMs != null) {
          if (position.inMilliseconds < _seekLockUntilMs!) {
            if (_activeVerseKey != _seekLockVerseKey) {
              _activeVerseKey = _seekLockVerseKey;
              _syncNotificationMetadata();
            }
            notifyListeners();
            return;
          }
          _seekLockVerseKey = null;
          _seekLockUntilMs = null;
        }

        if (_isIsolated && _isolatedEndTimeMs != null) {
          final posMs = position.inMilliseconds;
          if (posMs >= _isolatedEndTimeMs!) {
            unawaited(_player.pause());
            _isIsolated = false;
            _isolatedEndTimeMs = null;
            _isPlaying = false;
            _activeVerseKey = null;
            _syncNotificationState();
            notifyListeners();
            return;
          }
        }

        // Update active verse based on current position using timing data
        if (_verseTimings.isNotEmpty) {
          final posMs = position.inMilliseconds - _audioOffsetMs;

          String? newKey;

          // Reverse scan: find the last timing whose start is <= current position
          for (int i = _verseTimings.length - 1; i >= 0; i--) {
            final t = _verseTimings[i];
            if (posMs >= t.firstSegmentMs) {
              newKey = t.verseKey;
              break;
            }
          }

          if (newKey != null && newKey != _activeVerseKey) {
            final oldKey = _activeVerseKey;
            _activeVerseKey = newKey;

            _syncNotificationMetadata();

            // Handle repeat mode when verse changes
            unawaited(_handleRepeat(oldKey, newKey, posMs));
          }
        }

        notifyListeners();
      }),
    );

    _subscriptions.add(
      _player.durationStream.listen((duration) {
        if (duration == null) return;
        _totalDuration = duration;
        final shift = _applyBismillahCorrectionIfNeeded(duration);
        if (shift != null) {
          // Shift playhead to match the corrected timeline
          final gen = _generation;
          final newPos = _player.position + Duration(milliseconds: shift);
          unawaited(
            _seekIfCurrent(
              newPos < Duration.zero ? Duration.zero : newPos,
              gen,
            ),
          );
        }
        notifyListeners();
      }),
    );

    _subscriptions.add(
      _player.processingStateStream.listen((state) {
        if (state != ja.ProcessingState.completed) return;
        if (_isSeeking) return;
        _activeVerseKey = null;
        _isPlaying = false;
        _isIsolated = false;
        _isolatedEndTimeMs = null;
        _syncNotificationState();
        notifyListeners();
      }),
    );
  }

  /// Handle repeat logic when the active verse changes
  Future<void> _handleRepeat(String? oldKey, String newKey, int posMs) async {
    final gen = _generation;
    if (_repeatMode == AudioRepeatMode.repeatVerse && oldKey != null) {
      // Repeat single verse: re-seek to the old verse's start
      final oldTiming = _findTiming(oldKey);
      if (oldTiming != null && newKey != oldKey) {
        if (_repeatCount == 0 || _currentRepeatIteration < _repeatCount - 1) {
          _currentRepeatIteration++;
          _activeVerseKey = oldKey;
          final seekPosMs = oldTiming.firstSegmentMs + _audioOffsetMs;
          await _seekIfCurrent(Duration(milliseconds: seekPosMs), gen);
          return;
        } else {
          // Exhausted repeats, reset and continue
          _currentRepeatIteration = 0;
        }
      }
    } else if (_repeatMode == AudioRepeatMode.repeatRange &&
        _repeatRangeStart != null &&
        _repeatRangeEnd != null) {
      // Check if we just passed the end of the range
      final endTiming = _findTiming(_repeatRangeEnd!);
      if (endTiming != null && posMs >= endTiming.timestampTo) {
        if (_repeatCount == 0 || _currentRepeatIteration < _repeatCount - 1) {
          _currentRepeatIteration++;
          final startTiming = _findTiming(_repeatRangeStart!);
          if (startTiming != null) {
            _activeVerseKey = _repeatRangeStart;
            final rangeSeekPosMs = startTiming.firstSegmentMs + _audioOffsetMs;
            await _seekIfCurrent(Duration(milliseconds: rangeSeekPosMs), gen);
            return;
          }
        } else {
          _currentRepeatIteration = 0;
        }
      }
    }
  }

  Future<bool> _seekIfCurrent(Duration position, int generation) async {
    if (_disposed || generation != _generation) return false;
    await _player.seek(position);
    return !_disposed && generation == _generation;
  }

  void updateReciterName(String newName) {
    if (_reciterName != newName) {
      _reciterName = newName;
      notifyListeners();
    }
  }

  void setReciter(
    int reciterId, {
    String? name,
    ApiSource apiSource = ApiSource.quranDotCom,
    String? serverUrl,
    int? moshafId,
  }) async {
    if (_reciterId == reciterId) return;

    // Cancel any in-flight operation
    final gen = ++_generation;
    _currentRepeatIteration = 0;
    _reciterId = reciterId;
    _apiSource = apiSource;
    _serverUrl = serverUrl;
    _moshafId = moshafId;
    if (name != null) _reciterName = name;

    // Clear cache for MP3Quran when switching source type
    _chapterCache.clear();

    // If playing, restart with new reciter from current verse
    if (_activeVerseKey != null && _currentChapter != null) {
      final savedKey = _activeVerseKey!;
      final savedChapter = _currentChapter!;

      _isSeeking = true;
      _isLoading = true;
      await _player.stop();
      _isPlaying = false;
      notifyListeners();

      // Fetch new reciter's chapter audio
      final data = await _fetchChapterAudio(savedChapter);
      if (gen != _generation) return; // cancelled
      if (data == null) {
        _isSeeking = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _verseTimings = List<_VerseTiming>.from(data.timings);

      final finalUrl = _shouldProxy
          ? AudioProxyServer().proxyUrl(data.audioUrl)
          : data.audioUrl;
      await _setSourceUrl(finalUrl);
      if (gen != _generation) return; // cancelled

      final duration = await _getOrWaitForDuration();
      if (duration != null && gen == _generation) {
        _totalDuration = duration;
        _applyBismillahCorrectionIfNeeded(duration);
      }

      // Find timing for current verse and seek
      final timing = _findTiming(savedKey);
      if (timing != null) {
        _activeVerseKey = savedKey;
        await _player.setSpeed(_playbackSpeed);

        if (timing.firstSegmentMs > 0) {
          await _preciseSeekAndPlay(
            timing.firstSegmentMs,
            gen,
            verseKey: timing.verseKey,
          );
          if (gen != _generation) return;
        } else {
          await _player.setVolume(1.0);
          await _startPlayback();
          if (gen != _generation) return;
        }

        _isSeeking = false;
        _isLoading = false;
        _isPlaying = true;
        notifyListeners();
      } else {
        // No timing for that verse — just load from start
        _activeVerseKey = null;
        _isSeeking = false;
        _isLoading = false;
        notifyListeners();
      }
    } else {
      _chapterCache.clear();
      notifyListeners();
    }
  }

  /// Set playback speed (0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player.setSpeed(speed);
    notifyListeners();
  }

  /// Set repeat mode
  void setRepeatMode(AudioRepeatMode mode) {
    _repeatMode = mode;
    _currentRepeatIteration = 0;
    notifyListeners();
  }

  /// Toggle repeat mode: none -> repeatVerse -> repeatRange -> none
  void toggleRepeatMode() {
    switch (_repeatMode) {
      case AudioRepeatMode.none:
        _repeatMode = AudioRepeatMode.repeatVerse;
        break;
      case AudioRepeatMode.repeatVerse:
        _repeatMode = AudioRepeatMode.none;
        break;
      case AudioRepeatMode.repeatRange:
        _repeatMode = AudioRepeatMode.none;
        break;
    }
    _currentRepeatIteration = 0;
    notifyListeners();
  }

  /// Set repeat range (from ayah to ayah)
  void setRepeatRange(String fromKey, String toKey, {int count = 0}) {
    _repeatRangeStart = fromKey;
    _repeatRangeEnd = toKey;
    _repeatCount = count;
    _repeatMode = AudioRepeatMode.repeatRange;
    _currentRepeatIteration = 0;
    notifyListeners();
  }

  /// Set repeat count (0 = infinite)
  void setRepeatCount(int count) {
    _repeatCount = count;
    _currentRepeatIteration = 0;
    notifyListeners();
  }

  /// Skip to the next verse
  Future<void> skipToNextVerse() async {
    if (_verseTimings.isEmpty || _activeVerseKey == null) return;

    final currentIndex = _verseTimings.indexWhere(
      (t) => t.verseKey == _activeVerseKey,
    );

    if (currentIndex < 0 || currentIndex >= _verseTimings.length - 1) return;

    final nextTiming = _verseTimings[currentIndex + 1];
    _activeVerseKey = nextTiming.verseKey;
    await _player.seek(
      Duration(milliseconds: nextTiming.firstSegmentMs + _audioOffsetMs),
    );
    notifyListeners();
  }

  /// Skip to the previous verse
  Future<void> skipToPreviousVerse() async {
    if (_verseTimings.isEmpty || _activeVerseKey == null) return;

    final currentIndex = _verseTimings.indexWhere(
      (t) => t.verseKey == _activeVerseKey,
    );

    if (currentIndex <= 0) return;

    final prevTiming = _verseTimings[currentIndex - 1];
    _activeVerseKey = prevTiming.verseKey;
    await _player.seek(
      Duration(milliseconds: prevTiming.firstSegmentMs + _audioOffsetMs),
    );
    notifyListeners();
  }

  /// Seek forward by N seconds
  Future<void> seekForward(int seconds) async {
    final newPos = _currentPosition + Duration(seconds: seconds);
    final clampedPos = newPos > _totalDuration ? _totalDuration : newPos;
    await _player.seek(clampedPos);
  }

  /// Seek backward by N seconds
  Future<void> seekBackward(int seconds) async {
    final newPos = _currentPosition - Duration(seconds: seconds);
    final clampedPos = newPos < Duration.zero ? Duration.zero : newPos;
    await _player.seek(clampedPos);
  }

  /// Seek to a specific position (0.0 - 1.0 fraction)
  Future<void> seekToFraction(double fraction) async {
    if (_totalDuration.inMilliseconds <= 0) return;
    final posMs = (fraction * _totalDuration.inMilliseconds).round();
    await _player.seek(Duration(milliseconds: posMs));
  }

  /// Fetch chapter audio data with verse timings
  Future<_ChapterAudioData?> _fetchChapterAudio(int chapterNumber) async {
    final cacheKey = '$_reciterId:$chapterNumber';
    if (_chapterCache.containsKey(cacheKey)) {
      return _chapterCache[cacheKey];
    }

    try {
      if (_apiSource == ApiSource.mp3Quran) {
        // MP3Quran fetch
        final paddedSurah = chapterNumber.toString().padLeft(3, '0');
        final audioUrl = '$_serverUrl$paddedSurah.mp3';
        List<_VerseTiming> timings = [];

        try {
          final timingData = await _mp3QuranService.getAyatTiming(
            _moshafId ?? _reciterId,
            chapterNumber,
          );
          final parsedTimings = <_VerseTiming>[];
          for (final t in timingData) {
            try {
              final ayah = t['ayah'];
              if (ayah == null) continue;
              final verseKey = '$chapterNumber:$ayah';
              int timestampFrom = (t['start_time'] as num).toInt();
              int timestampTo = (t['end_time'] as num).toInt();
              if (timestampFrom < 0 ||
                  timestampTo < 0 ||
                  timestampTo < timestampFrom) {
                continue;
              }
              final overrideKey = '$_reciterId:$verseKey';
              timestampTo += _timingEndOverrides[overrideKey] ?? 0;
              final duration = timestampTo - timestampFrom;
              parsedTimings.add(
                _VerseTiming(
                  verseKey: verseKey,
                  timestampFrom: timestampFrom,
                  timestampTo: timestampTo,
                  duration: duration,
                  firstSegmentMs: timestampFrom,
                ),
              );
            } catch (e) {
              AppLogger.warn(
                'Audio',
                '[MP3Quran] Skipping malformed timing entry: $e',
              );
            }
          }
          parsedTimings.sort(
            (a, b) => a.timestampFrom.compareTo(b.timestampFrom),
          );
          timings = parsedTimings;
        } catch (e) {
          AppLogger.info(
            'Audio',
            'No timing data found for MP3Quran reciter $_reciterId: $e',
          );
        }

        final data = _ChapterAudioData(audioUrl: audioUrl, timings: timings);
        _chapterCache[cacheKey] = data;
        return data;
      }

      // Quran.com fetch — uses ApiClient for timeout + retry
      final uri = Uri.parse(
        'https://apis.quran.foundation/content/api/v4/chapter_recitations/$_reciterId/$chapterNumber?segments=true',
      );

      final response = await ApiClient.get(
        uri,
        timeout: const Duration(seconds: 15),
        maxRetries: 2,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final audioFile = json['audio_file'];
        final audioUrl = audioFile['audio_url'] as String;
        final timestamps = audioFile['timestamps'] as List? ?? [];

        // Parse each timing entry independently so one malformed entry cannot
        // discard the whole chapter's timings (verse highlighting + repeat).
        final parsedTimings = <_VerseTiming>[];
        for (final t in timestamps) {
          try {
            final verseKey = t['verse_key'] as String;
            int timestampFrom = (t['timestamp_from'] as num).toInt();
            int timestampTo = (t['timestamp_to'] as num).toInt();
            final duration = (t['duration'] as num).toInt();
            if (timestampFrom < 0 ||
                timestampTo < 0 ||
                timestampTo < timestampFrom) {
              continue;
            }

            // Apply end-time override if defined.
            final overrideKey = '$_reciterId:$verseKey';
            timestampTo += _timingEndOverrides[overrideKey] ?? 0;

            int firstSegmentMs = timestampFrom;
            final segments = t['segments'] as List?;
            if (segments != null && segments.isNotEmpty) {
              final firstSegment = segments.first;
              if (firstSegment is List && firstSegment.length >= 2) {
                final segmentStart = firstSegment[1];
                if (segmentStart is num) {
                  firstSegmentMs = segmentStart.toInt();
                }
              }
            }

            parsedTimings.add(
              _VerseTiming(
                verseKey: verseKey,
                timestampFrom: timestampFrom,
                timestampTo: timestampTo,
                duration: duration,
                firstSegmentMs: firstSegmentMs,
              ),
            );
          } catch (e) {
            AppLogger.warn(
              'Audio',
              '[Quran.com] Skipping malformed timing entry: $e',
            );
          }
        }
        parsedTimings.sort(
          (a, b) => a.timestampFrom.compareTo(b.timestampFrom),
        );
        final timings = parsedTimings;

        // ── Diagnostic: Log timing accuracy for first 10 verses ──
        AppLogger.info(
          'AudioSync',
          '┌─── TIMING DIAGNOSTIC for chapter $chapterNumber, reciter $_reciterId ($_reciterName) ───',
        );
        AppLogger.info(
          'AudioSync',
          '│ Total verses with timing: ${timings.length}',
        );
        for (int i = 0; i < timings.length && i < 10; i++) {
          final t = timings[i];
          final delta = t.timestampFrom - t.firstSegmentMs;
          final gap = i > 0 ? t.firstSegmentMs - timings[i - 1].timestampTo : 0;
          AppLogger.info(
            'AudioSync',
            '│ ${t.verseKey.padRight(8)} '
                'tsFrom=${t.timestampFrom}ms  '
                'firstSeg=${t.firstSegmentMs}ms  '
                'delta=${delta}ms  '
                'tsTo=${t.timestampTo}ms  '
                'gap=${gap}ms',
          );
        }
        AppLogger.info('AudioSync', '└─── END TIMING DIAGNOSTIC ───');

        final data = _ChapterAudioData(audioUrl: audioUrl, timings: timings);

        _chapterCache[cacheKey] = data;
        return data;
      }
    } catch (e) {
      AppLogger.error('Audio', 'Error fetching chapter audio', e);
    }
    return null;
  }

  /// Find timing data for a verse key
  _VerseTiming? _findTiming(String verseKey) {
    for (final t in _verseTimings) {
      if (t.verseKey == verseKey) return t;
    }
    return null;
  }

  /// Play a list of verses starting from the given index.
  /// Loads the full chapter audio and seeks to the start verse.
  Future<void> playVerseList(List<Verse> verses, {int startIndex = 0}) async {
    if (verses.isEmpty) return;

    // Cancel any in-flight operation
    final gen = ++_generation;
    _currentRepeatIteration = 0;

    _isIsolated = false;
    _isolatedEndTimeMs = null;

    final startVerse = verses[startIndex];
    final chapterNumber = int.parse(startVerse.verseKey.split(':')[0]);

    // Immediately show loading & target verse, block position listener
    _isSeeking = true;
    _isLoading = true;
    _activeVerseKey = startVerse.verseKey;

    // Stop any current playback first
    await _player.stop();
    _isPlaying = false;
    notifyListeners();

    try {
      // Fetch chapter audio with timings
      final data = await _fetchChapterAudio(chapterNumber);
      if (gen != _generation) return; // cancelled by newer call
      if (data == null) {
        _isSeeking = false;
        _isLoading = false;
        _activeVerseKey = null;
        notifyListeners();
        return;
      }

      _currentChapter = chapterNumber;
      _verseTimings = List<_VerseTiming>.from(data.timings);

      final finalUrl = _shouldProxy
          ? AudioProxyServer().proxyUrl(data.audioUrl)
          : data.audioUrl;
      await _setSourceUrl(finalUrl);
      if (gen != _generation) return; // cancelled

      final duration = await _getOrWaitForDuration();
      if (duration != null && gen == _generation) {
        _totalDuration = duration;
        _applyBismillahCorrectionIfNeeded(duration);
      }

      // Find the timing for the start verse
      final timing = _findTiming(startVerse.verseKey);
      AppLogger.info(
        'Audio',
        '[AudioProvider] verse=${startVerse.verseKey}, '
            'timings=${_verseTimings.length}, '
            'timing found=${timing != null}, '
            'seekMs=${timing?.firstSegmentMs}, '
            'audioUrl=${data.audioUrl.substring(0, data.audioUrl.length.clamp(0, 80))}',
      );

      await _player.setSpeed(_playbackSpeed);

      // For MP3Quran, we need to resume first then seek because some
      // backends silently ignore seek on an unbuffered source.
      if (timing != null && timing.firstSegmentMs > 0) {
        await _preciseSeekAndPlay(
          timing.firstSegmentMs,
          gen,
          verseKey: timing.verseKey,
        );
        if (gen != _generation) return;
      } else {
        await _player.setVolume(1.0); // Ensure volume is up
        await _startPlayback();
        if (gen != _generation) return;
      }

      // Only NOW release the seeking guard — audio is actually playing
      _isSeeking = false;
      _isLoading = false;

      // Explicitly set playing state — the onPlayerStateChanged listener
      // is blocked by _isSeeking during the above sequence, so _isPlaying
      // never got set to true. Without this, subsequent togglePlay() calls
      // see _isPlaying=false and try to resume() an already-playing source,
      // which may silently fail on some backends.
      _isPlaying = true;

      // If no timing data is available for this reciter, clear the
      // active verse so the UI doesn't freeze on the initial verse.
      // The audio still plays normally — just without verse highlighting.
      if (_verseTimings.isEmpty) {
        _activeVerseKey = null;
        AppLogger.warn(
          'Audio',
          'No timing data for reciter $_reciterId — verse highlighting disabled',
        );
      }

      _syncNotificationMetadata();
      _syncNotificationState();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Audio', 'Error in playVerseList', e);
      if (gen != _generation) return;
      _isSeeking = false;
      _isLoading = false;
      _activeVerseKey = null;
      _syncNotificationState();
      notifyListeners();
    }
  }

  /// Plays a single verse isolated from the full chapter audio, then stops at
  /// the verse end timestamp. Using the chapter file keeps Android VBR seeking
  /// on the same indexed timeline as normal reading playback.
  Future<void> playSingleVerseIsolated(String verseKey) async {
    // Cancel any in-flight operation
    final gen = ++_generation;
    _currentRepeatIteration = 0;

    _isSeeking = true;
    _isLoading = true;
    _isIsolated = true;
    _activeVerseKey = verseKey;
    _isolatedEndTimeMs = null;

    await _player.stop();
    _isPlaying = false;
    notifyListeners();

    try {
      final parts = verseKey.split(':');
      final chapterNumber = int.parse(parts[0]);

      final data = await _fetchChapterAudio(chapterNumber);
      if (gen != _generation) return;

      if (data == null) {
        _isSeeking = false;
        _isLoading = false;
        _isIsolated = false;
        _activeVerseKey = null;
        notifyListeners();
        return;
      }

      _currentChapter = chapterNumber;
      _verseTimings = List<_VerseTiming>.from(data.timings);

      final finalUrl = _shouldProxy
          ? AudioProxyServer().proxyUrl(data.audioUrl)
          : data.audioUrl;
      await _setSourceUrl(finalUrl);
      if (gen != _generation) return;

      final duration = await _getOrWaitForDuration();
      if (duration != null && gen == _generation) {
        _totalDuration = duration;
        _applyBismillahCorrectionIfNeeded(duration);
      }

      final timing = _findTiming(verseKey);
      if (timing != null) {
        _isolatedEndTimeMs = timing.timestampTo + _audioOffsetMs;
        await _player.setSpeed(_playbackSpeed);

        if (timing.firstSegmentMs > 0) {
          await _preciseSeekAndPlay(
            timing.firstSegmentMs,
            gen,
            verseKey: timing.verseKey,
          );
          if (gen != _generation) return;
        } else {
          await _player.setVolume(1.0);
          await _startPlayback();
          if (gen != _generation) return;
        }

        _isSeeking = false;
        _isLoading = false;
        _isPlaying = true;
        _syncNotificationMetadata();
        _syncNotificationState();
        notifyListeners();
      } else {
        _isSeeking = false;
        _isLoading = false;
        _isIsolated = false;
        _activeVerseKey = null;
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Audio', 'Error in playSingleVerseIsolated', e);
      if (gen != _generation) return;
      _isSeeking = false;
      _isLoading = false;
      _isIsolated = false;
      _activeVerseKey = null;
      _syncNotificationState();
      notifyListeners();
    }
  }

  /// Play a single verse isolated
  Future<void> playSingleVerse(Verse verse) async {
    await playSingleVerseIsolated(verse.verseKey);
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _startPlayback();
    }
  }

  /// Stops playback entirely and clears the active verse.
  Future<void> stop() async {
    ++_generation; // Cancel any in-flight seek/load
    _isIsolated = false;
    _isolatedEndTimeMs = null;
    _currentRepeatIteration = 0;
    await _player.stop();
    _activeVerseKey = null;
    _isPlaying = false;
    _isSeeking = false;
    _syncNotificationState();
    notifyListeners();
  }

  // ── Media notification sync helpers ──────────────────────────

  /// Push current playback state to the media notification.
  void _syncNotificationState() {
    _audioHandler?.updatePlaybackState(
      playing: _isPlaying,
      position: _currentPosition,
    );
  }

  /// Push current surah / reciter metadata to the media notification.
  void _syncNotificationMetadata() async {
    if (_currentChapter == null || _audioHandler == null) return;

    final notificationTitle = _activeVerseKey != null
        ? VerseRefFormatter.format(
            _activeVerseKey!,
            locale: 'en',
            tier: VerseRefFormat.full,
          )
        : 'Surah ${VerseRefFormatter.surahName(_currentChapter!, 'en')}';

    // Copy the reciter image asset to a temp file for the notification
    Uri? artUri;
    try {
      artUri = await _getReciterArtUri(_reciterId);
    } catch (_) {
      // Silently ignore — notification will just have no image
    }

    _audioHandler!.setMediaMetadata(
      surahName: notificationTitle,
      reciterName: _reciterName,
      artUri: artUri,
      duration: _totalDuration,
    );
  }

  /// Cache of reciter ID -> temp file URI for notification art.
  final Map<int, Uri> _artUriCache = {};

  /// Copy asset image to temp file and return a file:// URI.
  /// Returns null if the asset doesn't exist or any I/O error occurs —
  /// the notification will simply have no artwork.
  Future<Uri?> _getReciterArtUri(int reciterId) async {
    try {
      if (_artUriCache.containsKey(reciterId)) {
        return _artUriCache[reciterId]!;
      }
      final dir = await path_provider.getTemporaryDirectory();
      final file = File('${dir.path}/reciter_$reciterId.jpg');
      if (!file.existsSync()) {
        final data = await rootBundle.load(
          'assets/images/reciters/$reciterId.jpg',
        );
        await file.writeAsBytes(data.buffer.asUint8List());
      }
      final uri = Uri.file(file.path);
      _artUriCache[reciterId] = uri;
      return uri;
    } catch (_) {
      // Asset not bundled for this reciter ID, or temp dir unavailable.
      return null;
    }
  }

  /// Unified precise seek and play logic.
  /// Sets volume to 0.0, resumes playback, waits for buffer/preparation,
  /// performs seek, waits for seek operation, then restores volume.
  /// This ensures precise seeks on all platforms (Windows, Android, iOS).
  Future<void> _preciseSeekAndPlay(
    int targetMs,
    int targetGen, {
    String? verseKey,
  }) async {
    final limit = _totalDuration.inMilliseconds > 0
        ? _totalDuration.inMilliseconds
        : double.maxFinite.toInt();
    final offsetTargetMs = (targetMs + _audioOffsetMs).clamp(0, limit);
    if (Platform.isAndroid) {
      final seekMs = (offsetTargetMs - _androidSeekLeadInMs).clamp(
        0,
        offsetTargetMs,
      );
      if (verseKey != null && seekMs < offsetTargetMs) {
        _seekLockVerseKey = verseKey;
        _seekLockUntilMs = offsetTargetMs;
      }
      AppLogger.info(
        'AudioSync',
        'Android indexed seek lead-in: target=${offsetTargetMs}ms seek=${seekMs}ms verse=$verseKey',
      );
      await _player.setVolume(1.0);
      await _player.seek(Duration(milliseconds: seekMs));
      if (targetGen != _generation) return;

      await Future.delayed(const Duration(milliseconds: 50));
      if (targetGen != _generation) return;

      await _startPlayback();
      return;
    }

    await _player.setVolume(0.0);
    await _startPlayback();
    if (targetGen != _generation) return;

    await Future.delayed(const Duration(milliseconds: 400));
    if (targetGen != _generation) return;

    await _player.seek(Duration(milliseconds: offsetTargetMs));
    if (targetGen != _generation) return;

    await Future.delayed(const Duration(milliseconds: 150));
    if (targetGen != _generation) return;

    // Extra tiny buffer to stabilize playback at the seeked position
    await Future.delayed(const Duration(milliseconds: 100));
    if (targetGen != _generation) return;

    await _player.setVolume(1.0);
  }

  Future<void> _startPlayback() async {
    unawaited(_player.play());
    await Future<void>.delayed(Duration.zero);
  }

  Future<Duration?> _setSourceUrl(String url) {
    final source = ja.ProgressiveAudioSource(
      Uri.parse(url),
      options: const ja.ProgressiveAudioSourceOptions(
        androidExtractorOptions: ja.AndroidExtractorOptions(
          mp3Flags: ja.AndroidExtractorOptions.flagMp3EnableIndexSeeking,
        ),
      ),
    );
    return _player.setAudioSource(source);
  }

  Future<Duration?> _getOrWaitForDuration() async {
    Duration? duration = _player.duration;
    if (duration != null && duration.inMilliseconds > 0) {
      return duration;
    }
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      duration = _player.duration;
      if (duration != null && duration.inMilliseconds > 0) {
        return duration;
      }
    }
    return null;
  }

  int? _applyBismillahCorrectionIfNeeded(Duration audioDuration) {
    if (_verseTimings.isEmpty) return null;

    final lastVerse = _verseTimings.last;
    final expectedEndTime = lastVerse.timestampTo;
    final actualDurationMs = audioDuration.inMilliseconds;

    final firstVerse = _verseTimings.first;
    final bismillahGap = firstVerse.timestampFrom;
    final discrepancy = expectedEndTime - actualDurationMs;

    AppLogger.warn(
      'AudioSync',
      'Checking correction: actualDuration=$actualDurationMs ms, expectedEnd=$expectedEndTime ms, '
          'discrepancy=$discrepancy ms, bismillahGap=$bismillahGap ms.',
    );

    // Rule: If actual duration is shorter than expected end time by at least
    // 1500ms, the timing table is likely from a source with an intro/bismillah
    // segment that this audio file does not contain. Shift by the measured
    // duration discrepancy so seeks line up with the decoded file timeline.
    if (actualDurationMs < (expectedEndTime - 1500)) {
      // Verification: discrepancy should be reasonably close to the first
      // verse start gap, allowing encoder padding/trailing silence differences.
      if ((discrepancy - bismillahGap).abs() < 1500) {
        final shift = -bismillahGap;
        if (shift == 0) {
          AppLogger.warn('AudioSync', 'Shift is 0, no correction needed.');
          return null;
        }

        AppLogger.warn(
          'AudioSync',
          'Timeline discrepancy detected! Shifting all timings by $shift ms.',
        );

        _verseTimings = _verseTimings.map((t) {
          return _VerseTiming(
            verseKey: t.verseKey,
            timestampFrom: (t.timestampFrom + shift).clamp(0, actualDurationMs),
            timestampTo: (t.timestampTo + shift).clamp(0, actualDurationMs),
            duration: t.duration,
            firstSegmentMs: (t.firstSegmentMs + shift).clamp(
              0,
              actualDurationMs,
            ),
          );
        }).toList();

        return shift;
      } else {
        AppLogger.warn(
          'AudioSync',
          'Discrepancy ($discrepancy ms) was not close enough to bismillahGap ($bismillahGap ms) to apply correction.',
        );
      }
    } else {
      AppLogger.warn(
        'AudioSync',
        'Audio duration is not significantly shorter than expected end time. No correction applied.',
      );
    }
    return null;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    if (_shouldProxy) {
      unawaited(AudioProxyServer().shutdown());
    }
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}

/// Cached chapter audio data
class _ChapterAudioData {
  final String audioUrl;
  final List<_VerseTiming> timings;

  _ChapterAudioData({required this.audioUrl, required this.timings});
}

/// Verse timing within the chapter audio
class _VerseTiming {
  final String verseKey;
  final int timestampFrom; // ms — verse boundary from API
  final int timestampTo; // ms
  final int duration; // ms
  /// The actual first-word start from the segments array.
  /// Typically ~75-100ms before [timestampFrom] — use this for seeking.
  final int firstSegmentMs;

  _VerseTiming({
    required this.verseKey,
    required this.timestampFrom,
    required this.timestampTo,
    required this.duration,
    required this.firstSegmentMs,
  });
}
