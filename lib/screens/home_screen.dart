import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/analytics_provider.dart';
import 'package:quran_app/providers/flashcard_provider.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/plan_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/services/break_recovery_service.dart';
import 'package:quran_app/theme/icon_resolver.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/widgets/geist_button.dart';
import 'package:quran_app/widgets/dashboard/no_profile_dashboard.dart';
import 'package:quran_app/widgets/dashboard/profile_dashboard.dart';
import 'package:quran_app/screens/hifz/assessment_screen.dart';
import 'package:quran_app/widgets/hifz/pre_session_sheet.dart';
import 'package:quran_app/screens/hifz/progress_detail_screen.dart';

/// Dashboard screen — the primary home of the app.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _ayahText;
  String? _ayahRef;
  bool _ayahLoading = true;
  String? _lastLoadedProfileId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAyahOfDay();
      _checkMissedDays();
    });
  }

  void _loadPlanIfNeeded() {
    final profile = context.read<HifzProfileProvider>();
    if (profile.hasActiveProfile) {
      context.read<PlanProvider>().loadOrGeneratePlan(profile.activeProfile!);
      context.read<AnalyticsProvider>().loadAnalytics(profile.activeProfile!);
      context.read<FlashcardProvider>().loadDueCards(profile.activeProfile!.id);
    }
  }

  Future<void> _checkMissedDays() async {
    final profile = context.read<HifzProfileProvider>();
    if (!profile.hasActiveProfile) return;

    final recoveryService = context.read<BreakRecoveryService>();
    final missedDays = await recoveryService.detectBreak(
      profile.activeProfile!,
    );

    if (missedDays > 0 && mounted) {
      final theme = context.read<ThemeProvider>();
      final recoveryMsg = recoveryService.getRecoveryMessage(missedDays);
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _MissedDaySheet(
            missedDays: missedDays,
            theme: theme,
            recoveryMessage: recoveryMsg,
          ),
        );
      }
    }
  }

  void _loadAyahOfDay() {
    final reading = context.read<QuranReadingProvider>();
    final dayOfYear = DateTime.now()
        .difference(DateTime(DateTime.now().year, 1, 1))
        .inDays;
    final pageNum = (dayOfYear % 604) + 1;
    final verses = reading.getPageVerses(pageNum);

    if (verses.isNotEmpty) {
      final middleIndex = verses.length ~/ 2;
      final verse = verses[middleIndex];
      setState(() {
        _ayahText = verse.words.map((w) => w.textUthmani).join(' ');
        _ayahRef = verse.verseKey;
        _ayahLoading = false;
      });
    } else {
      setState(() => _ayahLoading = false);
    }
  }

  void _showProfileSwitcher() {
    final profileProvider = context.read<HifzProfileProvider>();
    final theme = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final profiles = profileProvider.allProfiles;
        return Padding(
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
                AppLocalizations.of(context)!.homeSwitchProfile,
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
                        final isActive =
                            p.id == profileProvider.activeProfile?.id;
                        return GestureDetector(
                          onTap: () async {
                            if (!isActive) {
                              final planProvider = context.read<PlanProvider>();
                              await profileProvider.switchProfile(p.id);
                              planProvider.clearPlan();
                              await planProvider.loadOrGeneratePlan(p);
                            }
                            if (ctx.mounted) Navigator.of(ctx).pop();
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
                              borderRadius: BorderRadius.circular(
                                theme.radiusLg,
                              ),
                              border: Border.all(
                                color: isActive
                                    ? theme.accentColor.withValues(alpha: 0.3)
                                    : theme.dividerColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  IconResolver.avatarIcons[p.avatarIndex.clamp(
                                    0,
                                    7,
                                  )],
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
                                      fontFamily:
                                          GeistTypography.primaryFontFamily,
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
                          Navigator.of(ctx).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AssessmentScreen(),
                            ),
                          ).then((_) {
                            if (context.mounted) _loadPlanIfNeeded();
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
                                AppLocalizations.of(context)!.homeCreateProfile,
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
        );
      },
    );
  }

  void _navigateToAssessment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AssessmentScreen()),
    ).then((_) {
      if (context.mounted) _loadPlanIfNeeded();
    });
  }

  void _navigateToSession() {
    final planProvider = context.read<PlanProvider>();
    if (planProvider.todayPlan != null) {
      PreSessionSheet.show(context);
    } else if (planProvider.isRestDay) {
      // Force-generate a plan on rest day ("Start Anyway")
      final profile = context.read<HifzProfileProvider>().activeProfile;
      if (profile != null) {
        planProvider.loadOrGeneratePlan(profile, forceRegenerate: true).then((
          _,
        ) {
          if (mounted && planProvider.todayPlan != null) {
            PreSessionSheet.show(context);
          }
        });
      }
    }
  }

  void _navigateToProgressDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProgressDetailScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: Consumer<HifzProfileProvider>(
        builder: (context, profileProvider, _) {
          if (profileProvider.isLoading) {
            return Container(color: theme.scaffoldBackground);
          }

          if (!profileProvider.hasActiveProfile) {
            _lastLoadedProfileId = null;
            return NoProfileDashboard(
              onAvatarTap: _showProfileSwitcher,
              onStartJourney: _navigateToAssessment,
              ayahCard: _buildAyahCard(theme),
            );
          }

          final activeId = profileProvider.activeProfile!.id;
          if (_lastLoadedProfileId != activeId) {
            _lastLoadedProfileId = activeId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _loadPlanIfNeeded();
            });
          }

          return ProfileDashboard(
            onAvatarTap: _showProfileSwitcher,
            onStartSession: _navigateToSession,
            onProgressStripTap: _navigateToProgressDetail,
            profile: profileProvider.activeProfile!,
          );
        },
      ),
    );
  }

  Widget _buildAyahCard(ThemeProvider theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkle, size: 16, color: theme.accentColor),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.homeAyahTitle,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_ayahLoading)
            Center(
              child: Text(
                AppLocalizations.of(context)!.homeLoading,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 13,
                  color: theme.mutedText,
                ),
              ),
            )
          else if (_ayahText != null) ...[
            Text(
              _ayahText!,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                color: theme.primaryText,
                height: 2.0,
              ),
            ),
            if (_ayahRef != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '— ${_ayahRef!}',
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 11,
                    color: theme.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ] else
            Text(
              AppLocalizations.of(context)!.homeAyahSubtitle,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 13,
                color: theme.mutedText,
              ),
            ),
        ],
      ),
    );
  }
}

/// Missed-day bottom sheet with recovery message support.
class _MissedDaySheet extends StatelessWidget {
  final int missedDays;
  final ThemeProvider theme;
  final RecoveryMessage? recoveryMessage;

  const _MissedDaySheet({
    required this.missedDays,
    required this.theme,
    this.recoveryMessage,
  });

  @override
  Widget build(BuildContext context) {
    final msg = recoveryMessage;
    final iconKey = msg?.emoji ?? 'sunrise';
    final title = msg?.title ?? AppLocalizations.of(context)!.homeWelcomeBack;
    final message =
        msg?.message ??
        (missedDays <= 3
            ? 'It\'s been $missedDays days. Let\'s ease back in!'
            : 'It\'s been $missedDays days. Every return is a fresh start!');
    final encouragement = msg?.encouragement;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            IconResolver.resolve(iconKey),
            size: 48,
            color: theme.accentColor,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
          if (encouragement != null) ...[
            const SizedBox(height: 8),
            Text(
              encouragement,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: theme.secondaryText.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GeistButton(
              onPressed: () => Navigator.of(context).pop(),
              label: AppLocalizations.of(context)!.homeLetsGo,
              type: GeistButtonType.primary,
              size: GeistButtonSize.large,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
