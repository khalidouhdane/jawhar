import '../models/hifz_models.dart';
import '../models/session_recipe_models.dart';
import '../quran_meta/quran_meta.dart';

/// Optional log sink so the app can keep its `AppLogger` output without
/// this package depending on Flutter.
typedef PlanLog = void Function(String message);

/// Pure, deterministic daily-plan math: data in → [DailyPlan] out.
///
/// Extracted verbatim from the app's `PlanGenerationService` (which now
/// owns only the SQLite reads/writes and delegates here). The server runs
/// this exact code, which is what makes offline plans reconcile cleanly
/// (identical inputs ⇒ identical plan, roadmap §3/§7.4).
class PlanGenerator {
  PlanGenerator._();

  /// Generate the plan for the local calendar day of [now]
  /// (defaults to `DateTime.now()`).
  ///
  /// [previousPlan] is today's pre-existing plan when regenerating after a
  /// completed session — sabaq line/verse progress carries over from it.
  /// Plan ids stay deterministic: `'${profile.id}_${today.toIso8601String()}'`.
  ///
  /// [localToday] (additive, Phase 4): the user-local calendar day as a
  /// timezone-naive midnight. On the device, [now] is the local wall clock,
  /// so its date components ARE the local day and its epoch IS the true
  /// instant — one value serves both. A server folding facts on a UTC host
  /// has no such DateTime: it passes the fact's `recordedAtUtc` as [now]
  /// (exact instant comparisons for the sabqi window and future-date
  /// guard) and the fact's client-local `date` here (plan id/date and
  /// manzil rotation day). When null, the historical behavior is
  /// byte-identical: the day is taken from [now]'s own components.
  static DailyPlan generate({
    required MemoryProfile profile,
    required Map<int, PageProgress> progress,
    required List<int> rotationJuz,
    DailyPlan? previousPlan,
    DateTime? now,
    DateTime? localToday,
    PlanLog? log,
  }) {
    final localNow = now ?? DateTime.now();
    final today = localToday == null
        ? DateTime(localNow.year, localNow.month, localNow.day)
        : DateTime(localToday.year, localToday.month, localToday.day);

    // Calculate framework parameters from profile
    final params = _getFrameworkParams(profile);

    // Generate sabaq (new material) — with line + verse carry-over
    final sabaqAssignment = _findNextSabaqAssignment(
      profile,
      progress,
      params,
      previousPlan,
      log,
    );

    // Generate sabqi (recent review) — only pages we've actually studied
    final sabqiPages = _getSabqiPages(progress, params, localNow);

    // Generate manzil (long-term review) — only if user has memorized juz
    final manzilData = _getManzilAssignment(rotationJuz, params, today);

    // For brand new users: if there's nothing to review, skip those phases
    final hasReviewContent = sabqiPages.isNotEmpty;
    final hasManzilContent = manzilData.pages.isNotEmpty;

    final planId = '${profile.id}_${today.toIso8601String()}';

    // ── Smart time redistribution ──
    // Always use the full daily budget. Redistribute unused phase time
    // proportionally to active phases.
    int sabaqMin, sabqiMin, manzilMin;

    if (!hasReviewContent && !hasManzilContent) {
      // Sabaq only → full daily budget
      sabaqMin = profile.dailyTimeMinutes;
      sabqiMin = 0;
      manzilMin = 0;
    } else if (hasReviewContent && !hasManzilContent) {
      // Sabaq + sabqi only → redistribute manzil's share
      // Original split: 45% sabaq, 30% sabqi, 25% manzil
      // New split: 60% sabaq, 40% sabqi (proportional to 45:30)
      sabaqMin = (profile.dailyTimeMinutes * 0.60).round();
      sabqiMin = profile.dailyTimeMinutes - sabaqMin;
      manzilMin = 0;
    } else if (!hasReviewContent && hasManzilContent) {
      // Sabaq + manzil only → redistribute sabqi's share
      sabaqMin = (profile.dailyTimeMinutes * 0.65).round();
      manzilMin = profile.dailyTimeMinutes - sabaqMin;
      sabqiMin = 0;
    } else {
      // All three phases active
      sabaqMin = params.sabaqMinutes;
      sabqiMin = params.sabqiMinutes;
      manzilMin = params.manzilMinutes;
    }

    log?.call(
      '[PLAN] Time redistribution: '
      'hasReview=$hasReviewContent, hasManzil=$hasManzilContent → '
      'sabaq=${sabaqMin}m, sabqi=${sabqiMin}m, manzil=${manzilMin}m '
      '(total=${sabaqMin + sabqiMin + manzilMin}m / daily=${profile.dailyTimeMinutes}m)',
    );

    return DailyPlan(
      id: planId,
      profileId: profile.id,
      date: today,
      sabaqPage: sabaqAssignment.page,
      sabaqLineStart: sabaqAssignment.lineStart,
      sabaqLineEnd: sabaqAssignment.lineEnd,
      sabaqStartVerse: sabaqAssignment.startVerse,
      sabaqTargetMinutes: sabaqMin,
      sabaqRepetitionTarget: params.minRepetitions,
      sabqiPages: sabqiPages,
      sabqiTargetMinutes: sabqiMin,
      manzilJuz: manzilData.juz,
      manzilPages: manzilData.pages,
      manzilTargetMinutes: manzilMin,
      // The *DoneOffline flags are no longer set at generation time: empty
      // phases auto-skip via the derived DailyPlan.isSabqiDone /
      // isManzilDone checks (roadmap Phase 1 task 7). The flags now only
      // record user-claimed offline completion.
    );
  }

  /// Determine the next sabaq assignment with dynamic line progression.
  /// Considers: previous plan's line range, encoding speed, verse-level progress.
  static _SabaqAssignment _findNextSabaqAssignment(
    MemoryProfile profile,
    Map<int, PageProgress> progress,
    _FrameworkParams params,
    DailyPlan? previousPlan,
    PlanLog? log,
  ) {
    // If we have a previous plan from today (regeneration after session),
    // carry over from where the user left off
    if (previousPlan != null) {
      final prevPage = previousPlan.sabaqPage;
      final prevLineEnd = previousPlan.sabaqLineEnd;

      log?.call(
        '[PLAN] Previous plan: page=$prevPage, lineEnd=$prevLineEnd, linesPerSession=${params.linesPerSession}',
      );

      if (prevLineEnd >= 15) {
        // Full page was assigned — advance to next page
        log?.call('[PLAN] Full page done → advancing to next page');
        return _findNextUnstartedPage(profile, progress, params);
      } else {
        // Partial page — continue from next line on same page
        final nextLineStart = prevLineEnd + 1;
        var nextLineEnd = (nextLineStart + params.linesPerSession - 1).clamp(
          1,
          15,
        );

        // Smart remainder absorption: if the lines left after this chunk
        // would be too few (< half of linesPerSession), absorb them now.
        // This prevents awkward 1-2 line sessions.
        final remainingAfter = 15 - nextLineEnd;
        if (remainingAfter > 0 &&
            remainingAfter < (params.linesPerSession / 2).ceil()) {
          nextLineEnd = 15;
          log?.call(
            '[PLAN] Absorbing $remainingAfter remaining lines → $nextLineStart-$nextLineEnd',
          );
        } else {
          log?.call(
            '[PLAN] Partial page → next lines: $nextLineStart-$nextLineEnd',
          );
        }

        return _SabaqAssignment(
          page: prevPage,
          lineStart: nextLineStart,
          lineEnd: nextLineEnd,
        );
      }
    }

    // First plan of the day — find the right page and start lines from 1
    log?.call('[PLAN] First plan of the day');
    return _findNextUnstartedPage(profile, progress, params);
  }

  /// Find the next page to memorize, checking for partial verse progress.
  static _SabaqAssignment _findNextUnstartedPage(
    MemoryProfile profile,
    Map<int, PageProgress> progress,
    _FrameworkParams params,
  ) {
    int page = profile.startingPage;

    for (int i = 0; i < 604; i++) {
      final current = (page - 1 + i) % 604 + 1;
      final p = progress[current];
      if (p == null || p.status == PageStatus.notStarted) {
        var lineEnd = params.linesPerSession.clamp(1, 15);
        // Smart remainder absorption: if the leftover lines would be
        // too small for a meaningful session, extend to cover the full page.
        final remaining = 15 - lineEnd;
        if (remaining > 0 && remaining < (params.linesPerSession / 2).ceil()) {
          lineEnd = 15;
        }
        return _SabaqAssignment(page: current, lineStart: 1, lineEnd: lineEnd);
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
  static List<int> _getSabqiPages(
    Map<int, PageProgress> progress,
    _FrameworkParams params,
    DateTime now,
  ) {
    final cutoff = now.subtract(Duration(days: params.sabqiDaysBack));

    final candidates =
        progress.values
            .where(
              (p) =>
                  p.status == PageStatus.learning &&
                  p.lastReviewedAt != null &&
                  p.lastReviewedAt!.isAfter(cutoff) &&
                  // Exclude future-dated progress (clock skew / multi-device sync).
                  !p.lastReviewedAt!.isAfter(now),
            )
            .toList()
          ..sort(
            (a, b) =>
                (a.lastReviewedAt ?? now).compareTo(b.lastReviewedAt ?? now),
          );

    return candidates
        .take(params.sabqiMaxPages)
        .map((p) => p.pageNumber)
        .toList();
  }

  /// Get manzil assignment from the rotation. [localToday] is the user-local
  /// calendar day as a naive midnight (already resolved by [generate]).
  static _ManzilData _getManzilAssignment(
    List<int> rotationJuz,
    _FrameworkParams params,
    DateTime localToday,
  ) {
    if (rotationJuz.isEmpty) {
      return _ManzilData(juz: 0, pages: []);
    }

    // Round-robin through rotation juz
    final dayIndex = localToday.difference(DateTime(2024, 1, 1)).inDays;
    final currentJuz = rotationJuz[dayIndex % rotationJuz.length];

    // Get pages for this juz (approximate: 20 pages per juz)
    final juzStartPage = QuranMeta.juzStartPage(currentJuz);
    final juzEndPage = QuranMeta.juzEndPage(currentJuz);

    // Pick a subset of pages for today's manzil
    final manzilPages = <int>[];
    for (
      int p = juzStartPage;
      p <= juzEndPage && manzilPages.length < params.manzilPagesPerDay;
      p++
    ) {
      manzilPages.add(p);
    }

    return _ManzilData(juz: currentJuz, pages: manzilPages);
  }

  /// Get framework parameters based on the profile's assessment.
  static _FrameworkParams _getFrameworkParams(MemoryProfile profile) {
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
        minReps = retention == RetentionStrength.fragile ? 20 : 15;
        break;
      case EncodingSpeed.moderate:
        minReps = retention == RetentionStrength.fragile ? 30 : 20;
        break;
      case EncodingSpeed.slow:
        minReps = retention == RetentionStrength.fragile ? 30 : 25;
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
        case EncodingSpeed.fast:
          linesPerSession = 7;
          break;
        case EncodingSpeed.moderate:
          linesPerSession = 4;
          break;
        case EncodingSpeed.slow:
          linesPerSession = 3;
          break;
      }
    } else if (totalMinutes <= 60) {
      switch (encoding) {
        case EncodingSpeed.fast:
          linesPerSession = 12;
          break;
        case EncodingSpeed.moderate:
          linesPerSession = 7;
          break;
        case EncodingSpeed.slow:
          linesPerSession = 4;
          break;
      }
    } else if (totalMinutes <= 120) {
      switch (encoding) {
        case EncodingSpeed.fast:
          linesPerSession = 15;
          break;
        case EncodingSpeed.moderate:
          linesPerSession = 12;
          break;
        case EncodingSpeed.slow:
          linesPerSession = 7;
          break;
      }
    } else {
      // 4+ hours
      switch (encoding) {
        case EncodingSpeed.fast:
          linesPerSession = 15;
          break;
        case EncodingSpeed.moderate:
          linesPerSession = 15;
          break;
        case EncodingSpeed.slow:
          linesPerSession = 12;
          break;
      }
    }

    // Pace adjustment (must match assessment display)
    switch (profile.pacePreference) {
      case PacePreference.aggressive:
        linesPerSession = (linesPerSession * 1.3).round();
        break;
      case PacePreference.gentle:
        linesPerSession = (linesPerSession * 0.7).round();
        break;
      case PacePreference.steady:
        break; // Use base
    }
    linesPerSession = linesPerSession.clamp(2, 15);

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

  /// Generate sensible default recipes for any deterministic plan.
  /// Ensures RecipeGuideWidget always has step-by-step instructions.
  /// When [profile] is provided, repetition targets adapt to the user's
  /// encoding speed, retention strength, and learning preference.
  ///
  /// [now] is injectable for tests/server; recipe ids embed its epoch millis
  /// (defaults to `DateTime.now()`, the historical behavior).
  static List<SessionRecipe> generateDefaultRecipes(
    DailyPlan plan, [
    MemoryProfile? profile,
    DateTime? now,
  ]) {
    final recipes = <SessionRecipe>[];
    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;

    // ── Compute adaptive repetition targets ──
    // Base: 5x for everything (research shows 20+ total reps needed).
    // Profile adjusts up/down.
    int listenReps = 5;
    int readAlongReps = 5;
    int readSoloReps = 5;
    int reciteReps = 5;

    if (profile != null) {
      // Encoding speed: slow learners need more reps overall
      switch (profile.encodingSpeed) {
        case EncodingSpeed.slow:
          listenReps += 1;
          readAlongReps += 1;
          readSoloReps += 1;
          reciteReps += 1;
          break;
        case EncodingSpeed.fast:
          // Fast encoders can do fewer listen/read-along
          listenReps = 2;
          readAlongReps = 2;
          break;
        case EncodingSpeed.moderate:
          break;
      }

      // Retention strength: weak retention → more recitation from memory
      switch (profile.retentionStrength) {
        case RetentionStrength.fragile:
          reciteReps += 1;
          readSoloReps += 1;
          break;
        case RetentionStrength.strong:
          reciteReps = (reciteReps - 1).clamp(2, 6);
          break;
        case RetentionStrength.moderate:
          break;
      }

      // Learning preference: auditory → more listening, visual → more reading
      switch (profile.learningPreference) {
        case LearningPreference.auditory:
          listenReps += 1;
          readAlongReps += 1;
          readSoloReps = (readSoloReps - 1).clamp(2, 6);
          break;
        case LearningPreference.visual:
          readSoloReps += 1;
          readAlongReps += 1;
          listenReps = (listenReps - 1).clamp(2, 6);
          break;
        case LearningPreference.kinesthetic:
          // Writing-focused: more solo practice
          readSoloReps += 1;
          reciteReps += 1;
          break;
        case LearningPreference.repetition:
          // Repetition-focused: more of everything, esp. recite from memory
          reciteReps += 2;
          readSoloReps += 1;
          break;
      }

      // Children get more listen+read-along (apprenticeship model)
      if (profile.ageGroup == AgeGroup.child) {
        listenReps += 1;
        readAlongReps += 1;
      }
    }

    // Clamp all reps to [3, 10] range
    listenReps = listenReps.clamp(3, 10);
    readAlongReps = readAlongReps.clamp(3, 10);
    readSoloReps = readSoloReps.clamp(3, 10);
    reciteReps = reciteReps.clamp(3, 10);

    // ── Sabaq recipe (new memorization) ──
    recipes.add(
      SessionRecipe(
        id: '${plan.id}_sabaq_$nowMs',
        planId: plan.id,
        phase: 'sabaq',
        estimatedMinutes: plan.sabaqTargetMinutes,
        steps: [
          RecipeStep(
            stepNumber: 1,
            action: RecipeAction.listen,
            instruction:
                'Listen to the page being recited. Focus on the melody and pronunciation.',
            target: listenReps,
            icon: 'headphones',
          ),
          RecipeStep(
            stepNumber: 2,
            action: RecipeAction.readAlong,
            instruction:
                'Read along with the audio. Match the reciter\'s pace and tajweed.',
            target: readAlongReps,
            icon: 'book_open',
          ),
          RecipeStep(
            stepNumber: 3,
            action: RecipeAction.readSolo,
            instruction:
                'Read on your own without audio. Check your accuracy after each attempt.',
            target: readSoloReps,
            icon: 'pencil',
          ),
          RecipeStep(
            stepNumber: 4,
            action: RecipeAction.reciteMemory,
            instruction:
                'Close the mushaf and recite from memory. Repeat until confident.',
            target: reciteReps,
            icon: 'brain',
          ),
        ],
        tips: [
          'Focus on 2-3 lines at a time, then connect them together.',
          'Record yourself and compare with the reciter to spot mistakes.',
          'Review the meaning to build deeper neural connections.',
        ],
      ),
    );

    // ── Sabqi recipe (recent review) ──
    if (plan.sabqiPages.isNotEmpty) {
      recipes.add(
        SessionRecipe(
          id: '${plan.id}_sabqi_$nowMs',
          planId: plan.id,
          phase: 'sabqi',
          estimatedMinutes: plan.sabqiTargetMinutes,
          steps: [
            const RecipeStep(
              stepNumber: 1,
              action: RecipeAction.readSolo,
              instruction:
                  'Read through the review pages. Note any areas that feel uncertain.',
              target: 2,
              icon: 'book_open',
            ),
            const RecipeStep(
              stepNumber: 2,
              action: RecipeAction.selfTest,
              instruction:
                  'Close the mushaf and recite each page from memory. Check and correct.',
              target: 2,
              icon: 'check_circle',
            ),
          ],
          tips: [
            'Don\'t skip pages that feel easy — even strong pages need maintenance.',
            'If a page feels weak, add an extra repetition.',
          ],
        ),
      );
    }

    // ── Manzil recipe (long-term review) ──
    if (plan.manzilPages.isNotEmpty) {
      recipes.add(
        SessionRecipe(
          id: '${plan.id}_manzil_$nowMs',
          planId: plan.id,
          phase: 'manzil',
          estimatedMinutes: plan.manzilTargetMinutes,
          steps: [
            const RecipeStep(
              stepNumber: 1,
              action: RecipeAction.readSolo,
              instruction:
                  'Read through the manzil pages at a steady pace. Focus on fluency.',
              target: 1,
              icon: 'library',
            ),
            const RecipeStep(
              stepNumber: 2,
              action: RecipeAction.selfTest,
              instruction:
                  'Recite from memory. Use the mushaf only to check uncertain sections.',
              target: 1,
              icon: 'check_circle',
            ),
          ],
          tips: [
            'Manzil keeps your long-term memorization strong.',
            'Consistency matters more than perfection here.',
          ],
        ),
      );
    }

    return recipes;
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
