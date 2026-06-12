/// Pure weekly-analytics calculators, copied from the app's
/// `lib/services/analytics_service.dart` (roadmap §3: MOVE invocation,
/// pure calculators in `hifz_core`; the app file is rewired by the client
/// stream — it is NOT edited here).
///
/// Parity notes (each preserves the original's observable semantics):
/// - The service filtered rows with SQLite string comparisons over
///   ISO-8601 text (`date >= ? AND date < ?`). These calculators compare
///   the SAME ISO strings (`toIso8601String()`), NOT epoch instants — so
///   mixed UTC-`Z`/naive values bucket exactly as the SQL did, on any
///   host timezone.
/// - Map iteration orders (sessions-per-day, juz grouping, struggle pages)
///   follow insertion order exactly like the originals.
/// - Every former `DateTime.now()` is an explicit `now` parameter (pure,
///   server-runnable, fixture-testable).
library;

import '../models/hifz_models.dart';
import '../quran_meta/quran_meta.dart';

/// Pace summary — the typed form of `AnalyticsService.calculatePace`'s map.
final class PaceSummary {
  final int memorizedPages;
  final int totalGoalPages;
  final int remainingPages;
  final double pagesPerMonth;
  final int monthsRemaining;
  final double progressPercent;

  const PaceSummary({
    required this.memorizedPages,
    required this.totalGoalPages,
    required this.remainingPages,
    required this.pagesPerMonth,
    required this.monthsRemaining,
    required this.progressPercent,
  });

  /// The exact map shape the app's `calculatePace` returned.
  Map<String, dynamic> toMap() => {
    'memorizedPages': memorizedPages,
    'totalGoalPages': totalGoalPages,
    'remainingPages': remainingPages,
    'pagesPerMonth': pagesPerMonth,
    'monthsRemaining': monthsRemaining,
    'progressPercent': progressPercent,
  };
}

/// A juz whose memorized/reviewing pages haven't been reviewed recently.
final class NeglectedJuz {
  final int juz;
  final List<int> pages;

  const NeglectedJuz({required this.juz, required this.pages});

  int get pageCount => pages.length;

  /// The exact map shape the app's `getNeglectedJuz` returned.
  Map<String, dynamic> toMap() => {
    'juz': juz,
    'pages': pages,
    'pageCount': pages.length,
  };
}

/// Pure analytics calculators (weekly snapshot, suggestions, pace,
/// neglected juz, struggle pages).
final class AnalyticsCalculators {
  AnalyticsCalculators._();

  /// `AnalyticsService.generateSnapshot`, data-in/snapshot-out.
  ///
  /// [sessions], [plans], and [progress] may span profiles — rows are
  /// filtered by [profileId] like the original SQL `WHERE profileId = ?`.
  static WeeklySnapshot weeklySnapshot({
    required String profileId,
    required DateTime startDate,
    required DateTime endDate,
    required Iterable<SessionRecord> sessions,
    required Iterable<DailyPlan> plans,
    required Iterable<PageProgress> progress,
  }) {
    // Normalize dates to midnight; end is exclusive (+1 day).
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    ).add(const Duration(days: 1));
    final startIso = start.toIso8601String();
    final endIso = end.toIso8601String();

    bool inRange(DateTime? value) {
      if (value == null) return false;
      final iso = value.toIso8601String();
      return iso.compareTo(startIso) >= 0 && iso.compareTo(endIso) < 0;
    }

    // ── Sessions in range (ordered by date ASC, like the query) ──
    final inRangeSessions =
        sessions
            .where((s) => s.profileId == profileId && inRange(s.date))
            .toList()
          ..sort(
            (a, b) =>
                a.date.toIso8601String().compareTo(b.date.toIso8601String()),
          );

    // ── Plans in range ──
    final inRangePlans = plans
        .where((p) => p.profileId == profileId && inRange(p.date))
        .toList();

    // ── Session metrics ──
    final totalSessions = inRangeSessions.length;
    final totalDuration = inRangeSessions.fold<int>(
      0,
      (sum, s) => sum + s.durationMinutes,
    );
    final avgDuration = totalSessions > 0 ? totalDuration / totalSessions : 0.0;

    // Sessions per day-of-week (1=Mon..7=Sun)
    final sessionsPerDay = <int, int>{};
    for (final s in inRangeSessions) {
      final dow = s.date.weekday;
      sessionsPerDay[dow] = (sessionsPerDay[dow] ?? 0) + 1;
    }

    // ── Completion rate ──
    final plannedDays = inRangePlans.length;
    final completedDays = inRangePlans.where((p) => p.isCompleted).length;
    final completionRate = plannedDays > 0 ? completedDays / plannedDays : 0.0;

    // ── Assessment distribution ──
    var strong = 0, okay = 0, needsWork = 0;
    void tally(SelfAssessment? assessment) {
      switch (assessment) {
        case SelfAssessment.strong:
          strong++;
        case SelfAssessment.okay:
          okay++;
        case SelfAssessment.needsWork:
          needsWork++;
        case null:
          break;
      }
    }

    for (final s in inRangeSessions) {
      tally(s.sabaqAssessment);
      tally(s.sabqiAssessment);
      tally(s.manzilAssessment);
    }

    // ── Pages memorized / reviewed in range ──
    final profileProgress = progress
        .where((p) => p.profileId == profileId)
        .toList();
    final pagesMemorized = profileProgress
        .where((p) => inRange(p.memorizedAt))
        .length;
    final pagesReviewed = profileProgress
        .where((p) => inRange(p.lastReviewedAt))
        .length;

    // ── Pace (pages per week) ──
    final daySpan = end.difference(start).inDays;
    final pagesPerWeek = daySpan > 0 ? pagesMemorized * 7 / daySpan : 0.0;

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

  /// `AnalyticsService.generateSuggestions` with `now` injected (it stamps
  /// suggestion ids and `createdAt`). Copy, language and thresholds intact.
  static List<Suggestion> suggestions({
    required MemoryProfile profile,
    required WeeklySnapshot current,
    WeeklySnapshot? previous,
    required DateTime now,
  }) {
    final result = <Suggestion>[];

    if (!current.hasEnoughData) return result;

    // ── Signal 1: Consistently strong → suggest increase ──
    if (current.completionRate >= 0.8 &&
        current.totalAssessments > 0 &&
        current.strongCount / current.totalAssessments > 0.6) {
      result.add(
        Suggestion(
          id: 'increase_${now.millisecondsSinceEpoch}',
          type: SuggestionType.increaseLoad,
          iconKey: 'star',
          title: "You're doing great!",
          message:
              'Your consistency and strong reviews show real progress. Want to increase your daily load?',
          createdAt: now,
        ),
      );
    }

    // ── Signal 2: Missing sessions frequently → suggest lighter plan ──
    if (current.completionRate < 0.5 && current.plannedDays >= 5) {
      result.add(
        Suggestion(
          id: 'decrease_${now.millisecondsSinceEpoch}',
          type: SuggestionType.takeBreak,
          iconKey: 'lightbulb',
          title: 'Looks like things have been busy',
          message:
              'No worries — life happens! Would a lighter daily plan work better for your schedule?',
          createdAt: now,
        ),
      );
    }

    // ── Signal 3: Mostly weak assessments → suggest more review ──
    if (current.totalAssessments > 0 &&
        current.needsWorkCount / current.totalAssessments > 0.4) {
      result.add(
        Suggestion(
          id: 'review_${now.millisecondsSinceEpoch}',
          type: SuggestionType.moreReview,
          iconKey: 'dumbbell',
          title: 'Review can help solidify things',
          message:
              'Consider spending an extra day reviewing before adding new material. Want to reduce your daily load temporarily?',
          createdAt: now,
        ),
      );
    }

    // ── Signal 4: Ahead of schedule ──
    if (previous != null &&
        current.pagesMemorized > previous.pagesMemorized * 1.3 &&
        current.completionRate >= 0.8) {
      result.add(
        Suggestion(
          id: 'ahead_${now.millisecondsSinceEpoch}',
          type: SuggestionType.aheadOfSchedule,
          iconKey: 'party_popper',
          title: "You're ahead of schedule!",
          message:
              'Amazing progress! Keep going at this pace, or take an extra review day to consolidate.',
          createdAt: now,
        ),
      );
    }

    return result;
  }

  /// `AnalyticsService.calculatePace`, data-in/summary-out.
  static PaceSummary pace({
    required MemoryProfile profile,
    required Iterable<PageProgress> progress,
    required DateTime now,
  }) {
    final profileProgress = progress
        .where((p) => p.profileId == profile.id)
        .toList();

    // Total memorized pages
    final memorizedPages = profileProgress
        .where((p) => p.status == PageStatus.memorized)
        .length;

    // Pages memorized in last 30 days (ISO string compare, like the SQL)
    final thirtyDaysAgoIso = now
        .subtract(const Duration(days: 30))
        .toIso8601String();
    final recentPages = profileProgress
        .where(
          (p) =>
              p.memorizedAt != null &&
              p.memorizedAt!.toIso8601String().compareTo(thirtyDaysAgoIso) >= 0,
        )
        .length;

    // Calculate total goal pages
    final int totalGoalPages;
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

    return PaceSummary(
      memorizedPages: memorizedPages,
      totalGoalPages: totalGoalPages,
      remainingPages: remainingPages,
      pagesPerMonth: pagesPerMonth,
      monthsRemaining: monthsRemaining.ceil(),
      progressPercent: totalGoalPages > 0
          ? memorizedPages / totalGoalPages
          : 0.0,
    );
  }

  /// `AnalyticsService.getNeglectedJuz`: memorized/reviewing pages not
  /// reviewed in [thresholdDays], grouped by juz, pages ascending.
  static List<NeglectedJuz> neglectedJuz({
    required String profileId,
    required Iterable<PageProgress> progress,
    int thresholdDays = 5,
    required DateTime now,
  }) {
    final thresholdIso = now
        .subtract(Duration(days: thresholdDays))
        .toIso8601String();

    final pages =
        progress
            .where(
              (p) =>
                  p.profileId == profileId &&
                  (p.status == PageStatus.reviewing ||
                      p.status == PageStatus.memorized) &&
                  (p.lastReviewedAt == null ||
                      p.lastReviewedAt!.toIso8601String().compareTo(
                            thresholdIso,
                          ) <
                          0),
            )
            .map((p) => p.pageNumber)
            .toList()
          ..sort();

    // Group pages by juz (insertion order = ascending juz, like the app)
    final juzGroups = <int, List<int>>{};
    for (final page in pages) {
      juzGroups.putIfAbsent(QuranMeta.pageToJuz(page), () => []).add(page);
    }

    return [
      for (final entry in juzGroups.entries)
        NeglectedJuz(juz: entry.key, pages: entry.value),
    ];
  }

  /// `AnalyticsService.detectStrugglePages`: pages with 2+ weak sabaq
  /// assessments in the last 14 days.
  static List<int> strugglePages({
    required String profileId,
    required Iterable<SessionRecord> sessions,
    required DateTime now,
  }) {
    final twoWeeksAgoIso = now
        .subtract(const Duration(days: 14))
        .toIso8601String();

    final weakPageCounts = <int, int>{};
    for (final s in sessions) {
      if (s.profileId != profileId) continue;
      if (s.date.toIso8601String().compareTo(twoWeeksAgoIso) < 0) continue;
      if (s.sabaqAssessment == SelfAssessment.needsWork &&
          s.sabaqPage != null) {
        weakPageCounts[s.sabaqPage!] = (weakPageCounts[s.sabaqPage!] ?? 0) + 1;
      }
    }

    return weakPageCounts.entries
        .where((e) => e.value >= 2)
        .map((e) => e.key)
        .toList();
  }
}
