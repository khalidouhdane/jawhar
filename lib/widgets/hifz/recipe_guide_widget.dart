import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/session_recipe_models.dart';
import 'package:quran_app/providers/session_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

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
      return _buildNoRecipe(theme, session);
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
                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                  : theme.dividerColor,
              width: isComplete ? 1.5 : 1,
            ),
            boxShadow: isComplete
                ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.08), blurRadius: 12)]
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
                      child: Text(step.icon, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Step ${currentIndex + 1} of $totalSteps',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.mutedText,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          step.action.label,
                          style: TextStyle(
                            fontFamily: 'Inter',
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '✓ Done',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Instruction text
              Text(
                step.instruction,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: theme.secondaryText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Rep/time progress bar
              _buildProgressIndicator(theme, session, step),
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
              _navButton(theme, LucideIcons.chevronLeft, 'Prev', () => session.previousStep())
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
                  color: isComplete ? const Color(0xFF10B981) : theme.accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isComplete ? const Color(0xFF10B981) : theme.accentColor)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isComplete ? LucideIcons.check : LucideIcons.plus,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Next step / Skip
            if (currentIndex < totalSteps - 1)
              _navButton(
                theme,
                LucideIcons.chevronRight,
                isComplete ? 'Next' : 'Skip',
                () => session.nextStep(),
              )
            else
              _navButton(
                theme,
                LucideIcons.checkCircle,
                'Finish',
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
              color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recipe.tips[currentIndex % recipe.tips.length],
                    style: TextStyle(
                      fontFamily: 'Inter',
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
    ThemeProvider theme, SessionProvider session, int totalSteps, int currentIndex,
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
                ? const Color(0xFF10B981)
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
    ThemeProvider theme, SessionProvider session, RecipeStep step,
  ) {
    final progress = (session.stepRepCount / step.target).clamp(0.0, 1.0);
    final unitLabel = step.unit == StepUnit.minutes ? 'min' : '×';

    return Column(
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: theme.dividerColor,
            valueColor: AlwaysStoppedAnimation(
              progress >= 1.0 ? const Color(0xFF10B981) : theme.accentColor,
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
              '${session.stepRepCount} $unitLabel',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: progress >= 1.0 ? const Color(0xFF10B981) : theme.accentColor,
              ),
            ),
            Text(
              '${step.target} $unitLabel target',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: theme.mutedText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoRecipe(ThemeProvider theme, SessionProvider session) {
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
            'Free Mode',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No recipe available for this phase. Use the + button to count your reps.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(ThemeProvider theme, IconData icon, String label, VoidCallback onTap) {
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
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
