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
import 'package:quran_app/screens/hifz/mutashabihat_practice_screen.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/widgets/hifz/session_reading_view.dart';
import 'package:quran/quran.dart' as quran;

/// Full-screen Hifz session experience.
/// Phases: Pre-session → Active session → Self-assessment → Complete.
class SessionScreen extends StatefulWidget {
  final DailyPlan plan;

  const SessionScreen({super.key, required this.plan});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  Timer? _timer;
  bool _isDigitalMode = false; // Phase 4: physical ↔ digital toggle
  int _coverageEndPage = 0; // for "more than planned" picker
  int _lastVerseLearned = 5; // CE-9: verse picker default
  int _totalVersesOnPage = 15; // CE-9: default (typical Quran page)
  bool _hasMutashabihat = false; // Integration trigger: alert banner
  bool _mutBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().startSession(widget.plan);
      _coverageEndPage = widget.plan.sabaqPage;
      _startTimer();
      _checkMutashabihat();
    });
  }

  Future<void> _checkMutashabihat() async {
    try {
      final db = context.read<HifzDatabaseService>();
      // Check if any verse on the sabaq page has mutashabihat
      final page = widget.plan.sabaqPage;
      // Quick check: query groups whose source verse key starts with common surahs on this page
      final all = await db.getAllMutashabihat();
      // Check if any group's source or mut verse is on the current page
      final hasMatch = all.any((g) {
        final srcPage = _verseKeyToPage(g.sourceVerseKey);
        if (srcPage == page) return true;
        return g.similarVerses.any((v) => _verseKeyToPage(v.verseKey) == page);
      });
      if (hasMatch && mounted) {
        setState(() => _hasMutashabihat = true);
      }
    } catch (_) {}
  }

  int _verseKeyToPage(String key) {
    final parts = key.split(':');
    if (parts.length != 2) return 0;
    final surah = int.tryParse(parts[0]);
    final verse = int.tryParse(parts[1]);
    if (surah == null || verse == null) return 0;
    try {
      return quran.getPageNumber(surah, verse);
    } catch (_) {
      return 0;
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: session.isSessionComplete
            ? _buildCompleteView(theme, session)
            : session.showingCoverageDialog
                ? _buildCoverageView(theme, session)
                : session.showingAssessment
                    ? _buildAssessmentView(theme, session)
                    : _isDigitalMode
                        ? _buildDigitalView(theme, session)
                        : _buildActiveView(theme, session),
      ),
    );
  }

  // ════════════════════════════════
  // ACTIVE SESSION VIEW (Physical Quran Mode)
  // ════════════════════════════════

  Widget _buildActiveView(ThemeProvider theme, SessionProvider session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Mutashabihat alert banner (integration trigger)
          if (_hasMutashabihat && !_mutBannerDismissed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This page has similar verses elsewhere',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MutashabihatPracticeScreen(),
                        ),
                      ),
                      child: Text(
                        'Practice',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _mutBannerDismissed = true),
                      child: Icon(LucideIcons.x, size: 14, color: theme.mutedText),
                    ),
                  ],
                ),
              ),
            ),
          // Top bar
          Row(
            children: [
              GestureDetector(
                onTap: () => _exitSession(context, session),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Icon(LucideIcons.x, size: 18, color: theme.primaryText),
                ),
              ),
              const Spacer(),
              // Phase indicator with step number
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(session.currentPhaseEmoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      '${session.currentPhaseLabel} · ${session.currentStepNumber}/${session.activePhaseCount}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Phase 4: Physical ↔ Digital mode toggle
              GestureDetector(
                onTap: () => setState(() => _isDigitalMode = !_isDigitalMode),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isDigitalMode
                        ? theme.accentColor.withValues(alpha: 0.15)
                        : theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isDigitalMode
                          ? theme.accentColor.withValues(alpha: 0.4)
                          : theme.dividerColor,
                    ),
                  ),
                  child: Icon(
                    _isDigitalMode ? LucideIcons.hand : LucideIcons.bookOpen,
                    size: 18,
                    color: _isDigitalMode ? theme.accentColor : theme.primaryText,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),

          // Phase info
          Text(
            session.currentPhaseEmoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 12),
          Text(
            session.currentPhaseLabel,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _phaseDetailText(session),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 32),

          // Timer display
          Text(
            _formatTime(session.elapsedSeconds),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 48,
              fontWeight: FontWeight.w200,
              color: theme.primaryText,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),

          // Rep counter with target
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: theme.secondaryText,
                  ),
                ),
                Text(
                  '${session.repCount}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: theme.accentColor,
                  ),
                ),
                if (session.currentPhase == SessionPhase.sabaq && session.plan != null)
                  Text(
                    ' / ${session.plan!.sabaqRepetitionTarget}',
                    style: TextStyle(
                      fontFamily: 'Inter',
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
              // Skip
              _controlButton(
                theme,
                icon: LucideIcons.skipForward,
                label: 'Skip',
                onTap: () => session.skipPhase(),
              ),
              // Rep counter
              GestureDetector(
                onTap: () => session.countRep(),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.accentColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(LucideIcons.plus, size: 28, color: Colors.white),
                ),
              ),
              // Done
              _controlButton(
                theme,
                icon: LucideIcons.check,
                label: 'Done',
                onTap: () => session.finishPhase(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pause
          GestureDetector(
            onTap: () => session.togglePause(),
            child: Text(
              session.isPaused ? '▶ Resume' : '⏸ Pause',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.mutedText,
              ),
            ),
          ),
          const SizedBox(height: 16),
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

    return Stack(
      children: [
        // Full-screen reading canvas with overlay
        SessionReadingView(
          pageNumber: pageNumber,
          showOverlay: true,
          session: session,
          onRepTap: () => session.countRep(),
          onDone: () => session.finishPhase(),
          onSkip: () => session.skipPhase(),
          onTogglePause: () => session.togglePause(),
        ),
        // Top-left close button + top-right mode toggle
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _exitSession(context, session),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.cardColor.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Icon(LucideIcons.x, size: 16, color: theme.primaryText),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _isDigitalMode = false),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.accentColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(LucideIcons.hand, size: 16, color: theme.accentColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _phaseDetailText(SessionProvider session) {
    switch (session.currentPhase) {
      case SessionPhase.sabaq:
        final plan = session.plan;
        final lineInfo = plan?.sabaqStartVerse != null
            ? 'from verse ${plan!.sabaqStartVerse}'
            : 'Lines ${plan?.sabaqLineStart ?? 1}–${plan?.sabaqLineEnd ?? 15}';
        return 'Page ${plan?.sabaqPage ?? "?"} · $lineInfo';
      case SessionPhase.sabqi:
        return '${session.plan?.sabqiPages.length ?? 0} pages to review';
      case SessionPhase.manzil:
        return 'Juz ${session.plan?.manzilJuz ?? "?"} · ${session.plan?.manzilPages.length ?? 0} pages';
      case SessionPhase.flashcards:
        return 'Review your cards';
    }
  }

  Widget _controlButton(ThemeProvider theme,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: theme.dividerColor),
            ),
            child: Icon(icon, size: 20, color: theme.secondaryText),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: theme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════
  // SELF-ASSESSMENT VIEW
  // ════════════════════════════════

  Widget _buildAssessmentView(ThemeProvider theme, SessionProvider session) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${session.currentPhaseEmoji} How did it go?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rate your ${session.currentPhaseLabel.toLowerCase()} performance',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 32),
          _assessmentOption(theme, '💪', 'Strong',
              'I nailed it — confident',
              () => session.submitAssessment(SelfAssessment.strong)),
          const SizedBox(height: 12),
          _assessmentOption(theme, '🤔', 'Okay',
              'Got through it, some mistakes',
              () => session.submitAssessment(SelfAssessment.okay)),
          const SizedBox(height: 12),
          _assessmentOption(theme, '😬', 'Needs Work',
              'I struggled — need more practice',
              () => session.submitAssessment(SelfAssessment.needsWork)),
        ],
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
        : 'Lines ${plan?.sabaqLineStart ?? 1}–${plan?.sabaqLineEnd ?? 15}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '📖 How much did you cover?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Planned: Page $sabaqPage · $lineInfo',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 32),

          // Option 1: Full page (all planned lines)
          _coverageOption(
            theme,
            '✅',
            'All planned lines',
            'I completed page $sabaqPage ($lineInfo)',
            () => session.setActualCoverage([sabaqPage]),
          ),
          const SizedBox(height: 12),

          // Option 2: Partial page (CE-9 with verse picker)
          _coverageOption(
            theme,
            '📄',
            'Part of the page',
            'I\'ll specify which verses I covered',
            () => _showVerseRangePicker(theme, session, sabaqPage),
          ),
          const SizedBox(height: 12),

          // Option 3: More than planned
          _coverageOption(
            theme,
            '📚',
            'More than planned',
            'I covered extra pages!',
            () => _showPageRangePicker(theme, session, sabaqPage),
          ),
        ],
      ),
    );
  }

  Widget _coverageOption(ThemeProvider theme, String emoji, String title,
      String subtitle, VoidCallback onTap) {
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
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
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
      ThemeProvider theme, SessionProvider session, int sabaqPage) {
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
                    'Pages covered',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Page $sabaqPage to $_coverageEndPage ($pageCount pages)',
                    style: TextStyle(
                      fontFamily: 'Inter',
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
                    label: 'Page $_coverageEndPage',
                    onChanged: (v) => setSheetState(
                        () => _coverageEndPage = v.round().clamp(1, 604)),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      final pages = List.generate(
                        _coverageEndPage - sabaqPage + 1,
                        (i) => sabaqPage + i,
                      );
                      Navigator.of(ctx).pop();
                      session.setActualCoverage(pages);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Confirm — $pageCount page${pageCount > 1 ? 's' : ''}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
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

  // CE-9: Verse-level partial page picker — auto-detects verse count from API
  void _showVerseRangePicker(
      ThemeProvider theme, SessionProvider session, int sabaqPage) async {
    // Fetch actual verse count from API
    final quranProvider = context.read<QuranReadingProvider>();
    try {
      final verses = await quranProvider.getPageVerses(sabaqPage);
      _totalVersesOnPage = verses.length;
    } catch (_) {
      _totalVersesOnPage = 15; // Fallback if API fails
    }

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
                    'Verses covered on Page $sabaqPage',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_totalVersesOnPage verses on this page'
                    '${startVerse > 1 ? ' · starting from verse $startVerse' : ''}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Last verse learned — single slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Last verse I learned:',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: theme.secondaryText)),
                      Text('Verse $_lastVerseLearned',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.accentColor)),
                    ],
                  ),
                  Slider(
                    value: _lastVerseLearned.toDouble(),
                    min: startVerse.toDouble(),
                    max: _totalVersesOnPage.toDouble(),
                    divisions: (_totalVersesOnPage - startVerse).clamp(1, 100),
                    activeColor: theme.accentColor,
                    label: 'Verse $_lastVerseLearned',
                    onChanged: (v) => setSheetState(
                        () => _lastVerseLearned = v.round()),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastVerseLearned >= _totalVersesOnPage
                        ? 'Full page covered ✅'
                        : 'Next time starts from verse ${_lastVerseLearned + 1}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
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
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: theme.accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Confirm — verse${startVerse > 1 ? 's $startVerse' : ' 1'} to $_lastVerseLearned',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
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

  Widget _assessmentOption(ThemeProvider theme, String emoji, String title,
      String subtitle, VoidCallback onTap) {
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
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'Session Complete!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Masha\'Allah! Great work today.',
            style: TextStyle(
              fontFamily: 'Inter',
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
                _summaryRow(theme, '⏱', 'Time spent',
                    _formatTime(session.elapsedSeconds)),
                const SizedBox(height: 12),
                _summaryRow(theme, '🔄', 'Total reps',
                    '${session.totalRepCount}'),
                if (session.sabaqAssessment != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _summaryRow(theme, '📖', 'Sabaq',
                        _assessmentLabel(session.sabaqAssessment!)),
                  ),
                if (session.sabqiAssessment != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _summaryRow(theme, '🔁', 'Sabqi',
                        _assessmentLabel(session.sabqiAssessment!)),
                  ),
                if (session.manzilAssessment != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _summaryRow(theme, '📚', 'Manzil',
                        _assessmentLabel(session.manzilAssessment!)),
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
                    border: Border.all(color: theme.accentColor.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Text('🌅', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tomorrow\'s preview',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.accentColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              snapshot.data!,
                              style: TextStyle(
                                fontFamily: 'Inter',
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
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FlashcardReviewScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🃏', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          'Practice $due Flashcards',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Back to Dashboard
          GestureDetector(
            onTap: () async {
              await session.completeSession();
              // Phase 1.9: Smart-skip today's notification
              if (mounted) {
                context.read<NotificationProvider>().onSessionCompleted();
              }
              // CE-7.2: Mark plan as completed — do NOT regenerate here.
              // The dashboard will show the "Plan Complete" card.
              // A new plan will be generated only if the user taps "Start Extra Session".
              if (mounted) {
                final profile = context.read<HifzProfileProvider>();
                final planProvider = context.read<PlanProvider>();
                await planProvider.completePlan();
                await profile.refresh();
                if (mounted) Navigator.of(context).pop();
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: theme.accentColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: theme.accentColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Back to Dashboard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(ThemeProvider theme, String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
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
      case SelfAssessment.strong: return '💪 Strong';
      case SelfAssessment.okay: return '🤔 Okay';
      case SelfAssessment.needsWork: return '😬 Needs Work';
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
        title: const Text('Exit Session?'),
        content: const Text('Your progress in this session will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              session.clearSession();
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Exit'),
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
      if (nextPage > 604) return 'You\'ve completed the Quran! 🎉';
      return '📖 Page $nextPage · 🔁 Review today\'s pages';
    } catch (_) {
      return null;
    }
  }
}
