import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A single asbab al-nuzul entry: the occasion(s) of revelation for specific
/// ayahs within a surah.
class AsbabNuzulEntry {
  final int surah;
  final List<int> ayahs;
  final List<String> occasions;

  const AsbabNuzulEntry({
    required this.surah,
    required this.ayahs,
    required this.occasions,
  });

  factory AsbabNuzulEntry.fromJson(Map<String, dynamic> json) {
    return AsbabNuzulEntry(
      surah: json['surah'] as int,
      ayahs: (json['ayahs'] as List<dynamic>).cast<int>(),
      occasions: (json['occasions'] as List<dynamic>).cast<String>(),
    );
  }
}

/// Service for importing and serving the asbab al-nuzul dataset.
///
/// Data source: mostafaahmed97/asbab-al-nuzul-dataset on GitHub.
/// Uses file-based caching (downloads JSON once, stores locally) plus
/// in-memory lookup for fast access.
class AsbabNuzulService {
  static const String _datasetUrl =
      'https://raw.githubusercontent.com/mostafaahmed97/asbab-al-nuzul-dataset/main/data/structured/json/all.json';

  static const String _cacheFileName = 'asbab_al_nuzul.json';

  /// In-memory dataset: keyed by "surah:ayah" for fast lookup.
  /// Multiple ayahs may point to the same entry.
  final Map<String, AsbabNuzulEntry> _lookup = {};

  /// All entries for iteration/stats.
  final List<AsbabNuzulEntry> _entries = [];

  bool _isLoaded = false;
  bool _isLoading = false;

  bool get isLoaded => _isLoaded;
  int get entryCount => _entries.length;

  /// Import the dataset if it hasn't been loaded yet.
  ///
  /// 1. Check for a locally cached file first (app documents directory).
  /// 2. If not cached, download from GitHub and save locally.
  /// 3. Parse JSON and build the in-memory lookup map.
  Future<void> importIfNeeded() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      String? jsonString;

      // Try loading from local cache first
      final cacheFile = await _getCacheFile();
      if (await cacheFile.exists()) {
        debugPrint('AsbabNuzulService: Loading from local cache');
        jsonString = await cacheFile.readAsString();
      } else {
        // Download from GitHub
        debugPrint('AsbabNuzulService: Downloading dataset from GitHub...');
        jsonString = await _downloadDataset();
        if (jsonString != null) {
          // Save to local cache
          await cacheFile.writeAsString(jsonString);
          debugPrint('AsbabNuzulService: Dataset cached locally');
        }
      }

      if (jsonString != null) {
        _parseDataset(jsonString);
        _isLoaded = true;
        debugPrint(
          'AsbabNuzulService: Loaded ${_entries.length} entries, '
          '${_lookup.length} verse keys indexed',
        );
      }
    } catch (e) {
      debugPrint('AsbabNuzulService: Error importing dataset: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// Get the asbab al-nuzul occasions for a specific verse.
  ///
  /// Returns null if the verse has no recorded asbab al-nuzul.
  /// [surah] and [ayah] are 1-indexed.
  List<String>? getOccasions(int surah, int ayah) {
    final entry = _lookup['$surah:$ayah'];
    return entry?.occasions;
  }

  /// Get the full entry (including which ayahs are covered) for a verse.
  AsbabNuzulEntry? getEntry(int surah, int ayah) {
    return _lookup['$surah:$ayah'];
  }

  /// Check if a verse has asbab al-nuzul data.
  bool hasOccasion(int surah, int ayah) {
    return _lookup.containsKey('$surah:$ayah');
  }

  /// Check if a verse key (e.g. "2:255") has asbab al-nuzul data.
  bool hasOccasionByKey(String verseKey) {
    return _lookup.containsKey(verseKey);
  }

  /// Get occasions by verse key (e.g. "2:255").
  List<String>? getOccasionsByKey(String verseKey) {
    return _lookup[verseKey]?.occasions;
  }

  /// Get all entries for a specific surah.
  List<AsbabNuzulEntry> getEntriesForSurah(int surah) {
    return _entries.where((e) => e.surah == surah).toList();
  }

  // ── Private Helpers ──

  Future<File> _getCacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _cacheFileName));
  }

  Future<String?> _downloadDataset() async {
    try {
      final response = await http.get(Uri.parse(_datasetUrl));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        debugPrint(
          'AsbabNuzulService: Download failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('AsbabNuzulService: Download error: $e');
    }
    return null;
  }

  void _parseDataset(String jsonString) {
    final List<dynamic> rawList = json.decode(jsonString);
    _entries.clear();
    _lookup.clear();

    for (final raw in rawList) {
      final entry = AsbabNuzulEntry.fromJson(raw as Map<String, dynamic>);
      _entries.add(entry);

      // Index each ayah in this entry for O(1) lookup
      for (final ayah in entry.ayahs) {
        _lookup['${entry.surah}:$ayah'] = entry;
      }
    }
  }
}
