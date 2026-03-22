import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quran_app/models/flashcard_models.dart';
import 'package:quran_app/services/hifz_database_service.dart';

/// Fetches the Waqar144/Quran_Mutashabihat_Data JSON dataset from GitHub
/// and imports it into the local SQLite database.
class MutashabihatImportService {
  static const _dataUrl =
      'https://raw.githubusercontent.com/Waqar144/Quran_Mutashabihat_Data/master/mutashabiha_data.json';

  final HifzDatabaseService _db;

  MutashabihatImportService(this._db);

  /// Import the dataset if not already imported.
  /// Returns the number of groups imported (0 if already done).
  Future<int> importIfNeeded() async {
    final existingCount = await _db.getMutashabihatCount();
    if (existingCount > 0) {
      debugPrint('Mutashabihat already imported ($existingCount groups)');
      return 0;
    }

    try {
      debugPrint('Fetching mutashabihat dataset from GitHub...');
      final response = await http.get(Uri.parse(_dataUrl));
      if (response.statusCode != 200) {
        debugPrint('Failed to fetch mutashabihat data: ${response.statusCode}');
        return 0;
      }

      // The dataset is a dictionary keyed by juz/para number:
      // { "1": [ { "src": { "ayah": 9 }, "muts": [{ "ayah": 1162 }] }, ... ], "2": [...] }
      // All ayah values are 0-based absolute indices (see common.dart surahAyahOffsets).
      final Map<String, dynamic> rawData = jsonDecode(response.body);
      final groups = <MutashabihatGroup>[];
      int groupIndex = 0;

      for (final juzEntry in rawData.entries) {
        final juzGroups = juzEntry.value as List<dynamic>? ?? [];
        for (final item in juzGroups) {
          final group = _parseGroup(item as Map<String, dynamic>, groupIndex);
          if (group != null) groups.add(group);
          groupIndex++;
        }
      }

      if (groups.isNotEmpty) {
        await _db.importMutashabihatBatch(groups);
        debugPrint('Imported ${groups.length} mutashabihat groups');
      }

      return groups.length;
    } catch (e) {
      debugPrint('Error importing mutashabihat: $e');
      return 0;
    }
  }

  /// Parse a single entry from the Waqar144 dataset format:
  /// { "src": { "ayah": 8 }, "muts": [{ "ayah": 1161 }], "ctx": 2 }
  ///
  /// The "ayah" field is a **0-based** absolute index:
  ///   absoluteAyah = surahAyahOffsets[surah_0based] + verse_0based
  /// For example, verse 2:2 = surahAyahOffsets[1] + 1 = 7 + 1 = 8
  ///
  /// "src.ayah" can be a single int OR a list of ints (for multi-verse sources).
  MutashabihatGroup? _parseGroup(Map<String, dynamic> item, int index) {
    try {
      // Handle src.ayah as either int or list
      final srcRaw = item['src']?['ayah'];
      int? srcAyah;
      if (srcRaw is int) {
        srcAyah = srcRaw;
      } else if (srcRaw is List && srcRaw.isNotEmpty) {
        srcAyah = srcRaw.first as int;
      }
      if (srcAyah == null) return null;

      final mutsRaw = item['muts'] as List<dynamic>? ?? [];
      final ctxValue = item['ctx'];
      final needsContext = ctxValue != null && ctxValue != false && ctxValue != 0;

      // Convert 0-based absolute ayah to "chapter:verse" format
      final srcVerseKey = _absoluteToVerseKey(srcAyah);
      if (srcVerseKey == null) return null;

      final similarVerses = <MutashabihatVerse>[];
      for (final mut in mutsRaw) {
        // Each mut can have ayah as int or list
        final mutAyahRaw = mut['ayah'];
        int? mutAyah;
        if (mutAyahRaw is int) {
          mutAyah = mutAyahRaw;
        } else if (mutAyahRaw is List && mutAyahRaw.isNotEmpty) {
          mutAyah = mutAyahRaw.first as int;
        }
        if (mutAyah == null) continue;
        final mutVerseKey = _absoluteToVerseKey(mutAyah);
        if (mutVerseKey != null) {
          similarVerses.add(MutashabihatVerse(
            verseKey: mutVerseKey,
            text: '', // Text populated at display time via quran package
          ));
        }
      }

      if (similarVerses.isEmpty) return null;

      return MutashabihatGroup(
        groupId: 'mut_$index',
        sourceVerseKey: srcVerseKey,
        sourceText: '',
        similarVerses: similarVerses,
        uniqueWords: const {'src': [], 'mut': []},
        category: MutashabihatCategory.wordSwap,
        difficulty: 'medium',
        needsContext: needsContext,
        userStatus: MutashabihatStatus.notStudied,
      );
    } catch (e) {
      debugPrint('Failed to parse mutashabihat entry $index: $e');
      return null;
    }
  }

  /// Convert a **0-based** absolute ayah index to "chapter:verse" format.
  ///
  /// Uses the exact same offsets as the dataset's common.dart:
  ///   surahAyahOffsets[surah_0based] = first absolute index for that surah
  ///
  /// Given absoluteAyah=8 → surahAyahOffsets[1]=7, so it's in surah 2,
  /// verse = absoluteAyah - offset + 1 = 8 - 7 + 1 = 2 → "2:2"
  static String? _absoluteToVerseKey(int absoluteAyah) {
    if (absoluteAyah < 0 || absoluteAyah >= 6236) return null;

    // Find the surah whose offset is ≤ absoluteAyah
    for (int i = _surahAyahOffsets.length - 1; i >= 0; i--) {
      if (absoluteAyah >= _surahAyahOffsets[i]) {
        final surah = i + 1; // 1-based surah number
        final verse = absoluteAyah - _surahAyahOffsets[i] + 1; // 1-based verse
        return '$surah:$verse';
      }
    }
    return null;
  }

  /// Exact offsets from the dataset's common.dart.
  /// Index 0 = Al-Fatiha (starts at 0), Index 1 = Al-Baqarah (starts at 7), etc.
  static const List<int> _surahAyahOffsets = [
    0, 7, 293, 493, 669, 789, 954, 1160, 1235, 1364,
    1473, 1596, 1707, 1750, 1802, 1901, 2029, 2140, 2250, 2348,
    2483, 2595, 2673, 2791, 2855, 2932, 3159, 3252, 3340, 3409,
    3469, 3503, 3533, 3606, 3660, 3705, 3788, 3970, 4058, 4133,
    4218, 4272, 4325, 4414, 4473, 4510, 4545, 4583, 4612, 4630,
    4675, 4735, 4784, 4846, 4901, 4979, 5075, 5104, 5126, 5150,
    5163, 5177, 5188, 5199, 5217, 5229, 5241, 5271, 5323, 5375,
    5419, 5447, 5475, 5495, 5551, 5591, 5622, 5672, 5712, 5758,
    5800, 5829, 5848, 5884, 5909, 5931, 5948, 5967, 5993, 6023,
    6043, 6058, 6079, 6090, 6098, 6106, 6125, 6130, 6138, 6146,
    6157, 6168, 6176, 6179, 6188, 6193, 6197, 6204, 6207, 6213,
    6216, 6221, 6225, 6230,
  ];
}
