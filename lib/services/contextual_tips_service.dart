import 'package:quran_app/models/hifz_models.dart';

/// Provides contextual tips during sessions and predicts page difficulty
/// based on Quranic page characteristics and user history.
///
/// Tips are surfaced in the RecipeGuideWidget and session overlay
/// to help users approach difficult pages with the right strategy.
class ContextualTipsService {
  /// Known difficult page ranges in the Mushaf.
  /// These pages have longer ayat, complex vocabulary, or dense text.
  static const _difficultRanges = [
    _PageRange(1, 9, 'Al-Fatiha & early Al-Baqarah — foundational but dense'),
    _PageRange(49, 62, 'Legal passages in Al-Baqarah — detailed rulings'),
    _PageRange(77, 87, 'Al-Imran — long narrative passages'),
    _PageRange(100, 106, 'Al-Nisa — complex legal verses'),
    _PageRange(235, 240, 'Al-Anfal — battle narratives'),
    _PageRange(282, 293, 'Hud — repetitive story patterns (watch for mix-ups)'),
    _PageRange(350, 360, 'Al-Kahf — long connected narrative'),
    _PageRange(489, 504, 'Ya-Sin through As-Saffat — shorter but similar surahs'),
  ];

  /// Get the predicted difficulty for a page (0.0=easy, 1.0=very hard).
  PageDifficulty predictDifficulty({
    required int pageNumber,
    required MemoryProfile profile,
    List<Map<String, dynamic>>? pageHistory,
  }) {
    double score = 0.0;
    final reasons = <String>[];

    // 1. Structural difficulty (known hard ranges)
    for (final range in _difficultRanges) {
      if (pageNumber >= range.start && pageNumber <= range.end) {
        score += 0.3;
        reasons.add(range.note);
        break;
      }
    }

    // 2. Early pages are harder (more text, longer ayat)
    if (pageNumber <= 100) {
      score += 0.15;
      reasons.add('Early Mushaf pages tend to have longer, denser verses');
    } else if (pageNumber >= 500) {
      // Last juz is generally easier (shorter surahs)
      score -= 0.1;
      reasons.add('Shorter surahs — generally easier to memorize');
    }

    // 3. User-specific: check past performance on nearby pages
    if (pageHistory != null && pageHistory.isNotEmpty) {
      final nearbyWeak = pageHistory.where((h) {
        final p = h['page'] as int? ?? 0;
        final assessment = h['assessment'] as String? ?? '';
        return (p - pageNumber).abs() <= 5 && assessment == 'needsWork';
      }).length;

      if (nearbyWeak >= 2) {
        score += 0.2;
        reasons.add('You found nearby pages challenging — this one may be similar');
      }
    }

    // 4. Age group adjustment
    if (profile.ageGroup == AgeGroup.senior || profile.ageGroup == AgeGroup.elderly) {
      score += 0.1;
      reasons.add('Adjusted for your learning pace');
    }

    // 5. Experience bonus
    if (profile.hifzExperience == HifzExperience.reviewing) {
      score -= 0.15;
    }

    // Clamp to [0, 1]
    score = score.clamp(0.0, 1.0);

    return PageDifficulty(
      score: score,
      level: _scoreToLevel(score),
      reasons: reasons,
      tips: _generateTips(score, profile, pageNumber),
    );
  }

  /// Get tips relevant to the current session phase and page.
  List<String> getSessionTips({
    required SessionPhase phase,
    required int pageNumber,
    required MemoryProfile profile,
  }) {
    final tips = <String>[];

    // Phase-specific tips
    switch (phase) {
      case SessionPhase.sabaq:
        tips.add('Focus on understanding the meaning first — memorization follows naturally.');
        if (profile.learningPreference == LearningPreference.auditory) {
          tips.add('Try listening with eyes closed, then open the Mushaf and follow along.');
        } else if (profile.learningPreference == LearningPreference.visual) {
          tips.add('Pay attention to where each verse starts on the page — visual anchoring helps retention.');
        }
        if (pageNumber <= 100) {
          tips.add('These early pages have longer verses. Try breaking them into smaller segments.');
        }
        break;

      case SessionPhase.sabqi:
        tips.add('Recite from memory first, then check. Retrieval practice strengthens retention.');
        tips.add('If you stumble, note the exact word — that\'s your anchor point for review.');
        break;

      case SessionPhase.manzil:
        tips.add('Speed matters less than accuracy. Read carefully and catch any drift.');
        tips.add('Try reciting to someone else — social recall is more effective than solo review.');
        break;

      case SessionPhase.flashcards:
        tips.add('Flashcards test your recall — try to answer before revealing the answer.');
        break;
    }

    // Age-specific tips
    if (profile.ageGroup == AgeGroup.senior || profile.ageGroup == AgeGroup.elderly) {
      tips.add('Take breaks between repetitions. Short, frequent sessions beat long ones.');
    }

    if (profile.ageGroup == AgeGroup.child || profile.ageGroup == AgeGroup.teen) {
      tips.add('Try connecting the verses to a story or image in your mind.');
    }

    return tips;
  }

  // ── Private helpers ──

  DifficultyLevel _scoreToLevel(double score) {
    if (score <= 0.2) return DifficultyLevel.easy;
    if (score <= 0.45) return DifficultyLevel.moderate;
    if (score <= 0.7) return DifficultyLevel.challenging;
    return DifficultyLevel.hard;
  }

  List<String> _generateTips(double score, MemoryProfile profile, int page) {
    final tips = <String>[];

    if (score > 0.5) {
      tips.add('This page may take extra repetitions. Be patient with yourself.');
      tips.add('Consider splitting this page into two sessions if it feels overwhelming.');
    }

    if (profile.learningPreference == LearningPreference.auditory) {
      tips.add('Listen to this page on repeat while doing other tasks to build familiarity.');
    }

    if (profile.learningPreference == LearningPreference.kinesthetic) {
      tips.add('Try writing out the verses by hand — motor memory reinforces recall.');
    }

    if (profile.encodingSpeed == EncodingSpeed.slow) {
      tips.add('Give yourself 2-3 extra repetitions. Slow encoding leads to stronger long-term retention.');
    }

    return tips;
  }
}

/// A predicted difficulty assessment for a Mushaf page.
class PageDifficulty {
  final double score; // 0.0–1.0
  final DifficultyLevel level;
  final List<String> reasons;
  final List<String> tips;

  const PageDifficulty({
    required this.score,
    required this.level,
    this.reasons = const [],
    this.tips = const [],
  });
}

/// Difficulty levels for UI display.
enum DifficultyLevel {
  easy,
  moderate,
  challenging,
  hard;

  String get label => switch (this) {
        easy => 'Easy',
        moderate => 'Moderate',
        challenging => 'Challenging',
        hard => 'Hard',
      };

  String get emoji => switch (this) {
        easy => '🟢',
        moderate => '🟡',
        challenging => '🟠',
        hard => '🔴',
      };
}

/// Internal helper for marking difficult page ranges.
class _PageRange {
  final int start;
  final int end;
  final String note;

  const _PageRange(this.start, this.end, this.note);
}
