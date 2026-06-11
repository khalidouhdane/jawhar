import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

MemoryProfile _profile({
  EncodingSpeed encodingSpeed = EncodingSpeed.moderate,
  RetentionStrength retentionStrength = RetentionStrength.moderate,
  LearningPreference learningPreference = LearningPreference.visual,
  PacePreference pacePreference = PacePreference.steady,
  AgeGroup ageGroup = AgeGroup.youngAdult,
  int dailyTimeMinutes = 30,
  int startingPage = 582,
}) => MemoryProfile(
  id: 'p1',
  name: 'Fixture',
  createdAt: DateTime(2026, 1, 1),
  startDate: DateTime(2026, 1, 1),
  encodingSpeed: encodingSpeed,
  retentionStrength: retentionStrength,
  learningPreference: learningPreference,
  pacePreference: pacePreference,
  ageGroup: ageGroup,
  dailyTimeMinutes: dailyTimeMinutes,
  startingPage: startingPage,
);

DailyPlan _plan({
  List<int> sabqiPages = const [],
  List<int> manzilPages = const [],
}) => DailyPlan(
  id: 'p1_2026-06-10T00:00:00.000',
  profileId: 'p1',
  date: DateTime(2026, 6, 10),
  sabaqPage: 582,
  sabaqTargetMinutes: 18,
  sabqiPages: sabqiPages,
  sabqiTargetMinutes: sabqiPages.isEmpty ? 0 : 12,
  manzilPages: manzilPages,
  manzilTargetMinutes: manzilPages.isEmpty ? 0 : 10,
);

void main() {
  group('PlanGenerator.generate — branch coverage beyond the goldens', () {
    test('sabaq + manzil only: sabqi budget redistributes 65/35', () {
      final plan = PlanGenerator.generate(
        profile: _profile(dailyTimeMinutes: 60, startingPage: 1),
        progress: {},
        rotationJuz: [1],
        now: DateTime(2026, 6, 10, 9),
      );

      expect(plan.sabqiPages, isEmpty);
      expect(plan.sabaqTargetMinutes, 39, reason: '60 × 0.65 rounded');
      expect(plan.manzilTargetMinutes, 21);
      expect(plan.sabqiTargetMinutes, 0);
      expect(plan.manzilJuz, 1);
      expect(
        plan.manzilPages,
        [1, 2, 3, 4, 5],
        reason: 'moderate retention → 5 manzil pages from juz start',
      );
      // Generation never sets the *DoneOffline flags (Phase 1 task 7).
      expect(plan.sabqiDoneOffline, isFalse);
      expect(plan.manzilDoneOffline, isFalse);
      expect(plan.isSabqiDone, isTrue);
      expect(plan.isManzilDone, isFalse);
    });

    test('manzil rotation round-robins by day index', () {
      // 2026-06-10 is 891 days after 2024-01-01 → odd → second juz of two.
      final plan = PlanGenerator.generate(
        profile: _profile(),
        progress: {},
        rotationJuz: [5, 10],
        now: DateTime(2026, 6, 10, 9),
      );
      expect(plan.manzilJuz, 10);
      expect(plan.manzilPages.first, QuranMeta.juzStartPage(10));
    });

    test('review mode: when every page has progress, sabaq returns to the '
        'starting page', () {
      final progress = <int, PageProgress>{
        for (var page = 1; page <= 604; page++)
          page: PageProgress(
            pageNumber: page,
            profileId: 'p1',
            status: PageStatus.memorized,
            lastReviewedAt: DateTime(2026, 6, 1),
          ),
      };
      final plan = PlanGenerator.generate(
        profile: _profile(startingPage: 100),
        progress: progress,
        rotationJuz: [],
        now: DateTime(2026, 6, 10, 9),
      );
      expect(plan.sabaqPage, 100);
      expect(plan.sabaqLineStart, 1);
    });

    test('fast encoder on a long daily budget gets a full page with '
        'aggressive pace clamped to 15 lines', () {
      final plan = PlanGenerator.generate(
        profile: _profile(
          encodingSpeed: EncodingSpeed.fast,
          retentionStrength: RetentionStrength.fragile,
          pacePreference: PacePreference.aggressive,
          dailyTimeMinutes: 240,
          startingPage: 1,
        ),
        progress: {},
        rotationJuz: [],
        now: DateTime(2026, 6, 10, 9),
      );
      expect(plan.sabaqLineStart, 1);
      expect(plan.sabaqLineEnd, 15);
      expect(
        plan.sabaqRepetitionTarget,
        20,
        reason: 'fast + fragile → 20 reps',
      );
    });

    test('slow encoder with gentle pace gets a small line chunk', () {
      final plan = PlanGenerator.generate(
        profile: _profile(
          encodingSpeed: EncodingSpeed.slow,
          retentionStrength: RetentionStrength.strong,
          pacePreference: PacePreference.gentle,
          dailyTimeMinutes: 90,
          startingPage: 1,
        ),
        progress: {},
        rotationJuz: [],
        now: DateTime(2026, 6, 10, 9),
      );
      // ≤120min slow → 7 lines, ×0.7 gentle → 5 lines.
      expect(plan.sabaqLineEnd, 5);
      expect(
        plan.sabaqRepetitionTarget,
        25,
        reason: 'slow + strong → 25 reps',
      );
    });
  });

  group('PlanGenerator.generateDefaultRecipes', () {
    final now = DateTime(2026, 6, 10, 9);
    final nowMs = now.millisecondsSinceEpoch;

    List<int> targets(SessionRecipe recipe) =>
        recipe.steps.map((s) => s.target).toList();

    test('sabaq-only plan without a profile uses the 5x base targets', () {
      final recipes = PlanGenerator.generateDefaultRecipes(_plan(), null, now);
      expect(recipes, hasLength(1));
      final sabaq = recipes.single;
      expect(sabaq.id, '${_plan().id}_sabaq_$nowMs');
      expect(sabaq.planId, _plan().id);
      expect(sabaq.phase, 'sabaq');
      expect(sabaq.estimatedMinutes, 18);
      expect(targets(sabaq), [5, 5, 5, 5]);
      expect(sabaq.steps.map((s) => s.action), [
        RecipeAction.listen,
        RecipeAction.readAlong,
        RecipeAction.readSolo,
        RecipeAction.reciteMemory,
      ]);
      expect(sabaq.tips, isNotEmpty);
    });

    test('full plan yields sabaq + sabqi + manzil recipes with fixed '
        'review steps', () {
      final plan = _plan(sabqiPages: [580, 581], manzilPages: [22]);
      final recipes = PlanGenerator.generateDefaultRecipes(plan, null, now);
      expect(recipes.map((r) => r.phase), ['sabaq', 'sabqi', 'manzil']);

      final sabqi = recipes[1];
      expect(sabqi.id, '${plan.id}_sabqi_$nowMs');
      expect(sabqi.estimatedMinutes, 12);
      expect(targets(sabqi), [2, 2]);
      expect(sabqi.steps.last.action, RecipeAction.selfTest);

      final manzil = recipes[2];
      expect(manzil.id, '${plan.id}_manzil_$nowMs');
      expect(manzil.estimatedMinutes, 10);
      expect(targets(manzil), [1, 1]);
    });

    test('fast + strong + auditory adult: fewer passive reps, fewer solo '
        'reads', () {
      final recipes = PlanGenerator.generateDefaultRecipes(
        _plan(),
        _profile(
          encodingSpeed: EncodingSpeed.fast,
          retentionStrength: RetentionStrength.strong,
          learningPreference: LearningPreference.auditory,
        ),
        now,
      );
      // listen 5→2(fast)→3(auditory); readAlong 5→2→3;
      // readSolo 5→4(auditory); recite 5→4(strong).
      expect(targets(recipes.single), [3, 3, 4, 4]);
    });

    test('slow + fragile + repetition child: everything ramps up', () {
      final recipes = PlanGenerator.generateDefaultRecipes(
        _plan(),
        _profile(
          encodingSpeed: EncodingSpeed.slow,
          retentionStrength: RetentionStrength.fragile,
          learningPreference: LearningPreference.repetition,
          ageGroup: AgeGroup.child,
        ),
        now,
      );
      // listen 5→6(slow)→7(child); readAlong 5→6→7;
      // readSolo 5→6(slow)→7(fragile)→8(repetition);
      // recite 5→6(slow)→7(fragile)→9(repetition).
      expect(targets(recipes.single), [7, 7, 8, 9]);
    });

    test('visual learner shifts reps from listening to reading', () {
      final recipes = PlanGenerator.generateDefaultRecipes(
        _plan(),
        _profile(learningPreference: LearningPreference.visual),
        now,
      );
      // listen 5→4(visual); readAlong 5→6; readSolo 5→6; recite 5.
      expect(targets(recipes.single), [4, 6, 6, 5]);
    });

    test('kinesthetic learner gets extra solo practice', () {
      final recipes = PlanGenerator.generateDefaultRecipes(
        _plan(),
        _profile(learningPreference: LearningPreference.kinesthetic),
        now,
      );
      expect(targets(recipes.single), [5, 5, 6, 6]);
    });
  });

  group('QuranMeta', () {
    test('constants describe the Madani mushaf', () {
      expect(QuranMeta.totalPages, 604);
      expect(QuranMeta.totalJuz, 30);
      expect(QuranMeta.linesPerPage, 15);
      expect(QuranMeta.juzStartPages, hasLength(31));
    });

    test('juzStartPage clamps and matches the vendored table', () {
      expect(QuranMeta.juzStartPage(1), 1);
      expect(QuranMeta.juzStartPage(30), 582);
      expect(QuranMeta.juzStartPage(0), 1, reason: 'clamped up to juz 1');
      expect(QuranMeta.juzStartPage(99), 582, reason: 'clamped down to 30');
    });

    test('juzEndPage is the page before the next juz, 604 for juz 30', () {
      expect(QuranMeta.juzEndPage(1), 21);
      expect(QuranMeta.juzEndPage(29), 581);
      expect(QuranMeta.juzEndPage(30), 604);
    });
  });

  group('SrsEngine helpers', () {
    test('systemLocalDayBoundary returns naive local midnight', () {
      expect(
        SrsEngine.systemLocalDayBoundary(DateTime(2026, 6, 10, 23, 30)),
        DateTime(2026, 6, 10),
      );
      // UTC instants are folded into the SYSTEM timezone first; assert the
      // timezone-independent invariants (naive local midnight) so this test
      // passes on any CI/dev machine timezone.
      final utcInstant = DateTime.utc(2026, 6, 10, 12);
      final boundary = SrsEngine.systemLocalDayBoundary(utcInstant);
      expect(boundary.isUtc, isFalse);
      expect(boundary.hour, 0);
      expect(boundary.minute, 0);
      final local = utcInstant.toLocal();
      expect(boundary, DateTime(local.year, local.month, local.day));
    });

    test('dayBoundaryForOffset shifts the day exactly like the device', () {
      final utcPlus3 = SrsEngine.dayBoundaryForOffset(180);
      expect(
        utcPlus3(DateTime.utc(2026, 6, 10, 22, 0)),
        DateTime(2026, 6, 11),
        reason: '22:00Z is 01:00 local at UTC+3 → next local day',
      );
      final utcMinus5 = SrsEngine.dayBoundaryForOffset(-300);
      expect(
        utcMinus5(DateTime.utc(2026, 6, 11, 3, 30)),
        DateTime(2026, 6, 10),
        reason: '03:30Z is 22:30 local at UTC-5 → previous local day',
      );
    });

    test('estimateMinutes assumes ~10s per card, clamped to 1–60', () {
      expect(SrsEngine.estimateMinutes(0), 1);
      expect(SrsEngine.estimateMinutes(30), 5);
      expect(SrsEngine.estimateMinutes(100000), 60);
    });
  });
}
