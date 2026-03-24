import 'package:flutter/material.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/services/ai_plan_service.dart';
import 'package:quran_app/services/hifz_database_service.dart';

/// Detects extended breaks (3+ missed days) and generates a compassionate
/// review-first recovery plan to ease the user back into memorization.
///
/// **Detection**: Uses `HifzDatabaseService.getMissedDays()` which counts
/// missed *active* days (respecting rest days) since the last session.
/// **Recovery plan**: Lighter load, review-focused, with a ramp-up schedule.
/// **AI mode**: Uses Gemini's recovery mode for personalized re-entry guidance.
/// **Offline mode**: Falls back to a deterministic review-first template plan.
class BreakRecoveryService {
  final HifzDatabaseService _db;
  final AIPlanService? _aiService;

  /// Minimum consecutive missed active days before triggering recovery mode.
  static const int breakThresholdDays = 3;

  BreakRecoveryService(this._db, {AIPlanService? aiService})
      : _aiService = aiService;

  /// Check if the user is returning from a break.
  ///
  /// Returns the number of missed active days, or 0 if not on a break.
  Future<int> detectBreak(MemoryProfile profile) async {
    final missedDays = await _db.getMissedDays(
      profile.id,
      activeDays: profile.activeDays,
    );
    return missedDays >= breakThresholdDays ? missedDays : 0;
  }

  /// Determine the recovery intensity based on break length.
  RecoveryIntensity getRecoveryIntensity(int missedDays) {
    if (missedDays <= 5) return RecoveryIntensity.light;
    if (missedDays <= 14) return RecoveryIntensity.moderate;
    return RecoveryIntensity.full;
  }

  /// Generate a compassionate recovery message based on break duration.
  RecoveryMessage getRecoveryMessage(int missedDays) {
    if (missedDays <= 5) {
      return const RecoveryMessage(
        emoji: '🌱',
        title: 'Welcome back!',
        message: "A few days away is perfectly fine. Let's do a light review to refresh your memory before continuing.",
        encouragement: 'Your previous progress is still there — it just needs a gentle refresh.',
      );
    } else if (missedDays <= 14) {
      return RecoveryMessage(
        emoji: '🌿',
        title: 'Great to see you again!',
        message: "It's been $missedDays days. Let's start with a focused review session to rebuild your confidence.",
        encouragement: 'The fact that you came back shows real commitment. That matters more than any streak.',
      );
    } else {
      return RecoveryMessage(
        emoji: '🌳',
        title: "You're back — that's what counts!",
        message: "It's been a while ($missedDays days), but every return is a victory. Let's review at your own pace.",
        encouragement: 'The Quran is patient with those who return to it. So are we. No rush, no pressure.',
      );
    }
  }

  /// Generate a recovery plan.
  ///
  /// Tries AI first (recovery mode), falls back to a deterministic template.
  /// Returns a map matching the DailyPlan structure with reduced load.
  Future<Map<String, dynamic>> generateRecoveryPlan({
    required MemoryProfile profile,
    required int missedDays,
  }) async {
    final intensity = getRecoveryIntensity(missedDays);

    // Try AI recovery
    if (_aiService != null) {
      try {
        final progressSnapshot = await _buildProgressSnapshot(profile);
        final result = await _aiService.generatePlan(
          profile: profile,
          progressSnapshot: {
            ...progressSnapshot,
            'missedDays': missedDays,
            'recoveryIntensity': intensity.name,
          },
          recentSessions: [],
          isRecoveryMode: true,
        );
        return result;
      } catch (e) {
        debugPrint('AI recovery plan failed, using template: $e');
      }
    }

    // Deterministic fallback: review-first plan
    return _buildTemplatePlan(profile, missedDays, intensity);
  }

  /// Build a progress snapshot for the AI context.
  Future<Map<String, dynamic>> _buildProgressSnapshot(MemoryProfile profile) async {
    try {
      final sessions = await _db.getSessionHistory(profile.id, limit: 10);
      final totalPages = sessions.length;
      final strongSessions = sessions.where((s) =>
          s.sabaqAssessment == SelfAssessment.strong).length;

      return {
        'totalSessions': totalPages,
        'strongSessions': strongSessions,
        'currentSabaqPage': profile.startingPage,
      };
    } catch (e) {
      debugPrint('[AI] Break recovery progress fetch failed: $e');
      return {
        'totalSessions': 0,
        'strongSessions': 0,
        'currentSabaqPage': profile.startingPage,
      };
    }
  }

  /// Build a deterministic review-focused recovery plan.
  Map<String, dynamic> _buildTemplatePlan(
    MemoryProfile profile,
    int missedDays,
    RecoveryIntensity intensity,
  ) {
    // Recovery: no new sabaq, only review
    final currentPage = profile.startingPage;

    // Time reduction based on intensity
    final timeMultiplier = switch (intensity) {
      RecoveryIntensity.light => 0.7,
      RecoveryIntensity.moderate => 0.5,
      RecoveryIntensity.full => 0.3,
    };

    final dailyMinutes = (profile.dailyTimeMinutes * timeMultiplier).round();

    return {
      'plan': {
        'sabaq_page': currentPage,
        'sabaq_line_start': 1,
        'sabaq_line_end': 5, // Reduced from full page
        'sabaq_repetition_target': 3, // Gentle target
        'sabaq_target_minutes': (dailyMinutes * 0.3).round(),
        'sabqi_pages': <int>[], // Will be filled by validator
        'sabqi_target_minutes': (dailyMinutes * 0.4).round(),
        'manzil_pages': <int>[],
        'manzil_juz': 0,
        'manzil_target_minutes': (dailyMinutes * 0.3).round(),
        'estimated_minutes': dailyMinutes,
      },
      'reasoning': _buildRecoveryReasoning(missedDays, intensity),
      'recipes': {
        'sabaq': {
          'steps': [
            {
              'action': 'listen',
              'target': 3,
              'unit': 'repetitions',
              'instruction': 'Listen to the page being recited. Just listen — no pressure to follow along.',
              'icon': '🎧',
            },
            {
              'action': 'read_aloud',
              'target': 2,
              'unit': 'repetitions',
              'instruction': 'Read along softly with the audio. Let the words come back naturally.',
              'icon': '📖',
            },
          ],
          'tips': [
            'This is a recovery session — be gentle with yourself.',
            'Focus on reconnecting with the Quran, not on speed.',
          ],
        },
      },
    };
  }

  String _buildRecoveryReasoning(int missedDays, RecoveryIntensity intensity) {
    return switch (intensity) {
      RecoveryIntensity.light =>
        'Light recovery after $missedDays days away. Focus on refreshing recent memorization with reduced repetitions.',
      RecoveryIntensity.moderate =>
        'Moderate recovery after $missedDays days. Prioritizing review over new content to rebuild confidence and retention.',
      RecoveryIntensity.full =>
        'Full recovery mode after $missedDays days. Starting very gently with review only. New memorization resumes after 2-3 successful sessions.',
    };
  }
}

/// Recovery intensity levels.
enum RecoveryIntensity { light, moderate, full }

/// A compassionate recovery message shown to the user after a break.
class RecoveryMessage {
  final String emoji;
  final String title;
  final String message;
  final String encouragement;

  const RecoveryMessage({
    required this.emoji,
    required this.title,
    required this.message,
    required this.encouragement,
  });
}
