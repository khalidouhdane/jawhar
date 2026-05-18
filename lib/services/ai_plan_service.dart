import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/utils/app_logger.dart';

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
class AIPlanService {
  // ── Constants ──

  /// Fallback system prompt if the asset can't be loaded.
  static const _fallbackSystemPrompt = '''
You are a Quran memorization (Hifz) planning assistant.
Generate a daily plan based on the user's profile and progress.
Return valid JSON only.
''';

  // ── State ──

  AIPlanService();

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

    // 3. Call Firebase Cloud Function
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('generateDailyPlan');

      final result = await callable
          .call<Map<Object?, Object?>>({
            'context': context,
            'isRecoveryMode': isRecoveryMode,
            'systemPrompt': systemPrompt,
          })
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              throw const AIPlanException(
                'AI plan generation timed out after 20 seconds. Check your connection.',
                isRetryable: true,
              );
            },
          );

      final data = result.data;
      if (data.isEmpty) {
        throw const AIPlanException(
          'AI returned empty response.',
          isRetryable: true,
        );
      }

      // Convert Map<Object?, Object?> to Map<String, dynamic>
      return Map<String, dynamic>.from(data);
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
