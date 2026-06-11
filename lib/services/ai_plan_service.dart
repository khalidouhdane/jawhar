import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:quran_app/config/api_config.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/utils/app_logger.dart';

/// Signature for the legacy Firebase callable invocation (injectable for
/// tests — the default talks to `generateDailyPlan` in europe-west1).
typedef AiCallableInvoker =
    Future<Map<String, dynamic>> Function(Map<String, dynamic> payload);

/// Custom exception for AI service errors.
class AIPlanException implements Exception {
  final String message;
  final String? rawResponse;
  final bool isRetryable;

  const AIPlanException(
    this.message, {
    this.rawResponse,
    this.isRetryable = false,
  });

  @override
  String toString() => 'AIPlanException: $message';
}

/// Service for generating AI-powered daily Hifz plans using Gemini.
///
/// This service:
/// - Builds user context from profile, progress, and session history
/// - Sends context + system prompt to Gemini for plan generation
/// - Returns structured JSON plan with session recipes and guidance
/// - Supports model switching between Flash and Pro for dev testing
///
/// Transport selection (roadmap §8 Phase 3 task 5): when [kUseApiV1Ai] is
/// baked in AND a [kJawharApiBaseUrl] is configured, the call goes to
/// `POST {base}/v1/me/plan:enhance` on jawhar-api with a Firebase ID token.
/// ANY failure on that path falls through to the legacy callable chain —
/// the API transport must never be worse than the callable.
class AIPlanService {
  // ── Constants ──

  /// Fallback system prompt if the asset can't be loaded.
  static const _fallbackSystemPrompt = '''
You are a Quran memorization (Hifz) planning assistant.
Generate a daily plan based on the user's profile and progress.
Return valid JSON only.
''';

  // ── State ──

  final bool _useApiV1Ai;
  final String _apiBaseUrl;
  final http.Client? _httpClient;
  final Future<String?> Function()? _idTokenProvider;
  final AiCallableInvoker? _callableInvoker;

  AIPlanService({
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

  /// Whether using the Pro model (now handled on backend).
  bool get isProModel => true;

  // ── Context Building ──

  /// Build a comprehensive user context map for the AI prompt.
  ///
  /// Includes profile data, progress snapshot, recent sessions,
  /// and temporal context (day of week, active day status).
  Map<String, dynamic> buildUserContext({
    required MemoryProfile profile,
    required Map<String, dynamic> progressSnapshot,
    required List<Map<String, dynamic>> recentSessions,
  }) {
    final now = DateTime.now();
    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final todayIndex = now.weekday - 1; // 0-indexed

    return {
      'profile': {
        'age': profile.age,
        'ageGroup': profile.ageGroup.name,
        'encodingSpeed': profile.encodingSpeed.name,
        'retentionStrength': profile.retentionStrength.name,
        'learningPreference': profile.learningPreference.name,
        'dailyTimeMinutes': profile.dailyTimeMinutes,
        'activeDays': profile.activeDays,
        'activeDayNames': profile.activeDays.map((d) => dayNames[d]).toList(),
        'pacePreference': profile.pacePreference.name,
        'hifzExperience': profile.hifzExperience.name,
        'goal': profile.goal.name,
        'goalDetails': profile.goalDetails,
        'startingPage': profile.startingPage,
      },
      'progress': progressSnapshot,
      'recentSessions': recentSessions,
      'temporal': {
        'todayIs': dayNames[todayIndex],
        'todayIndex': todayIndex,
        'isActiveDay': profile.activeDays.contains(todayIndex),
        'date': now.toIso8601String().substring(0, 10),
      },
    };
  }

  // ── Plan Generation ──

  /// Generate a daily plan using Gemini AI.
  ///
  /// Loads the system prompt from assets, builds user context,
  /// sends to Gemini, and returns the parsed JSON plan.
  ///
  /// Throws [AIPlanException] on any failure.
  Future<Map<String, dynamic>> generatePlan({
    required MemoryProfile profile,
    required Map<String, dynamic> progressSnapshot,
    required List<Map<String, dynamic>> recentSessions,
    String? systemPromptOverride,
    bool isRecoveryMode = false,
  }) async {
    // 1. Load system prompt
    final systemPrompt = systemPromptOverride ?? await _loadSystemPrompt();

    // 2. Build user context
    final context = buildUserContext(
      profile: profile,
      progressSnapshot: progressSnapshot,
      recentSessions: recentSessions,
    );

    final payload = <String, dynamic>{
      'context': context,
      'isRecoveryMode': isRecoveryMode,
      'systemPrompt': systemPrompt,
    };

    // 3a. Alternate transport: jawhar-api /v1, behind the compile-time flag.
    // Any failure (no token, non-200, bad JSON, timeout) falls through to
    // the callable below — same behavior chain as today.
    if (_useApiV1Ai && _apiBaseUrl.isNotEmpty) {
      try {
        final viaApi = await _postJsonAuthenticated(
          path: '/v1/me/plan:enhance',
          payload: payload,
        );
        if (viaApi != null && viaApi.isNotEmpty) return viaApi;
        AppLogger.warn('AIPlan', 'API transport unusable, using callable.');
      } catch (e) {
        AppLogger.warn('AIPlan', 'API transport failed, using callable: $e');
      }
    }

    // 3b. Call Firebase Cloud Function (legacy path, unchanged).
    try {
      final data = await _invokeCallable(payload);
      if (data.isEmpty) {
        throw const AIPlanException(
          'AI returned empty response.',
          isRetryable: true,
        );
      }
      return data;
    } on FirebaseFunctionsException catch (e) {
      throw AIPlanException(
        'Backend service error: ${e.message}',
        rawResponse: e.details?.toString(),
        isRetryable: true,
      );
    } catch (e) {
      if (e is AIPlanException) rethrow;
      throw AIPlanException(
        'Failed to generate AI plan: ${e.toString()}',
        isRetryable: true,
      );
    }
  }

  // ── Private Helpers ──

  /// Invoke the legacy callable (or the injected test double).
  Future<Map<String, dynamic>> _invokeCallable(
    Map<String, dynamic> payload,
  ) async {
    final invoker = _callableInvoker;
    if (invoker != null) return invoker(payload);

    final callable = FirebaseFunctions.instanceFor(
      region: 'europe-west1',
    ).httpsCallable('generateDailyPlan');

    final result = await callable
        .call<Map<Object?, Object?>>(payload)
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw const AIPlanException(
              'AI plan generation timed out after 20 seconds. Check your connection.',
              isRetryable: true,
            );
          },
        );

    // Convert Map<Object?, Object?> to Map<String, dynamic>
    return Map<String, dynamic>.from(result.data);
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
      AppLogger.warn('AIPlan', 'No Firebase ID token; skipping API path.');
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
          'AIPlan',
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
      AppLogger.warn('AIPlan', 'Failed to get ID token: $e');
      return null;
    }
  }

  /// Load the system prompt from assets, with fallback.
  Future<String> _loadSystemPrompt() async {
    try {
      return await rootBundle.loadString(
        'assets/prompts/plan_system_prompt_v1.md',
      );
    } catch (e) {
      AppLogger.info(
        'AIPlan',
        'Failed to load system prompt asset, using fallback: $e',
      );
      return _fallbackSystemPrompt;
    }
  }
}
