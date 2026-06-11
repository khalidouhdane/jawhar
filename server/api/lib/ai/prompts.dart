/// Prompt construction for the AI endpoints — ported EXACTLY from the legacy
/// callables in `functions/src/index.ts` (the reference implementation) so
/// the client transport can swap 1:1. Do not "improve" the wording here
/// without a contract decision.
library;

import 'dart:convert';

/// Default system instruction for plan generation
/// (functions/src/index.ts `generateDailyPlan`).
const String defaultPlanSystemInstruction =
    'You are a Quran memorization (Hifz) planning assistant. Generate a '
    'daily plan based on the user\'s profile and progress. Return valid '
    'JSON only.';

/// Default system instruction for weekly calibration
/// (functions/src/index.ts `generateCalibration`).
const String defaultCalibrationSystemInstruction =
    'You are a Quran memorization (Hifz) coach analyzing a student\'s '
    'weekly performance.';

/// `JSON.stringify(context, null, 2)` equivalent — the legacy callables embed
/// the context as 2-space-indented JSON.
String contextToJson(Object? context) =>
    const JsonEncoder.withIndent('  ').convert(context);

/// User message for plan generation. [isRecoveryMode] selects the
/// recovery-mode preamble, byte-for-byte the legacy strings.
String buildPlanUserMessage(String contextJson, {required bool isRecoveryMode}) {
  if (isRecoveryMode) {
    return 'RECOVERY MODE: The user has returned after missed days.\n'
        'Generate a lighter, review-focused plan to ease them back in.\n\n'
        'User Context:\n$contextJson\n\nGenerate the daily plan as JSON.';
  }
  return 'Generate today\'s memorization plan based on this user context:'
      '\n\n$contextJson\n\nGenerate the daily plan as JSON.';
}

/// User message for calibration. The legacy `generateCalibration` reuses the
/// plan wording verbatim (a known copy-paste in functions/src/index.ts) —
/// ported as-is, because "exact port" beats "tidier prompt" until the
/// callables are retired.
String buildCalibrationUserMessage(String contextJson) {
  return 'Generate today\'s memorization plan based on this user context:'
      '\n\n$contextJson\n\nGenerate the daily plan as JSON.';
}
