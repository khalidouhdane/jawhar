import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/session_recipe_models.dart';
import 'package:quran_app/providers/session_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/theme/semantic_colors.dart';
import 'package:quran_app/theme/geist_typography.dart';

/// Displays the current recipe step with progress, instructions,
/// rep counter, and navigation controls.
///
/// Replaces the simple rep counter in the active session view
/// when guided mode is enabled.
class RecipeGuideWidget extends StatelessWidget {
  const RecipeGuideWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final session = context.watch<SessionProvider>();
    final recipe = session.currentRecipe;
    final step = session.currentStep;

    if (recipe == null || recipe.isEmpty || step == null) {
      return _buildNoRecipe(context, theme, session);
    }

    final totalSteps = recipe.steps.length;
    final currentIndex = session.currentStepIndex;
    final isComplete = session.isStepComplete;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Step progress dots ──
        _buildStepDots(theme, session, totalSteps, currentIndex),
        const SizedBox(height: 16),

        // ── Step card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isComplete
                  ? SemanticColors.practiceEmerald
                        .fg(theme.isDark)
                        .withValues(alpha: 0.4)
                  : theme.dividerColor,
              width: isComplete ? 1.5 : 1,
            ),
            boxShadow: isComplete
                ? [
                    BoxShadow(
                      color: SemanticColors.practiceEmerald
                          .fg(theme.isDark)
                          .withValues(alpha: 0.08),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              // Step header
              Row(
                children: [
                  // Action icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        _getIconData(step.icon),
                        size: 20,
                        color: theme.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.recipeStepOf(currentIndex + 1, totalSteps),
                          style: TextStyle(
                            fontFamily: GeistTypography.primaryFontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.mutedText,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getActionLabel(context, step.action),
                          style: TextStyle(
                            fontFamily: GeistTypography.primaryFontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: theme.primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Completion badge
                  if (isComplete)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: SemanticColors.practiceEmerald
                            .fg(theme.isDark)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.recipeDoneBadge,
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: SemanticColors.practiceEmerald.fg(
                            theme.isDark,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Instruction text
              Text(
                _getInstructionLabel(context, step.instruction),
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 14,
                  color: theme.secondaryText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Rep/time progress bar
              _buildProgressIndicator(context, theme, session, step),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Step navigation ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous step
            if (currentIndex > 0)
              _navButton(
                theme,
                LucideIcons.chevronLeft,
                AppLocalizations.of(context)!.recipeBtnPrev,
                () => session.previousStep(),
              )
            else
              const SizedBox(width: 80),

            const SizedBox(width: 16),

            // Rep counter button
            GestureDetector(
              onTap: () => session.countRep(),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: isComplete
                      ? SemanticColors.practiceEmerald.fg(theme.isDark)
                      : theme.accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isComplete
                                  ? SemanticColors.practiceEmerald.fg(
                                      theme.isDark,
                                    )
                                  : theme.accentColor)
                              .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isComplete ? LucideIcons.check : LucideIcons.plus,
                  size: 24,
                  color: isComplete ? theme.scaffoldBackground : theme.scaffoldBackground,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Next step / Skip
            if (currentIndex < totalSteps - 1)
              _navButton(
                theme,
                LucideIcons.chevronRight,
                isComplete
                    ? AppLocalizations.of(context)!.recipeBtnNext
                    : AppLocalizations.of(context)!.recipeBtnSkip,
                () => session.nextStep(),
              )
            else
              _navButton(
                theme,
                LucideIcons.checkCircle,
                AppLocalizations.of(context)!.recipeBtnFinish,
                () => session.finishPhase(),
              ),
          ],
        ),

        // Tips
        if (recipe.tips.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: SemanticColors.practiceBlue.bg(theme.isDark),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.lightbulb,
                  size: 16,
                  color: SemanticColors.practiceBlue.fg(theme.isDark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getTipLabel(
                      context,
                      recipe.tips[currentIndex % recipe.tips.length],
                    ),
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 12,
                      color: theme.secondaryText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepDots(
    ThemeProvider theme,
    SessionProvider session,
    int totalSteps,
    int currentIndex,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (i) {
        final isActive = i == currentIndex;
        final isDone = i < currentIndex;
        return Container(
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isDone
                ? SemanticColors.practiceEmerald.fg(theme.isDark)
                : isActive
                ? theme.accentColor
                : theme.dividerColor,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    ThemeProvider theme,
    SessionProvider session,
    RecipeStep step,
  ) {
    final progress = (session.stepRepCount / step.target).clamp(0.0, 1.0);

    return Column(
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.dividerColor,
            valueColor: AlwaysStoppedAnimation(
              progress >= 1.0
                  ? SemanticColors.practiceEmerald.fg(theme.isDark)
                  : theme.accentColor,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        // Count label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              step.unit == StepUnit.minutes
                  ? AppLocalizations.of(
                      context,
                    )!.recipeMin(session.stepRepCount)
                  : AppLocalizations.of(
                      context,
                    )!.recipeTimes(session.stepRepCount),
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: progress >= 1.0
                    ? SemanticColors.practiceEmerald.fg(theme.isDark)
                    : theme.accentColor,
              ),
            ),
            Text(
              step.unit == StepUnit.minutes
                  ? AppLocalizations.of(
                      context,
                    )!.recipeTargetMinLabel(step.target)
                  : AppLocalizations.of(
                      context,
                    )!.recipeTargetTimesLabel(step.target),
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 12,
                color: theme.mutedText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoRecipe(
    BuildContext context,
    ThemeProvider theme,
    SessionProvider session,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.recipeFreeModeTitle,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.recipeFreeModeDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 13,
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(
    ThemeProvider theme,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor),
            ),
            child: Icon(icon, size: 18, color: theme.primaryText),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  String _getActionLabel(BuildContext context, RecipeAction action) {
    final loc = AppLocalizations.of(context)!;
    switch (action) {
      case RecipeAction.listen:
        return loc.recipeActionListen;
      case RecipeAction.readAlong:
        return loc.recipeActionReadAlong;
      case RecipeAction.readSolo:
        return loc.recipeActionReadSolo;
      case RecipeAction.reciteMemory:
        return loc.recipeActionReciteMemory;
      case RecipeAction.linkPractice:
        return loc.recipeActionLinkPractice;
      case RecipeAction.write:
        return loc.recipeActionWrite;
      case RecipeAction.reviewMeaning:
        return loc.recipeActionReviewMeaning;
      case RecipeAction.selfTest:
        return loc.recipeActionSelfTest;
    }
  }

  String _getInstructionLabel(BuildContext context, String instruction) {
    final loc = AppLocalizations.of(context)!;
    if (instruction.contains('Listen to the page being recited')) {
      return loc.recipeInstListen;
    }
    if (instruction.contains('Read along with the audio')) {
      return loc.recipeInstReadAlong;
    }
    if (instruction.contains('Read on your own without audio')) {
      return loc.recipeInstReadSolo;
    }
    if (instruction.contains('Close the mushaf and recite from memory')) {
      if (instruction.contains('Check and correct.')) {
        return loc.recipeInstSabqiSelfTest;
      }
      return loc.recipeInstReciteMemory;
    }
    if (instruction.contains('Read through the review pages')) {
      return loc.recipeInstSabqiReadSolo;
    }
    if (instruction.contains('Read through the manzil pages')) {
      return loc.recipeInstManzilReadSolo;
    }
    if (instruction.contains('Use the mushaf only to check')) {
      return loc.recipeInstManzilSelfTest;
    }
    return instruction;
  }

  String _getTipLabel(BuildContext context, String tip) {
    final loc = AppLocalizations.of(context)!;
    if (tip.contains('Focus on 2-3 lines')) {
      return loc.recipeTipFocusLines;
    }
    if (tip.contains('Record yourself')) {
      return loc.recipeTipRecord;
    }
    if (tip.contains('Review the meaning')) {
      return loc.recipeTipMeaning;
    }
    if (tip.contains("Don't skip pages")) {
      return loc.recipeTipMaintenance;
    }
    if (tip.contains('If a page feels weak')) {
      return loc.recipeTipWeakPage;
    }
    if (tip.contains('Manzil keeps your long-term')) {
      return loc.recipeTipManzilLongTerm;
    }
    if (tip.contains('Consistency matters')) {
      return loc.recipeTipConsistency;
    }
    return tip;
  }

  IconData _getIconData(String iconName) {
    return switch (iconName) {
      'headphones' => LucideIcons.headphones,
      'book_open' => LucideIcons.bookOpen,
      'brain' => LucideIcons.brain,
      'link' => LucideIcons.link,
      'pen_tool' => LucideIcons.penTool,
      'search' => LucideIcons.search,
      'check_circle' => LucideIcons.checkCircle,
      'eye_off' => LucideIcons.eyeOff,
      _ => LucideIcons.bookOpen,
    };
  }
}
