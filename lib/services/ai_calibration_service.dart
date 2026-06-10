import 'package:cloud_functions/cloud_functions.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/utils/app_logger.dart';
import 'package:quran_app/utils/id_generator.dart';

/// Generates AI-powered weekly calibration suggestions based on performance data.
///
/// Sends the user's weekly snapshot (sessions, completion, assessments) to Gemini
/// and receives personalized suggestions with reasoning. Falls back to the
/// existing deterministic suggestion engine on failure.
///
/// **Trigger**: Called after every 7th completed session (configurable).
class AICalibrationService {
  /// Number of sessions between AI calibrations.
  static const int calibrationInterval = 7;

  AICalibrationService();

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

      final callable = FirebaseFunctions.instanceFor(
        region: 'europe-west1',
      ).httpsCallable('generateCalibration');

      final result = await callable
          .call<Map<Object?, Object?>>({
            'context': contextMap,
            'systemPrompt': _calibrationPrompt,
          })
          .timeout(const Duration(seconds: 20));

      final data = result.data;
      if (data.isEmpty) {
        throw Exception('AI returned empty response.');
      }

      final raw = Map<String, dynamic>.from(data);
      return _parseCalibrationResponse(raw);
    } catch (e) {
      AppLogger.info('AICalib', 'AI calibration failed, falling back: $e');
      return [];
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
