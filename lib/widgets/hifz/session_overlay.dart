import 'dart:ui';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:quran_app/utils/verse_ref_formatter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/session_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/models/session_recipe_models.dart';
import 'package:quran_app/widgets/audio_player_bridge.dart';
import 'package:quran_app/widgets/hifz/verse_highlighter.dart';
import 'package:quran_app/widgets/overlays.dart';
import 'package:quran_app/theme/semantic_colors.dart';
import 'package:quran_app/theme/icon_resolver.dart';
import 'package:quran_app/theme/geist_typography.dart';

/// Floating session controls overlay for the digital reading mode (Phase 4).
///
/// Displays a top phase bar and a bottom control bar on top of the
/// [ReadingCanvas], providing session context (phase, timer, reps) and
/// actions (rep count, skip, done, audio) without leaving the reading view.
///
/// Now includes full [AudioPlayerBridge] with reciter info, scrubber,
/// and theme picker — matching the main reading screen experience.
class SessionOverlay extends StatefulWidget {
  final SessionProvider session;
  final int pageNumber;
  final VoidCallback onRepTap;
  final VoidCallback onDone;
  final VoidCallback? onSkip;
  final VoidCallback? onTogglePause;
  final List<Verse> verses;
  final bool isFullScreen;
  final VoidCallback onMinimize;
  final VoidCallback onExit;

  const SessionOverlay({
    super.key,
    required this.session,
    required this.pageNumber,
    required this.onRepTap,
    required this.onDone,
    this.onSkip,
    this.onTogglePause,
    required this.verses,
    this.isFullScreen = false,
    required this.onMinimize,
    required this.onExit,
  });

  @override
  State<SessionOverlay> createState() => _SessionOverlayState();
}

class _SessionOverlayState extends State<SessionOverlay> {
  bool _isAudioExpanded = false;

  String _formatTime(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  void _showReciterMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(ctx).size.height * 0.1),
        child: DefaultTextStyle(
          style: TextStyle(fontFamily: 'Inter'),
          child: ReciterMenuSheet(onClose: () => Navigator.pop(ctx)),
        ),
      ),
    );
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(ctx).size.height * 0.1),
        child: DefaultTextStyle(
          style: TextStyle(fontFamily: 'Inter'),
          child: ThemePickerSheet(onClose: () => Navigator.pop(ctx)),
        ),
      ),
    );
  }

  void _showAudioSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(ctx).size.height * 0.1),
        child: DefaultTextStyle(
          style: TextStyle(fontFamily: 'Inter'),
          child: AudioSettingsSheet(onClose: () => Navigator.pop(ctx)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Positioned.fill(
      child: Column(
        children: [
          // ── Top Phase Bar ──
          AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            offset: widget.isFullScreen ? const Offset(0, -1.5) : Offset.zero,
            child: _TopPhaseBar(
              session: widget.session,
              pageNumber: widget.pageNumber,
              theme: theme,
              onThemeTap: _showThemePicker,
              onMinimize: widget.onMinimize,
              onExit: widget.onExit,
            ),
          ),

          const Spacer(),

          // ── Bottom Control Bar + Audio Pill ──
          AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            offset: widget.isFullScreen ? const Offset(0, 1.5) : Offset.zero,
            child: _buildBottomSection(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(ThemeProvider theme) {
    final audioProvider = context.watch<AudioProvider>();
    final session = widget.session;

    final currentPosStr = _formatDuration(audioProvider.currentPosition);
    final totalDurStr = _formatDuration(audioProvider.totalDuration);
    final progress = audioProvider.totalDuration.inMilliseconds > 0
        ? (audioProvider.currentPosition.inMilliseconds /
                  audioProvider.totalDuration.inMilliseconds)
              .clamp(0.0, 1.0)
        : 0.0;

    // Build the playing title
    String playingVerseLabel = AppLocalizations.of(context)!.audioSelectVerse;
    if (audioProvider.activeVerseKey != null) {
      playingVerseLabel = VerseRefFormatter.format(
        audioProvider.activeVerseKey!,
        locale: AppLocalizations.of(context)!.localeName,
        tier: VerseRefFormat.compact,
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Floating Recipe Tooltip (if guided mode) ──
            if (session.isGuidedMode && session.currentStep != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: _buildRecipeStepBanner(theme, session),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Action Dock Row ──
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Timer Pill
                      GestureDetector(
                        onTap: widget.onTogglePause,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.pillBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _chip(
                            theme,
                            icon: session.isPaused
                                ? LucideIcons.pause
                                : LucideIcons.timer,
                            label: _formatTime(session.elapsedSeconds),
                          ),
                        ),
                      ),

                      // Action Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (session.isGuidedMode &&
                              session.currentStep != null) ...[
                            _ActionButton(
                              icon: LucideIcons.chevronLeft,
                              theme: theme,
                              onTap: () => session.previousStep(),
                            ),
                            const SizedBox(width: 12),
                            _buildBigAddRepButton(theme, session),
                            const SizedBox(width: 12),
                            if (session.currentStepIndex <
                                (session.currentRecipe?.steps.length ?? 1) - 1)
                              _ActionButton(
                                icon: LucideIcons.chevronRight,
                                theme: theme,
                                onTap: () => session.nextStep(),
                              )
                            else
                              _ActionButton(
                                icon: LucideIcons.checkCircle,
                                theme: theme,
                                isPrimary: true,
                                onTap: widget.onDone,
                              ),
                          ] else ...[
                            _ActionButton(
                              icon: LucideIcons.skipForward,
                              theme: theme,
                              onTap: widget.onSkip ?? () {},
                            ),
                            const SizedBox(width: 12),
                            _buildBigAddRepButton(theme, session),
                            const SizedBox(width: 12),
                            _ActionButton(
                              icon: LucideIcons.check,
                              theme: theme,
                              isPrimary: true,
                              onTap: widget.onDone,
                            ),
                          ],
                        ],
                      ),

                      // Rep counter
                      GestureDetector(
                        onTap: widget.onRepTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${session.repCount}',
                                style: TextStyle(
                                  fontFamily: GeistTypography.primaryFontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: theme.accentColor,
                                ),
                              ),
                              if (session.currentPhase == SessionPhase.sabaq &&
                                  session.plan != null)
                                Text(
                                  '/${session.plan!.sabaqRepetitionTarget}',
                                  style: TextStyle(
                                    fontFamily:
                                        GeistTypography.primaryFontFamily,
                                    fontSize: 11,
                                    color: theme.accentColor.withValues(
                                      alpha: 0.7,
                                    ),
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
            ),

            const SizedBox(height: 8),

            // ── Full Audio Player Bridge ──
            AudioPlayerBridge(
              isExpanded: _isAudioExpanded,
              isPlaying: audioProvider.isPlaying,
              isLoading: audioProvider.isLoading,
              currentPositionText: currentPosStr,
              totalDurationText: totalDurStr,
              progress: progress,
              playingTitle: playingVerseLabel,
              reciterId: audioProvider.reciterId,
              reciterName: audioProvider.reciterName,
              repeatMode: audioProvider.repeatMode,
              repeatCount: audioProvider.repeatCount,
              onToggleExpand: () =>
                  setState(() => _isAudioExpanded = !_isAudioExpanded),
              onTogglePlay: () {
                if (audioProvider.activeVerseKey == null &&
                    widget.verses.isNotEmpty) {
                  SessionAudioHelper.playPageAudio(
                    audioProvider,
                    widget.verses,
                  );
                } else {
                  audioProvider.togglePlay();
                }
              },
              onReciterMenuTapped: _showReciterMenu,
              onSettingsTapped: _showAudioSettings,
              onSkipNext: () => audioProvider.skipToNextVerse(),
              onSkipPrevious: () => audioProvider.skipToPreviousVerse(),
              onJumpForward: () => audioProvider.seekForward(10),
              onJumpBackward: () => audioProvider.seekBackward(10),
              onRepeatToggle: () => audioProvider.toggleRepeatMode(),
              onSeek: (val) => audioProvider.seekToFraction(val),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeStepBanner(ThemeProvider theme, SessionProvider session) {
    final step = session.currentStep!;
    final recipe = session.currentRecipe!;
    final l10n = AppLocalizations.of(context)!;
    final totalSteps = recipe.steps.length;
    final unitLabel = step.unit == StepUnit.minutes ? l10n.sessionMin : l10n.sessionTimes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(
            IconResolver.resolve(step.icon),
            size: 16,
            color: theme.accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step.instruction,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 11,
                color: theme.secondaryText,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Step progress badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: session.isStepComplete
                  ? SemanticColors.practiceEmerald
                        .fg(theme.isDark)
                        .withValues(alpha: 0.15)
                  : theme.pillBackground,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${session.currentStepIndex + 1}/$totalSteps · ${session.stepRepCount}/${step.target}$unitLabel',
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: session.isStepComplete
                    ? SemanticColors.practiceEmerald.fg(theme.isDark)
                    : theme.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigAddRepButton(ThemeProvider theme, SessionProvider session) {
    return GestureDetector(
      onTap: widget.onRepTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: session.isStepComplete
              ? SemanticColors.practiceEmerald.fg(theme.isDark)
              : theme.accentColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color:
                  (session.isStepComplete
                          ? SemanticColors.practiceEmerald.fg(theme.isDark)
                          : theme.accentColor)
                      .withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          session.isStepComplete ? LucideIcons.check : LucideIcons.plus,
          size: 20,
          color: theme.scaffoldBackground,
        ),
      ),
    );
  }

  Widget _chip(
    ThemeProvider theme, {
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.secondaryText),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════
// TOP PHASE BAR
// ═══════════════════════════════════════

class _TopPhaseBar extends StatelessWidget {
  final SessionProvider session;
  final int pageNumber;
  final ThemeProvider theme;
  final VoidCallback onThemeTap;
  final VoidCallback onMinimize;
  final VoidCallback onExit;

  const _TopPhaseBar({
    required this.session,
    required this.pageNumber,
    required this.theme,
    required this.onThemeTap,
    required this.onMinimize,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  // Minimize button
                  GestureDetector(
                    onTap: onMinimize,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackground.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.minimize2,
                        size: 14,
                        color: theme.secondaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Phase label & details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              session.currentPhaseIcon,
                              size: 14,
                              color: theme.accentColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _getPhaseLabel(
                                  context,
                                  session.currentPhase,
                                ).toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: GeistTypography.primaryFontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: theme.accentColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.overlayPageLines(pageNumber, 1, 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: GeistTypography.primaryFontFamily,
                            fontSize: 12,
                            color: theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Theme picker button
                  GestureDetector(
                    onTap: onThemeTap,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackground.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.slidersHorizontal,
                        size: 14,
                        color: theme.secondaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Step indicator chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${session.currentStepNumber}/${session.activePhaseCount}',
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close button
                  GestureDetector(
                    onTap: onExit,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackground.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.x,
                        size: 14,
                        color: theme.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

// ═══════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════

/// Small action button (Skip, Done) with icon and label.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final ThemeProvider theme;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.theme,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isPrimary
                  ? theme.accentColor.withValues(alpha: 0.15)
                  : theme.scaffoldBackground.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: isPrimary
                    ? theme.accentColor.withValues(alpha: 0.4)
                    : theme.dividerColor,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isPrimary ? theme.accentColor : theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

