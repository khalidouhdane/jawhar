import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quran_app/models/quran_models.dart';

class QuranApiService {
  static const String baseUrl = 'https://api.quran.com/api/v4';

  // Fetch Verses by Page with word-by-word data
  Future<List<Verse>> getVersesByPage(
    int pageNumber, {
    String language = 'en',
  }) async {
    final uri = Uri.parse(
      '$baseUrl/verses/by_page/$pageNumber?words=true&word_fields=text_uthmani,location,audio_url&translations=131&audio=7',
    ); // 131 is Clear Quran English, 7 is Mishary Alafasy

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> versesJson = jsonResponse['verses'];
      return versesJson.map((json) => Verse.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load verses');
    }
  }

  // Fetch all Chapters
  Future<List<Chapter>> getChapters() async {
    final uri = Uri.parse('$baseUrl/chapters');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> chaptersJson = jsonResponse['chapters'];
      return chaptersJson.map((json) => Chapter.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load chapters');
    }
  }

  /// Fetch reciters from both the standard API and the QDC API, then merge
  /// them (dedup by id). This gives us ~14 entries including reciters like
  /// Yasser Ad Dussary and Khalifah Al Tunaiji that only appear in QDC.
  Future<List<Reciter>> getReciters() async {
    final Map<int, Reciter> merged = {};

    // 1) Standard API (always works)
    try {
      final res = await http.get(Uri.parse('$baseUrl/resources/recitations'));
      if (res.statusCode == 200) {
        final list = json.decode(res.body)['recitations'] as List;
        for (final j in list) {
          final r = Reciter.fromJson(j);
          merged[r.id] = r;
        }
      }
    } catch (e) {
      debugPrint('Standard reciters fetch failed: $e');
    }

    // 2) QDC API (has extra reciters)
    try {
      final res = await http.get(
        Uri.parse('https://api.qurancdn.com/api/qdc/audio/reciters?locale=en'),
      );
      if (res.statusCode == 200) {
        final list = json.decode(res.body)['reciters'] as List;
        for (final j in list) {
          final r = Reciter.fromQdcJson(j);
          // Only add if not already present (standard API takes priority)
          merged.putIfAbsent(r.id, () => r);
        }
      }
    } catch (e) {
      debugPrint('QDC reciters fetch failed: $e');
    }

    if (merged.isEmpty) {
      throw Exception('Failed to load reciters from any source');
    }

    // Sort alphabetically by name for a clean list
    final result = merged.values.toList()
      ..sort((a, b) => a.reciterName.compareTo(b.reciterName));
    return result;
  }
}
