import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

MemoryProfile _profile({int dailyTimeMinutes = 30}) => MemoryProfile(
  id: 'p1',
  name: 'Fixture',
  createdAt: DateTime(2026, 1, 1),
  startDate: DateTime(2026, 1, 1),
  dailyTimeMinutes: dailyTimeMinutes,
);

void main() {
  group('AIPlanValidator.validate — plan section', () {
    test('clamps sabaq page and lines into the mushaf bounds', () {
      final validated = AIPlanValidator.validate(<String, dynamic>{
        'plan': <String, dynamic>{
          'sabaq': <String, dynamic>{
            'page': 700,
            'lineStart': 0,
            'lineEnd': 99,
            'startVerse': 3,
          },
        },
      });

      final sabaq =
          (validated['plan'] as Map<String, dynamic>)['sabaq']
              as Map<String, dynamic>;
      expect(sabaq['page'], 604);
      expect(sabaq['lineStart'], 1);
      expect(sabaq['lineEnd'], 15);
      expect(sabaq['startVerse'], 3);
    });

    test('raises lineEnd to lineStart when the AI inverts the range', () {
      final validated = AIPlanValidator.validate(<String, dynamic>{
        'plan': <String, dynamic>{
          'sabaq': <String, dynamic>{'page': 10, 'lineStart': 10, 'lineEnd': 2},
        },
      });

      final sabaq =
          (validated['plan'] as Map<String, dynamic>)['sabaq']
              as Map<String, dynamic>;
      expect(sabaq['lineStart'], 10);
      expect(sabaq['lineEnd'], 10);
    });

    test('filters sabqi pages: out-of-range and junk dropped, '
        'numeric strings and doubles coerced', () {
      final validated = AIPlanValidator.validate(<String, dynamic>{
        'plan': <String, dynamic>{
          'sabaq': <String, dynamic>{'page': 1},
          'sabqi': <String, dynamic>{
            'pages': [5, 'x', 0, 605, '12', 3.7],
          },
        },
      });

      final sabqi =
          (validated['plan'] as Map<String, dynamic>)['sabqi']
              as Map<String, dynamic>;
      expect(sabqi['pages'], [5, 12, 3]);
    });

    test('missing sabqi/manzil default to empty phases', () {
      final validated = AIPlanValidator.validate(<String, dynamic>{
        'plan': <String, dynamic>{
          'sabaq': <String, dynamic>{'page': 1},
        },
      });

      final plan = validated['plan'] as Map<String, dynamic>;
      expect((plan['sabqi'] as Map<String, dynamic>)['pages'], isEmpty);
      expect((plan['manzil'] as Map<String, dynamic>)['juz'], 0);
      expect((plan['manzil'] as Map<String, dynamic>)['pages'], isEmpty);
    });

    test('clamps manzil juz and filters its pages', () {
      final validated = AIPlanValidator.validate(<String, dynamic>{
        'plan': <String, dynamic>{
          'sabaq': <String, dynamic>{'page': 1},
          'manzil': <String, dynamic>{
            'juz': 42,
            'pages': [582, -1, 604],
          },
        },
      });

      final manzil =
          (validated['plan'] as Map<String, dynamic>)['manzil']
              as Map<String, dynamic>;
      expect(manzil['juz'], 30);
      expect(manzil['pages'], [582, 604]);
    });

    test('throws when "plan" is missing', () {
      expect(
        () => AIPlanValidator.validate(<String, dynamic>{}),
        throwsA(
          isA<AIValidationException>().having(
            (e) => e.message,
            'message',
            contains('Missing "plan"'),
          ),
        ),
      );
    });

    test('throws when "plan.sabaq" is missing', () {
      expect(
        () => AIPlanValidator.validate(<String, dynamic>{
          'plan': <String, dynamic>{},
        }),
        throwsA(
          isA<AIValidationException>().having(
            (e) => e.message,
            'message',
            contains('plan.sabaq'),
          ),
        ),
      );
    });

    test('wraps structural cast errors with the raw response attached', () {
      final raw = <String, dynamic>{'plan': 'not a map'};
      expect(
        () => AIPlanValidator.validate(raw),
        throwsA(
          isA<AIValidationException>()
              .having(
                (e) => e.message,
                'message',
                contains('Failed to validate AI response'),
              )
              .having((e) => e.rawResponse, 'rawResponse', same(raw)),
        ),
      );
    });

    test('AIValidationException.toString carries the message', () {
      const e = AIValidationException('boom');
      expect(e.toString(), 'AIValidationException: boom');
    });
  });

  group('AIPlanValidator.validate — recipes section', () {
    Map<String, dynamic> validRaw(Map<String, dynamic>? recipes) =>
        <String, dynamic>{
          'plan': <String, dynamic>{
            'sabaq': <String, dynamic>{'page': 1},
          },
          'recipes': ?recipes,
        };

    test('missing recipes default to three empty recipes', () {
      final validated = AIPlanValidator.validate(validRaw(null));
      final recipes = validated['recipes'] as Map<String, dynamic>;
      for (final phase in ['sabaq', 'sabqi', 'manzil']) {
        final recipe = recipes[phase] as Map<String, dynamic>;
        expect(recipe['steps'], isEmpty);
        expect(recipe['estimatedMinutes'], 0);
        expect(recipe['tips'], isEmpty);
      }
    });

    test('clamps steps to 8, reps to 20, minutes to 5–120, '
        'and sanitizes actions/units/instructions', () {
      final steps = List.generate(
        10,
        (i) => <String, dynamic>{
          'action': 'fly',
          'target': 50,
          'unit': 'hours',
        },
      );
      final validated = AIPlanValidator.validate(
        validRaw(<String, dynamic>{
          'sabaq': <String, dynamic>{
            'steps': steps,
            'estimatedMinutes': 2,
            'tips': ['keep going', '', 42, 'breathe'],
          },
          'sabqi': <String, dynamic>{'estimatedMinutes': 300, 'steps': 'junk'},
        }),
      );

      final recipes = validated['recipes'] as Map<String, dynamic>;
      final sabaq = recipes['sabaq'] as Map<String, dynamic>;
      final sabaqSteps = sabaq['steps'] as List<Map<String, dynamic>>;
      expect(sabaqSteps, hasLength(8), reason: 'max 8 steps');
      expect(sabaqSteps.first['stepNumber'], 1);
      expect(sabaqSteps.last['stepNumber'], 8);
      expect(sabaqSteps.first['action'], 'read_solo', reason: 'invalid action');
      expect(sabaqSteps.first['instruction'], 'Continue with this step.');
      expect(sabaqSteps.first['target'], 20, reason: 'max 20 reps');
      expect(sabaqSteps.first['unit'], 'times', reason: 'invalid unit');
      expect(sabaqSteps.first['icon'], 'book_open');
      expect(sabaq['estimatedMinutes'], 5, reason: 'min 5 minutes');
      expect(sabaq['tips'], ['keep going', 'breathe']);

      final sabqi = recipes['sabqi'] as Map<String, dynamic>;
      expect(sabqi['estimatedMinutes'], 120, reason: 'max 120 minutes');
      expect(sabqi['steps'], isEmpty, reason: 'non-list steps ignored');
    });

    test('keeps valid actions and minute-unit steps unchanged', () {
      final validated = AIPlanValidator.validate(
        validRaw(<String, dynamic>{
          'manzil': <String, dynamic>{
            'steps': [
              <String, dynamic>{
                'action': 'self_test',
                'instruction': 'Recite from memory.',
                'target': 2,
                'unit': 'minutes',
                'icon': 'check_circle',
              },
            ],
            'estimatedMinutes': 10,
          },
        }),
      );

      final manzil =
          (validated['recipes'] as Map<String, dynamic>)['manzil']
              as Map<String, dynamic>;
      final step = (manzil['steps'] as List<Map<String, dynamic>>).single;
      expect(step['action'], 'self_test');
      expect(step['instruction'], 'Recite from memory.');
      expect(step['target'], 2);
      expect(step['unit'], 'minutes');
      expect(step['icon'], 'check_circle');
    });
  });

  group('AIPlanValidator.validate — frameworkParams and reasoning', () {
    test('missing frameworkParams produce the documented defaults', () {
      final validated = AIPlanValidator.validate(<String, dynamic>{
        'plan': <String, dynamic>{
          'sabaq': <String, dynamic>{'page': 1},
        },
      });

      expect(validated['frameworkParams'], {
        'dailySabaqLoad': 'unknown',
        'minReps': 10,
        'sabqiDaysBack': 7,
        'manzilPagesPerDay': 4,
        'timeDistribution': {'sabaq': 45, 'sabqi': 30, 'manzil': 25},
      });
      expect(validated['reasoning'], 'Plan generated successfully.');
    });

    test('clamps provided frameworkParams', () {
      final validated = AIPlanValidator.validate(<String, dynamic>{
        'plan': <String, dynamic>{
          'sabaq': <String, dynamic>{'page': 1},
        },
        'frameworkParams': <String, dynamic>{
          'dailySabaqLoad': 'half page',
          'minReps': 99,
          'sabqiDaysBack': 1,
          'manzilPagesPerDay': 0,
          'timeDistribution': <String, dynamic>{
            'sabaq': 2,
            'sabqi': 200,
            'manzil': '15',
          },
        },
        'reasoning': 'Custom reasoning.',
      });

      expect(validated['frameworkParams'], {
        'dailySabaqLoad': 'half page',
        'minReps': 30,
        'sabqiDaysBack': 3,
        'manzilPagesPerDay': 1,
        'timeDistribution': {'sabaq': 5, 'sabqi': 120, 'manzil': 15},
      });
      expect(validated['reasoning'], 'Custom reasoning.');
    });
  });

  group('AIPlanValidator.toDailyPlan', () {
    Map<String, dynamic> validatedFull() => AIPlanValidator.validate(
      <String, dynamic>{
        'plan': <String, dynamic>{
          'sabaq': <String, dynamic>{
            'page': 582,
            'lineStart': 1,
            'lineEnd': 4,
            'startVerse': 6,
          },
          'sabqi': <String, dynamic>{
            'pages': [580, 581],
          },
          'manzil': <String, dynamic>{
            'juz': 30,
            'pages': [582, 583],
          },
        },
        'frameworkParams': <String, dynamic>{
          'minReps': 20,
          'timeDistribution': <String, dynamic>{
            'sabaq': 18,
            'sabqi': 7,
            'manzil': 5,
          },
        },
        'reasoning': 'Validated reasoning.',
      },
    );

    test('builds a deterministic plan keyed to the local day of `now`', () {
      final plan = AIPlanValidator.toDailyPlan(
        validated: validatedFull(),
        profile: _profile(),
        now: DateTime(2026, 6, 10, 21, 45),
      );

      expect(plan.id, 'p1_2026-06-10T00:00:00.000');
      expect(plan.date, DateTime(2026, 6, 10));
      expect(plan.sabaqPage, 582);
      expect(plan.sabaqLineStart, 1);
      expect(plan.sabaqLineEnd, 4);
      expect(plan.sabaqStartVerse, 6);
      expect(plan.sabaqTargetMinutes, 18);
      expect(plan.sabaqRepetitionTarget, 20);
      expect(plan.sabqiPages, [580, 581]);
      expect(plan.sabqiTargetMinutes, 7);
      expect(plan.manzilJuz, 30);
      expect(plan.manzilPages, [582, 583]);
      expect(plan.manzilTargetMinutes, 5);
      expect(plan.isAiGenerated, isTrue);
      expect(plan.aiReasoning, 'Validated reasoning.');
    });

    test('explicit reasoning argument overrides the validated one', () {
      final plan = AIPlanValidator.toDailyPlan(
        validated: validatedFull(),
        profile: _profile(),
        reasoning: 'Override.',
        now: DateTime(2026, 6, 10),
      );
      expect(plan.aiReasoning, 'Override.');
    });

    test('empty phases get zero minutes and are auto-skipped via the derived '
        'checks — the *DoneOffline flags are never set at generation', () {
      final validated = AIPlanValidator.validate(<String, dynamic>{
        'plan': <String, dynamic>{
          'sabaq': <String, dynamic>{'page': 1},
        },
      });
      final plan = AIPlanValidator.toDailyPlan(
        validated: validated,
        profile: _profile(),
        now: DateTime(2026, 6, 10),
      );

      expect(plan.sabqiPages, isEmpty);
      expect(plan.manzilPages, isEmpty);
      expect(plan.sabqiTargetMinutes, 0);
      expect(plan.manzilTargetMinutes, 0);
      // Retired generation-time auto-skip (roadmap Phase 1 task 7):
      expect(plan.sabqiDoneOffline, isFalse);
      expect(plan.manzilDoneOffline, isFalse);
      // …replaced by derived emptiness checks:
      expect(plan.isSabqiDone, isTrue);
      expect(plan.isManzilDone, isTrue);
    });
  });
}
