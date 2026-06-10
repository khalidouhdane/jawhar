import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/plan_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/services/break_recovery_service.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';

class ContextualStatus extends StatelessWidget {
  const ContextualStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final planProvider = context.watch<PlanProvider>();
    final profileProvider = context.watch<HifzProfileProvider>();
    final l = AppLocalizations.of(context)!;

    if (!profileProvider.hasActiveProfile) {
      return const SizedBox.shrink();
    }

    final profile = profileProvider.activeProfile!;

    // Determine the message based on the plan and missed days state
    return FutureBuilder<int>(
      future: context.read<BreakRecoveryService>().detectBreak(profile),
      builder: (context, snapshot) {
        String message = '';

        final missedDays = snapshot.data ?? 0;
        final plan = planProvider.todayPlan;

        if (planProvider.aiProgress != AiProgress.idle &&
            planProvider.aiProgress != AiProgress.done &&
            planProvider.aiProgress != AiProgress.fallback) {
          message = l.homeAiPreparing;
        } else if (plan == null) {
          message = l.homeReadyToStart(profile.name);
        } else if (missedDays > 3) {
          message = l.homeStatusFreshStart;
        } else if (missedDays > 0) {
          message = l.homeStatusWelcomeBack;
        } else if (plan.isCompleted) {
          message = l.homeStatusDoneToday(
            profileProvider.streak.totalActiveDays,
          );
        } else if (plan.sabaqDoneOffline &&
            plan.sabqiDoneOffline &&
            plan.manzilDoneOffline) {
          message = l.homeStatusReady;
        } else {
          // Normal state: Page X awaits · ~Y min
          final pageInfo = plan.sabaqPage > 0
              ? l.homeStatusPageAwaits(plan.sabaqPage)
              : l.homeStatusSessionReady;
          message = l.homeStatusEstimate(pageInfo, plan.estimatedMinutes);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            message,
            style: theme.textCaption.copyWith(color: theme.secondaryText),
          ),
        );
      },
    );
  }
}
