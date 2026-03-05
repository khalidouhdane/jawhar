import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quran_app/models/quran_models.dart';

class Mp3QuranService {
  static const String baseUrl = 'https://mp3quran.net/api/v3';

  /// Fetch reciters based on the rewaya (reading)
  /// 1 = Hafs A'n Assem
  /// 2 = Warsh A'n Nafi'
  /// 3 = Qalon A'n Nafi'
  /// ... etc
  Future<List<Reciter>> getReciters({int rewaya = 2}) async {
    final uri = Uri.parse('$baseUrl/reciters?language=en&rewaya=$rewaya');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> recitersJson = jsonResponse['reciters'];

      final result = recitersJson
          .map((json) => Reciter.fromMp3QuranJson(json))
          .where((r) => r.serverUrl != null && r.serverUrl!.isNotEmpty)
          .toList();
      result.sort((a, b) => a.reciterName.compareTo(b.reciterName));
      return result;
    } else {
      throw Exception(
        'Failed to load MP3Quran reciters: ${response.statusCode}',
      );
    }
  }

  /// Get Ayat Timing for a specific surah and reciter (to sync audio with verses).
  /// The `readId` should be the moshaf ID from the reciters API.
  /// Returns empty list if no timing data is available.
  Future<List<dynamic>> getAyatTiming(int readId, int surah) async {
    final uri = Uri.parse('$baseUrl/ayat_timing?surah=$surah&read=$readId');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty || body == '[]') return [];

        final decoded = json.decode(body);
        if (decoded is List) {
          return decoded;
        }
        // Some responses may be wrapped in an object
        if (decoded is Map && decoded.containsKey('data')) {
          return decoded['data'] as List? ?? [];
        }
        return [];
      }
    } catch (e) {
      // Timeout, network error, or parse error — no timing data available
      return [];
    }
    return [];
  }

  /// Cached set of read IDs that have timing data
  static Set<int>? _timingReadIds;

  /// Fetch the set of read IDs that have ayat timing data available.
  /// Uses /ayat_timing/reads endpoint.
  Future<Set<int>> getTimingReadIds() async {
    if (_timingReadIds != null) return _timingReadIds!;

    try {
      final uri = Uri.parse('$baseUrl/ayat_timing/reads');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          _timingReadIds = decoded.map((r) => (r['id'] as num).toInt()).toSet();
          return _timingReadIds!;
        }
      }
    } catch (e) {
      // Silently fail — just assume no timing data
    }
    _timingReadIds = {};
    return _timingReadIds!;
  }

  /// Fetch reciters and mark which ones have timing data available.
  Future<List<Reciter>> getRecitersWithTimingInfo({int rewaya = 2}) async {
    final reciters = await getReciters(rewaya: rewaya);
    final timingIds = await getTimingReadIds();

    return reciters.map((r) {
      final hasTiming = r.moshafId != null && timingIds.contains(r.moshafId);
      return Reciter(
        id: r.id,
        reciterName: r.reciterName,
        style: r.style,
        apiSource: r.apiSource,
        serverUrl: r.serverUrl,
        moshafId: r.moshafId,
        hasTimingData: hasTiming,
      );
    }).toList();
  }
}
