import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/services/quran_auth_service.dart';
import 'package:quran_app/services/quran_audio_handler.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

/// Surah names for media notification display.
const List<String> _surahNames = [
  '', // index 0 unused
  'Al-Fatihah', 'Al-Baqarah', 'Ali \'Imran', 'An-Nisa', 'Al-Ma\'idah',
  'Al-An\'am', 'Al-A\'raf', 'Al-Anfal', 'At-Tawbah', 'Yunus',
  'Hud', 'Yusuf', 'Ar-Ra\'d', 'Ibrahim', 'Al-Hijr',
  'An-Nahl', 'Al-Isra', 'Al-Kahf', 'Maryam', 'Taha',
  'Al-Anbiya', 'Al-Hajj', 'Al-Mu\'minun', 'An-Nur', 'Al-Furqan',
  'Ash-Shu\'ara', 'An-Naml', 'Al-Qasas', 'Al-Ankabut', 'Ar-Rum',
  'Luqman', 'As-Sajdah', 'Al-Ahzab', 'Saba', 'Fatir',
  'Ya-Sin', 'As-Saffat', 'Sad', 'Az-Zumar', 'Ghafir',
  'Fussilat', 'Ash-Shura', 'Az-Zukhruf', 'Ad-Dukhan', 'Al-Jathiyah',
  'Al-Ahqaf', 'Muhammad', 'Al-Fath', 'Al-Hujurat', 'Qaf',
  'Adh-Dhariyat', 'At-Tur', 'An-Najm', 'Al-Qamar', 'Ar-Rahman',
  'Al-Waqi\'ah', 'Al-Hadid', 'Al-Mujadila', 'Al-Hashr', 'Al-Mumtahanah',
  'As-Saf', 'Al-Jumu\'ah', 'Al-Munafiqun', 'At-Taghabun', 'At-Talaq',
  'At-Tahrim', 'Al-Mulk', 'Al-Qalam', 'Al-Haqqah', 'Al-Ma\'arij',
  'Nuh', 'Al-Jinn', 'Al-Muzzammil', 'Al-Muddaththir', 'Al-Qiyamah',
  'Al-Insan', 'Al-Mursalat', 'An-Naba', 'An-Nazi\'at', 'Abasa',
  'At-Takwir', 'Al-Infitar', 'Al-Mutaffifin', 'Al-Inshiqaq', 'Al-Buruj',
  'At-Tariq', 'Al-A\'la', 'Al-Ghashiyah', 'Al-Fajr', 'Al-Balad',
  'Ash-Shams', 'Al-Layl', 'Ad-Duhaa', 'Ash-Sharh', 'At-Tin',
  'Al-Alaq', 'Al-Qadr', 'Al-Bayyinah', 'Az-Zalzalah', 'Al-Adiyat',
  'Al-Qari\'ah', 'At-Takathur', 'Al-Asr', 'Al-Humazah', 'Al-Fil',
  'Quraysh', 'Al-Ma\'un', 'Al-Kawthar', 'Al-Kafirun', 'An-Nasr',
  'Al-Masad', 'Al-Ikhlas', 'Al-Falaq', 'An-Nas',
];

/// Repeat mode for audio playback
enum AudioRepeatMode { none, repeatVerse, repeatRange }

/// Audio playback using full chapter audio with verse timing data.
/// Plays the complete chapter mp3 and seeks to exact verse positions
/// using timestamp data from the API. This gives truly gapless playback
/// since it's a single continuous audio file.
///
/// Tracks the active verse by verseKey (e.g., "2:5") so highlighting
/// works across page boundaries without needing the page's verse list.
class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  /// Reference to the media notification handler.
  QuranAudioHandler? _audioHandler;

  /// Attach the audio handler (called once from main.dart).
  void attachAudioHandler(QuranAudioHandler handler) {
    _audioHandler = handler;
    handler.onPlay = () => togglePlay();
    handler.onPause = () => togglePlay();
    handler.onSkipToNext = () => skipToNextVerse();
    handler.onSkipToPrevious = () => skipToPreviousVerse();
    handler.onSeek = (pos) => _player.seek(pos);
    handler.onStop = () async {
      await _player.stop();
      _activeVerseKey = null;
      _isPlaying = false;
      notifyListeners();
    };
  }

  bool _isPlaying = false;
  String? _activeVerseKey; // e.g., "2:5" — works across pages
  int _reciterId = 7;
  String _reciterName = 'Mishary Rashid al-`Afasy';
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Playback speed
  double _playbackSpeed = 1.0;

  // Repeat mode
  AudioRepeatMode _repeatMode = AudioRepeatMode.none;
  String? _repeatRangeStart; // e.g., "2:1"
  String? _repeatRangeEnd; // e.g., "2:5"
  int _repeatCount = 0; // 0 = infinite
  int _currentRepeatIteration = 0;

  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  String? get activeVerseKey => _activeVerseKey;
  int get reciterId => _reciterId;
  String get reciterName => _reciterName;
  double get playbackSpeed => _playbackSpeed;
  AudioRepeatMode get repeatMode => _repeatMode;
  String? get repeatRangeStart => _repeatRangeStart;
  String? get repeatRangeEnd => _repeatRangeEnd;
  int get repeatCount => _repeatCount;

  // Chapter audio data

  int? _currentChapter;
  List<_VerseTiming> _verseTimings = [];
  bool _isLoading = false;
  bool _isSeeking =
      false; // Guard: prevents onPositionChanged from overriding _activeVerseKey during seek

  // Cache: "reciterId:chapter" -> { audioUrl, timings }
  final Map<String, _ChapterAudioData> _chapterCache = {};

  AudioProvider() {
    _player.onPlayerStateChanged.listen((state) {
      if (_isSeeking) return;
      final playing = state == PlayerState.playing;
      if (_isPlaying != playing) {
        _isPlaying = playing;
        _syncNotificationState();
        notifyListeners();
      }
    });

    _player.onPositionChanged.listen((position) {
      _currentPosition = position;

      // While seeking to a target verse, don't let intermediate positions
      // override _activeVerseKey — this prevents the wrong-verse flash.
      if (_isSeeking) {
        notifyListeners();
        return;
      }

      // Update active verse based on current position using timing data
      if (_verseTimings.isNotEmpty) {
        final posMs = position.inMilliseconds;
        String? newKey;

        // Find the most recent verse whose start has been reached.
        // Search in REVERSE so that when timing ranges overlap (verse N's
        // firstSegmentMs < verse N-1's timestampTo), we pick the newer verse
        // instead of the older one — eliminating the previous-verse flash.
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
          _handleRepeat(oldKey, newKey, posMs);
        }
      }

      notifyListeners();
    });

    _player.onDurationChanged.listen((duration) {
      if (_isSeeking) return;
      _totalDuration = duration;
      notifyListeners();
    });

    _player.onPlayerComplete.listen((_) {
      if (_isSeeking) return;
      _activeVerseKey = null;
      _isPlaying = false;
      _syncNotificationState();
      notifyListeners();
    });
  }

  /// Handle repeat logic when the active verse changes
  void _handleRepeat(String? oldKey, String newKey, int posMs) {
    if (_repeatMode == AudioRepeatMode.repeatVerse && oldKey != null) {
      // Repeat single verse: re-seek to the old verse's start
      final oldTiming = _findTiming(oldKey);
      if (oldTiming != null && newKey != oldKey) {
        if (_repeatCount == 0 || _currentRepeatIteration < _repeatCount - 1) {
          _currentRepeatIteration++;
          _activeVerseKey = oldKey;
          _player.seek(Duration(milliseconds: oldTiming.firstSegmentMs));
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
            _player.seek(Duration(milliseconds: startTiming.firstSegmentMs));
            return;
          }
        } else {
          _currentRepeatIteration = 0;
        }
      }
    }
  }

  void setReciter(int reciterId, {String? name}) async {
    if (_reciterId == reciterId) return;
    _reciterId = reciterId;
    if (name != null) _reciterName = name;

    // If playing, restart with new reciter from current verse
    if (_activeVerseKey != null && _currentChapter != null) {
      final savedKey = _activeVerseKey!;

      await _player.stop();
      notifyListeners();

      // Fetch new reciter's chapter audio
      final data = await _fetchChapterAudio(_currentChapter!);
      if (data == null) return;

      _verseTimings = data.timings;

      // Find timing for current verse and seek
      final timing = _findTiming(savedKey);
      if (timing != null) {
        // Guard: block onPositionChanged from overriding _activeVerseKey
        _isSeeking = true;
        _activeVerseKey = savedKey;
        await _player.setSourceUrl(data.audioUrl);
        await _player.seek(Duration(milliseconds: timing.firstSegmentMs));
        _isSeeking = false;
        await _player.setPlaybackRate(_playbackSpeed);
        await _player.resume();
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  /// Set playback speed (0.5, 0.75, 1.0, 1.25, 1.5, 2.0)
  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    await _player.setPlaybackRate(speed);
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
    await _player.seek(Duration(milliseconds: nextTiming.firstSegmentMs));
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
    await _player.seek(Duration(milliseconds: prevTiming.firstSegmentMs));
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
      final uri = Uri.parse(
        'https://apis.quran.foundation/content/api/v4/chapter_recitations/$_reciterId/$chapterNumber?segments=true',
      );

      final token = await QuranAuthService.getValidToken();
      final response = await http.get(
        uri,
        headers: {
          'x-auth-token': token,
          'x-client-id': QuranAuthService.clientId,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final audioFile = json['audio_file'];
        final audioUrl = audioFile['audio_url'] as String;
        final timestamps = audioFile['timestamps'] as List? ?? [];

        final timings = timestamps.map((t) {
          final verseKey = t['verse_key'] as String;
          final timestampFrom = (t['timestamp_from'] as num).toInt();
          final timestampTo = (t['timestamp_to'] as num).toInt();
          final duration = (t['duration'] as num).toInt();

          // Extract the true first-word start from the segments array.
          // Each segment is [wordIndex, startMs, endMs]. The first segment's
          // startMs is the genuine moment the reciter begins this verse —
          // typically 75-100ms before timestampFrom.
          int firstSegmentMs = timestampFrom;
          final segs = t['segments'] as List?;
          if (segs != null && segs.isNotEmpty) {
            final firstSeg = segs[0] as List;
            if (firstSeg.length >= 2) {
              final segStart = (firstSeg[1] as num).toInt();
              // Only use segment start if it's sensibly close to timestampFrom
              // (within 500ms) to guard against bad data.
              if ((segStart - timestampFrom).abs() < 500) {
                firstSegmentMs = segStart;
              }
            }
          }

          return _VerseTiming(
            verseKey: verseKey,
            timestampFrom: timestampFrom,
            timestampTo: timestampTo,
            duration: duration,
            firstSegmentMs: firstSegmentMs,
          );
        }).toList();

        final data = _ChapterAudioData(audioUrl: audioUrl, timings: timings);

        _chapterCache[cacheKey] = data;
        return data;
      }
    } catch (e) {
      debugPrint('Error fetching chapter audio: $e');
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
    if (_isLoading) return;
    _isLoading = true;

    try {
      if (verses.isEmpty) {
        _isLoading = false;
        return;
      }

      final startVerse = verses[startIndex];
      final chapterNumber = int.parse(startVerse.verseKey.split(':')[0]);

      // Block ALL player listeners from modifying state or triggering rebuilds
      // during the transition. This MUST happen synchronously before any await.
      _isSeeking = true;
      _activeVerseKey = startVerse.verseKey;
      notifyListeners();

      // Fetch chapter audio with timings
      final data = await _fetchChapterAudio(chapterNumber);
      if (data == null) {
        _isSeeking = false;
        _isLoading = false;
        return;
      }

      _currentChapter = chapterNumber;
      _verseTimings = data.timings;

      // Find the timing for the start verse
      final timing = _findTiming(startVerse.verseKey);

      await _player.setSourceUrl(data.audioUrl);

      // Seek to the exact first-word start of the target verse.
      // firstSegmentMs is derived from the segments array and is the
      // genuine moment the reciter begins speaking — no artificial buffer.
      if (timing != null && timing.firstSegmentMs > 0) {
        await _player.seek(Duration(milliseconds: timing.firstSegmentMs));
      }
      _isSeeking = false;

      await _player.setPlaybackRate(_playbackSpeed);
      await _player.resume();
      _syncNotificationMetadata();
      _syncNotificationState();
    } catch (e) {
      debugPrint('Error in playVerseList: $e');
      _isSeeking = false;
      _activeVerseKey = null;
      _syncNotificationState();
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  /// Play a single verse
  Future<void> playSingleVerse(Verse verse) async {
    await playVerseList([verse], startIndex: 0);
  }

  Future<void> togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
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

    final surahName =
        (_currentChapter! >= 1 && _currentChapter! < _surahNames.length)
        ? _surahNames[_currentChapter!]
        : 'Surah $_currentChapter';

    // Verse info for subtitle
    final verseInfo = _activeVerseKey != null
        ? ' \u2022 Ayah ${_activeVerseKey!.split(':').last}'
        : '';

    // Copy the reciter image asset to a temp file for the notification
    Uri? artUri;
    try {
      artUri = await _getReciterArtUri(_reciterId);
    } catch (_) {
      // Silently ignore — notification will just have no image
    }

    _audioHandler!.setMediaMetadata(
      surahName: '$surahName$verseInfo',
      reciterName: _reciterName,
      artUri: artUri,
      duration: _totalDuration,
    );
  }

  /// Cache of reciter ID -> temp file URI for notification art.
  final Map<int, Uri> _artUriCache = {};

  /// Copy asset image to temp file and return a file:// URI.
  Future<Uri> _getReciterArtUri(int reciterId) async {
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
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
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
