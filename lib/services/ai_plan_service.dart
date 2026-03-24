import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:quran_app/models/hifz_models.dart';

/// Custom exception for AI service errors.
class AIPlanException implements Exception {
  final String message;
  final String? rawResponse;
  final bool isRetryable;

  const AIPlanException(this.message, {this.rawResponse, this.isRetryable = false});

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

  /// Bundled API key (dev phase only — will be proxied through backend later).
  static const _apiKey = 'AIzaSyD96foZ4BModJtXB8W2Kj-6Yewnx3uiBzA';

  /// Available model IDs.
  static const modelFlash = 'gemini-3.1-flash-lite-preview';
  static const modelPro = 'gemini-3.1-pro-preview';

  /// Fallback system prompt if the asset can't be loaded.
  static const _fallbackSystemPrompt = '''
You are a Quran memorization (Hifz) planning assistant.
Generate a daily plan based on the user's profile and progress.
Return valid JSON only.
''';

  // ── State ──

  String _activeModelName;
  GenerativeModel? _model;

  AIPlanService({String? model}) : _activeModelName = model ?? modelFlash;

  /// The active model name.
  String get activeModelName => _activeModelName;

  /// Whether using the Pro model.
  bool get isProModel => _activeModelName == modelPro;

  // ── Model Management ──

  /// Switch the active model (for dev testing).
  void setModel(String modelName) {
    if (modelName != _activeModelName) {
      _activeModelName = modelName;
      _model = null; // Force re-creation
    }
  }

  /// Get or create the GenerativeModel instance.
  GenerativeModel _getModel(String systemPrompt) {
    _model ??= GenerativeModel(
      model: _activeModelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.3,
        maxOutputTokens: 4096,
      ),
    );
    return _model!;
  }

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
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
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

    // 3. Build the user message
    final userMessage = _buildUserMessage(context, isRecoveryMode: isRecoveryMode);

    // 4. Call Gemini with timeout
    try {
      final model = _getModel(systemPrompt);
      final response = await model.generateContent([
        Content.text(userMessage),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw const AIPlanException(
            'AI plan generation timed out after 15 seconds. Check your connection.',
            isRetryable: true,
          );
        },
      );

      // 5. Parse response
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw const AIPlanException(
          'AI returned empty response.',
          isRetryable: true,
        );
      }

      try {
        final parsed = jsonDecode(text) as Map<String, dynamic>;
        return parsed;
      } catch (e) {
        throw AIPlanException(
          'AI returned invalid JSON: ${e.toString()}',
          rawResponse: text,
        );
      }
    } on AIPlanException {
      rethrow;
    } on GenerativeAIException catch (e) {
      // Handle rate limiting
      if (e.message.contains('429') || e.message.toLowerCase().contains('rate')) {
        throw AIPlanException(
          'AI rate limit reached. Please try again in a minute.',
          rawResponse: e.message,
          isRetryable: true,
        );
      }
      throw AIPlanException(
        'AI service error: ${e.message}',
        rawResponse: e.message,
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
      return await rootBundle.loadString('assets/prompts/plan_system_prompt_v1.md');
    } catch (e) {
      debugPrint('Failed to load system prompt asset, using fallback: $e');
      return _fallbackSystemPrompt;
    }
  }

  /// Build the user message sent to Gemini.
  String _buildUserMessage(
    Map<String, dynamic> context, {
    bool isRecoveryMode = false,
  }) {
    final contextJson = const JsonEncoder.withIndent('  ').convert(context);

    if (isRecoveryMode) {
      return '''
RECOVERY MODE: The user has returned after missed days.
Generate a lighter, review-focused plan to ease them back in.

User Context:
$contextJson

Generate the daily plan as JSON.''';
    }

    return '''
Generate today's memorization plan based on this user context:

$contextJson

Generate the daily plan as JSON.''';
  }
}
