import 'dart:convert';

/// Actions that a recipe step can instruct the user to perform.
enum RecipeAction {
  listen,
  readAlong,
  readSolo,
  reciteMemory,
  linkPractice,
  write,
  reviewMeaning,
  selfTest;

  /// Convert from snake_case JSON string to enum.
  static RecipeAction fromJson(String value) {
    return switch (value) {
      'listen' => RecipeAction.listen,
      'read_along' => RecipeAction.readAlong,
      'read_solo' => RecipeAction.readSolo,
      'recite_memory' => RecipeAction.reciteMemory,
      'link_practice' => RecipeAction.linkPractice,
      'write' => RecipeAction.write,
      'review_meaning' => RecipeAction.reviewMeaning,
      'self_test' => RecipeAction.selfTest,
      _ => RecipeAction.readSolo,
    };
  }

  /// Convert to snake_case JSON string.
  String toJson() {
    return switch (this) {
      RecipeAction.listen => 'listen',
      RecipeAction.readAlong => 'read_along',
      RecipeAction.readSolo => 'read_solo',
      RecipeAction.reciteMemory => 'recite_memory',
      RecipeAction.linkPractice => 'link_practice',
      RecipeAction.write => 'write',
      RecipeAction.reviewMeaning => 'review_meaning',
      RecipeAction.selfTest => 'self_test',
    };
  }

  /// Human-readable label for UI display.
  String get label {
    return switch (this) {
      RecipeAction.listen => 'Listen',
      RecipeAction.readAlong => 'Read Along',
      RecipeAction.readSolo => 'Read Solo',
      RecipeAction.reciteMemory => 'Recite from Memory',
      RecipeAction.linkPractice => 'Link Practice',
      RecipeAction.write => 'Write',
      RecipeAction.reviewMeaning => 'Review Meaning',
      RecipeAction.selfTest => 'Self Test',
    };
  }
}

/// The unit for a recipe step's target (repetitions or duration).
enum StepUnit {
  times,
  minutes;

  static StepUnit fromJson(String value) {
    return value == 'minutes' ? StepUnit.minutes : StepUnit.times;
  }

  String toJson() => name;
}

/// A single step in a session recipe.
///
/// Each step has an action to perform, an instruction text,
/// a target count (reps or minutes), and an icon.
class RecipeStep {
  final int stepNumber;
  final RecipeAction action;
  final String instruction;
  final int target;
  final StepUnit unit;
  final String icon;

  const RecipeStep({
    required this.stepNumber,
    required this.action,
    required this.instruction,
    required this.target,
    this.unit = StepUnit.times,
    this.icon = '📖',
  });

  Map<String, dynamic> toMap() => {
    'stepNumber': stepNumber,
    'action': action.toJson(),
    'instruction': instruction,
    'target': target,
    'unit': unit.toJson(),
    'icon': icon,
  };

  factory RecipeStep.fromMap(Map<String, dynamic> map) {
    return RecipeStep(
      stepNumber: map['stepNumber'] as int? ?? 1,
      action: RecipeAction.fromJson(map['action'] as String? ?? 'read_solo'),
      instruction: map['instruction'] as String? ?? '',
      target: map['target'] as int? ?? 1,
      unit: StepUnit.fromJson(map['unit'] as String? ?? 'times'),
      icon: map['icon'] as String? ?? '📖',
    );
  }
}

/// A session recipe for one phase (sabaq, sabqi, or manzil).
///
/// Contains the step-by-step instructions, estimated time, and tips.
class SessionRecipe {
  final String id;
  final String planId; // Links to DailyPlan.id
  final String phase; // 'sabaq', 'sabqi', or 'manzil'
  final List<RecipeStep> steps;
  final int estimatedMinutes;
  final List<String> tips;

  const SessionRecipe({
    required this.id,
    required this.planId,
    required this.phase,
    this.steps = const [],
    this.estimatedMinutes = 0,
    this.tips = const [],
  });

  /// Whether this recipe has any content.
  bool get isEmpty => steps.isEmpty;
  bool get isNotEmpty => steps.isNotEmpty;

  /// Total target reps across all steps (for 'times' unit only).
  int get totalTargetReps => steps
      .where((s) => s.unit == StepUnit.times)
      .fold(0, (sum, s) => sum + s.target);

  Map<String, dynamic> toMap() => {
    'id': id,
    'planId': planId,
    'phase': phase,
    'stepsJson': jsonEncode(steps.map((s) => s.toMap()).toList()),
    'estimatedMinutes': estimatedMinutes,
    'tipsJson': jsonEncode(tips),
  };

  factory SessionRecipe.fromMap(Map<String, dynamic> map) {
    final stepsRaw = map['stepsJson'] as String? ?? '[]';
    final tipsRaw = map['tipsJson'] as String? ?? '[]';

    return SessionRecipe(
      id: map['id'] as String,
      planId: map['planId'] as String,
      phase: map['phase'] as String,
      steps: (jsonDecode(stepsRaw) as List)
          .map((s) => RecipeStep.fromMap(s as Map<String, dynamic>))
          .toList(),
      estimatedMinutes: map['estimatedMinutes'] as int? ?? 0,
      tips: (jsonDecode(tipsRaw) as List).cast<String>(),
    );
  }

  /// Create from a validated AI response recipe map.
  factory SessionRecipe.fromAIResponse({
    required String planId,
    required String phase,
    required Map<String, dynamic> recipeMap,
  }) {
    final rawSteps = recipeMap['steps'] as List? ?? [];
    final steps = rawSteps
        .map((s) => RecipeStep.fromMap(s as Map<String, dynamic>))
        .toList();

    final rawTips = recipeMap['tips'] as List? ?? [];
    final tips = rawTips.cast<String>();

    final now = DateTime.now();
    return SessionRecipe(
      id: '${planId}_${phase}_${now.millisecondsSinceEpoch}',
      planId: planId,
      phase: phase,
      steps: steps,
      estimatedMinutes: recipeMap['estimatedMinutes'] as int? ?? 0,
      tips: tips,
    );
  }
}
