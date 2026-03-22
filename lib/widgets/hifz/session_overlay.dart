import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/session_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/widgets/audio_player_bridge.dart';
import 'package:quran_app/widgets/hifz/verse_highlighter.dart';
import 'package:quran_app/widgets/overlays.dart';

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
    final minutes =
        d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  void _showReciterMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(ctx).size.height * 0.1,
        ),
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Inter'),
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
        padding: EdgeInsets.only(
          top: MediaQuery.of(ctx).size.height * 0.1,
        ),
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Inter'),
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
        padding: EdgeInsets.only(
          top: MediaQuery.of(ctx).size.height * 0.1,
        ),
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Inter'),
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
            offset: widget.isFullScreen
                ? const Offset(0, -1.5)
                : Offset.zero,
            child: _TopPhaseBar(
              session: widget.session,
              pageNumber: widget.pageNumber,
              theme: theme,
              onThemeTap: _showThemePicker,
            ),
          ),

          const Spacer(),

          // ── Bottom Control Bar + Audio Pill ──
          AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            offset: widget.isFullScreen
                ? const Offset(0, 1.5)
                : Offset.zero,
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
    String playingVerseLabel = 'Select verse to play';
    if (audioProvider.activeVerseKey != null) {
      playingVerseLabel = audioProvider.activeVerseKey!;
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Session Controls Row ──
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: Timer · Reps
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Timer
                          GestureDetector(
                            onTap: widget.onTogglePause,
                            child: _chip(
                              theme,
                              icon: session.isPaused
                                  ? LucideIcons.pause
                                  : LucideIcons.timer,
                              label: _formatTime(session.elapsedSeconds),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Rep counter
                          GestureDetector(
                            onTap: widget.onRepTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.accentColor
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.accentColor
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.repeat,
                                      size: 14, color: theme.accentColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${session.repCount}',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: theme.accentColor,
                                    ),
                                  ),
                                  if (session.currentPhase ==
                                          SessionPhase.sabaq &&
                                      session.plan != null)
                                    Text(
                                      '/${session.plan!.sabaqRepetitionTarget}',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: theme.mutedText,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        color: theme.dividerColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 10),
                      // Row 2: Skip · +REP (large) · Done
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ActionButton(
                            icon: LucideIcons.skipForward,
                            label: 'Skip',
                            theme: theme,
                            onTap: widget.onSkip ?? () {},
                          ),
                          GestureDetector(
                            onTap: widget.onRepTap,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: theme.accentColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.accentColor
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                LucideIcons.plus,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          _ActionButton(
                            icon: LucideIcons.check,
                            label: 'Done',
                            theme: theme,
                            isPrimary: true,
                            onTap: widget.onDone,
                          ),
                        ],
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

  Widget _chip(ThemeProvider theme,
      {required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.secondaryText),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
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

  const _TopPhaseBar({
    required this.session,
    required this.pageNumber,
    required this.theme,
    required this.onThemeTap,
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
                  // Phase emoji + label
                  Text(
                    session.currentPhaseEmoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          session.currentPhaseLabel.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: theme.accentColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Page $pageNumber',
                          style: TextStyle(
                            fontFamily: 'Inter',
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
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${session.currentStepNumber}/${session.activePhaseCount}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: theme.accentColor,
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
}

// ═══════════════════════════════════════
// HELPER WIDGETS
// ═══════════════════════════════════════

/// Small action button (Skip, Done) with icon and label.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeProvider theme;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
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
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isPrimary ? theme.accentColor : theme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
