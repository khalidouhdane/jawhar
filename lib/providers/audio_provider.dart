import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:quran_app/models/quran_models.dart';

/// Audio playback using full chapter audio with verse timing data.
/// Plays the complete chapter mp3 and seeks to exact verse positions
/// using timestamp data from the API. This gives truly gapless playback
/// since it's a single continuous audio file.
class AudioProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  bool _isPlaying = false;
  int? _activeVerseId;
  int _reciterId = 7;
  String _reciterName = 'Mishary Rashid al-`Afasy';
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  int? get activeVerseId => _activeVerseId;
  int get reciterId => _reciterId;
  String get reciterName => _reciterName;

  // Chapter audio data
  String? _currentAudioUrl;
  int? _currentChapter;
  List<_VerseTiming> _verseTimings = [];
  List<Verse> _playlist = [];
  int _currentPlaylistIndex = -1;
  bool _isLoading = false;

  // Cache: "reciterId:chapter" -> { audioUrl, timings }
  final Map<String, _ChapterAudioData> _chapterCache = {};

  AudioProvider() {
    _player.onPlayerStateChanged.listen((state) {
      final playing = state == PlayerState.playing;
      if (_isPlaying != playing) {
        _isPlaying = playing;
        notifyListeners();
      }
    });

    _player.onPositionChanged.listen((position) {
      _currentPosition = position;

      // Update active verse based on current position
      if (_verseTimings.isNotEmpty && _playlist.isNotEmpty) {
        final posMs = position.inMilliseconds;
        for (int i = _playlist.length - 1; i >= 0; i--) {
          final timing = _findTiming(_playlist[i].verseKey);
          if (timing != null && posMs >= timing.timestampFrom) {
            if (_currentPlaylistIndex != i) {
              _currentPlaylistIndex = i;
              _activeVerseId = _playlist[i].id;
            }
            break;
          }
        }
      }

      notifyListeners();
    });

    _player.onDurationChanged.listen((duration) {
      _totalDuration = duration;
      notifyListeners();
    });

    _player.onPlayerComplete.listen((_) {
      _activeVerseId = null;
      _isPlaying = false;
      notifyListeners();
    });
  }

  void setReciter(int reciterId, {String? name}) async {
    if (_reciterId == reciterId) return;
    _reciterId = reciterId;
    if (name != null) _reciterName = name;

    // If playing, restart with new reciter from current verse
    if (_playlist.isNotEmpty && _currentPlaylistIndex >= 0) {
      final currentVerse = _playlist[_currentPlaylistIndex];
      final chapterNumber = int.parse(currentVerse.verseKey.split(':')[0]);

      await _player.stop();
      notifyListeners();

      // Fetch new reciter's chapter audio
      final data = await _fetchChapterAudio(chapterNumber);
      if (data == null) return;

      _currentAudioUrl = data.audioUrl;
      _verseTimings = data.timings;

      // Find timing for current verse and seek
      final timing = _findTiming(currentVerse.verseKey);
      if (timing != null) {
        await _player.play(UrlSource(data.audioUrl));
        await _player.seek(Duration(milliseconds: timing.timestampFrom));
        _activeVerseId = currentVerse.id;
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  /// Fetch chapter audio data with verse timings
  Future<_ChapterAudioData?> _fetchChapterAudio(int chapterNumber) async {
    final cacheKey = '$_reciterId:$chapterNumber';
    if (_chapterCache.containsKey(cacheKey)) {
      return _chapterCache[cacheKey];
    }

    try {
      final uri = Uri.parse(
        'https://api.quran.com/api/v4/chapter_recitations/$_reciterId/$chapterNumber?segments=true',
      );
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final audioFile = json['audio_file'];
        final audioUrl = audioFile['audio_url'] as String;
        final timestamps = audioFile['timestamps'] as List? ?? [];

        final timings = timestamps
            .map(
              (t) => _VerseTiming(
                verseKey: t['verse_key'] as String,
                timestampFrom: t['timestamp_from'] as int,
                timestampTo: t['timestamp_to'] as int,
                duration: t['duration'] as int,
              ),
            )
            .toList();

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

      _playlist = List<Verse>.from(verses);
      _currentPlaylistIndex = startIndex;

      final startVerse = verses[startIndex];
      final chapterNumber = int.parse(startVerse.verseKey.split(':')[0]);

      // Fetch chapter audio with timings
      final data = await _fetchChapterAudio(chapterNumber);
      if (data == null) {
        _isLoading = false;
        return;
      }

      _currentAudioUrl = data.audioUrl;
      _currentChapter = chapterNumber;
      _verseTimings = data.timings;

      // Find the timing for the start verse
      final timing = _findTiming(startVerse.verseKey);

      _activeVerseId = startVerse.id;
      notifyListeners();

      // Play the full chapter audio
      await _player.play(UrlSource(data.audioUrl));

      // Seek to the correct verse position
      if (timing != null && timing.timestampFrom > 0) {
        await _player.seek(Duration(milliseconds: timing.timestampFrom));
      }
    } catch (e) {
      debugPrint('Error in playVerseList: $e');
      _activeVerseId = null;
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
  final int timestampFrom; // ms
  final int timestampTo; // ms
  final int duration; // ms

  _VerseTiming({
    required this.verseKey,
    required this.timestampFrom,
    required this.timestampTo,
    required this.duration,
  });
}
