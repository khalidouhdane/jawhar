import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quran_app/services/qf_user_auth_service.dart';
import 'package:quran_app/utils/app_logger.dart';

/// Client for the Quran Foundation User-related APIs.
///
/// Handles bookmarks, reading sessions, goals, and streaks.
/// All requests require a valid user access_token from [QfUserAuthService].
///
/// Base URL: https://prelive-apis.quran.foundation/auth/v1
/// Auth headers: x-auth-token + x-client-id
class QfUserApiService {
  final QfUserAuthService _authService;

  // Pre-live API base
  static const _baseUrl = 'https://prelive-apis.quran.foundation/auth/v1';

  QfUserApiService(this._authService);

  /// Whether the user is authenticated and can make API calls.
  bool get isAvailable => _authService.isSignedIn;

  // ══════════════════════════════════════════════════════════════════════
  // HTTP Helpers
  // ══════════════════════════════════════════════════════════════════════

  /// Builds authenticated headers for User API requests.
  Future<Map<String, String>?> _getHeaders() async {
    final token = await _authService.getValidAccessToken();
    if (token == null) return null;

    return {
      'x-auth-token': token,
      'x-client-id': QfUserAuthService.clientId,
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Performs an authenticated GET request.
  Future<Map<String, dynamic>?> _get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final headers = await _getHeaders();
    if (headers == null) {
      AppLogger.info('QfApi', '[QF_API] Not authenticated, skipping GET $path');
      return null;
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl$path',
      ).replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        AppLogger.info(
          'QfApi',
          '[QF_API] 401 on GET $path — token may be expired',
        );
        // Try refresh and retry once
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          return _get(path, queryParams: queryParams);
        }
        return null;
      } else {
        AppLogger.info(
          'QfApi',
          '[QF_API] GET $path failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      AppLogger.info('QfApi', '[QF_API] GET $path error: $e');
      return null;
    }
  }

  /// Performs an authenticated POST request.
  Future<Map<String, dynamic>?> _post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _getHeaders();
    if (headers == null) {
      AppLogger.info(
        'QfApi',
        '[QF_API] Not authenticated, skipping POST $path',
      );
      return null;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) return {};
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        AppLogger.info(
          'QfApi',
          '[QF_API] 401 on POST $path — attempting refresh',
        );
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          return _post(path, body: body);
        }
        return null;
      } else {
        AppLogger.info(
          'QfApi',
          '[QF_API] POST $path failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      AppLogger.info('QfApi', '[QF_API] POST $path error: $e');
      return null;
    }
  }

  /// Performs an authenticated PATCH request.
  Future<Map<String, dynamic>?> _patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final headers = await _getHeaders();
    if (headers == null) return null;

    try {
      final response = await http
          .patch(
            Uri.parse('$_baseUrl$path'),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return {};
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        AppLogger.info(
          'QfApi',
          '[QF_API] PATCH $path failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      AppLogger.info('QfApi', '[QF_API] PATCH $path error: $e');
      return null;
    }
  }

  /// Performs an authenticated DELETE request.
  Future<bool> _delete(String path) async {
    final headers = await _getHeaders();
    if (headers == null) return false;

    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl$path'), headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        AppLogger.info(
          'QfApi',
          '[QF_API] DELETE $path failed: ${response.statusCode} ${response.body}',
        );
        return false;
      }
    } catch (e) {
      AppLogger.info('QfApi', '[QF_API] DELETE $path error: $e');
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // Bookmarks API
  // ══════════════════════════════════════════════════════════════════════

  /// Fetches the user's bookmarks.
  ///
  /// Returns a list of bookmark objects, or null if the request fails.
  /// Supports cursor-based pagination with [first] and [after].
  Future<QfPaginatedResponse?> getBookmarks({
    int first = 50,
    String? after,
  }) async {
    final params = <String, String>{'first': first.toString()};
    if (after != null) params['after'] = after;

    final data = await _get('/bookmarks', queryParams: params);
    if (data == null) return null;

    return QfPaginatedResponse.fromJson(data);
  }

  /// Creates a new bookmark.
  ///
  /// [verseKey] — e.g. "2:255" (Ayatul Kursi)
  /// [type] — bookmark type (optional)
  Future<Map<String, dynamic>?> createBookmark({
    required String verseKey,
    String? type,
  }) async {
    final body = <String, dynamic>{'verse_key': verseKey};
    if (type != null) body['type'] = type;

    return _post('/bookmarks', body: body);
  }

  /// Deletes a bookmark by its ID.
  Future<bool> deleteBookmark(String bookmarkId) async {
    return _delete('/bookmarks/$bookmarkId');
  }

  // ══════════════════════════════════════════════════════════════════════
  // Reading Sessions API
  // ══════════════════════════════════════════════════════════════════════

  /// Fetches the user's reading sessions.
  Future<QfPaginatedResponse?> getReadingSessions({
    int first = 50,
    String? after,
  }) async {
    final params = <String, String>{'first': first.toString()};
    if (after != null) params['after'] = after;

    return QfPaginatedResponse.fromJson(
      (await _get('/reading-sessions', queryParams: params)) ?? {},
    );
  }

  /// Records a new reading session.
  ///
  /// [startPage] / [endPage] — pages covered in this session
  /// [durationSeconds] — total session time
  /// [versesRead] — number of verses read
  Future<Map<String, dynamic>?> createReadingSession({
    required int startPage,
    required int endPage,
    required int durationSeconds,
    int? versesRead,
  }) async {
    final body = <String, dynamic>{
      'start_page': startPage,
      'end_page': endPage,
      'duration': durationSeconds,
    };
    if (versesRead != null) body['verses_read'] = versesRead;

    return _post('/reading-sessions', body: body);
  }

  // ══════════════════════════════════════════════════════════════════════
  // Goals API
  // ══════════════════════════════════════════════════════════════════════

  /// Fetches the user's goals.
  Future<QfPaginatedResponse?> getGoals({int first = 50, String? after}) async {
    final params = <String, String>{'first': first.toString()};
    if (after != null) params['after'] = after;

    final data = await _get('/goals', queryParams: params);
    if (data == null) return null;
    return QfPaginatedResponse.fromJson(data);
  }

  /// Creates a new reading goal.
  ///
  /// [type] — e.g. "pages", "time", "verses"
  /// [target] — numeric target value
  /// [period] — e.g. "daily", "weekly"
  Future<Map<String, dynamic>?> createGoal({
    required String type,
    required int target,
    required String period,
  }) async {
    return _post(
      '/goals',
      body: {'type': type, 'target': target, 'period': period},
    );
  }

  /// Updates an existing goal.
  Future<Map<String, dynamic>?> updateGoal(
    String goalId, {
    int? target,
    String? period,
  }) async {
    final body = <String, dynamic>{};
    if (target != null) body['target'] = target;
    if (period != null) body['period'] = period;

    return _patch('/goals/$goalId', body: body);
  }

  // ══════════════════════════════════════════════════════════════════════
  // Streaks API
  // ══════════════════════════════════════════════════════════════════════

  /// Fetches the user's streak data.
  Future<Map<String, dynamic>?> getStreak() async {
    return _get('/streaks');
  }

  /// Updates/records a streak event (e.g. marks today as active).
  Future<Map<String, dynamic>?> recordStreakActivity() async {
    return _post('/streaks');
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Response Models
// ══════════════════════════════════════════════════════════════════════════

/// Represents a paginated response from the QF User API.
///
/// The QF API uses cursor-based pagination:
/// - `first` + `after` for forward pagination
/// - `last` + `before` for backward pagination
class QfPaginatedResponse {
  final List<Map<String, dynamic>> items;
  final bool hasNextPage;
  final String? endCursor;

  const QfPaginatedResponse({
    required this.items,
    this.hasNextPage = false,
    this.endCursor,
  });

  factory QfPaginatedResponse.fromJson(Map<String, dynamic> json) {
    // The API may nest items under 'data', 'bookmarks', 'items', etc.
    // We attempt multiple common patterns.
    List<dynamic> rawItems = [];

    if (json.containsKey('data')) {
      final data = json['data'];
      if (data is List) {
        rawItems = data;
      } else if (data is Map) {
        // Nested edges/nodes pattern
        rawItems =
            (data['edges'] as List?)?.map((e) => e['node'] ?? e).toList() ?? [];
      }
    } else if (json.containsKey('bookmarks')) {
      rawItems = json['bookmarks'] as List? ?? [];
    } else if (json.containsKey('reading_sessions')) {
      rawItems = json['reading_sessions'] as List? ?? [];
    } else if (json.containsKey('goals')) {
      rawItems = json['goals'] as List? ?? [];
    } else if (json.containsKey('items')) {
      rawItems = json['items'] as List? ?? [];
    }

    // Pagination info
    final pageInfo = json['pageInfo'] ?? json['page_info'] ?? {};
    final hasNext =
        pageInfo['hasNextPage'] ?? pageInfo['has_next_page'] ?? false;
    final cursor = pageInfo['endCursor'] ?? pageInfo['end_cursor'];

    return QfPaginatedResponse(
      items: rawItems.cast<Map<String, dynamic>>(),
      hasNextPage: hasNext as bool,
      endCursor: cursor as String?,
    );
  }

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get length => items.length;
}
