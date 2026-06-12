import 'dart:convert';
import 'dart:io';

import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

/// Golden weekly-analytics suite: the pure calculators copied from
/// `lib/services/analytics_service.dart` must reproduce its semantics
/// exactly, including the SQLite ISO-string range comparisons (the
/// non-UTC boundary fixture pins the accepted R5 mis-bucketing so it can
/// never change silently).
void main() {
  final fixtureDir = Directory('test/fixtures/analytics');
  final fixtureFiles =
      fixtureDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('analytics fixture directory is populated', () {
    expect(fixtureFiles, isNotEmpty);
  });

  for (final file in fixtureFiles) {
    final fixture = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final name = file.uri.pathSegments.last;

    test('golden weekly snapshot: $name', () {
      final sessions = [
        for (final raw in fixture['sessions'] as List)
          SessionRecord.fromMap((raw as Map).cast<String, dynamic>()),
      ];
      final plans = [
        for (final raw in fixture['plans'] as List)
          DailyPlan.fromMap((raw as Map).cast<String, dynamic>()),
      ];
      final progress = [
        for (final raw in fixture['progress'] as List)
          PageProgress.fromMap((raw as Map).cast<String, dynamic>()),
      ];

      final snapshot = AnalyticsCalculators.weeklySnapshot(
        profileId: fixture['profileId'] as String,
        startDate: DateTime.parse(fixture['startDate'] as String),
        endDate: DateTime.parse(fixture['endDate'] as String),
        sessions: sessions,
        plans: plans,
        progress: progress,
      );

      final expected = fixture['expected'] as Map<String, dynamic>;
      expect(snapshot.startDate.toIso8601String(), expected['startDate']);
      expect(snapshot.endDate.toIso8601String(), expected['endDate']);
      expect(snapshot.totalSessions, expected['totalSessions']);
      expect(snapshot.totalDurationMinutes, expected['totalDurationMinutes']);
      expect(
        snapshot.avgDurationMinutes,
        (expected['avgDurationMinutes'] as num).toDouble(),
      );
      expect(snapshot.sessionsPerDay, {
        for (final entry in (expected['sessionsPerDay'] as Map).entries)
          int.parse(entry.key as String): entry.value as int,
      });
      expect(snapshot.plannedDays, expected['plannedDays']);
      expect(snapshot.completedDays, expected['completedDays']);
      expect(
        snapshot.completionRate,
        closeTo((expected['completionRate'] as num).toDouble(), 1e-12),
      );
      expect(snapshot.strongCount, expected['strongCount']);
      expect(snapshot.okayCount, expected['okayCount']);
      expect(snapshot.needsWorkCount, expected['needsWorkCount']);
      expect(snapshot.pagesMemorized, expected['pagesMemorized']);
      expect(snapshot.pagesReviewed, expected['pagesReviewed']);
      expect(
        snapshot.pagesPerWeek,
        closeTo((expected['pagesPerWeek'] as num).toDouble(), 1e-12),
      );
    });
  }

  group('suggestions (ported thresholds)', () {
    final profile = MemoryProfile(
      id: 'p1',
      name: 'Test',
      createdAt: DateTime(2026, 1, 1),
      startDate: DateTime(2026, 1, 1),
    );
    final now = DateTime(2026, 6, 10, 12);

    test('not enough data → no suggestions', () {
      expect(
        AnalyticsCalculators.suggestions(
          profile: profile,
          current: WeeklySnapshot(
            startDate: DateTime(2026, 6, 8),
            endDate: DateTime(2026, 6, 14),
            totalSessions: 2,
          ),
          now: now,
        ),
        isEmpty,
      );
    });

    test('strong week → increaseLoad; ahead-of-schedule needs previous', () {
      final current = WeeklySnapshot(
        startDate: DateTime(2026, 6, 8),
        endDate: DateTime(2026, 6, 14),
        totalSessions: 5,
        plannedDays: 5,
        completedDays: 5,
        completionRate: 1.0,
        strongCount: 8,
        okayCount: 2,
        needsWorkCount: 0,
        pagesMemorized: 4,
      );
      final previous = WeeklySnapshot(
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 7),
        totalSessions: 5,
        pagesMemorized: 2,
      );

      final withoutPrevious = AnalyticsCalculators.suggestions(
        profile: profile,
        current: current,
        now: now,
      );
      expect(withoutPrevious.map((s) => s.type), [SuggestionType.increaseLoad]);
      expect(
        withoutPrevious.first.id,
        'increase_${now.millisecondsSinceEpoch}',
      );

      final withPrevious = AnalyticsCalculators.suggestions(
        profile: profile,
        current: current,
        previous: previous,
        now: now,
      );
      expect(withPrevious.map((s) => s.type), [
        SuggestionType.increaseLoad,
        SuggestionType.aheadOfSchedule,
      ]);
    });

    test('low completion + weak assessments → takeBreak and moreReview', () {
      final current = WeeklySnapshot(
        startDate: DateTime(2026, 6, 8),
        endDate: DateTime(2026, 6, 14),
        totalSessions: 4,
        plannedDays: 6,
        completedDays: 2,
        completionRate: 2 / 6,
        strongCount: 1,
        okayCount: 1,
        needsWorkCount: 3,
      );
      final result = AnalyticsCalculators.suggestions(
        profile: profile,
        current: current,
        now: now,
      );
      expect(result.map((s) => s.type), [
        SuggestionType.takeBreak,
        SuggestionType.moreReview,
      ]);
    });
  });

  group('pace (ported from calculatePace)', () {
    final now = DateTime(2026, 6, 10, 12);

    test('full-Quran goal with recent pages', () {
      final profile = MemoryProfile(
        id: 'p1',
        name: 'Test',
        createdAt: DateTime(2026, 1, 1),
        startDate: DateTime(2026, 1, 1),
      );
      final progress = [
        // 3 memorized, 2 of them within the last 30 days.
        PageProgress(
          pageNumber: 1,
          profileId: 'p1',
          status: PageStatus.memorized,
          memorizedAt: DateTime.utc(2026, 6, 1),
        ),
        PageProgress(
          pageNumber: 2,
          profileId: 'p1',
          status: PageStatus.memorized,
          memorizedAt: DateTime.utc(2026, 5, 20),
        ),
        PageProgress(
          pageNumber: 3,
          profileId: 'p1',
          status: PageStatus.memorized,
          memorizedAt: DateTime.utc(2026, 1, 10),
        ),
        const PageProgress(
          pageNumber: 4,
          profileId: 'p1',
          status: PageStatus.learning,
        ),
        const PageProgress(
          pageNumber: 5,
          profileId: 'p2', // other profile — excluded
          status: PageStatus.memorized,
        ),
      ];

      final pace = AnalyticsCalculators.pace(
        profile: profile,
        progress: progress,
        now: now,
      );
      expect(pace.memorizedPages, 3);
      expect(pace.totalGoalPages, 604);
      expect(pace.remainingPages, 601);
      expect(pace.pagesPerMonth, 2.0);
      expect(pace.monthsRemaining, (601 / 2.0).ceil());
      expect(pace.progressPercent, 3 / 604);
      expect(pace.toMap(), {
        'memorizedPages': 3,
        'totalGoalPages': 604,
        'remainingPages': 601,
        'pagesPerMonth': 2.0,
        'monthsRemaining': 301,
        'progressPercent': 3 / 604,
      });
    });

    test('specific-juz and specific-surah goal sizing, zero recent → 1.0', () {
      final juzProfile = MemoryProfile(
        id: 'p1',
        name: 'Test',
        createdAt: DateTime(2026, 1, 1),
        startDate: DateTime(2026, 1, 1),
        goal: HifzGoal.specificJuz,
        goalDetails: const [29, 30],
      );
      final pace = AnalyticsCalculators.pace(
        profile: juzProfile,
        progress: const [],
        now: now,
      );
      expect(pace.totalGoalPages, 40);
      expect(pace.pagesPerMonth, 1.0); // zero recent → floor of 1/month
      expect(pace.progressPercent, 0.0);

      final surahProfile = MemoryProfile(
        id: 'p1',
        name: 'Test',
        createdAt: DateTime(2026, 1, 1),
        startDate: DateTime(2026, 1, 1),
        goal: HifzGoal.specificSurahs,
        goalDetails: const [1, 2, 3],
      );
      expect(
        AnalyticsCalculators.pace(
          profile: surahProfile,
          progress: const [],
          now: now,
        ).totalGoalPages,
        15,
      );
    });
  });

  group('neglected juz + struggle pages (ported)', () {
    final now = DateTime(2026, 6, 10, 12);

    test('neglected juz groups stale memorized/reviewing pages', () {
      final progress = [
        // Juz 30 (582+), stale.
        PageProgress(
          pageNumber: 583,
          profileId: 'p1',
          status: PageStatus.memorized,
          lastReviewedAt: DateTime.utc(2026, 6, 1),
        ),
        PageProgress(
          pageNumber: 582,
          profileId: 'p1',
          status: PageStatus.reviewing,
          lastReviewedAt: DateTime.utc(2026, 5, 30),
        ),
        // Juz 1, never reviewed (null → neglected).
        const PageProgress(
          pageNumber: 3,
          profileId: 'p1',
          status: PageStatus.reviewing,
        ),
        // Fresh page — not neglected.
        PageProgress(
          pageNumber: 584,
          profileId: 'p1',
          status: PageStatus.memorized,
          lastReviewedAt: DateTime.utc(2026, 6, 9),
        ),
        // Learning status — never eligible.
        PageProgress(
          pageNumber: 100,
          profileId: 'p1',
          status: PageStatus.learning,
          lastReviewedAt: DateTime.utc(2026, 5, 1),
        ),
      ];

      final result = AnalyticsCalculators.neglectedJuz(
        profileId: 'p1',
        progress: progress,
        now: now,
      );
      expect(result.map((n) => n.juz), [1, 30]);
      expect(result.first.pages, [3]);
      expect(result.last.pages, [582, 583]);
      expect(result.last.pageCount, 2);
      expect(result.last.toMap(), {
        'juz': 30,
        'pages': [582, 583],
        'pageCount': 2,
      });
    });

    test('struggle pages need 2+ weak sabaq assessments in 14 days', () {
      SessionRecord weak(String id, DateTime date, int page) => SessionRecord(
        id: id,
        profileId: 'p1',
        date: date,
        durationMinutes: 20,
        sabaqAssessment: SelfAssessment.needsWork,
        sabaqPage: page,
      );

      final sessions = [
        weak('w1', DateTime.utc(2026, 6, 8), 582),
        weak('w2', DateTime.utc(2026, 6, 9), 582),
        weak('w3', DateTime.utc(2026, 6, 9, 18), 583), // only once
        weak('w4', DateTime.utc(2026, 5, 1), 584), // out of 14-day window
        weak('w5', DateTime.utc(2026, 5, 2), 584),
        SessionRecord(
          id: 'strong1',
          profileId: 'p1',
          date: DateTime.utc(2026, 6, 9),
          durationMinutes: 20,
          sabaqAssessment: SelfAssessment.strong,
          sabaqPage: 585,
        ),
      ];

      expect(
        AnalyticsCalculators.strugglePages(
          profileId: 'p1',
          sessions: sessions,
          now: now,
        ),
        [582],
      );
    });
  });

  test('QuranMeta.pageToJuz matches the juz table walk', () {
    expect(QuranMeta.pageToJuz(1), 1);
    expect(QuranMeta.pageToJuz(21), 1);
    expect(QuranMeta.pageToJuz(22), 2);
    expect(QuranMeta.pageToJuz(581), 29);
    expect(QuranMeta.pageToJuz(582), 30);
    expect(QuranMeta.pageToJuz(604), 30);
    // Every juz start page maps to its own juz.
    for (var juz = 1; juz <= QuranMeta.totalJuz; juz++) {
      expect(QuranMeta.pageToJuz(QuranMeta.juzStartPage(juz)), juz);
      expect(QuranMeta.pageToJuz(QuranMeta.juzEndPage(juz)), juz);
    }
  });
}
