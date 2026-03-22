import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/services/hifz_database_service.dart';

/// Weekly analysis engine for adaptive calibration.
/// Analyzes session data, generates performance snapshots, and produces
/// intelligent suggestions based on real performance patterns.
class AnalyticsService {
  final HifzDatabaseService _db;

  AnalyticsService(this._db);

  // ════════════════════════════════════════════
  // WEEKLY SNAPSHOT GENERATION
  // ════════════════════════════════════════════

  /// Generate a snapshot for a given date range.
  Future<WeeklySnapshot> generateSnapshot(
    String profileId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _db.database;

    // Normalize dates to midnight
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day)
        .add(const Duration(days: 1));

    // ── Sessions in range ──
    final sessionRows = await db.query(
      'session_history',
      where: 'profileId = ? AND date >= ? AND date < ?',
      whereArgs: [profileId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date ASC',
    );
    final sessions = sessionRows.map(SessionRecord.fromMap).toList();

    // ── Plans in range ──
    final planRows = await db.query(
      'daily_plans',
      where: 'profileId = ? AND date >= ? AND date < ?',
      whereArgs: [profileId, start.toIso8601String(), end.toIso8601String()],
    );
    final plans = planRows.map(DailyPlan.fromMap).toList();

    // ── Session metrics ──
    final totalSessions = sessions.length;
    final totalDuration =
        sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);
    final avgDuration =
        totalSessions > 0 ? totalDuration / totalSessions : 0.0;

    // Sessions per day-of-week (1=Mon..7=Sun)
    final sessionsPerDay = <int, int>{};
    for (final s in sessions) {
      final dow = s.date.weekday;
      sessionsPerDay[dow] = (sessionsPerDay[dow] ?? 0) + 1;
    }

    // ── Completion rate ──
    final plannedDays = plans.length;
    final completedDays = plans.where((p) => p.isCompleted).length;
    final completionRate =
        plannedDays > 0 ? completedDays / plannedDays : 0.0;

    // ── Assessment distribution ──
    int strong = 0, okay = 0, needsWork = 0;
    for (final s in sessions) {
      _tallyAssessment(s.sabaqAssessment, strong, okay, needsWork,
          (st, ok, nw) {
        strong = st;
        okay = ok;
        needsWork = nw;
      });
      _tallyAssessment(s.sabqiAssessment, strong, okay, needsWork,
          (st, ok, nw) {
        strong = st;
        okay = ok;
        needsWork = nw;
      });
      _tallyAssessment(s.manzilAssessment, strong, okay, needsWork,
          (st, ok, nw) {
        strong = st;
        okay = ok;
        needsWork = nw;
      });
    }

    // ── Pages memorized in range ──
    final memResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM page_progress '
      'WHERE profileId = ? AND memorizedAt >= ? AND memorizedAt < ?',
      [profileId, start.toIso8601String(), end.toIso8601String()],
    );
    final pagesMemorized = memResult.first['count'] as int? ?? 0;

    // ── Pages reviewed in range ──
    final revResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM page_progress '
      'WHERE profileId = ? AND lastReviewedAt >= ? AND lastReviewedAt < ?',
      [profileId, start.toIso8601String(), end.toIso8601String()],
    );
    final pagesReviewed = revResult.first['count'] as int? ?? 0;

    // ── Pace (pages per week) ──
    final daySpan = end.difference(start).inDays;
    final pagesPerWeek =
        daySpan > 0 ? pagesMemorized * 7 / daySpan : 0.0;

    return WeeklySnapshot(
      startDate: start,
      endDate: end.subtract(const Duration(days: 1)),
      totalSessions: totalSessions,
      totalDurationMinutes: totalDuration,
      avgDurationMinutes: avgDuration,
      sessionsPerDay: sessionsPerDay,
      plannedDays: plannedDays,
      completedDays: completedDays,
      completionRate: completionRate,
      strongCount: strong,
      okayCount: okay,
      needsWorkCount: needsWork,
      pagesMemorized: pagesMemorized,
      pagesReviewed: pagesReviewed,
      pagesPerWeek: pagesPerWeek,
    );
  }

  /// Helper to tally assessment values.
  void _tallyAssessment(
    SelfAssessment? assessment,
    int strong,
    int okay,
    int needsWork,
    void Function(int, int, int) update,
  ) {
    if (assessment == null) return;
    switch (assessment) {
      case SelfAssessment.strong:
        update(strong + 1, okay, needsWork);
      case SelfAssessment.okay:
        update(strong, okay + 1, needsWork);
      case SelfAssessment.needsWork:
        update(strong, okay, needsWork + 1);
    }
  }

  // ════════════════════════════════════════════
  // SUGGESTION GENERATION
  // ════════════════════════════════════════════

  /// Generate adaptive suggestions based on performance data.
  /// All language is compassionate and non-judgmental per design spec.
  List<Suggestion> generateSuggestions(
    MemoryProfile profile,
    WeeklySnapshot current, {
    WeeklySnapshot? previous,
  }) {
    final suggestions = <Suggestion>[];
    final now = DateTime.now();

    if (!current.hasEnoughData) return suggestions;

    // ── Signal 1: Consistently strong → suggest increase ──
    if (current.completionRate >= 0.8 &&
        current.totalAssessments > 0 &&
        current.strongCount / current.totalAssessments > 0.6) {
      suggestions.add(Suggestion(
        id: 'increase_${now.millisecondsSinceEpoch}',
        type: SuggestionType.increaseLoad,
        emoji: '🌟',
        title: "You're doing great!",
        message:
            'Your consistency and strong reviews show real progress. Want to increase your daily load?',
        createdAt: now,
      ));
    }

    // ── Signal 2: Missing sessions frequently → suggest lighter plan ──
    if (current.completionRate < 0.5 && current.plannedDays >= 5) {
      suggestions.add(Suggestion(
        id: 'decrease_${now.millisecondsSinceEpoch}',
        type: SuggestionType.takeBreak,
        emoji: '💡',
        title: 'Looks like things have been busy',
        message:
            'No worries — life happens! Would a lighter daily plan work better for your schedule?',
        createdAt: now,
      ));
    }

    // ── Signal 3: Mostly weak assessments → suggest more review ──
    if (current.totalAssessments > 0 &&
        current.needsWorkCount / current.totalAssessments > 0.4) {
      suggestions.add(Suggestion(
        id: 'review_${now.millisecondsSinceEpoch}',
        type: SuggestionType.moreReview,
        emoji: '💪',
        title: 'Review can help solidify things',
        message:
            'Consider spending an extra day reviewing before adding new material. Want to reduce your daily load temporarily?',
        createdAt: now,
      ));
    }

    // ── Signal 4: Ahead of schedule ──
    if (previous != null &&
        current.pagesMemorized > previous.pagesMemorized * 1.3 &&
        current.completionRate >= 0.8) {
      suggestions.add(Suggestion(
        id: 'ahead_${now.millisecondsSinceEpoch}',
        type: SuggestionType.aheadOfSchedule,
        emoji: '🎉',
        title: "You're ahead of schedule!",
        message:
            'Amazing progress! Keep going at this pace, or take an extra review day to consolidate.',
        createdAt: now,
      ));
    }

    return suggestions;
  }

  // ════════════════════════════════════════════
  // PACE CALCULATION
  // ════════════════════════════════════════════

  /// Calculate estimated completion based on current pace.
  Future<Map<String, dynamic>> calculatePace(
    String profileId,
    MemoryProfile profile,
  ) async {
    final db = await _db.database;

    // Total memorized pages
    final memResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM page_progress '
      'WHERE profileId = ? AND status = ?',
      [profileId, PageStatus.memorized.index],
    );
    final memorizedPages = memResult.first['count'] as int? ?? 0;

    // Pages memorized in last 30 days
    final thirtyDaysAgo =
        DateTime.now().subtract(const Duration(days: 30));
    final recentResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM page_progress '
      'WHERE profileId = ? AND memorizedAt >= ?',
      [profileId, thirtyDaysAgo.toIso8601String()],
    );
    final recentPages = recentResult.first['count'] as int? ?? 0;

    // Calculate total goal pages
    int totalGoalPages;
    switch (profile.goal) {
      case HifzGoal.fullQuran:
        totalGoalPages = 604;
      case HifzGoal.specificJuz:
        totalGoalPages = profile.goalDetails.length * 20;
      case HifzGoal.specificSurahs:
        totalGoalPages = profile.goalDetails.length * 5; // rough estimate
    }

    final remainingPages = totalGoalPages - memorizedPages;
    final pagesPerMonth = recentPages > 0 ? recentPages.toDouble() : 1.0;
    final monthsRemaining = remainingPages / pagesPerMonth;

    return {
      'memorizedPages': memorizedPages,
      'totalGoalPages': totalGoalPages,
      'remainingPages': remainingPages,
      'pagesPerMonth': pagesPerMonth,
      'monthsRemaining': monthsRemaining.ceil(),
      'progressPercent':
          totalGoalPages > 0 ? memorizedPages / totalGoalPages : 0.0,
    };
  }

  // ════════════════════════════════════════════
  // NEGLECTED JUZ DETECTION
  // ════════════════════════════════════════════

  /// Find memorized/reviewing pages that haven't been reviewed in N days.
  /// Groups them by juz to create "neglected juz" notifications.
  Future<List<Map<String, dynamic>>> getNeglectedJuz(
    String profileId, {
    int thresholdDays = 5,
  }) async {
    final db = await _db.database;
    final threshold =
        DateTime.now().subtract(Duration(days: thresholdDays));

    final results = await db.rawQuery(
      'SELECT pageNumber FROM page_progress '
      'WHERE profileId = ? AND status IN (?, ?) '
      'AND (lastReviewedAt IS NULL OR lastReviewedAt < ?) '
      'ORDER BY pageNumber ASC',
      [
        profileId,
        PageStatus.reviewing.index,
        PageStatus.memorized.index,
        threshold.toIso8601String(),
      ],
    );

    // Group pages by juz
    final juzGroups = <int, List<int>>{};
    for (final row in results) {
      final page = row['pageNumber'] as int;
      final juz = _pageToJuz(page);
      juzGroups.putIfAbsent(juz, () => []).add(page);
    }

    return juzGroups.entries.map((e) => {
      'juz': e.key,
      'pages': e.value,
      'pageCount': e.value.length,
    }).toList();
  }

  /// Detect pages where assessments are consistently weak.
  Future<List<int>> detectStrugglePages(String profileId) async {
    final db = await _db.database;

    // Get last 14 days of sessions
    final twoWeeksAgo =
        DateTime.now().subtract(const Duration(days: 14));
    final sessionRows = await db.query(
      'session_history',
      where: 'profileId = ? AND date >= ?',
      whereArgs: [profileId, twoWeeksAgo.toIso8601String()],
    );
    final sessions = sessionRows.map(SessionRecord.fromMap).toList();

    // Track pages with weak sabaq assessments
    final weakPageCounts = <int, int>{};
    for (final s in sessions) {
      if (s.sabaqAssessment == SelfAssessment.needsWork && s.sabaqPage != null) {
        weakPageCounts[s.sabaqPage!] =
            (weakPageCounts[s.sabaqPage!] ?? 0) + 1;
      }
    }

    // Pages with 2+ weak assessments are struggling
    return weakPageCounts.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toList();
  }

  /// Convert page number to juz number.
  static int _pageToJuz(int page) {
    const starts = [
      1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
      201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
      402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
    ];
    for (int j = starts.length - 1; j >= 0; j--) {
      if (page >= starts[j]) return j + 1;
    }
    return 1;
  }
}
