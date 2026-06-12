import 'dart:async';
import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:quran_app/config/api_config.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/services/ai_plan_service.dart' show AiCallableInvoker;
import 'package:quran_app/utils/app_logger.dart';
import 'package:quran_app/utils/id_generator.dart';

/// Generates AI-powered weekly calibration suggestions based on performance data.
///
/// Sends the user's weekly snapshot (sessions, completion, assessments) to Gemini
/// and receives personalized suggestions with reasoning. Falls back to the
/// existing deterministic suggestion engine on failure.
///
/// **Trigger**: Called after every 7th completed session (configurable).
///
/// Transport selection mirrors [AIPlanService] (roadmap §8 Phase 3 task 5):
/// with `kUseApiV1Ai` on and a base URL baked in, the call goes to
/// `POST {base}/v1/me/calibration:run` with a Firebase ID token; ANY failure
/// falls through to the legacy callable, then to the deterministic fallback.
class AICalibrationService {
  /// Number of sessions between AI calibrations.
  static const int calibrationInterval = 7;

  final bool _useApiV1Ai;
  final String _apiBaseUrl;
  final http.Client? _httpClient;
  final Future<String?> Function()? _idTokenProvider;
  final AiCallableInvoker? _callableInvoker;

  AICalibrationService({
    bool? useApiV1Ai,
    String? apiBaseUrl,
    http.Client? httpClient,
    Future<String?> Function()? idTokenProvider,
    AiCallableInvoker? callableInvoker,
  }) : _useApiV1Ai = useApiV1Ai ?? kUseApiV1Ai,
       _apiBaseUrl = apiBaseUrl ?? kJawharApiBaseUrl,
       _httpClient = httpClient,
       _idTokenProvider = idTokenProvider,
       _callableInvoker = callableInvoker;

  /// Check whether a calibration is due based on total session count.
  bool isCalibrationDue(
    int totalSessionCount, {
    DateTime? lastCalibrationDate,
  }) {
    if (totalSessionCount <= 0 ||
        totalSessionCount % calibrationInterval != 0) {
      return false;
    }
    if (lastCalibrationDate != null) {
      final elapsed = DateTime.now().toUtc().difference(
        lastCalibrationDate.toUtc(),
      );
      if (elapsed < const Duration(days: calibrationInterval)) return false;
    }
    return true;
  }

  /// Generate AI-powered calibration suggestions.
  ///
  /// Returns a list of [Suggestion] objects with AI-generated reasoning.
  /// Falls back to an empty list on failure (caller should use deterministic fallback).
  Future<List<Suggestion>> generateCalibration({
    required MemoryProfile profile,
    required WeeklySnapshot currentWeek,
    WeeklySnapshot? previousWeek,
    required int totalSessionCount,
  }) async {
    try {
      final contextMap = _buildCalibrationContext(
        profile: profile,
        current: currentWeek,
        previous: previousWeek,
        totalSessions: totalSessionCount,
      );

      final payload = <String, dynamic>{
        'context': contextMap,
        'systemPrompt': _calibrationPrompt,
      };

      // Alternate transport: jawhar-api /v1, behind the compile-time flag.
      // Any failure falls through to the callable below — the API path must
      // never be worse than the callable path.
      if (_useApiV1Ai && _apiBaseUrl.isNotEmpty) {
        try {
          final viaApi = await _postJsonAuthenticated(
            path: '/v1/me/calibration:run',
            payload: payload,
          );
          if (viaApi != null && viaApi.isNotEmpty) {
            return _parseCalibrationResponse(viaApi);
          }
          AppLogger.warn('AICalib', 'API transport unusable, using callable.');
        } catch (e) {
          AppLogger.warn('AICalib', 'API transport failed, using callable: $e');
        }
      }

      final raw = await _invokeCallable(payload);
      if (raw.isEmpty) {
        throw Exception('AI returned empty response.');
      }
      return _parseCalibrationResponse(raw);
    } catch (e) {
      AppLogger.info('AICalib', 'AI calibration failed, falling back: $e');
      return [];
    }
  }

  /// Invoke the legacy callable (or the injected test double).
  Future<Map<String, dynamic>> _invokeCallable(
    Map<String, dynamic> payload,
  ) async {
    final invoker = _callableInvoker;
    if (invoker != null) return invoker(payload);

    final callable = FirebaseFunctions.instanceFor(
      region: 'europe-west1',
    ).httpsCallable('generateCalibration');

    final result = await callable
        .call<Map<Object?, Object?>>(payload)
        .timeout(const Duration(seconds: 20));

    // Deep-convert: nested maps from the platform channel are
    // Map<Object?, Object?>; a shallow .from() breaks nested casts.
    return _deepStringKeyed(result.data) as Map<String, dynamic>;
  }

  static dynamic _deepStringKeyed(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (k, v) => MapEntry(k.toString(), _deepStringKeyed(v)),
      );
    }
    if (value is List) return value.map(_deepStringKeyed).toList();
    return value;
  }

  /// POST [payload] to `{base}{path}` on jawhar-api with a Firebase ID
  /// token. Returns the decoded JSON object, or `null` when the call cannot
  /// be made / did not succeed (callers fall back to the callable).
  Future<Map<String, dynamic>?> _postJsonAuthenticated({
    required String path,
    required Map<String, dynamic> payload,
  }) async {
    final token = await _getIdToken();
    if (token == null || token.isEmpty) {
      AppLogger.warn('AICalib', 'No Firebase ID token; skipping API path.');
      return null;
    }

    final base = _apiBaseUrl.endsWith('/')
        ? _apiBaseUrl.substring(0, _apiBaseUrl.length - 1)
        : _apiBaseUrl;
    final uri = Uri.parse('$base$path');

    final client = _httpClient ?? http.Client();
    try {
      final response = await client
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        AppLogger.warn(
          'AICalib',
          'API $path returned HTTP ${response.statusCode}; falling back.',
        );
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      return decoded;
    } finally {
      if (_httpClient == null) client.close();
    }
  }

  /// Current user's Firebase ID token, or `null` (signed out / auth error).
  Future<String?> _getIdToken() async {
    final provider = _idTokenProvider;
    try {
      if (provider != null) return await provider();
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (e) {
      AppLogger.warn('AICalib', 'Failed to get ID token: $e');
      return null;
    }
  }

  /// Build context map for the calibration prompt.
  Map<String, dynamic> _buildCalibrationContext({
    required MemoryProfile profile,
    required WeeklySnapshot current,
    WeeklySnapshot? previous,
    required int totalSessions,
  }) {
    return {
      'totalSessionsCompleted': totalSessions,
      'currentWeek': {
        'totalSessions': current.totalSessions,
        'totalMinutes': current.totalDurationMinutes,
        'avgMinutes': current.avgDurationMinutes.toStringAsFixed(1),
        'completionRate': (current.completionRate * 100).toStringAsFixed(0),
        'strong': current.strongCount,
        'okay': current.okayCount,
        'needsWork': current.needsWorkCount,
        'pagesMemorized': current.pagesMemorized,
        'pagesReviewed': current.pagesReviewed,
      },
      if (previous != null)
        'previousWeek': {
          'totalSessions': previous.totalSessions,
          'completionRate': (previous.completionRate * 100).toStringAsFixed(0),
          'strong': previous.strongCount,
          'okay': previous.okayCount,
          'needsWork': previous.needsWorkCount,
          'pagesMemorized': previous.pagesMemorized,
        },
      'profile': {
        'dailyTimeMinutes': profile.dailyTimeMinutes,
        'pacePreference': profile.pacePreference.name,
        'ageGroup': profile.ageGroup.name,
        'hifzExperience': profile.hifzExperience.name,
      },
    };
  }

  /// Parse the AI response into Suggestion objects.
  List<Suggestion> _parseCalibrationResponse(Map<String, dynamic> raw) {
    final suggestions = <Suggestion>[];
    final items = raw['suggestions'] as List<dynamic>? ?? [];

    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;

      final typeStr = item['type'] as String? ?? '';
      final type = _parseSuggestionType(typeStr);
      if (type == null) continue;

      suggestions.add(
        Suggestion(
          id: IdGenerator.uuidV4(),
          type: type,
          iconKey: item['iconKey'] as String? ?? 'lightbulb',
          title: item['title'] as String? ?? 'Suggestion',
          message: item['message'] as String? ?? '',
          createdAt: DateTime.now().toUtc(),
          data: {
            'reasoning': item['reasoning'] as String? ?? '',
            'source': 'ai_calibration',
          },
        ),
      );
    }

    // Safety: max 3 suggestions per calibration
    return suggestions.take(3).toList();
  }

  /// Map string type → SuggestionType enum.
  SuggestionType? _parseSuggestionType(String type) {
    switch (type.toLowerCase()) {
      case 'increase_load':
      case 'increaseload':
        return SuggestionType.increaseLoad;
      case 'decrease_load':
      case 'decreaseload':
        return SuggestionType.decreaseLoad;
      case 'more_review':
      case 'morereview':
        return SuggestionType.moreReview;
      case 'take_break':
      case 'takebreak':
        return SuggestionType.takeBreak;
      case 'ahead_of_schedule':
      case 'aheadofschedule':
        return SuggestionType.aheadOfSchedule;
      case 'neglected_juz':
      case 'neglectedjuz':
        return SuggestionType.neglectedJuz;
      case 'struggle_page':
      case 'strugglepage':
        return SuggestionType.strugglePage;
      default:
        return null;
    }
  }

  /// System prompt for the calibration AI call.
  static const _calibrationPrompt = '''
You are a Quran memorization (Hifz) coach analyzing a student's weekly performance.

Your job is to generate 1-3 personalized suggestions based on their data.
Each suggestion should be actionable and compassionate.

## Available Suggestion Types
- increase_load — Student is doing well, suggest memorizing more
- decrease_load — Student is struggling, suggest reducing load
- more_review — Weak assessments detected, suggest more review time
- take_break — Missing sessions, suggest a lighter plan
- ahead_of_schedule — Student is ahead, celebrate and suggest extra review
- neglected_juz — A juz hasn't been reviewed recently
- struggle_page — Consistently weak section detected

## Rules
1. NEVER suggest more than 3 items
2. Be encouraging, not critical — this is a spiritual practice
3. Consider the student's age group and experience level
4. If performance is steady and good, it's okay to return 0 suggestions
5. Each suggestion MUST have a reasoning field explaining WHY

## Output Format (JSON only)
{
  "suggestions": [
    {
      "type": "increase_load",
      "iconKey": "rocket",
      "title": "You're ready for more!",
      "message": "Your strong assessments this week show solid retention. Consider adding one extra page to your daily sabaq.",
      "reasoning": "85% completion rate with 70% strong assessments indicates capacity for increased load."
    }
  ]
}

If no suggestions are needed, return: {"suggestions": []}
''';
}
