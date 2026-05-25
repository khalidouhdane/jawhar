import 'package:flutter/material.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/plan_provider.dart';
import 'package:quran_app/providers/analytics_provider.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/widgets/app_header.dart';
import 'package:quran_app/widgets/dashboard/contextual_status.dart';
import 'package:quran_app/widgets/dashboard/flashcard_carousel.dart';
import 'package:quran_app/widgets/dashboard/explore_carousel.dart';
import 'package:quran_app/widgets/dashboard/progress_strip.dart';
import 'package:quran_app/widgets/dashboard/understanding_spotlight.dart';
import 'package:quran_app/widgets/read/continue_reading_card.dart';
import 'package:quran_app/widgets/hifz/plan_card.dart';
import 'package:quran_app/widgets/hifz/suggestion_card.dart';
import 'package:quran_app/providers/theme_provider.dart';

class ProfileDashboard extends StatelessWidget {
  final VoidCallback onAvatarTap;
  final VoidCallback onStartSession;
  final VoidCallback onProgressStripTap;
  final MemoryProfile profile;

  const ProfileDashboard({
    super.key,
    required this.onAvatarTap,
    required this.onStartSession,
    required this.onProgressStripTap,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final planProvider = context.watch<PlanProvider>();
    final plan = planProvider.todayPlan;
    final theme = context.watch<ThemeProvider>();

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        context.read<HifzDatabaseService>().getPageStatusCounts(profile.id),
        context.read<HifzDatabaseService>().getStreak(profile.id),
        context.read<HifzDatabaseService>().getSessionHistory(profile.id),
      ]),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final counts = (data?[0] as Map<PageStatus, int>?) ?? {};
        final streakData = (data?[1] as StreakData?) ?? const StreakData();
        final sessions = (data?[2] as List<SessionRecord>?) ?? [];

        final memorizedCount = (counts[PageStatus.memorized] ?? 0) +
            (counts[PageStatus.learning] ?? 0) +
            (counts[PageStatus.reviewing] ?? 0);
        final streakDays = streakData.totalActiveDays;
        final sessionCount = sessions.length;

        final hasProgress = streakDays > 0 || memorizedCount > 0 || sessionCount > 0;

        final progressStrip = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ProgressStrip(
            memorizedPages: memorizedCount,
            streakDays: streakDays,
            sessionCount: sessionCount,
            onTap: onProgressStripTap,
          ),
        );

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 16,
                ),
                child: AppHeader(onAvatarTap: onAvatarTap),
              ),
            ),

            // 1. Contextual Status
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ContextualStatus(),
            ),

            // 2. Plan Card / Rest Day / Loading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  if (planProvider.isLoading) ...[
                    _buildPlanLoadingSkeleton(theme),
                    const SizedBox(height: 16),
                  ] else if (planProvider.isRestDay) ...[
                    _buildRestDayCard(context, theme, onStartSession),
                    const SizedBox(height: 16),
                  ] else if (plan != null) ...[
                    PlanCard(
                      plan: plan,
                      theme: theme,
                      onStartSession: onStartSession,
                      profile: profile,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),

            // 3. Redesigned Progress Strip dynamically placed at top if user has progress
            if (hasProgress) ...[
              progressStrip,
              const SizedBox(height: 16),
            ],

            // 4. Continue Reading
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ContinueReadingCard(),
            ),
            const SizedBox(height: 20),

            // 5. Flashcard Carousel (edge-to-edge scrolling)
            const FlashcardCarousel(),
            const SizedBox(height: 20),

            // 6. Explore Stories & Themes (edge-to-edge scrolling)
            const ExploreCarousel(),
            const SizedBox(height: 20),

            // 7. Progress Strip at bottom if user does not have progress
            if (!hasProgress) ...[
              progressStrip,
              const SizedBox(height: 24),
            ],

            // 8. Understanding Spotlight (Only if plan has sabaq)
            if (plan != null && plan.sabaqPage > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: UnderstandingSpotlight(sabaqPage: plan.sabaqPage),
              ),
              const SizedBox(height: 16),
            ],

            // 9. Suggestions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSuggestions(context),
            ),

            const SizedBox(height: 48), // Bottom padding
          ],
        );
      },
    );
  }

  Widget _buildSuggestions(BuildContext context) {
    return Consumer<AnalyticsProvider>(
      builder: (context, analytics, child) {
        final suggestions = analytics.activeSuggestions;
        if (suggestions.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SuggestionCard(
                  suggestion: s,
                  theme: Provider.of<ThemeProvider>(context, listen: false),
                  onAccept: () => analytics.acceptSuggestion(s.id),
                  onDismiss: () => analytics.dismissSuggestion(s.id),
                  onRemindLater: () => analytics.remindLater(s.id),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRestDayCard(BuildContext context, ThemeProvider theme, VoidCallback onStartSession) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusXl),
        border: Border.all(color: theme.dividerColor),
        boxShadow: theme.shadowCard,
      ),
      child: Column(
        children: [
          Icon(LucideIcons.moonStar, size: 32, color: theme.mutedText),
          const SizedBox(height: 12),
          Text(
            l10n.homeRestDayTitle,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.homeRestDaySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: theme.mutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _RestDayAction(
                  icon: LucideIcons.bookOpen,
                  label: l10n.homeRestDayContinueReading,
                  theme: theme,
                  onTap: () {
                    final nav = Provider.of<NavigationProvider>(
                      context,
                      listen: false,
                    );
                    final localStorage = Provider.of<LocalStorageService>(
                      context,
                      listen: false,
                    );
                    final lastRead = localStorage.getLastRead();
                    final page = lastRead?.page ?? 1;
                    nav.enterReadingView();
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (_) => ReadingScreen(initialPage: page),
                          ),
                        )
                        .then((_) => nav.exitReadingView());
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RestDayAction(
                  icon: LucideIcons.play,
                  label: l10n.homeRestDayStartAnyway,
                  theme: theme,
                  onTap: onStartSession,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanLoadingSkeleton(ThemeProvider theme) {
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusXl),
        border: Border.all(color: theme.dividerColor),
        boxShadow: theme.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: theme.pillBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: theme.pillBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 160,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.pillBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: theme.pillBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 14,
                    decoration: BoxDecoration(
                      color: theme.pillBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 140,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.pillBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: theme.pillBackground,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestDayAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeProvider theme;
  final VoidCallback onTap;

  const _RestDayAction({
    required this.icon,
    required this.label,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.pillBackground,
      borderRadius: BorderRadius.circular(theme.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(theme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 18, color: theme.primaryText),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

