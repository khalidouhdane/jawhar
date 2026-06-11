import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

void main() {
  group('RecipeAction', () {
    const jsonByAction = {
      RecipeAction.listen: 'listen',
      RecipeAction.readAlong: 'read_along',
      RecipeAction.readSolo: 'read_solo',
      RecipeAction.reciteMemory: 'recite_memory',
      RecipeAction.linkPractice: 'link_practice',
      RecipeAction.write: 'write',
      RecipeAction.reviewMeaning: 'review_meaning',
      RecipeAction.selfTest: 'self_test',
    };

    test('toJson/fromJson round-trips every action', () {
      for (final entry in jsonByAction.entries) {
        expect(entry.key.toJson(), entry.value);
        expect(RecipeAction.fromJson(entry.value), entry.key);
      }
    });

    test('fromJson falls back to readSolo on unknown input', () {
      expect(RecipeAction.fromJson('moonwalk'), RecipeAction.readSolo);
    });

    test('every action has a non-empty human label', () {
      expect(RecipeAction.listen.label, 'Listen');
      expect(RecipeAction.reciteMemory.label, 'Recite from Memory');
      for (final action in RecipeAction.values) {
        expect(action.label, isNotEmpty);
      }
    });
  });

  group('StepUnit', () {
    test('round-trips and falls back to times', () {
      expect(StepUnit.fromJson('minutes'), StepUnit.minutes);
      expect(StepUnit.fromJson('times'), StepUnit.times);
      expect(StepUnit.fromJson('anything-else'), StepUnit.times);
      expect(StepUnit.minutes.toJson(), 'minutes');
      expect(StepUnit.times.toJson(), 'times');
    });
  });

  group('RecipeStep', () {
    test('toMap/fromMap round-trips', () {
      const step = RecipeStep(
        stepNumber: 3,
        action: RecipeAction.reviewMeaning,
        instruction: 'Review the meaning.',
        target: 4,
        unit: StepUnit.minutes,
        icon: 'brain',
      );

      final restored = RecipeStep.fromMap(step.toMap());
      expect(restored.stepNumber, 3);
      expect(restored.action, RecipeAction.reviewMeaning);
      expect(restored.instruction, 'Review the meaning.');
      expect(restored.target, 4);
      expect(restored.unit, StepUnit.minutes);
      expect(restored.icon, 'brain');
    });

    test('fromMap applies defaults for missing fields', () {
      final step = RecipeStep.fromMap(<String, dynamic>{});
      expect(step.stepNumber, 1);
      expect(step.action, RecipeAction.readSolo);
      expect(step.instruction, '');
      expect(step.target, 1);
      expect(step.unit, StepUnit.times);
      expect(step.icon, 'book_open');
    });
  });

  group('SessionRecipe', () {
    const steps = [
      RecipeStep(
        stepNumber: 1,
        action: RecipeAction.listen,
        instruction: 'Listen first.',
        target: 5,
        icon: 'headphones',
      ),
      RecipeStep(
        stepNumber: 2,
        action: RecipeAction.selfTest,
        instruction: 'Test yourself.',
        target: 10,
        unit: StepUnit.minutes,
      ),
      RecipeStep(
        stepNumber: 3,
        action: RecipeAction.reciteMemory,
        instruction: 'Recite.',
        target: 3,
      ),
    ];

    test('toMap/fromMap round-trips steps and tips through JSON columns', () {
      const recipe = SessionRecipe(
        id: 'plan1_sabaq_123',
        planId: 'plan1',
        phase: 'sabaq',
        steps: steps,
        estimatedMinutes: 18,
        tips: ['Tip one.', 'Tip two.'],
      );

      final restored = SessionRecipe.fromMap(recipe.toMap());
      expect(restored.id, 'plan1_sabaq_123');
      expect(restored.planId, 'plan1');
      expect(restored.phase, 'sabaq');
      expect(restored.estimatedMinutes, 18);
      expect(restored.tips, ['Tip one.', 'Tip two.']);
      expect(restored.steps, hasLength(3));
      expect(restored.steps[0].action, RecipeAction.listen);
      expect(restored.steps[1].unit, StepUnit.minutes);
      expect(restored.steps[2].target, 3);
    });

    test('fromMap tolerates missing JSON columns', () {
      final restored = SessionRecipe.fromMap(<String, dynamic>{
        'id': 'r1',
        'planId': 'plan1',
        'phase': 'manzil',
      });
      expect(restored.steps, isEmpty);
      expect(restored.tips, isEmpty);
      expect(restored.estimatedMinutes, 0);
      expect(restored.isEmpty, isTrue);
      expect(restored.isNotEmpty, isFalse);
    });

    test('totalTargetReps sums only times-unit steps', () {
      const recipe = SessionRecipe(
        id: 'r1',
        planId: 'plan1',
        phase: 'sabaq',
        steps: steps,
      );
      expect(recipe.totalTargetReps, 8, reason: '5 + 3, minutes step excluded');
      expect(recipe.isNotEmpty, isTrue);
    });

    test('fromAIResponse builds a phase-keyed recipe from validated maps', () {
      final recipe = SessionRecipe.fromAIResponse(
        planId: 'plan1',
        phase: 'sabqi',
        recipeMap: <String, dynamic>{
          'steps': [
            <String, dynamic>{
              'stepNumber': 1,
              'action': 'read_solo',
              'instruction': 'Read through.',
              'target': 2,
              'unit': 'times',
              'icon': 'book_open',
            },
          ],
          'estimatedMinutes': 12,
          'tips': ['Stay steady.'],
        },
      );

      expect(recipe.id, startsWith('plan1_sabqi_'));
      expect(recipe.planId, 'plan1');
      expect(recipe.phase, 'sabqi');
      expect(recipe.steps.single.action, RecipeAction.readSolo);
      expect(recipe.estimatedMinutes, 12);
      expect(recipe.tips, ['Stay steady.']);
    });

    test('fromAIResponse tolerates a sparse recipe map', () {
      final recipe = SessionRecipe.fromAIResponse(
        planId: 'plan1',
        phase: 'manzil',
        recipeMap: <String, dynamic>{},
      );
      expect(recipe.steps, isEmpty);
      expect(recipe.estimatedMinutes, 0);
      expect(recipe.tips, isEmpty);
    });
  });
}
