import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/services/quran_auth_service.dart';

class QuranApiService {
  static const String baseUrl = 'https://apis.quran.foundation/content/api/v4';

  /// Helper to get the authenticated HTTP headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await QuranAuthService.getValidToken();
    return {'x-auth-token': token, 'x-client-id': QuranAuthService.clientId};
  }

  // Fetch Verses by Page with word-by-word data
  Future<List<Verse>> getVersesByPage(
    int pageNumber, {
    String language = 'en',
  }) async {
    final uri = Uri.parse(
      '$baseUrl/verses/by_page/$pageNumber?words=true&word_fields=text_uthmani,location,audio_url&translations=131&audio=7',
    ); // 131 is Clear Quran English, 7 is Mishary Alafasy

    final headers = await _getAuthHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> versesJson = jsonResponse['verses'];
      return versesJson.map((json) => Verse.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load verses: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // Fetch all Chapters
  Future<List<Chapter>> getChapters() async {
    final uri = Uri.parse('$baseUrl/chapters');
    final headers = await _getAuthHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> chaptersJson = jsonResponse['chapters'];
      return chaptersJson.map((json) => Chapter.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load chapters: ${response.statusCode}');
    }
  }

  /// Fetch reciters using the new authenticated /resources/chapter_reciters
  /// endpoint which natively returns 20+ reciters including QDC exclusives.
  /// The endpoint always returns `arabic_name` as a dedicated field,
  /// so we don't need to change the language parameter to get Arabic names.
  Future<List<Reciter>> getReciters({String language = 'en'}) async {
    final uri = Uri.parse('$baseUrl/resources/chapter_reciters');
    final headers = await _getAuthHeaders();
    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> recitersJson = jsonResponse['reciters'];

      final result = recitersJson
          .map((json) => Reciter.fromQdcJson(json, language: language))
          .toList();
      // Sort using locale-aware comparison to handle both Arabic and English
      result.sort((a, b) {
        try {
          return a.reciterName.compareTo(b.reciterName);
        } catch (_) {
          return 0;
        }
      });
      return result;
    } else {
      throw Exception('Failed to load reciters: ${response.statusCode}');
    }
  }
}
