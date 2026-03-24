import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/services/plan_generation_service.dart';
import 'package:quran_app/services/hifz_database_service.dart';

/// Provides offline/fallback plan generation when AI is unavailable.
///
/// This service:
/// - Delegates to the existing deterministic [PlanGenerationService] for the plan structure
/// - Generates template-based session recipes based on the user's learning preference
/// - Provides a consistent experience even without network connectivity
class OfflineFallbackService {
  final PlanGenerationService _planService;

  OfflineFallbackService(HifzDatabaseService db) : _planService = PlanGenerationService(db);

  /// Generate a complete fallback response (plan + template recipes).
  ///
  /// Returns a map shaped identically to the validated AI response,
  /// so downstream code doesn't need to differentiate.
  Future<Map<String, dynamic>> generateFallback({
    required MemoryProfile profile,
    bool forceRegenerate = false,
    bool isRecoveryMode = false,
  }) async {
    // 1. Use the existing deterministic plan service
    final dailyPlan = await _planService.generateTodayPlan(
      profile,
      forceRegenerate: forceRegenerate,
    );

    // 2. Generate template recipes based on learning preference
    final recipes = _generateTemplateRecipes(
      profile: profile,
      plan: dailyPlan,
      isRecoveryMode: isRecoveryMode,
    );

    // 3. Build the response in the same shape as validated AI output
    return {
      'plan': {
        'sabaq': {
          'page': dailyPlan.sabaqPage,
          'lineStart': dailyPlan.sabaqLineStart,
          'lineEnd': dailyPlan.sabaqLineEnd,
          'startVerse': dailyPlan.sabaqStartVerse,
        },
        'sabqi': {
          'pages': dailyPlan.sabqiPages,
        },
        'manzil': {
          'juz': dailyPlan.manzilJuz,
          'pages': dailyPlan.manzilPages,
        },
      },
      'recipes': recipes,
      'reasoning': isRecoveryMode
          ? 'Welcome back! This is a review-focused plan to help you ease back in. (Generated offline)'
          : 'Plan generated using your profile settings. (Generated offline — connect to the internet for AI-personalized plans)',
      'frameworkParams': {
        'dailySabaqLoad': '${dailyPlan.sabaqLineEnd - dailyPlan.sabaqLineStart + 1} lines',
        'minReps': dailyPlan.sabaqRepetitionTarget,
        'sabqiDaysBack': 7,
        'manzilPagesPerDay': dailyPlan.manzilPages.length,
        'timeDistribution': {
          'sabaq': dailyPlan.sabaqTargetMinutes,
          'sabqi': dailyPlan.sabqiTargetMinutes,
          'manzil': dailyPlan.manzilTargetMinutes,
        },
      },
      'dailyPlan': dailyPlan, // Pass through so caller can use directly
    };
  }

  /// The underlying daily plan (for direct use without recipes).
  Future<DailyPlan> generateFallbackPlan(
    MemoryProfile profile, {
    bool forceRegenerate = false,
  }) {
    return _planService.generateTodayPlan(
      profile,
      forceRegenerate: forceRegenerate,
    );
  }

  // ── Template Recipes ──

  Map<String, dynamic> _generateTemplateRecipes({
    required MemoryProfile profile,
    required DailyPlan plan,
    bool isRecoveryMode = false,
  }) {
    final pref = profile.learningPreference;
    final lineRange = '${plan.sabaqLineStart}–${plan.sabaqLineEnd}';
    final pageRef = 'page ${plan.sabaqPage}';

    return {
      'sabaq': _sabaqRecipe(pref, lineRange, pageRef, plan.sabaqRepetitionTarget, isRecoveryMode),
      'sabqi': _sabqiRecipe(pref, plan.sabqiPages),
      'manzil': _manzilRecipe(pref, plan.manzilPages, plan.manzilJuz),
    };
  }

  Map<String, dynamic> _sabaqRecipe(
    LearningPreference pref,
    String lineRange,
    String pageRef,
    int targetReps,
    bool isRecoveryMode,
  ) {
    if (isRecoveryMode) {
      return {
        'steps': [
          _step(1, 'listen', 'Listen to the reciter read lines $lineRange of $pageRef. Just relax and follow along.', 3, 'times', '🎧'),
          _step(2, 'read_along', 'Read along with the audio at a comfortable pace.', 2, 'times', '📖'),
          _step(3, 'recite_memory', 'Try reciting from memory. No pressure — see what you remember.', 2, 'times', '🧠'),
        ],
        'estimatedMinutes': 15,
        'tips': ['Welcome back! Today is about reconnecting, not perfection.', 'Take it slow — momentum builds naturally.'],
      };
    }

    switch (pref) {
      case LearningPreference.auditory:
        return {
          'steps': [
            _step(1, 'listen', 'Listen to the reciter read lines $lineRange of $pageRef carefully.', 3, 'times', '🎧'),
            _step(2, 'read_along', 'Play the audio and read along out loud, matching the pace.', 3, 'times', '📖'),
            _step(3, 'listen', 'Listen once more with your eyes closed, trying to hear each word.', 1, 'times', '🎧'),
            _step(4, 'recite_memory', 'Turn off audio and recite from memory.', targetReps.clamp(3, 10), 'times', '🧠'),
            _step(5, 'self_test', 'Final recitation without any aid. You can do this!', 1, 'times', '✅'),
          ],
          'estimatedMinutes': 25,
          'tips': ['Focus on the melody and rhythm of the recitation.', 'Record yourself and compare with the reciter.'],
        };

      case LearningPreference.visual:
        return {
          'steps': [
            _step(1, 'read_solo', 'Read lines $lineRange of $pageRef slowly, noting the position of each verse.', 3, 'times', '👁️'),
            _step(2, 'listen', 'Listen to the reciter while following along with your finger.', 2, 'times', '🎧'),
            _step(3, 'read_solo', 'Read again, focusing on tricky words and their visual position.', 2, 'times', '📖'),
            _step(4, 'recite_memory', 'Close the Mushaf and recite, visualizing the page layout.', targetReps.clamp(3, 10), 'times', '🧠'),
            _step(5, 'self_test', 'Final test: recite the passage once perfectly.', 1, 'times', '✅'),
          ],
          'estimatedMinutes': 25,
          'tips': ['Visualize where each verse sits on the page.', 'Pay attention to verse beginnings at line starts.'],
        };

      case LearningPreference.kinesthetic:
        return {
          'steps': [
            _step(1, 'listen', 'Listen to lines $lineRange of $pageRef while following in your Mushaf.', 2, 'times', '🎧'),
            _step(2, 'write', 'Write out the verses by hand on paper or a whiteboard.', 1, 'times', '✍️'),
            _step(3, 'read_solo', 'Read the passage while tracking each word with your finger.', 3, 'times', '📖'),
            _step(4, 'recite_memory', 'Cover the text and recite from memory.', targetReps.clamp(3, 10), 'times', '🧠'),
            _step(5, 'self_test', 'Final recitation — you know this!', 1, 'times', '✅'),
          ],
          'estimatedMinutes': 30,
          'tips': ['Writing engages extra memory pathways.', 'Use a physical Mushaf whenever possible.'],
        };

      case LearningPreference.repetition:
        final reps = targetReps.clamp(5, 15);
        return {
          'steps': [
            _step(1, 'read_solo', 'Read lines $lineRange of $pageRef carefully.', 3, 'times', '📖'),
            _step(2, 'recite_memory', 'Recite from memory (3×3 method: read 3, recite 3).', 3, 'times', '🧠'),
            _step(3, 'read_solo', 'Read again to reinforce.', 2, 'times', '📖'),
            _step(4, 'recite_memory', 'Recite from memory again — feel the flow.', reps, 'times', '🧠'),
            _step(5, 'link_practice', 'Connect these verses with the previous passage.', 2, 'times', '🔗'),
            _step(6, 'self_test', 'Final recitation — from start to finish, no pauses.', 1, 'times', '✅'),
          ],
          'estimatedMinutes': 30,
          'tips': ['The 3×3 method: Read 3x → Recite 3x → Read 2x → Final recite 3x.', 'Consistency beats speed. Trust the reps.'],
        };
    }
  }

  Map<String, dynamic> _sabqiRecipe(LearningPreference pref, List<int> pages) {
    if (pages.isEmpty) {
      return {'steps': <Map<String, dynamic>>[], 'estimatedMinutes': 0, 'tips': <String>[]};
    }

    final pageList = pages.join(', ');
    return {
      'steps': [
        _step(1, 'recite_memory', 'Recite pages $pageList from memory. Note any weak spots.', 2, 'times', '🧠'),
        _step(2, 'read_solo', 'Open any pages where you stumbled and review them.', 2, 'times', '📖'),
        _step(3, 'recite_memory', 'Final recitation of weak sections.', 1, 'times', '🧠'),
      ],
      'estimatedMinutes': 15,
      'tips': ['Focus extra time on mutashabihat (similar-sounding verses).'],
    };
  }

  Map<String, dynamic> _manzilRecipe(LearningPreference pref, List<int> pages, int juz) {
    if (pages.isEmpty) {
      return {'steps': <Map<String, dynamic>>[], 'estimatedMinutes': 0, 'tips': <String>[]};
    }

    final pageList = pages.join(', ');
    return {
      'steps': [
        _step(1, 'recite_memory', 'Recite pages $pageList (Juz $juz) at a steady pace.', 1, 'times', '🧠'),
        _step(2, 'review_meaning', 'Reflect on the meaning of any verses that felt disconnected.', 5, 'minutes', '💭'),
      ],
      'estimatedMinutes': 10,
      'tips': ['Manzil review maintains your long-term retention. Consistency is key.'],
    };
  }

  // ── Helper ──

  static Map<String, dynamic> _step(
    int number, String action, String instruction, int target, String unit, String icon,
  ) => {
    'stepNumber': number,
    'action': action,
    'instruction': instruction,
    'target': target,
    'unit': unit,
    'icon': icon,
  };
}
