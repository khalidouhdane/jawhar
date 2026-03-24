import 'package:quran_app/models/hifz_models.dart';

/// Generates personalized motivational messages based on the user's
/// progress, streak, milestones, and session history.
///
/// Messages are surfaced on the dashboard, at session start, and
/// after session completion to keep users engaged and encouraged.
class MotivationalMessagesService {
  /// Get a motivational message for the dashboard based on current state.
  MotivationalMessage getDashboardMessage({
    required MemoryProfile profile,
    required StreakData streak,
    required int totalPagesMemorized,
    WeeklySnapshot? currentWeek,
  }) {
    // Priority 1: Milestone celebrations
    final milestone = _checkMilestone(totalPagesMemorized);
    if (milestone != null) return milestone;

    // Priority 2: Streak messages
    if (streak.totalActiveDays > 0) {
      return _getStreakMessage(streak.totalActiveDays);
    }

    // Priority 3: Experience-based encouragement
    return _getExperienceMessage(profile, totalPagesMemorized);
  }

  /// Get a message shown at the start of a session.
  MotivationalMessage getSessionStartMessage({
    required MemoryProfile profile,
    required SessionPhase phase,
    required int pageNumber,
  }) {
    switch (phase) {
      case SessionPhase.sabaq:
        return _getSabaqStartMessage(profile, pageNumber);
      case SessionPhase.sabqi:
        return const MotivationalMessage(
          emoji: '🔁',
          text: 'Review strengthens what you\'ve built. Each repetition makes it more permanent.',
        );
      case SessionPhase.manzil:
        return const MotivationalMessage(
          emoji: '📚',
          text: 'Revision is the secret of the huffaz. What you review today, you keep forever.',
        );
      case SessionPhase.flashcards:
        return const MotivationalMessage(
          emoji: '🃏',
          text: 'Test your recall — active retrieval is the fastest path to permanent memory.',
        );
    }
  }

  /// Get a message shown after completing a session.
  MotivationalMessage getSessionCompleteMessage({
    required int sessionDurationMinutes,
    required String assessment,
    required int totalPagesMemorized,
    required int streakDays,
  }) {
    // Assessment-based messages
    switch (assessment) {
      case 'strong':
        return MotivationalMessage(
          emoji: '🌟',
          text: 'Excellent session! You\'re building a solid foundation, one page at a time.',
          subtitle: _getProgressContext(totalPagesMemorized),
        );
      case 'needsWork':
        return const MotivationalMessage(
          emoji: '💪',
          text: 'Every difficult session is a step forward. Struggle means you\'re growing.',
          subtitle: 'The pages that challenge you today will be your strongest tomorrow.',
        );
      default: // 'okay'
        return MotivationalMessage(
          emoji: '✨',
          text: 'Good session! Consistency beats perfection every time.',
          subtitle: streakDays > 1
              ? '$streakDays days strong — keep going!'
              : null,
        );
    }
  }

  /// Get a message for specific time of day (for notifications).
  MotivationalMessage getTimeOfDayMessage(StudyTimeOfDay preferredTime) {
    switch (preferredTime) {
      case StudyTimeOfDay.fajr:
        return const MotivationalMessage(
          emoji: '🌅',
          text: 'The morning hours are blessed. Your mind is fresh and ready to absorb.',
        );
      case StudyTimeOfDay.morning:
        return const MotivationalMessage(
          emoji: '☀️',
          text: 'A beautiful morning awaits. Start it with the words of Allah.',
        );
      case StudyTimeOfDay.afternoon:
        return const MotivationalMessage(
          emoji: '🌤️',
          text: 'A midday break with the Quran refreshes both mind and soul.',
        );
      case StudyTimeOfDay.evening:
        return const MotivationalMessage(
          emoji: '🌆',
          text: 'End your day with what matters most. The evening mind retains deeply.',
        );
      case StudyTimeOfDay.night:
        return const MotivationalMessage(
          emoji: '🌙',
          text: 'The quiet night is perfect for memorization. Peace and focus await you.',
        );
    }
  }

  // ── Private helpers ──

  MotivationalMessage? _checkMilestone(int totalPages) {
    if (totalPages == 1) {
      return const MotivationalMessage(
        emoji: '🎉',
        text: 'Your first page! The journey of a thousand pages begins with one.',
        subtitle: 'You have taken the most important step — starting.',
      );
    }
    if (totalPages == 10) {
      return const MotivationalMessage(
        emoji: '🏆',
        text: '10 pages memorized! You\'re building real momentum.',
        subtitle: 'At this pace, the Quran is within your reach.',
      );
    }
    if (totalPages == 20) {
      return const MotivationalMessage(
        emoji: '⭐',
        text: '20 pages — that\'s a full juz! SubhanAllah!',
        subtitle: 'You\'ve memorized 1/30th of the entire Quran.',
      );
    }
    if (totalPages == 100) {
      return const MotivationalMessage(
        emoji: '🌟',
        text: '100 pages! You\'re well on your way to becoming a hafiz.',
        subtitle: 'That\'s over 16% of the Quran. Truly remarkable.',
      );
    }
    if (totalPages == 604) {
      return const MotivationalMessage(
        emoji: '👑',
        text: 'You\'ve memorized the entire Quran! May Allah bless you and preserve it in your heart.',
        subtitle: 'You are now among the huffaz. Share this blessing with the Ummah.',
      );
    }
    // Every 50 pages
    if (totalPages > 0 && totalPages % 50 == 0) {
      final juz = (totalPages / 20).floor();
      return MotivationalMessage(
        emoji: '🎯',
        text: '$totalPages pages memorized — approximately $juz juz!',
        subtitle: 'Your dedication is inspiring. Keep going!',
      );
    }
    return null;
  }

  MotivationalMessage _getStreakMessage(int days) {
    if (days >= 30) {
      return MotivationalMessage(
        emoji: '🔥',
        text: '$days days of consistent practice! You\'re unstoppable.',
        subtitle: 'Consistency is the hallmark of the serious student.',
      );
    }
    if (days >= 7) {
      return MotivationalMessage(
        emoji: '💫',
        text: '$days-day streak! Building a beautiful habit.',
        subtitle: 'The Prophet ﷺ said: "The best deeds are those done consistently, even if small."',
      );
    }
    return MotivationalMessage(
      emoji: '🌱',
      text: '$days days active. Every session plants a seed.',
    );
  }

  MotivationalMessage _getExperienceMessage(MemoryProfile profile, int totalPages) {
    if (totalPages == 0) {
      return const MotivationalMessage(
        emoji: '📖',
        text: 'Ready to begin your memorization journey? Start with bismillah.',
        subtitle: 'The best time to start was yesterday. The second best is now.',
      );
    }
    return MotivationalMessage(
      emoji: '📝',
      text: 'You\'ve memorized $totalPages pages so far. Let\'s add more today!',
    );
  }

  MotivationalMessage _getSabaqStartMessage(MemoryProfile profile, int pageNumber) {
    if (pageNumber >= 582) {
      return const MotivationalMessage(
        emoji: '📖',
        text: 'Juz Amma — the surahs you hear most often. This will feel familiar.',
      );
    }
    if (pageNumber <= 50) {
      return const MotivationalMessage(
        emoji: '📖',
        text: 'Al-Baqarah — the longest surah. Take it one page at a time.',
        subtitle: 'Slow and steady wins this race. Every ayah counts.',
      );
    }
    return MotivationalMessage(
      emoji: '📖',
      text: 'Page $pageNumber awaits. Let\'s make it yours today.',
    );
  }

  String? _getProgressContext(int totalPages) {
    if (totalPages <= 0) return null;
    final percentage = ((totalPages / 604) * 100).toStringAsFixed(1);
    return '$totalPages pages ($percentage% of the Quran)';
  }
}

/// A motivational message with emoji, text, and optional subtitle.
class MotivationalMessage {
  final String emoji;
  final String text;
  final String? subtitle;

  const MotivationalMessage({
    required this.emoji,
    required this.text,
    this.subtitle,
  });
}
