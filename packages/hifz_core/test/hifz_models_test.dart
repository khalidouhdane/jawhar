import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

void main() {
  group('MemoryProfile', () {
    final profile = MemoryProfile(
      id: 'p1',
      name: 'Tester',
      avatarIndex: 2,
      createdAt: DateTime(2026, 1, 1),
      birthday: DateTime(1990, 1, 1),
      ageGroup: AgeGroup.adult,
      encodingSpeed: EncodingSpeed.fast,
      retentionStrength: RetentionStrength.fragile,
      learningPreference: LearningPreference.auditory,
      dailyTimeMinutes: 45,
      preferredTimeOfDay: StudyTimeOfDay.evening,
      goal: HifzGoal.specificJuz,
      goalDetails: const [29, 30],
      defaultReciterId: 4,
      defaultReciterSource: ReciterSource.mp3Quran,
      startingPage: 562,
      startDate: DateTime(2026, 2, 1),
      isActive: true,
      activeDays: const [0, 2, 4],
      pacePreference: PacePreference.aggressive,
      hifzExperience: HifzExperience.resuming,
    );

    test('toMap/fromMap round-trips every field', () {
      final restored = MemoryProfile.fromMap(profile.toMap());
      expect(restored.id, 'p1');
      expect(restored.name, 'Tester');
      expect(restored.avatarIndex, 2);
      expect(restored.createdAt, DateTime(2026, 1, 1));
      expect(restored.birthday, DateTime(1990, 1, 1));
      expect(restored.ageGroup, AgeGroup.adult);
      expect(restored.encodingSpeed, EncodingSpeed.fast);
      expect(restored.retentionStrength, RetentionStrength.fragile);
      expect(restored.learningPreference, LearningPreference.auditory);
      expect(restored.dailyTimeMinutes, 45);
      expect(restored.preferredTimeOfDay, StudyTimeOfDay.evening);
      expect(restored.goal, HifzGoal.specificJuz);
      expect(restored.goalDetails, [29, 30]);
      expect(restored.defaultReciterId, 4);
      expect(restored.defaultReciterSource, ReciterSource.mp3Quran);
      expect(restored.startingPage, 562);
      expect(restored.startDate, DateTime(2026, 2, 1));
      expect(restored.isActive, isTrue);
      expect(restored.activeDays, [0, 2, 4]);
      expect(restored.pacePreference, PacePreference.aggressive);
      expect(restored.hifzExperience, HifzExperience.resuming);
    });

    test('fromMap clamps persisted numbers and falls back on bad enums', () {
      final map = profile.toMap()
        ..['dailyTimeMinutes'] = 100000
        ..['startingPage'] = 700
        ..['encodingSpeed'] = 99
        ..['goalDetails'] = '1,114,200,abc'
        ..['isActive'] = 0;
      final restored = MemoryProfile.fromMap(map);
      expect(restored.dailyTimeMinutes, 480);
      expect(restored.startingPage, 604);
      expect(restored.encodingSpeed, EncodingSpeed.moderate);
      expect(restored.goalDetails, [1, 114]);
      expect(restored.isActive, isFalse);
    });

    test('age derives from birthday and clamps to a sane range', () {
      expect(
        profile.age,
        MemoryProfile.calculateAge(DateTime(1990, 1, 1)).clamp(7, 100),
      );
      // A birthday "today" yields age 0 → clamped to the 7 floor.
      final newborn = profile.copyWith(birthday: DateTime.now());
      expect(newborn.age, 7);
    });

    test('age falls back to the stored legacy value without a birthday', () {
      final legacy = MemoryProfile(
        id: 'p2',
        name: 'Legacy',
        createdAt: DateTime(2026, 1, 1),
        startDate: DateTime(2026, 1, 1),
        age: 33,
      );
      expect(legacy.age, 33);
    });

    test('calculateAge decrements before the birthday has passed this year',
        () {
      final now = DateTime.now();
      final notYet = DateTime(now.year - 20, now.month, now.day)
          .add(const Duration(days: 40));
      final passed = DateTime(now.year - 20, now.month, now.day)
          .subtract(const Duration(days: 40));
      expect(
        MemoryProfile.calculateAge(notYet) <
            MemoryProfile.calculateAge(passed),
        isTrue,
      );
    });

    test('ageGroupFromAge covers every bracket', () {
      expect(MemoryProfile.ageGroupFromAge(10), AgeGroup.child);
      expect(MemoryProfile.ageGroupFromAge(15), AgeGroup.teen);
      expect(MemoryProfile.ageGroupFromAge(25), AgeGroup.youngAdult);
      expect(MemoryProfile.ageGroupFromAge(40), AgeGroup.adult);
      expect(MemoryProfile.ageGroupFromAge(50), AgeGroup.middleAged);
      expect(MemoryProfile.ageGroupFromAge(65), AgeGroup.senior);
      expect(MemoryProfile.ageGroupFromAge(80), AgeGroup.elderly);
    });

    test('copyWith replaces named fields and can clear the birthday', () {
      final updated = profile.copyWith(
        name: 'Renamed',
        dailyTimeMinutes: 60,
        pacePreference: PacePreference.gentle,
      );
      expect(updated.name, 'Renamed');
      expect(updated.dailyTimeMinutes, 60);
      expect(updated.pacePreference, PacePreference.gentle);
      expect(updated.id, profile.id);
      expect(updated.birthday, profile.birthday);

      final cleared = profile.copyWith(clearBirthday: true);
      expect(cleared.birthday, isNull);
    });
  });

  group('PageProgress', () {
    final progress = PageProgress(
      pageNumber: 582,
      profileId: 'p1',
      status: PageStatus.learning,
      lastReviewedAt: DateTime.utc(2026, 6, 9, 10),
      reviewCount: 3,
      memorizedAt: null,
      lastVerseLearned: 5,
      totalVersesOnPage: 10,
    );

    test('toMap/fromMap round-trips', () {
      final restored = PageProgress.fromMap(progress.toMap());
      expect(restored.pageNumber, 582);
      expect(restored.profileId, 'p1');
      expect(restored.status, PageStatus.learning);
      expect(restored.lastReviewedAt, DateTime.utc(2026, 6, 9, 10));
      expect(restored.reviewCount, 3);
      expect(restored.memorizedAt, isNull);
      expect(restored.lastVerseLearned, 5);
      expect(restored.totalVersesOnPage, 10);
    });

    test('fromMap clamps the page number into the mushaf', () {
      final restored = PageProgress.fromMap(
        progress.toMap()..['pageNumber'] = 9999,
      );
      expect(restored.pageNumber, 604);
    });

    test('copyWith replaces only named fields', () {
      final updated = progress.copyWith(
        status: PageStatus.memorized,
        reviewCount: 4,
        memorizedAt: DateTime.utc(2026, 6, 10),
      );
      expect(updated.status, PageStatus.memorized);
      expect(updated.reviewCount, 4);
      expect(updated.memorizedAt, DateTime.utc(2026, 6, 10));
      expect(updated.pageNumber, progress.pageNumber);
      expect(updated.lastVerseLearned, progress.lastVerseLearned);
    });
  });

  group('DailyPlan derived phase checks (retired generation-time flags)', () {
    DailyPlan plan({
      List<int> sabqiPages = const [],
      List<int> manzilPages = const [],
      bool sabaqDoneOffline = false,
      bool sabqiDoneOffline = false,
      bool manzilDoneOffline = false,
    }) => DailyPlan(
      id: 'p1_2026-06-10T00:00:00.000',
      profileId: 'p1',
      date: DateTime(2026, 6, 10),
      sabaqPage: 582,
      sabqiPages: sabqiPages,
      manzilPages: manzilPages,
      sabaqDoneOffline: sabaqDoneOffline,
      sabqiDoneOffline: sabqiDoneOffline,
      manzilDoneOffline: manzilDoneOffline,
    );

    test('empty phases count as done WITHOUT any stored flag', () {
      final p = plan();
      expect(p.hasSabqiContent, isFalse);
      expect(p.hasManzilContent, isFalse);
      expect(p.sabqiDoneOffline, isFalse);
      expect(p.manzilDoneOffline, isFalse);
      expect(p.isSabqiDone, isTrue);
      expect(p.isManzilDone, isTrue);
      expect(p.isSabaqDone, isFalse, reason: 'sabaq is never empty');
    });

    test('non-empty phases are pending until marked done offline', () {
      final p = plan(sabqiPages: [580, 581], manzilPages: [22, 23]);
      expect(p.hasSabqiContent, isTrue);
      expect(p.hasManzilContent, isTrue);
      expect(p.isSabqiDone, isFalse);
      expect(p.isManzilDone, isFalse);
    });

    test('user-claimed offline completion still works on real content', () {
      final p = plan(
        sabqiPages: [580],
        manzilPages: [22],
        sabaqDoneOffline: true,
        sabqiDoneOffline: true,
        manzilDoneOffline: true,
      );
      expect(p.isSabaqDone, isTrue);
      expect(p.isSabqiDone, isTrue);
      expect(p.isManzilDone, isTrue);
    });

    test('legacy plans persisted with generation-time flags stay skipped', () {
      // Plans written before the refactor stored sabqiDoneOffline=1 for
      // empty phases; the derived getters must agree with them.
      final p = plan(sabqiDoneOffline: true, manzilDoneOffline: true);
      expect(p.isSabqiDone, isTrue);
      expect(p.isManzilDone, isTrue);
    });
  });

  group('DailyPlan', () {
    final plan = DailyPlan(
      id: 'p1_2026-06-10T00:00:00.000',
      profileId: 'p1',
      date: DateTime(2026, 6, 10),
      sabaqPage: 582,
      sabaqLineStart: 5,
      sabaqLineEnd: 8,
      sabaqTargetMinutes: 18,
      sabaqRepetitionTarget: 20,
      sabaqStartVerse: 6,
      sabqiPages: const [580, 581],
      sabqiTargetMinutes: 12,
      manzilJuz: 30,
      manzilPages: const [583, 584],
      manzilTargetMinutes: 10,
      isAiGenerated: true,
      aiReasoning: 'Because.',
    );

    test('estimatedMinutes sums the three phase budgets', () {
      expect(plan.estimatedMinutes, 40);
    });

    test('toMap/fromMap round-trips every field', () {
      final restored = DailyPlan.fromMap(plan.toMap());
      expect(restored.toMap(), plan.toMap());
      expect(restored.sabaqStartVerse, 6);
      expect(restored.sabqiPages, [580, 581]);
      expect(restored.manzilPages, [583, 584]);
      expect(restored.isAiGenerated, isTrue);
      expect(restored.aiReasoning, 'Because.');
    });

    test('fromMap clamps the sabaq page', () {
      final restored = DailyPlan.fromMap(plan.toMap()..['sabaqPage'] = 0);
      expect(restored.sabaqPage, 1);
    });

    test('copyWith replaces only named fields', () {
      final updated = plan.copyWith(
        sabqiDoneOffline: true,
        isCompleted: true,
        sabaqTargetMinutes: 25,
      );
      expect(updated.sabqiDoneOffline, isTrue);
      expect(updated.isCompleted, isTrue);
      expect(updated.sabaqTargetMinutes, 25);
      expect(updated.id, plan.id);
      expect(updated.sabaqPage, plan.sabaqPage);
      expect(updated.aiReasoning, plan.aiReasoning);
      expect(plan.copyWith().toMap(), plan.toMap());
    });
  });

  group('SessionRecord', () {
    final record = SessionRecord(
      id: 'sess-1',
      profileId: 'p1',
      date: DateTime.utc(2026, 6, 10, 19),
      durationMinutes: 38,
      sabaqCompleted: true,
      sabqiCompleted: true,
      manzilCompleted: false,
      sabaqAssessment: SelfAssessment.strong,
      sabqiAssessment: SelfAssessment.okay,
      manzilAssessment: null,
      sabaqPage: 582,
      sabqiPages: const [580, 581],
      manzilPages: const [22, 23],
      repCount: 14,
    );

    test('toMap/fromMap round-trips, keeping null assessments null', () {
      final restored = SessionRecord.fromMap(record.toMap());
      expect(restored.id, 'sess-1');
      expect(restored.profileId, 'p1');
      expect(restored.date, DateTime.utc(2026, 6, 10, 19));
      expect(restored.durationMinutes, 38);
      expect(restored.sabaqCompleted, isTrue);
      expect(restored.sabqiCompleted, isTrue);
      expect(restored.manzilCompleted, isFalse);
      expect(restored.sabaqAssessment, SelfAssessment.strong);
      expect(restored.sabqiAssessment, SelfAssessment.okay);
      expect(restored.manzilAssessment, isNull);
      expect(restored.sabaqPage, 582);
      expect(restored.sabqiPages, [580, 581]);
      expect(restored.manzilPages, [22, 23]);
      expect(restored.repCount, 14);
    });

    test('fromMap clamps duration and drops out-of-range pages', () {
      final restored = SessionRecord.fromMap(
        record.toMap()
          ..['durationMinutes'] = -5
          ..['sabqiPages'] = '580,9999,581',
      );
      expect(restored.durationMinutes, 0);
      expect(restored.sabqiPages, [580, 581]);
    });
  });

  group('StreakData / Suggestion / WeeklySnapshot', () {
    test('StreakData defaults to an empty streak', () {
      const streak = StreakData();
      expect(streak.totalActiveDays, 0);
      expect(streak.lastActiveDate, isNull);
    });

    test('Suggestion.copyWith only changes the action', () {
      final suggestion = Suggestion(
        id: 's1',
        type: SuggestionType.moreReview,
        iconKey: 'repeat',
        title: 'More review',
        message: 'Add review time.',
        createdAt: DateTime(2026, 6, 10),
        data: const {'juz': 30},
      );
      final accepted = suggestion.copyWith(action: SuggestionAction.accepted);
      expect(accepted.action, SuggestionAction.accepted);
      expect(accepted.id, 's1');
      expect(accepted.data, {'juz': 30});
      expect(suggestion.action, SuggestionAction.pending);
      expect(suggestion.copyWith().action, SuggestionAction.pending);
    });

    test('WeeklySnapshot derives assessment totals and data sufficiency', () {
      final sparse = WeeklySnapshot(
        startDate: DateTime(2026, 6, 8),
        endDate: DateTime(2026, 6, 14),
        totalSessions: 2,
        strongCount: 1,
        okayCount: 1,
      );
      expect(sparse.totalAssessments, 2);
      expect(sparse.hasEnoughData, isFalse);

      final rich = WeeklySnapshot(
        startDate: DateTime(2026, 6, 8),
        endDate: DateTime(2026, 6, 14),
        totalSessions: 5,
        strongCount: 3,
        okayCount: 2,
        needsWorkCount: 1,
      );
      expect(rich.totalAssessments, 6);
      expect(rich.hasEnoughData, isTrue);
    });
  });
}
