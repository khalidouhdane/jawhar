import 'package:quran_app/l10n/app_localizations.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/session_provider.dart';
import 'package:quran_app/providers/plan_provider.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/flashcard_provider.dart';
import 'package:quran_app/providers/notification_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/screens/hifz/flashcard_review_screen.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/services/plan_generation_service.dart';
import 'package:quran_app/models/session_recipe_models.dart';
import 'package:quran_app/widgets/hifz/session_reading_view.dart';
import 'package:quran_app/widgets/hifz/recipe_guide_widget.dart';
import 'package:quran_app/widgets/sheets/session_settings_sheet.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/widgets/geist_button.dart';
import 'package:quran_app/utils/app_logger.dart';

/// Full-screen Hifz session experience.
/// Phases: Pre-session → Active session → Self-assessment → Complete.
class SessionScreen extends StatefulWidget {
  final DailyPlan plan;

  const SessionScreen({super.key, required this.plan});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  bool _isDigitalMode = false; // Phase 4: physical ↔ digital toggle
  int _coverageEndPage = 0; // for "more than planned" picker
  int _lastVerseLearned = 5; // CE-9: verse picker default
  int _totalVersesOnPage = 15; // CE-9: default (typical Quran page)
  // Timer management
  Timer? _timer;

  void _showSessionSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SessionSettingsSheet(),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<SessionProvider>();
      session.startSession(widget.plan);
      // Initialize countdown from the first active phase's allocated minutes
      // (not total — each phase gets its own countdown)
      final firstPhaseMinutes = widget.plan.sabaqTargetMinutes > 0
          ? widget.plan.sabaqTargetMinutes
          : widget.plan.estimatedMinutes;
      if (firstPhaseMinutes > 0) {
        session.setTargetTime(firstPhaseMinutes);
      }
      _coverageEndPage = widget.plan.sabaqPage;
      _startTimer();
      _loadRecipes();
    });
  }

  Future<void> _loadRecipes() async {
    final session = context.read<SessionProvider>();
    List<SessionRecipe> recipes = [];

    // Layer 1: Try loading from database
    try {
      final db = context.read<HifzDatabaseService>();
      recipes = await db.getRecipesForPlan(widget.plan.id);
    } catch (e) {
      AppLogger.info('SessionUI', 'Recipe DB load failed: $e');
    }

    if (!mounted) return;

    // Layer 2: Try PlanProvider's in-memory recipes
    if (recipes.isEmpty) {
      try {
        final planProvider = context.read<PlanProvider>();
        recipes = planProvider.todayRecipes;
      } catch (_) {}
    }

    // Layer 3: Generate defaults inline as last resort
    if (recipes.isEmpty) {
      recipes = PlanGenerationService.generateDefaultRecipes(widget.plan);
    }

    if (recipes.isNotEmpty && mounted) {
      session.loadRecipes(recipes);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        context.read<SessionProvider>().tick();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final session = context.watch<SessionProvider>();

    // CE-7.1: Stop timer when session is complete
    if (session.isSessionComplete) {
      _timer?.cancel();
      _timer = null;
    }

    final body = session.isSessionComplete
        ? _buildCompleteView(theme, session)
        : session.showingCoverageDialog
        ? _buildCoverageView(theme, session)
        : session.showingAssessment
        ? _buildAssessmentView(theme, session)
        : _isDigitalMode
        ? _buildDigitalView(theme, session)
        : _buildActiveView(theme, session);

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: _isDigitalMode
            ? body
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: body,
                ),
              ),
      ),
    );
  }

  // ════════════════════════════════
  // ACTIVE SESSION VIEW (Physical Quran Mode)
  // ════════════════════════════════

  Widget _buildActiveView(ThemeProvider theme, SessionProvider session) {
    final l10n = AppLocalizations.of(context)!;
    final isCountdown = session.targetSeconds > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // ── Top bar: close + phase badge + pause/digital ──
          Row(
            children: [
              GeistButton.icon(
                onPressed: () => _exitSession(context, session),
                icon: Icon(LucideIcons.x, size: 18, color: theme.primaryText),
                type: GeistButtonType.secondary,
              ),
              const Spacer(),
              // Phase indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      session.currentPhaseIcon,
                      size: 14,
                      color: theme.accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_getPhaseLabel(context, session.currentPhase)} · ${session.currentStepNumber}/${session.activePhaseCount}',
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Settings button
              GestureDetector(
                onTap: () => _showSessionSettings(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Icon(
                    LucideIcons.sliders,
                    size: 18,
                    color: theme.primaryText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Pause button
              GestureDetector(
                onTap: () => session.togglePause(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: session.isPaused
                        ? theme.accentColor.withValues(alpha: 0.15)
                        : theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: session.isPaused
                          ? theme.accentColor.withValues(alpha: 0.4)
                          : theme.dividerColor,
                    ),
                  ),
                  child: Icon(
                    session.isPaused ? LucideIcons.play : LucideIcons.pause,
                    size: 18,
                    color: session.isPaused
                        ? theme.accentColor
                        : theme.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Phase detail text ──
          Text(
            _phaseDetailText(session),
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 13,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 16),

          // ── BIG countdown timer ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isCountdown)
                GeistButton.icon(
                  onPressed: () => session.adjustTime(-1),
                  icon: Icon(
                    LucideIcons.minus,
                    size: 14,
                    color: theme.primaryText,
                  ),
                  type: GeistButtonType.secondary,
                ),
              if (isCountdown) const SizedBox(width: 24),
              Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: session.elapsedSecondsListenable,
                    builder: (context, elapsedSeconds, child) {
                      final isOvertime =
                          session.targetSeconds > 0 &&
                          elapsedSeconds > session.targetSeconds;
                      final displaySeconds = session.targetSeconds > 0
                          ? (isOvertime
                                ? elapsedSeconds - session.targetSeconds
                                : session.targetSeconds - elapsedSeconds)
                          : elapsedSeconds;
                      return Text(
                        '${isOvertime ? '+' : ''}'
                        '${_formatTime(displaySeconds)}',
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 56,
                          fontWeight: FontWeight.w200,
                          color: isOvertime
                              ? const Color(0xFFF59E0B)
                              : theme.primaryText,
                          letterSpacing: 2,
                        ),
                      );
                    },
                  ),
                  if (session.isPaused)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.sessionPaused,
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                          color: theme.accentColor,
                        ),
                      ),
                    ),
                ],
              ),
              if (isCountdown) const SizedBox(width: 24),
              if (isCountdown)
                GeistButton.icon(
                  onPressed: () => session.adjustTime(1),
                  icon: Icon(
                    LucideIcons.plus,
                    size: 14,
                    color: theme.primaryText,
                  ),
                  type: GeistButtonType.secondary,
                ),
            ],
          ),

          if (isCountdown)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${(session.targetSeconds / 60).ceil()} min',
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.mutedText,
                ),
              ),
            ),
          const SizedBox(height: 16),

          // ── Guided recipe view OR Free-mode rep counter ──
          Expanded(
            child: session.isGuidedMode && session.hasRecipes
                ? const SingleChildScrollView(child: RecipeGuideWidget())
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Rep counter with target
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Reps: ',
                              style: TextStyle(
                                fontFamily: GeistTypography.primaryFontFamily,
                                fontSize: 14,
                                color: theme.secondaryText,
                              ),
                            ),
                            Text(
                              '${session.repCount}',
                              style: TextStyle(
                                fontFamily: GeistTypography.primaryFontFamily,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: theme.accentColor,
                              ),
                            ),
                            if (session.currentPhase == SessionPhase.sabaq &&
                                session.plan != null)
                              Text(
                                ' / ${session.plan!.sabaqRepetitionTarget}',
                                style: TextStyle(
                                  fontFamily: GeistTypography.primaryFontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: theme.mutedText,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _controlButton(
                            theme,
                            icon: LucideIcons.skipForward,
                            label: AppLocalizations.of(context)!.sessionSkip,
                            onTap: () => session.skipPhase(),
                          ),
                          GeistButton.icon(
                            onPressed: () => session.countRep(),
                            icon: const Icon(LucideIcons.plus, size: 28),
                            type: GeistButtonType.primary,
                            size: GeistButtonSize.large,
                          ),
                          _controlButton(
                            theme,
                            icon: LucideIcons.check,
                            label: AppLocalizations.of(context)!.sessionDone,
                            onTap: () => session.finishPhase(),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          // ── Open Digital Quran Button ──
          SizedBox(
            width: double.infinity,
            child: GeistButton(
              onPressed: () => setState(() => _isDigitalMode = true),
              label: AppLocalizations.of(context)!.sessionOpenDigitalQuran,
              prefix: const Icon(
                LucideIcons.bookOpen,
                size: 18,
                color: Colors.white,
              ),
              type: GeistButtonType.primary,
              size: GeistButtonSize.large,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════
  // DIGITAL SESSION VIEW (Phase 4)
  // ════════════════════════════════

  Widget _buildDigitalView(ThemeProvider theme, SessionProvider session) {
    // Determine which page to show based on current phase
    final pageNumber = session.currentPhase == SessionPhase.sabaq
        ? (session.plan?.sabaqPage ?? 1)
        : session.currentPhase == SessionPhase.sabqi
        ? (session.plan?.sabqiPages.isNotEmpty == true
              ? session.plan!.sabqiPages.first
              : 1)
        : session.currentPhase == SessionPhase.manzil
        ? (session.plan?.manzilPages.isNotEmpty == true
              ? session.plan!.manzilPages.first
              : 1)
        : 1;

    return SessionReadingView(
      pageNumber: pageNumber,
      showOverlay: true,
      session: session,
      onRepTap: () => session.countRep(),
      onDone: () => session.finishPhase(),
      onSkip: () => session.skipPhase(),
      onTogglePause: () => session.togglePause(),
      onMinimize: () => setState(() => _isDigitalMode = false),
      onExit: () => _exitSession(context, session),
    );
  }

  String _phaseDetailText(SessionProvider session) {
    switch (session.currentPhase) {
      case SessionPhase.sabaq:
        final plan = session.plan;
        final lineInfo = plan?.sabaqStartVerse != null
            ? AppLocalizations.of(
                context,
              )!.sessionFromVerse(plan!.sabaqStartVerse!)
            : AppLocalizations.of(context)!.planPageLines(
                plan?.sabaqPage ?? 0,
                plan?.sabaqLineStart ?? 1,
                plan?.sabaqLineEnd ?? 15,
              );
        return AppLocalizations.of(
          context,
        )!.sessionPageAndInfo(plan?.sabaqPage.toString() ?? "?", lineInfo);
      case SessionPhase.sabqi:
        return AppLocalizations.of(
          context,
        )!.sessionPagesToReview(session.plan?.sabqiPages.length ?? 0);
      case SessionPhase.manzil:
        return AppLocalizations.of(context)!.sessionJuzAndPages(
          session.plan?.manzilJuz.toString() ?? "?",
          session.plan?.manzilPages.length ?? 0,
        );
      case SessionPhase.flashcards:
        return AppLocalizations.of(context)!.sessionReviewCards;
    }
  }

  Widget _controlButton(
    ThemeProvider theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GeistButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20, color: theme.primaryText),
          type: GeistButtonType.secondary,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 11,
            color: theme.mutedText,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════
  // SELF-ASSESSMENT VIEW
  // ════════════════════════════════

  Widget _buildAssessmentView(ThemeProvider theme, SessionProvider session) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.sessionHowDidItGo,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.sessionRatePerformance(
                _getPhaseLabel(context, session.currentPhase).toLowerCase(),
              ),
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 14,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 32),
            _assessmentOption(
              theme,
              LucideIcons.dumbbell,
              AppLocalizations.of(context)!.sessionAssessmentStrong,
              AppLocalizations.of(context)!.sessionAssessmentStrongDesc,
              () => session.submitAssessment(SelfAssessment.strong),
            ),
            const SizedBox(height: 12),
            _assessmentOption(
              theme,
              LucideIcons.helpCircle,
              AppLocalizations.of(context)!.sessionAssessmentOkay,
              AppLocalizations.of(context)!.sessionAssessmentOkayDesc,
              () => session.submitAssessment(SelfAssessment.okay),
            ),
            const SizedBox(height: 12),
            _assessmentOption(
              theme,
              LucideIcons.alertCircle,
              AppLocalizations.of(context)!.sessionAssessmentNeedsWork,
              AppLocalizations.of(context)!.sessionAssessmentNeedsWorkDesc,
              () => session.submitAssessment(SelfAssessment.needsWork),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════
  // COVERAGE DIALOG (CE-3)
  // ════════════════════════════════

  Widget _buildCoverageView(ThemeProvider theme, SessionProvider session) {
    final sabaqPage = session.plan?.sabaqPage ?? 1;

    final plan = session.plan;
    final lineInfo = plan?.sabaqStartVerse != null
        ? 'from verse ${plan!.sabaqStartVerse}'
        : AppLocalizations.of(context)!.planPageLines(
            plan?.sabaqPage ?? 0,
            plan?.sabaqLineStart ?? 1,
            plan?.sabaqLineEnd ?? 15,
          );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppLocalizations.of(context)!.coverageHowMuch,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(
                context,
              )!.coveragePlanned(sabaqPage.toString(), lineInfo),
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 14,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 32),

            // Option 1: Full page (all planned lines)
            _coverageOption(
              theme,
              LucideIcons.checkCircle2,
              AppLocalizations.of(context)!.coverageAllLines,
              AppLocalizations.of(
                context,
              )!.coverageAllLinesDesc(sabaqPage.toString(), lineInfo),
              () => session.setActualCoverage([sabaqPage]),
            ),
            const SizedBox(height: 12),

            // Option 2: Partial page (CE-9 with verse picker)
            _coverageOption(
              theme,
              LucideIcons.fileText,
              AppLocalizations.of(context)!.coveragePartOfPage,
              AppLocalizations.of(context)!.coveragePartOfPageDesc,
              () => _showVerseRangePicker(theme, session, sabaqPage),
            ),
            const SizedBox(height: 12),

            // Option 3: More than planned
            _coverageOption(
              theme,
              LucideIcons.library,
              AppLocalizations.of(context)!.coverageMoreThanPlanned,
              AppLocalizations.of(context)!.coverageMoreThanPlannedDesc,
              () => _showPageRangePicker(theme, session, sabaqPage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverageOption(
    ThemeProvider theme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: theme.accentColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPageRangePicker(
    ThemeProvider theme,
    SessionProvider session,
    int sabaqPage,
  ) {
    _coverageEndPage = sabaqPage + 1; // Default to one extra page

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final pageCount = _coverageEndPage - sabaqPage + 1;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.coveragePagesCovered,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.coveragePageXtoY(sabaqPage, _coverageEndPage, pageCount),
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 13,
                      color: theme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: _coverageEndPage.toDouble(),
                    min: sabaqPage.toDouble(),
                    max: (sabaqPage + 10).toDouble().clamp(1, 604),
                    divisions: 10,
                    activeColor: theme.accentColor,
                    label: AppLocalizations.of(
                      context,
                    )!.coveragePageX(_coverageEndPage),
                    onChanged: (v) => setSheetState(
                      () => _coverageEndPage = v.round().clamp(1, 604),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: GeistButton(
                      onPressed: () {
                        final pages = List.generate(
                          _coverageEndPage - sabaqPage + 1,
                          (i) => sabaqPage + i,
                        );
                        Navigator.of(ctx).pop();
                        session.setActualCoverage(pages);
                      },
                      label: AppLocalizations.of(
                        context,
                      )!.coverageConfirmPages(pageCount),
                      type: GeistButtonType.primary,
                      size: GeistButtonSize.large,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // CE-9: Verse-level partial page picker — auto-detects verse count from local data
  void _showVerseRangePicker(
    ThemeProvider theme,
    SessionProvider session,
    int sabaqPage,
  ) {
    // Get actual verse count from local data (instant)
    final quranProvider = context.read<QuranReadingProvider>();
    final verses = quranProvider.getPageVerses(sabaqPage);
    _totalVersesOnPage = verses.length;

    // If carry-over from previous session, start from that verse
    final startVerse = session.plan?.sabaqStartVerse ?? 1;
    _lastVerseLearned = startVerse; // Default to the starting verse

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(
                      context,
                    )!.coverageVersesCoveredOnPage(sabaqPage),
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    startVerse > 1
                        ? AppLocalizations.of(
                            context,
                          )!.coverageVersesOnPageStartFrom(
                            _totalVersesOnPage,
                            startVerse,
                          )
                        : AppLocalizations.of(
                            context,
                          )!.coverageVersesOnPage(_totalVersesOnPage),
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Last verse learned — single slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.sessionLastVerseLearned,
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 13,
                          color: theme.secondaryText,
                        ),
                      ),
                      Text(
                        '${AppLocalizations.of(context)!.readingVerse} $_lastVerseLearned',
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.accentColor,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _lastVerseLearned.toDouble(),
                    min: startVerse.toDouble(),
                    max: _totalVersesOnPage.toDouble(),
                    divisions: (_totalVersesOnPage - startVerse).clamp(1, 100),
                    activeColor: theme.accentColor,
                    label: AppLocalizations.of(
                      context,
                    )!.coverageVerseX(_lastVerseLearned),
                    onChanged: (v) =>
                        setSheetState(() => _lastVerseLearned = v.round()),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastVerseLearned >= _totalVersesOnPage
                        ? AppLocalizations.of(context)!.coverageFullPageCovered
                        : AppLocalizations.of(
                            context,
                          )!.coverageNextTimeStartsFromVerse(
                            _lastVerseLearned + 1,
                          ),
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: GeistButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (_lastVerseLearned >= _totalVersesOnPage) {
                          // Full page — no verse tracking needed
                          session.setActualCoverage([sabaqPage]);
                        } else {
                          // Partial page — save verse progress
                          session.setActualCoverage(
                            [sabaqPage],
                            lastVerseLearned: _lastVerseLearned,
                            totalVersesOnPage: _totalVersesOnPage,
                          );
                        }
                      },
                      label: startVerse > 1
                          ? AppLocalizations.of(
                              context,
                            )!.coverageConfirmVersesXtoY(
                              startVerse,
                              _lastVerseLearned,
                            )
                          : AppLocalizations.of(
                              context,
                            )!.coverageConfirmVerseXtoY(_lastVerseLearned),
                      type: GeistButtonType.primary,
                      size: GeistButtonSize.large,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _assessmentOption(
    ThemeProvider theme,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: theme.accentColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════
  // SESSION COMPLETE VIEW
  // ════════════════════════════════

  Widget _buildCompleteView(ThemeProvider theme, SessionProvider session) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.partyPopper, size: 64, color: theme.accentColor),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.completeSessionComplete,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getCompletionMessage(),
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 14,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 32),

            // Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: session.elapsedSecondsListenable,
                    builder: (context, elapsedSeconds, child) => _summaryRow(
                      theme,
                      LucideIcons.clock,
                      AppLocalizations.of(context)!.completeTimeSpent,
                      _formatTime(elapsedSeconds),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _summaryRow(
                    theme,
                    LucideIcons.rotateCcw,
                    AppLocalizations.of(context)!.completeTotalReps,
                    '${session.totalRepCount}',
                  ),
                  if (session.sabaqAssessment != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _summaryRow(
                        theme,
                        LucideIcons.bookOpen,
                        AppLocalizations.of(context)!.planPhaseSabaq,
                        _assessmentLabel(session.sabaqAssessment!),
                      ),
                    ),
                  if (session.sabqiAssessment != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _summaryRow(
                        theme,
                        LucideIcons.repeat,
                        AppLocalizations.of(context)!.planPhaseSabqi,
                        _assessmentLabel(session.sabqiAssessment!),
                      ),
                    ),
                  if (session.manzilAssessment != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _summaryRow(
                        theme,
                        LucideIcons.library,
                        AppLocalizations.of(context)!.planPhaseManzil,
                        _assessmentLabel(session.manzilAssessment!),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tomorrow's preview
            FutureBuilder<String?>(
              future: _getTomorrowPreview(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.accentColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.sunrise,
                          size: 20,
                          color: theme.accentColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.completeTomorrowsPreview,
                                style: TextStyle(
                                  fontFamily: GeistTypography.primaryFontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.accentColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                snapshot.data!,
                                style: TextStyle(
                                  fontFamily: GeistTypography.primaryFontFamily,
                                  fontSize: 12,
                                  color: theme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Practice Flashcards CTA (Phase 2)
            Builder(
              builder: (_) {
                final fc = context.read<FlashcardProvider>();
                final due = fc.dueCardCount;
                if (due <= 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: GeistButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FlashcardReviewScreen(),
                          ),
                        );
                      },
                      label: AppLocalizations.of(
                        context,
                      )!.completePracticeFlashcards(due),
                      prefix: Icon(
                        LucideIcons.layers,
                        size: 16,
                        color: theme.primaryText,
                      ),
                      type: GeistButtonType.secondary,
                      size: GeistButtonSize.large,
                    ),
                  ),
                );
              },
            ),

            // Back to Dashboard
            SizedBox(
              width: double.infinity,
              child: GeistButton(
                onPressed: () async {
                  await session.completeSession();
                  // Phase 1.9: Smart-skip today's notification
                  if (mounted) {
                    context.read<NotificationProvider>().onSessionCompleted();
                  }
                  // Mark the CURRENT plan as completed first,
                  // then regenerate so the next session picks up
                  // the advanced page/line range.
                  if (mounted) {
                    final profile = context.read<HifzProfileProvider>();
                    final planProvider = context.read<PlanProvider>();
                    await planProvider.completePlan();
                    if (profile.activeProfile != null) {
                      await planProvider.regeneratePlan(profile.activeProfile!);
                    }
                    await profile.refresh();
                    if (mounted) Navigator.of(context).pop();
                  }
                },
                label: AppLocalizations.of(context)!.completeBackToDashboard,
                type: GeistButtonType.primary,
                size: GeistButtonSize.large,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(
    ThemeProvider theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.accentColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
      ],
    );
  }

  String _assessmentLabel(SelfAssessment a) {
    switch (a) {
      case SelfAssessment.strong:
        return AppLocalizations.of(context)!.sessionAssessmentStrong;
      case SelfAssessment.okay:
        return AppLocalizations.of(context)!.sessionAssessmentOkay;
      case SelfAssessment.needsWork:
        return AppLocalizations.of(context)!.sessionAssessmentNeedsWork;
    }
  }

  // ── Helpers ──

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _exitSession(BuildContext context, SessionProvider session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.sessionExitTitle),
        content: Text(AppLocalizations.of(context)!.sessionExitDesc),
        actions: [
          GeistButton(
            onPressed: () => Navigator.of(ctx).pop(),
            label: AppLocalizations.of(context)!.actionContinue,
            type: GeistButtonType.tertiary,
            size: GeistButtonSize.small,
          ),
          GeistButton(
            onPressed: () {
              session.clearSession();
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            label: AppLocalizations.of(context)!.actionExit,
            type: GeistButtonType.error,
            size: GeistButtonSize.small,
          ),
        ],
      ),
    );
  }

  Future<String?> _getTomorrowPreview() async {
    try {
      final planProvider = context.read<PlanProvider>();
      final plan = planProvider.todayPlan;
      if (plan == null) return null;
      // The plan was already regenerated after completeSession,
      // so todayPlan now has the next page
      final nextPage = plan.sabaqPage + 1;
      if (nextPage > 604) return AppLocalizations.of(context)!.khatmCongrats;
      return AppLocalizations.of(context)!.tomorrowPreview(nextPage);
    } catch (_) {
      return null;
    }
  }

  /// Get a personalized session completion message.
  String _getCompletionMessage() {
    try {
      final session = context.read<SessionProvider>();
      final minutes = session.elapsedSeconds ~/ 60;
      final reps = session.totalRepCount;

      // Time-based encouragement
      if (minutes >= 30) {
        return 'Masha\'Allah! $minutes minutes of focused memorization. Your dedication is inspiring!';
      }
      if (minutes >= 15) {
        return AppLocalizations.of(context)!.feedbackTime(minutes);
      }

      // Assessment-based
      final sabaq = session.sabaqAssessment;
      if (sabaq == SelfAssessment.strong) {
        return AppLocalizations.of(context)!.feedbackSabaqStrong;
      }
      if (sabaq == SelfAssessment.needsWork) {
        return AppLocalizations.of(context)!.feedbackSabaqNeedsWork;
      }

      // Rep-based
      if (reps >= 20) {
        return AppLocalizations.of(context)!.feedbackRepetition(reps);
      }

      return AppLocalizations.of(context)!.feedbackFallback;
    } catch (_) {
      return AppLocalizations.of(context)!.feedbackFallbackShort;
    }
  }

  String _getPhaseLabel(BuildContext context, SessionPhase phase) {
    switch (phase) {
      case SessionPhase.sabaq:
        return AppLocalizations.of(context)!.phaseSabaq;
      case SessionPhase.sabqi:
        return AppLocalizations.of(context)!.phaseSabqi;
      case SessionPhase.manzil:
        return AppLocalizations.of(context)!.phaseManzil;
      case SessionPhase.flashcards:
        return AppLocalizations.of(context)!.phaseFlashcards;
    }
  }
}
