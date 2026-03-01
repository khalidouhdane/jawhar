import 'dart:convert';
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

  // Fetch Reciters that have both chapter audio and verse timing support
  Future<List<Reciter>> getReciters() async {
    final uri = Uri.parse('$baseUrl/resources/recitations');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> recitersJson = jsonResponse['recitations'];
      return recitersJson.map((json) => Reciter.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reciters');
    }
  }

  // Fetch audio timestamps for a specific chapter and reciter
  // This is used for gapless playback if we playback chapter by chapter
  // Or we use word.audioUrl for word-by-word audio.
}
