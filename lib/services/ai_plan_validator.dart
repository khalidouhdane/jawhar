import 'package:quran_app/models/hifz_models.dart';

/// Exception thrown when AI response validation fails.
class AIValidationException implements Exception {
  final String message;
  final Map<String, dynamic>? rawResponse;

  const AIValidationException(this.message, {this.rawResponse});

  @override
  String toString() => 'AIValidationException: $message';
}

/// Validates and transforms raw AI-generated JSON into safe, usable plan data.
///
/// Safety rails enforced:
/// - Page range: 1–604
/// - Line range: 1–15
/// - Max reps per step: 20
/// - Max steps per recipe: 8
/// - Min estimated minutes per phase: 5
/// - Max sabaq load: 15 lines
class AIPlanValidator {
  /// Validate raw AI response and extract a validated plan map.
  ///
  /// Returns a validated map with clamped values. Throws
  /// [AIValidationException] if the response is structurally invalid.
  static Map<String, dynamic> validate(Map<String, dynamic> raw) {
    try {
      final plan = _validatePlan(raw['plan'] as Map<String, dynamic>?);
      final recipes = _validateRecipes(raw['recipes'] as Map<String, dynamic>?);
      final reasoning = _validateReasoning(raw['reasoning']);
      final frameworkParams = _validateFrameworkParams(
        raw['frameworkParams'] as Map<String, dynamic>?,
      );

      return {
        'plan': plan,
        'recipes': recipes,
        'reasoning': reasoning,
        'frameworkParams': frameworkParams,
      };
    } catch (e) {
      if (e is AIValidationException) rethrow;
      throw AIValidationException(
        'Failed to validate AI response: $e',
        rawResponse: raw,
      );
    }
  }

  // ── Plan Validation ──

  static Map<String, dynamic> _validatePlan(Map<String, dynamic>? plan) {
    if (plan == null) {
      throw const AIValidationException('Missing "plan" in AI response');
    }

    final sabaq = _validateSabaq(plan['sabaq'] as Map<String, dynamic>?);
    final sabqi = _validateSabqi(plan['sabqi'] as Map<String, dynamic>?);
    final manzil = _validateManzil(plan['manzil'] as Map<String, dynamic>?);

    return {
      'sabaq': sabaq,
      'sabqi': sabqi,
      'manzil': manzil,
    };
  }

  static Map<String, dynamic> _validateSabaq(Map<String, dynamic>? sabaq) {
    if (sabaq == null) {
      throw const AIValidationException('Missing "plan.sabaq" in AI response');
    }

    final page = _clampPage(_toInt(sabaq['page']));
    final lineStart = _clampLine(_toInt(sabaq['lineStart'], fallback: 1));
    var lineEnd = _clampLine(_toInt(sabaq['lineEnd'], fallback: 15));
    if (lineEnd < lineStart) lineEnd = lineStart;

    return {
      'page': page,
      'lineStart': lineStart,
      'lineEnd': lineEnd,
      'startVerse': sabaq['startVerse'],
    };
  }

  static Map<String, dynamic> _validateSabqi(Map<String, dynamic>? sabqi) {
    if (sabqi == null) {
      return {'pages': <int>[]};
    }

    final rawPages = sabqi['pages'];
    final pages = <int>[];
    if (rawPages is List) {
      for (final p in rawPages) {
        final page = _toInt(p, fallback: -1);
        if (page >= 1 && page <= 604) {
          pages.add(page);
        }
      }
    }

    return {'pages': pages};
  }

  static Map<String, dynamic> _validateManzil(Map<String, dynamic>? manzil) {
    if (manzil == null) {
      return {'juz': 0, 'pages': <int>[]};
    }

    final juz = _toInt(manzil['juz'], fallback: 0).clamp(0, 30);
    final rawPages = manzil['pages'];
    final pages = <int>[];
    if (rawPages is List) {
      for (final p in rawPages) {
        final page = _toInt(p, fallback: -1);
        if (page >= 1 && page <= 604) {
          pages.add(page);
        }
      }
    }

    return {'juz': juz, 'pages': pages};
  }

  // ── Recipe Validation ──

  static Map<String, dynamic> _validateRecipes(Map<String, dynamic>? recipes) {
    if (recipes == null) {
      return {
        'sabaq': _emptyRecipe(),
        'sabqi': _emptyRecipe(),
        'manzil': _emptyRecipe(),
      };
    }

    return {
      'sabaq': _validateRecipe(recipes['sabaq'] as Map<String, dynamic>?, 'sabaq'),
      'sabqi': _validateRecipe(recipes['sabqi'] as Map<String, dynamic>?, 'sabqi'),
      'manzil': _validateRecipe(recipes['manzil'] as Map<String, dynamic>?, 'manzil'),
    };
  }

  static Map<String, dynamic> _validateRecipe(
    Map<String, dynamic>? recipe,
    String phase,
  ) {
    if (recipe == null) return _emptyRecipe();

    final rawSteps = recipe['steps'];
    final steps = <Map<String, dynamic>>[];

    if (rawSteps is List) {
      for (var i = 0; i < rawSteps.length && i < 8; i++) {
        // Max 8 steps
        final step = rawSteps[i];
        if (step is Map<String, dynamic>) {
          steps.add(_validateStep(step, i + 1));
        }
      }
    }

    final estimatedMinutes = _toInt(recipe['estimatedMinutes'], fallback: 10).clamp(5, 120);

    final rawTips = recipe['tips'];
    final tips = <String>[];
    if (rawTips is List) {
      for (final t in rawTips) {
        if (t is String && t.isNotEmpty) {
          tips.add(t);
        }
      }
    }

    return {
      'steps': steps,
      'estimatedMinutes': estimatedMinutes,
      'tips': tips,
    };
  }

  static Map<String, dynamic> _validateStep(Map<String, dynamic> step, int index) {
    final action = _validateAction(step['action']?.toString() ?? 'read_solo');
    final instruction = step['instruction']?.toString() ?? 'Continue with this step.';
    final target = _toInt(step['target'], fallback: 1).clamp(1, 20); // Max 20 reps
    final unit = _validateUnit(step['unit']?.toString() ?? 'times');
    final icon = step['icon']?.toString() ?? '📖';

    return {
      'stepNumber': index,
      'action': action,
      'instruction': instruction,
      'target': target,
      'unit': unit,
      'icon': icon,
    };
  }

  // ── Framework Params Validation ──

  static Map<String, dynamic> _validateFrameworkParams(Map<String, dynamic>? params) {
    if (params == null) {
      return {
        'dailySabaqLoad': 'unknown',
        'minReps': 10,
        'sabqiDaysBack': 7,
        'manzilPagesPerDay': 4,
        'timeDistribution': {'sabaq': 45, 'sabqi': 30, 'manzil': 25},
      };
    }

    return {
      'dailySabaqLoad': params['dailySabaqLoad']?.toString() ?? 'unknown',
      'minReps': _toInt(params['minReps'], fallback: 10).clamp(1, 30),
      'sabqiDaysBack': _toInt(params['sabqiDaysBack'], fallback: 7).clamp(3, 30),
      'manzilPagesPerDay': _toInt(params['manzilPagesPerDay'], fallback: 4).clamp(1, 20),
      'timeDistribution': _validateTimeDistribution(
        params['timeDistribution'] as Map<String, dynamic>?,
      ),
    };
  }

  static Map<String, dynamic> _validateTimeDistribution(Map<String, dynamic>? dist) {
    if (dist == null) {
      return {'sabaq': 45, 'sabqi': 30, 'manzil': 25};
    }
    return {
      'sabaq': _toInt(dist['sabaq'], fallback: 45).clamp(5, 120),
      'sabqi': _toInt(dist['sabqi'], fallback: 30).clamp(0, 120),
      'manzil': _toInt(dist['manzil'], fallback: 25).clamp(0, 120),
    };
  }

  // ── Reasoning Validation ──

  static String _validateReasoning(dynamic reasoning) {
    if (reasoning is String && reasoning.isNotEmpty) {
      return reasoning;
    }
    return 'Plan generated successfully.';
  }

  // ── Conversion: Validated AI response → DailyPlan ──

  /// Convert a validated AI response into a [DailyPlan].
  ///
  /// This bridges the AI output with the existing plan infrastructure.
  static DailyPlan toDailyPlan({
    required Map<String, dynamic> validated,
    required MemoryProfile profile,
    String? reasoning,
  }) {
    final plan = validated['plan'] as Map<String, dynamic>;
    final sabaq = plan['sabaq'] as Map<String, dynamic>;
    final sabqi = plan['sabqi'] as Map<String, dynamic>;
    final manzil = plan['manzil'] as Map<String, dynamic>;
    final frameworkParams = validated['frameworkParams'] as Map<String, dynamic>;
    final timeDist = frameworkParams['timeDistribution'] as Map<String, dynamic>;

    final sabqiPages = (sabqi['pages'] as List).cast<int>();
    final manzilPages = (manzil['pages'] as List).cast<int>();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final planId = '${profile.id}_${today.toIso8601String()}_ai_${now.millisecondsSinceEpoch}';

    return DailyPlan(
      id: planId,
      profileId: profile.id,
      date: today,
      sabaqPage: sabaq['page'] as int,
      sabaqLineStart: sabaq['lineStart'] as int,
      sabaqLineEnd: sabaq['lineEnd'] as int,
      sabaqStartVerse: sabaq['startVerse'] as int?,
      sabaqTargetMinutes: _toInt(timeDist['sabaq'], fallback: 25),
      sabaqRepetitionTarget: _toInt(frameworkParams['minReps'], fallback: 10),
      sabqiPages: sabqiPages,
      sabqiTargetMinutes: sabqiPages.isEmpty ? 0 : _toInt(timeDist['sabqi'], fallback: 15),
      manzilJuz: manzil['juz'] as int,
      manzilPages: manzilPages,
      manzilTargetMinutes: manzilPages.isEmpty ? 0 : _toInt(timeDist['manzil'], fallback: 10),
      // Auto-skip empty phases
      sabqiDoneOffline: sabqiPages.isEmpty,
      manzilDoneOffline: manzilPages.isEmpty,
      // AI metadata
      isAiGenerated: true,
      aiReasoning: reasoning ?? validated['reasoning'] as String?,
    );
  }

  // ── Helpers ──

  static Map<String, dynamic> _emptyRecipe() => {
        'steps': <Map<String, dynamic>>[],
        'estimatedMinutes': 0,
        'tips': <String>[],
      };

  static const _validActions = {
    'listen', 'read_along', 'read_solo', 'recite_memory',
    'link_practice', 'write', 'review_meaning', 'self_test',
  };

  static String _validateAction(String action) {
    return _validActions.contains(action) ? action : 'read_solo';
  }

  static String _validateUnit(String unit) {
    return (unit == 'times' || unit == 'minutes') ? unit : 'times';
  }

  static int _clampPage(int page) => page.clamp(1, 604);
  static int _clampLine(int line) => line.clamp(1, 15);

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
