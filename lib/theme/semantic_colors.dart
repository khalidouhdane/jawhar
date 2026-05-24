import 'package:flutter/material.dart';

/// Functional colors for content differentiation.
/// These are NOT part of the Geist neutral scale — they are a Jawhar extension.
/// Used only in specific content contexts (practice cards, analytics, milestones).
class SemanticColors {
  SemanticColors._();

  // ── Core Pillar Themes (Consistent with Landing Page / DESIGN.md) ──
  static const pillarRead = SemanticPair(
    lightBg: Color(0xFFEFF6FF), // 5% tint of #0a72ef
    lightFg: Color(0xFF0A72EF), // Develop Blue
    darkBg: Color(0x140A72EF),
    darkFg: Color(0xFF3B82F6),
  );
  static const pillarUnderstand = SemanticPair(
    lightBg: Color(0xFFFDF2F8), // 5% tint of #de1d8d
    lightFg: Color(0xFFDE1D8D), // Preview Pink
    darkBg: Color(0x14DE1D8D),
    darkFg: Color(0xFFF472B6),
  );
  static const pillarMemorize = SemanticPair(
    lightBg: Color(0xFFFFF5F5), // 5% tint of #ff5b4f
    lightFg: Color(0xFFFF5B4F), // Ship Red
    darkBg: Color(0x14FF5B4F),
    darkFg: Color(0xFFFB7185),
  );

  // ── Practice Card Identity (muted, whispered tints) ──
  static const practiceBlue = SemanticPair(
    lightBg: Color(0xFFF0F4FF),
    lightFg: Color(0xFF4B6A9B),
    darkBg: Color(0x143B82F6),
    darkFg: Color(0xFF7DA4D4),
  );
  static const practiceCyan = SemanticPair(
    lightBg: Color(0xFFEFFCFC),
    lightFg: Color(0xFF3D8A8A),
    darkBg: Color(0x1406B6D4),
    darkFg: Color(0xFF6DB5B5),
  );
  static const practiceEmerald = SemanticPair(
    lightBg: Color(0xFFEEFBF4),
    lightFg: Color(0xFF3D7A5F),
    darkBg: Color(0x1410B981),
    darkFg: Color(0xFF6DBF9A),
  );
  static const practicePurple = SemanticPair(
    lightBg: Color(0xFFF3F0FF),
    lightFg: Color(0xFF6B5CA5),
    darkBg: Color(0x148B5CF6),
    darkFg: Color(0xFFA893E0),
  );
  static const practiceAmber = SemanticPair(
    lightBg: Color(0xFFFFF9EB),
    lightFg: Color(0xFF8A6D2B),
    darkBg: Color(0x14F59E0B),
    darkFg: Color(0xFFCDB06A),
  );
  static const practiceRed = SemanticPair(
    lightBg: Color(0xFFFEF1F1),
    lightFg: Color(0xFF9B4B4B),
    darkBg: Color(0x14EF4444),
    darkFg: Color(0xFFD48A8A),
  );

  // ── Hifz Phase Identity ──
  static const phaseSabaq = SemanticPair(
    lightBg: Color(0xFFEFFCFC),
    lightFg: Color(0xFF3D8A8A),
    darkBg: Color(0x144ECDC4),
    darkFg: Color(0xFF6DB5B5),
  );
  static const phaseSabqi = SemanticPair(
    lightBg: Color(0xFFF3F0FF),
    lightFg: Color(0xFF6B5CA5),
    darkBg: Color(0x146C63FF),
    darkFg: Color(0xFFA893E0),
  );
  static const phaseManzil = SemanticPair(
    lightBg: Color(0xFFFFF9EB),
    lightFg: Color(0xFF8A6D2B),
    darkBg: Color(0x14F5A623),
    darkFg: Color(0xFFCDB06A),
  );

  // ── Flashcard Ratings ──
  static const ratingForgot = Color(0xFFB84040);
  static const ratingWeak = Color(0xFFC4882A);
  static const ratingOk = Color(0xFF4B7BBF);
  static const ratingStrong = Color(0xFF3DA06A);

  // ── Progress States ──
  static const progressMemorized = Color(0xFF3DA06A);
  static const progressReviewing = Color(0xFF4B7BBF);
  static const progressLearning = Color(0xFFC4882A);

  // ── Suggestion Types ──
  static const suggPositive = SemanticPair(
    lightBg: Color(0xFFEEFBF4),
    lightFg: Color(0xFF3D7A5F),
    darkBg: Color(0x144DB6AC),
    darkFg: Color(0xFF6DB5B5),
  );
  static const suggGentle = SemanticPair(
    lightBg: Color(0xFFF0F0FF),
    lightFg: Color(0xFF5A5CA5),
    darkBg: Color(0x147986CB),
    darkFg: Color(0xFF9AA4D4),
  );
  static const suggAttention = SemanticPair(
    lightBg: Color(0xFFFFF9EB),
    lightFg: Color(0xFF8A6D2B),
    darkBg: Color(0x14FFB74D),
    darkFg: Color(0xFFCDB06A),
  );
  static const suggInfo = SemanticPair(
    lightBg: Color(0xFFF0F4FF),
    lightFg: Color(0xFF4B6A9B),
    darkBg: Color(0x1490CAF9),
    darkFg: Color(0xFF7DA4D4),
  );

  // ── Milestone Gradients (celebratory content, not UI chrome) ──
  static const milestoneJuz = [Color(0xFF1A454E), Color(0xFF2D7A6F)];
  static const milestoneKhatm = [Color(0xFFB8860B), Color(0xFFDAA520)];
  static const milestoneStreak = [Color(0xFFD84315), Color(0xFFFF6D00)];

  // ── Analytics ──
  static const analyticsSessions = Color(0xFF5AA0A0);
  static const analyticsPages = Color(0xFF6B7BBF);
  static const analyticsCompletion = Color(0xFFCDA04A);
  static const analyticsTime = Color(0xFF7DA4D4);

  // ── Assessment ──
  static const assessStrong = Color(0xFF5AAA6A);
  static const assessOkay = Color(0xFFCDA030);
  static const assessNeedsWork = Color(0xFFBF5050);
}

/// A color pair for light/dark mode semantic usage.
class SemanticPair {
  final Color lightBg, lightFg, darkBg, darkFg;
  const SemanticPair({
    required this.lightBg,
    required this.lightFg,
    required this.darkBg,
    required this.darkFg,
  });

  Color bg(bool isDark) => isDark ? darkBg : lightBg;
  Color fg(bool isDark) => isDark ? darkFg : lightFg;
}
