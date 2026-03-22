import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/services/hifz_database_service.dart';

/// Pure logic class for generating daily memorization plans.
/// Takes a profile + current progress → produces a DailyPlan.
class PlanGenerationService {
  final HifzDatabaseService _db;

  PlanGenerationService(this._db);

  /// Generate today's plan for the given profile.
  /// If [forceRegenerate] is true, replaces any existing plan for today
  /// (used after completing a session so the next page is assigned).
  Future<DailyPlan> generateTodayPlan(
    MemoryProfile profile, {
    bool forceRegenerate = false,
  }) async {
    // Check if plan already exists for today
    DailyPlan? previousPlan;
    if (!forceRegenerate) {
      final existing = await _db.getTodayPlan(profile.id);
      if (existing != null) return existing;
    } else {
      // When regenerating, grab the old plan to carry over line progress
      previousPlan = await _db.getTodayPlan(profile.id);
    }

    // Get progress data
    final allProgress = await _db.getAllPageProgress(profile.id);
    final rotationJuz = await _db.getRotationJuz(profile.id);

    // Calculate framework parameters from profile
    final params = _getFrameworkParams(profile);

    // Generate sabaq (new material) — with line + verse carry-over
    final sabaqAssignment = _findNextSabaqAssignment(
      profile, allProgress, params, previousPlan,
    );

    // Generate sabqi (recent review) — only pages we've actually studied
    final sabqiPages = _getSabqiPages(allProgress, params);

    // Generate manzil (long-term review) — only if user has memorized juz
    final manzilData = _getManzilAssignment(rotationJuz, allProgress, params);

    // For brand new users: if there's nothing to review, skip those phases
    final hasReviewContent = sabqiPages.isNotEmpty;
    final hasManzilContent = manzilData.pages.isNotEmpty;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final planId = '${profile.id}_${today.toIso8601String()}_${now.millisecondsSinceEpoch}';

    final plan = DailyPlan(
      id: planId,
      profileId: profile.id,
      date: today,
      sabaqPage: sabaqAssignment.page,
      sabaqLineStart: sabaqAssignment.lineStart,
      sabaqLineEnd: sabaqAssignment.lineEnd,
      sabaqStartVerse: sabaqAssignment.startVerse,
      sabaqTargetMinutes: hasReviewContent || hasManzilContent
          ? params.sabaqMinutes
          : profile.dailyTimeMinutes, // Full time if sabaq-only
      sabaqRepetitionTarget: params.minRepetitions,
      sabqiPages: sabqiPages,
      sabqiTargetMinutes: hasReviewContent ? params.sabqiMinutes : 0,
      manzilJuz: manzilData.juz,
      manzilPages: manzilData.pages,
      manzilTargetMinutes: hasManzilContent ? params.manzilMinutes : 0,
      // Auto-skip empty phases
      sabqiDoneOffline: !hasReviewContent,
      manzilDoneOffline: !hasManzilContent,
    );

    await _db.saveDailyPlan(plan);
    return plan;
  }

  /// Determine the next sabaq assignment with dynamic line progression.
  /// Considers: previous plan's line range, encoding speed, verse-level progress.
  _SabaqAssignment _findNextSabaqAssignment(
    MemoryProfile profile,
    Map<int, PageProgress> progress,
    _FrameworkParams params,
    DailyPlan? previousPlan,
  ) {
    // If we have a previous plan from today (regeneration after session),
    // carry over from where the user left off
    if (previousPlan != null) {
      final prevPage = previousPlan.sabaqPage;
      final prevLineEnd = previousPlan.sabaqLineEnd;

      if (prevLineEnd >= 15) {
        // Full page was assigned — advance to next page
        return _findNextUnstartedPage(profile, progress, params);
      } else {
        // Partial page — continue from next line on same page
        final nextLineStart = prevLineEnd + 1;
        final nextLineEnd = (nextLineStart + params.linesPerSession - 1).clamp(1, 15);
        return _SabaqAssignment(
          page: prevPage,
          lineStart: nextLineStart,
          lineEnd: nextLineEnd,
        );
      }
    }

    // First plan of the day — find the right page and start lines from 1
    return _findNextUnstartedPage(profile, progress, params);
  }

  /// Find the next page to memorize, checking for partial verse progress.
  _SabaqAssignment _findNextUnstartedPage(
    MemoryProfile profile,
    Map<int, PageProgress> progress,
    _FrameworkParams params,
  ) {
    int page = profile.startingPage;

    for (int i = 0; i < 604; i++) {
      final current = (page - 1 + i) % 604 + 1;
      final p = progress[current];
      if (p == null || p.status == PageStatus.notStarted) {
        return _SabaqAssignment(
          page: current,
          lineStart: 1,
          lineEnd: params.linesPerSession.clamp(1, 15),
        );
      }
      // CE-9: Check for partial page via verse tracking
      if (p.status == PageStatus.learning &&
          p.lastVerseLearned != null &&
          p.totalVersesOnPage != null &&
          p.lastVerseLearned! < p.totalVersesOnPage!) {
        return _SabaqAssignment(
          page: current,
          lineStart: 1,
          lineEnd: params.linesPerSession.clamp(1, 15),
          startVerse: p.lastVerseLearned! + 1,
        );
      }
    }

    // All pages have progress — return starting page (review mode)
    return _SabaqAssignment(
      page: profile.startingPage,
      lineStart: 1,
      lineEnd: params.linesPerSession.clamp(1, 15),
    );
  }

  /// Get pages that need sabqi (recent review).
  /// These are pages marked as "learning" in the last 7-10 days.
  List<int> _getSabqiPages(
    Map<int, PageProgress> progress,
    _FrameworkParams params,
  ) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: params.sabqiDaysBack));

    final candidates = progress.values
        .where((p) =>
            p.status == PageStatus.learning &&
            p.lastReviewedAt != null &&
            p.lastReviewedAt!.isAfter(cutoff))
        .toList()
      ..sort((a, b) =>
          (a.lastReviewedAt ?? now).compareTo(b.lastReviewedAt ?? now));

    return candidates
        .take(params.sabqiMaxPages)
        .map((p) => p.pageNumber)
        .toList();
  }

  /// Get manzil assignment from the rotation.
  _ManzilData _getManzilAssignment(
    List<int> rotationJuz,
    Map<int, PageProgress> progress,
    _FrameworkParams params,
  ) {
    if (rotationJuz.isEmpty) {
      return _ManzilData(juz: 0, pages: []);
    }

    // Round-robin through rotation juz
    final dayIndex = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    final currentJuz = rotationJuz[dayIndex % rotationJuz.length];

    // Get pages for this juz (approximate: 20 pages per juz)
    final juzStartPage = _juzStartPage(currentJuz);
    final juzEndPage = currentJuz < 30
        ? _juzStartPage(currentJuz + 1) - 1
        : 604;

    // Pick a subset of pages for today's manzil
    final manzilPages = <int>[];
    for (int p = juzStartPage; p <= juzEndPage && manzilPages.length < params.manzilPagesPerDay; p++) {
      manzilPages.add(p);
    }

    return _ManzilData(juz: currentJuz, pages: manzilPages);
  }

  /// Get framework parameters based on the profile's assessment.
  _FrameworkParams _getFrameworkParams(MemoryProfile profile) {
    final encoding = profile.encodingSpeed;
    final retention = profile.retentionStrength;
    final totalMinutes = profile.dailyTimeMinutes;

    // Determine parameters based on profile
    int minReps;
    int sabqiDaysBack;
    int sabqiMaxPages;
    int manzilPagesPerDay;

    switch (encoding) {
      case EncodingSpeed.fast:
        minReps = retention == RetentionStrength.fragile ? 10 : 5;
        break;
      case EncodingSpeed.moderate:
        minReps = retention == RetentionStrength.fragile ? 15 : 7;
        break;
      case EncodingSpeed.slow:
        minReps = retention == RetentionStrength.fragile ? 15 : 10;
        break;
    }

    switch (retention) {
      case RetentionStrength.strong:
        sabqiDaysBack = 5;
        sabqiMaxPages = 3;
        manzilPagesPerDay = 4;
        break;
      case RetentionStrength.moderate:
        sabqiDaysBack = 7;
        sabqiMaxPages = 5;
        manzilPagesPerDay = 5;
        break;
      case RetentionStrength.fragile:
        sabqiDaysBack = 10;
        sabqiMaxPages = 7;
        manzilPagesPerDay = 6;
        break;
    }

    // Lines per session — 2-axis lookup (dailyTime × encodingSpeed)
    // From plan-generation.md research table:
    // | Daily Time   | Fast       | Moderate  | Slow     |
    // |-------------|-----------|-----------|----------|
    // | 15-30 min   | 5-8 lines | 3-5 lines | 2-3 lines|
    // | 1 hour      | 8-15 lines| 5-8 lines | 3-5 lines|
    // | 2 hours     | 15 (page) | 8-15 lines| 5-8 lines|
    // | 4+ hours    | 15+ (2-3p)| 15 (1-2p) | 8-15     |
    int linesPerSession;
    if (totalMinutes <= 30) {
      switch (encoding) {
        case EncodingSpeed.fast:    linesPerSession = 7; break;
        case EncodingSpeed.moderate: linesPerSession = 4; break;
        case EncodingSpeed.slow:    linesPerSession = 3; break;
      }
    } else if (totalMinutes <= 60) {
      switch (encoding) {
        case EncodingSpeed.fast:    linesPerSession = 12; break;
        case EncodingSpeed.moderate: linesPerSession = 7; break;
        case EncodingSpeed.slow:    linesPerSession = 4; break;
      }
    } else if (totalMinutes <= 120) {
      switch (encoding) {
        case EncodingSpeed.fast:    linesPerSession = 15; break;
        case EncodingSpeed.moderate: linesPerSession = 12; break;
        case EncodingSpeed.slow:    linesPerSession = 7; break;
      }
    } else {
      // 4+ hours
      switch (encoding) {
        case EncodingSpeed.fast:    linesPerSession = 15; break;
        case EncodingSpeed.moderate: linesPerSession = 15; break;
        case EncodingSpeed.slow:    linesPerSession = 12; break;
      }
    }

    // Time distribution (approximate split)
    final sabaqMinutes = (totalMinutes * 0.45).round();
    final sabqiMinutes = (totalMinutes * 0.30).round();
    final manzilMinutes = totalMinutes - sabaqMinutes - sabqiMinutes;

    return _FrameworkParams(
      minRepetitions: minReps,
      sabqiDaysBack: sabqiDaysBack,
      sabqiMaxPages: sabqiMaxPages,
      manzilPagesPerDay: manzilPagesPerDay,
      linesPerSession: linesPerSession,
      sabaqMinutes: sabaqMinutes,
      sabqiMinutes: sabqiMinutes,
      manzilMinutes: manzilMinutes,
    );
  }

  /// Approximate juz start pages (Madani mushaf).
  static int _juzStartPage(int juz) {
    const starts = [
      0, 1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
      201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
      402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
    ];
    return starts[juz.clamp(1, 30)];
  }
}

class _FrameworkParams {
  final int minRepetitions;
  final int sabqiDaysBack;
  final int sabqiMaxPages;
  final int manzilPagesPerDay;
  final int linesPerSession;
  final int sabaqMinutes;
  final int sabqiMinutes;
  final int manzilMinutes;

  const _FrameworkParams({
    required this.minRepetitions,
    required this.sabqiDaysBack,
    required this.sabqiMaxPages,
    required this.manzilPagesPerDay,
    required this.linesPerSession,
    required this.sabaqMinutes,
    required this.sabqiMinutes,
    required this.manzilMinutes,
  });
}

class _ManzilData {
  final int juz;
  final List<int> pages;
  _ManzilData({required this.juz, required this.pages});
}

/// Sabaq assignment with page, line range, and optional verse carry-over.
class _SabaqAssignment {
  final int page;
  final int lineStart;
  final int lineEnd;
  final int? startVerse; // null = no verse carry-over
  _SabaqAssignment({
    required this.page,
    this.lineStart = 1,
    this.lineEnd = 15,
    this.startVerse,
  });
}
