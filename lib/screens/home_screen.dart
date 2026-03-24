import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/analytics_provider.dart';
import 'package:quran_app/providers/flashcard_provider.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/plan_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/hifz/analytics_screen.dart';
import 'package:quran_app/screens/hifz/assessment_screen.dart';
import 'package:quran_app/screens/hifz/progress_detail_screen.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/widgets/hifz/plan_card.dart';
import 'package:quran_app/widgets/hifz/progress_card.dart';
import 'package:quran_app/widgets/hifz/hifz_cta_card.dart';
import 'package:quran_app/widgets/hifz/suggestion_card.dart';
import 'package:quran_app/widgets/hifz/pre_session_sheet.dart';
import 'package:quran_app/widgets/werd_card.dart';
import 'package:quran_app/screens/hifz/session_history_screen.dart';
import 'package:quran_app/services/break_recovery_service.dart';
import 'package:quran_app/services/motivational_messages_service.dart';

/// Dashboard screen — the primary home of the app.
/// Shows either the Hifz plan (if profile exists) or a CTA card.
/// Always shows Werd card and Ayah of the Day.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _ayahText;
  String? _ayahRef;
  bool _ayahLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAyahOfDay();
      _loadPlanIfNeeded();
      _checkMissedDays();
    });
  }

  void _loadPlanIfNeeded() {
    final profile = context.read<HifzProfileProvider>();
    if (profile.hasActiveProfile) {
      context.read<PlanProvider>().loadOrGeneratePlan(profile.activeProfile!);
      // Phase 5: Load analytics when dashboard loads
      context.read<AnalyticsProvider>().loadAnalytics(profile.activeProfile!);
      // Phase 2: Load flashcard due counts for dashboard indicator
      context.read<FlashcardProvider>().loadDueCards(profile.activeProfile!.id);
    }
  }

  Future<void> _checkMissedDays() async {
    final profile = context.read<HifzProfileProvider>();
    if (!profile.hasActiveProfile) return;

    // Use BreakRecoveryService for enhanced detection
    final recoveryService = context.read<BreakRecoveryService>();
    final missedDays = await recoveryService.detectBreak(profile.activeProfile!);

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

  Future<void> _loadAyahOfDay() async {
    try {
      final reading = context.read<QuranReadingProvider>();
      // Use a deterministic "random" page based on the day
      final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
      final pageNum = (dayOfYear % 604) + 1;

      // Load the page (it caches internally)
      await reading.loadPage(pageNum);
      final verses = reading.verses;
      if (verses.isNotEmpty && mounted) {
        final verse = verses[Random(dayOfYear).nextInt(verses.length)];
        // Reconstruct verse text from word objects
        final verseText = verse.words
            .where((w) => w.charTypeName != 'end')
            .map((w) => w.textUthmani)
            .join(' ');
        setState(() {
          _ayahText = verseText;
          _ayahRef = verse.verseKey;
          _ayahLoading = false;
        });
        final lastPage = reading.activePage;
        if (lastPage != pageNum) {
          await reading.loadPage(lastPage);
        }
      } else {
        if (mounted) setState(() => _ayahLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _ayahLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final profile = context.watch<HifzProfileProvider>();
    final plan = context.watch<PlanProvider>();
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Greeting ──
              _buildGreeting(theme, profile, l),
              const SizedBox(height: 24),

              // ── Hifz Section ──
              if (profile.isLoading) ...[
                // Initial load — show skeleton instead of flashing CTA (CE-6)
                _buildLoadingCard(theme),
              ] else if (!profile.hasActiveProfile) ...[
                // No profile — show CTA (only when we're SURE there's no profile)
                HifzCtaCard(
                  theme: theme,
                  onTap: () => _openAssessment(context),
                ),
              ] else if (plan.isLoading && plan.aiProgress != AiProgress.idle) ...[
                // AI is actively generating — show animated progress card
                _buildAiProgressCard(theme, plan.aiProgress),
              ] else if (plan.hasPlan) ...[
                // Plan completed → show extra session CTA (CE-2)
                if (plan.isPlanCompleted) ...[
                  _buildExtraSessionCard(theme, plan, profile),
                  const SizedBox(height: 16),
                ] else ...[
                  // Today's plan card
                  PlanCard(
                    plan: plan.todayPlan!,
                    theme: theme,
                    profile: profile.activeProfile,
                    flashcardsDue: context.watch<FlashcardProvider>().dueCardCount,
                    recipes: plan.todayRecipes,
                    sessionCount: plan.todaySessionCount,
                    onStartSession: () async {
                      await PreSessionSheet.show(context);
                      _loadPlanIfNeeded();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                // Session count for today
                if (plan.todaySessionCount > 0) ...[
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const SessionHistoryScreen()),
                    ),
                    child: _buildSessionCountBadge(
                        theme, plan.todaySessionCount),
                  ),
                  const SizedBox(height: 16),
                ],
                // Progress card — tap to open detail
                FutureBuilder<_ProgressData>(
                  future: _getProgressData(profile.activeProfile!),
                  builder: (context, snapshot) {
                    final data = snapshot.data;
                    final counts = data?.statusCounts ?? {};
                    return ProgressCard(
                      totalPagesDone:
                          counts.values.fold(0, (a, b) => a + b),
                      activeDays: profile.streak.totalActiveDays,
                      statusCounts: counts,
                      theme: theme,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ProgressDetailScreen()),
                        );
                      },
                      lastSession: data?.lastSession,
                      currentJuz: data?.currentJuz,
                      currentJuzProgress: data?.currentJuzProgress,
                      currentJuzTotal: data?.currentJuzTotal,
                      pagesPerWeek: data?.pagesPerWeek,
                    );
                  },
                ),
              ] else if (plan.isLoading) ...[
                // Plan is actively loading
                _buildLoadingCard(theme),
              ] else ...[
                // Plan generation failed or hasn't been triggered — show retry
                _buildPlanRetryCard(theme, profile),
                const SizedBox(height: 16),
                // Still show progress card even without a plan
                FutureBuilder<_ProgressData>(
                  future: _getProgressData(profile.activeProfile!),
                  builder: (context, snapshot) {
                    final data = snapshot.data;
                    final counts = data?.statusCounts ?? {};
                    return ProgressCard(
                      totalPagesDone:
                          counts.values.fold(0, (a, b) => a + b),
                      activeDays: profile.streak.totalActiveDays,
                      statusCounts: counts,
                      theme: theme,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ProgressDetailScreen()),
                        );
                      },
                      lastSession: data?.lastSession,
                      currentJuz: data?.currentJuz,
                      currentJuzProgress: data?.currentJuzProgress,
                      currentJuzTotal: data?.currentJuzTotal,
                      pagesPerWeek: data?.pagesPerWeek,
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),

              // ── Motivational Message (AI integration) ──
              if (profile.hasActiveProfile) _buildMotivationalCard(theme, profile),

              // ── Adaptive Suggestions (Phase 5) ──
              if (profile.hasActiveProfile) _buildSuggestionCards(theme),

              // ── Werd Card ──
              const WerdCard(),
              const SizedBox(height: 20),

              // ── Ayah of the Day ──
              _buildAyahCard(theme, l),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<_ProgressData> _getProgressData(MemoryProfile profile) async {
    final db = context.read<HifzDatabaseService>();
    final counts = await db.getPageStatusCounts(profile.id);
    final lastSession = await db.getLastSession(profile.id);

    // Calculate pages/week from sessions in the last 7 days
    final sessions = await db.getSessionHistory(profile.id, limit: 50);
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekSessions = sessions.where((s) => s.date.isAfter(weekAgo)).toList();
    int weekPages = 0;
    for (final s in weekSessions) {
      if (s.sabaqCompleted && s.sabaqPage != null) weekPages++;
    }
    final pagesPerWeek = weekPages > 0 ? weekPages.toDouble() : null;

    // Determine active juz from current sabaq page
    final plan = context.read<PlanProvider>().todayPlan;
    int? currentJuz;
    int? juzProgress;
    int? juzTotal;
    if (plan != null) {
      currentJuz = _pageToJuz(plan.sabaqPage);
      final juzStart = _juzStartPage(currentJuz);
      final juzEnd = currentJuz < 30 ? _juzStartPage(currentJuz + 1) - 1 : 604;
      juzTotal = juzEnd - juzStart + 1;
      // Count how many pages in this juz are in progress
      juzProgress = 0;
      final allProgress = await db.getAllPageProgress(profile.id);
      for (int p = juzStart; p <= juzEnd; p++) {
        if (allProgress.containsKey(p)) juzProgress = juzProgress! + 1;
      }
    }

    return _ProgressData(
      statusCounts: counts,
      lastSession: lastSession,
      currentJuz: currentJuz,
      currentJuzProgress: juzProgress,
      currentJuzTotal: juzTotal,
      pagesPerWeek: pagesPerWeek,
    );
  }

  static int _juzStartPage(int juz) {
    const starts = [
      0, 1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
      201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
      402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
    ];
    return starts[juz.clamp(1, 30)];
  }

  static int _pageToJuz(int page) {
    const starts = [
      1, 22, 42, 62, 82, 102, 121, 142, 162, 182,
      201, 222, 242, 262, 282, 302, 322, 342, 362, 382,
      402, 422, 442, 462, 482, 502, 522, 542, 562, 582,
    ];
    for (int j = starts.length - 1; j >= 0; j--) {
      if (page >= starts[j]) return j + 1;
    }
    return 1;
  }

  // ── Adaptive Suggestions (Phase 5) ──

  Widget _buildSuggestionCards(ThemeProvider theme) {
    final analytics = context.watch<AnalyticsProvider>();
    if (!analytics.hasSuggestions) {
      // No active suggestions — just show the insights link if data exists
      if (analytics.currentWeek != null) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildInsightsLink(theme),
        );
      }
      return const SizedBox.shrink();
    }

    final suggestions = analytics.activeSuggestions.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in suggestions) ...[
          SuggestionCard(
            suggestion: s,
            theme: theme,
            onAccept: () => analytics.acceptSuggestion(s.id),
            onDismiss: () => analytics.dismissSuggestion(s.id),
            onRemindLater: () => analytics.remindLater(s.id),
          ),
          const SizedBox(height: 12),
        ],
        _buildInsightsLink(theme),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInsightsLink(ThemeProvider theme) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.barChart3, size: 14, color: theme.accentColor),
          const SizedBox(width: 6),
          Text(
            'Weekly Insights →',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Motivational Message Card ──

  Widget _buildMotivationalCard(
      ThemeProvider theme, HifzProfileProvider profileProvider) {
    final profile = profileProvider.activeProfile!;
    final motivational = context.read<MotivationalMessagesService>();
    final msg = motivational.getDashboardMessage(
      profile: profile,
      streak: profileProvider.streak,
      totalPagesMemorized: profileProvider.streak.totalActiveDays,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: theme.accentColor.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Text(msg.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg.text,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.primaryText,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAssessment(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AssessmentScreen()),
    ).then((_) async {
      // Force refresh profile state, then generate plan
      final profileProvider = context.read<HifzProfileProvider>();
      await profileProvider.refresh();
      _loadPlanIfNeeded();
    });
  }

  // ── Extra session CTA (CE-2) ──

  Widget _buildExtraSessionCard(
      ThemeProvider theme, PlanProvider plan, HifzProfileProvider profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Text('🌟', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            'Great work today!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your plan is complete. Want to keep going?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              if (profile.hasActiveProfile) {
                await plan.generateExtraSession(profile.activeProfile!);
                if (mounted) {
                  await PreSessionSheet.show(context);
                  _loadPlanIfNeeded();
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: theme.accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Start Extra Session ▶',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCountBadge(ThemeProvider theme, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.activity, size: 16, color: theme.accentColor),
          const SizedBox(width: 8),
          Text(
            'Today: $count session${count > 1 ? 's' : ''} completed',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(
    ThemeProvider theme,
    HifzProfileProvider profile,
    AppLocalizations l,
  ) {
    final name = profile.hasActiveProfile ? profile.activeProfile!.name : '';
    final greeting = l.t('home_greeting');
    final displayName = name.isNotEmpty ? ', $name' : '';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting$displayName',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.primaryText,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getSubGreeting(profile),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: theme.secondaryText,
                ),
              ),
            ],
          ),
        ),
        if (profile.hasActiveProfile)
          GestureDetector(
            onTap: () => _showProfileSwitcher(context, theme, profile),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: theme.accentColor.withValues(alpha: 0.3)),
              ),
              child: Center(
                child: Text(
                  _HomeScreenState._avatarEmojis[
                      profile.activeProfile!.avatarIndex.clamp(0, 7)],
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static const _avatarEmojis = ['🌙', '⭐', '📖', '🕌', '🌿', '🕋', '💎', '🌸'];

  String _getSubGreeting(HifzProfileProvider profile) {
    if (!profile.hasActiveProfile) {
      return 'Begin your memorization journey today';
    }
    final streak = profile.streak.totalActiveDays;
    if (streak > 0) {
      return '$streak active days — keep it up! 🔥';
    }
    return 'Your journey awaits';
  }

  void _showProfileSwitcher(
    BuildContext context,
    ThemeProvider theme,
    HifzProfileProvider profile,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final profiles = profile.allProfiles;
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
                'Switch Profile',
                style: TextStyle(
                  fontFamily: 'Inter',
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
                final isActive = p.id == profile.activeProfile?.id;
                return GestureDetector(
                  onTap: () async {
                    if (!isActive) {
                      await profile.switchProfile(p.id);
                      if (context.mounted) {
                        final planProvider = context.read<PlanProvider>();
                        planProvider.clearPlan();
                        await planProvider.loadOrGeneratePlan(p);
                      }
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.accentColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? theme.accentColor.withValues(alpha: 0.3)
                            : theme.dividerColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _HomeScreenState._avatarEmojis[
                              p.avatarIndex.clamp(0, 7)],
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.name,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w500,
                              color: theme.primaryText,
                            ),
                          ),
                        ),
                        if (isActive)
                          Icon(LucideIcons.check,
                              size: 18, color: theme.accentColor),
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
                  _openAssessment(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.plus,
                          size: 16, color: theme.secondaryText),
                      const SizedBox(width: 8),
                      Text(
                        'Create New Profile',
                        style: TextStyle(
                          fontFamily: 'Inter',
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

  Widget _buildLoadingCard(ThemeProvider theme) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.accentColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Preparing your plan...',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: theme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Plan retry / fallback card ──
  Widget _buildPlanRetryCard(ThemeProvider theme, HifzProfileProvider profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          const Text('📖', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            'Ready to start, ${profile.activeProfile!.name}?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap below to generate today\'s plan',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _loadPlanIfNeeded(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: theme.accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Generate Plan',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyahCard(ThemeProvider theme, AppLocalizations l) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
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
                l.t('home_ayah_title'),
                style: TextStyle(
                  fontFamily: 'Inter',
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
                l.t('home_loading'),
                style: TextStyle(
                  fontFamily: 'Inter',
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
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: theme.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ] else
            Text(
              l.t('home_ayah_subtitle'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: theme.mutedText,
              ),
            ),
        ],
      ),
    );
  }

  /// Animated AI progress card shown while AI is generating the plan.
  Widget _buildAiProgressCard(ThemeProvider theme, AiProgress progress) {
    final steps = [
      (AiProgress.analyzing, '📊', 'Analyzing your progress'),
      (AiProgress.generating, '✨', 'Generating your plan'),
      (AiProgress.validating, '✅', 'Validating & optimizing'),
    ];

    // Determine which step is active
    int activeIndex;
    switch (progress) {
      case AiProgress.analyzing:
        activeIndex = 0;
        break;
      case AiProgress.generating:
        activeIndex = 1;
        break;
      case AiProgress.validating:
        activeIndex = 2;
        break;
      default:
        activeIndex = 0;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.accentColor.withValues(alpha: 0.15),
            theme.accentColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(theme.accentColor),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AI is preparing your plan',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Step indicators
          ...List.generate(steps.length, (i) {
            final (_, emoji, label) = steps[i];
            final isDone = i < activeIndex;
            final isActive = i == activeIndex;
            final isFuture = i > activeIndex;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  if (isDone)
                    Icon(LucideIcons.checkCircle, size: 18,
                        color: theme.accentColor)
                  else if (isActive) ...[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(theme.accentColor),
                      ),
                    ),
                  ] else
                    Icon(LucideIcons.circle, size: 18,
                        color: theme.dividerColor),
                  const SizedBox(width: 10),
                  Text(emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isFuture
                          ? theme.mutedText
                          : (isDone
                              ? theme.secondaryText
                              : theme.primaryText),
                    ),
                  ),
                ],
              ),
            );
          }),
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
    final emoji = msg?.emoji ?? '🌅';
    final title = msg?.title ?? 'Welcome back!';
    final message = msg?.message ??
        (missedDays <= 3
            ? 'It\'s been $missedDays days. Let\'s ease back in!'
            : 'It\'s been $missedDays days. Every return is a fresh start! 🌱');
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
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
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
              fontFamily: 'Inter',
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
                fontFamily: 'Inter',
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: theme.secondaryText.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: theme.accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Let\'s Go! ✨',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


/// Helper data class for enriched ProgressCard.
class _ProgressData {
  final Map<PageStatus, int> statusCounts;
  final SessionRecord? lastSession;
  final int? currentJuz;
  final int? currentJuzProgress;
  final int? currentJuzTotal;
  final double? pagesPerWeek;

  const _ProgressData({
    required this.statusCounts,
    this.lastSession,
    this.currentJuz,
    this.currentJuzProgress,
    this.currentJuzTotal,
    this.pagesPerWeek,
  });
}
