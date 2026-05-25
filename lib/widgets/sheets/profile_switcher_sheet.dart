import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/plan_provider.dart';
import 'package:quran_app/providers/analytics_provider.dart';
import 'package:quran_app/providers/flashcard_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/theme/icon_resolver.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/screens/hifz/assessment_screen.dart';

/// Reusable sheet allowing users to switch between active Hifz profiles or create new ones.
class ProfileSwitcherSheet extends StatelessWidget {
  const ProfileSwitcherSheet({super.key});

  /// Static helper to display the profile switcher sheet.
  static Future<void> show(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    return showModalBottomSheet(
      context: context,
      constraints: const BoxConstraints(maxWidth: 680),
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const ProfileSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<HifzProfileProvider>();
    final theme = context.watch<ThemeProvider>();
    final l = AppLocalizations.of(context)!;
    final profiles = profileProvider.allProfiles;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.homeSwitchProfile,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...profiles.map((p) {
                    final isActive = p.id == profileProvider.activeProfile?.id;
                    return GestureDetector(
                      onTap: () async {
                        if (!isActive) {
                          final planProvider = context.read<PlanProvider>();
                          final analyticsProvider = context.read<AnalyticsProvider>();
                          final flashcardProvider = context.read<FlashcardProvider>();

                          await profileProvider.switchProfile(p.id);
                          planProvider.clearPlan();
                          await planProvider.loadOrGeneratePlan(p);
                          await analyticsProvider.loadAnalytics(p);
                          await flashcardProvider.loadDueCards(p.id);
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? theme.accentColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(theme.radiusLg),
                          border: Border.all(
                            color: isActive
                                ? theme.accentColor.withValues(alpha: 0.3)
                                : theme.dividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              IconResolver.avatarIcons[p.avatarIndex.clamp(0, 7)],
                              size: 24,
                              color: isActive
                                  ? theme.accentColor
                                  : theme.secondaryText,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                p.name,
                                style: TextStyle(
                                  fontFamily: GeistTypography.primaryFontFamily,
                                  fontSize: 15,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: theme.primaryText,
                                ),
                              ),
                            ),
                            if (isActive)
                              Icon(
                                LucideIcons.check,
                                size: 18,
                                color: theme.accentColor,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                  // Add new profile
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AssessmentScreen(),
                        ),
                      ).then((_) {
                        if (context.mounted) {
                          final activeProfile = context.read<HifzProfileProvider>().activeProfile;
                          if (activeProfile != null) {
                            context.read<PlanProvider>().loadOrGeneratePlan(activeProfile);
                            context.read<AnalyticsProvider>().loadAnalytics(activeProfile);
                            context.read<FlashcardProvider>().loadDueCards(activeProfile.id);
                          }
                        }
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(theme.radiusLg),
                        boxShadow: theme.shadowCard,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.plus,
                            size: 16,
                            color: theme.secondaryText,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l.homeCreateProfile,
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
}
