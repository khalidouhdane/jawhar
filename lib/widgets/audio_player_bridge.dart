import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/audio_provider.dart' show AudioRepeatMode;
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';

class AudioPlayerBridge extends StatelessWidget {
  final bool isExpanded;
  final bool isPlaying;
  final bool isLoading;
  final bool isViewingPlayingPage;
  final String currentPositionText;
  final String totalDurationText;
  final double progress;
  final String playingTitle;
  final int reciterId;
  final String reciterName;
  final AudioRepeatMode repeatMode;
  final int repeatCount;
  final VoidCallback onToggleExpand;
  final VoidCallback onTogglePlay;
  final VoidCallback onReciterMenuTapped;
  final VoidCallback onSettingsTapped;
  final VoidCallback onSkipNext;
  final VoidCallback onSkipPrevious;
  final VoidCallback onJumpForward;
  final VoidCallback onJumpBackward;
  final VoidCallback onRepeatToggle;
  final VoidCallback? onJumpToPlayingVerse;
  final ValueChanged<double> onSeek;

  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;

  const AudioPlayerBridge({
    super.key,
    required this.isExpanded,
    required this.isPlaying,
    this.isLoading = false,
    this.isViewingPlayingPage = true,
    required this.currentPositionText,
    required this.totalDurationText,
    required this.progress,
    required this.playingTitle,
    required this.reciterId,
    required this.reciterName,
    required this.repeatMode,
    required this.repeatCount,
    required this.onToggleExpand,
    required this.onTogglePlay,
    required this.onReciterMenuTapped,
    required this.onSettingsTapped,
    required this.onSkipNext,
    required this.onSkipPrevious,
    required this.onJumpForward,
    required this.onJumpBackward,
    required this.onRepeatToggle,
    this.onJumpToPlayingVerse,
    required this.onSeek,
    this.margin,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: !isExpanded ? onToggleExpand : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        margin:
            margin ??
            EdgeInsets.only(
              bottom: isExpanded ? 24 : 16,
              left: isExpanded ? 16 : 24,
              right: isExpanded ? 16 : 24,
            ),
        decoration:
            decoration ??
            BoxDecoration(
              color: theme.playerBackground,
              borderRadius: BorderRadius.circular(isExpanded ? 24 : 34),
              boxShadow: theme.shadowCardFull,
            ),
        clipBehavior: Clip.hardEdge,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Expanded Content (Top/Middle) ──
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.fastOutSlowIn,
                  alignment: Alignment.bottomCenter,
                  heightFactor: isExpanded ? 1.0 : 0.0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isExpanded ? 1.0 : 0.0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Scrubber
                          _buildCustomScrubber(theme),
                          const SizedBox(height: 6),
                          // Time Labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                currentPositionText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: theme.mutedText,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                totalDurationText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: theme.mutedText,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Playback Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                onTap: onJumpBackward,
                                child: Icon(
                                  Icons.replay_10_rounded,
                                  size: 28,
                                  color: theme.primaryText,
                                ),
                              ),
                              GestureDetector(
                                onTap: onSkipPrevious,
                                child: Icon(
                                  Icons.skip_previous_rounded,
                                  size: 36,
                                  color: theme.primaryText,
                                ),
                              ),
                              GestureDetector(
                                onTap: isLoading ? null : onTogglePlay,
                                child: Container(
                                  width: 52,
                                  height: 52,
                                  alignment: Alignment.center,
                                  child: isLoading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: theme.primaryText,
                                          ),
                                        )
                                      : Icon(
                                          isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          size: 48,
                                          color: theme.primaryText,
                                        ),
                                ),
                              ),
                              GestureDetector(
                                onTap: onSkipNext,
                                child: Icon(
                                  Icons.skip_next_rounded,
                                  size: 36,
                                  color: theme.primaryText,
                                ),
                              ),
                              GestureDetector(
                                onTap: onJumpForward,
                                child: Icon(
                                  Icons.forward_10_rounded,
                                  size: 28,
                                  color: theme.primaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Always Visible Row (Bottom Row) ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Reciter Section
                    Expanded(
                      child: GestureDetector(
                        onTap: onReciterMenuTapped,
                        child: Container(
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.pillBackground,
                                  boxShadow: theme.shadowRing,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/reciters/$reciterId.jpg',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Text(
                                            reciterName.isNotEmpty
                                                ? reciterName
                                                      .trim()
                                                      .characters
                                                      .first
                                                : '?',
                                            style: TextStyle(
                                              color: theme.mutedText,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      reciterName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: theme.primaryText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      playingTitle,
                                      style: TextStyle(
                                        color: theme.mutedText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Action Buttons (Right Group)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: !isExpanded
                          ? Row(
                              key: const ValueKey('collapsed_actions'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isViewingPlayingPage &&
                                    isPlaying &&
                                    onJumpToPlayingVerse != null) ...[
                                  GestureDetector(
                                    onTap: onJumpToPlayingVerse,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: theme.pillBackground,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        LucideIcons.locate,
                                        size: 20,
                                        color: theme.primaryText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                GestureDetector(
                                  onTap: onTogglePlay,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: theme.pillBackground,
                                      shape: BoxShape.circle,
                                    ),
                                    child: isLoading
                                        ? Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                color: theme.primaryText,
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            isPlaying
                                                ? Icons.pause_rounded
                                                : Icons.play_arrow_rounded,
                                            size: 24,
                                            color: theme.primaryText,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: onToggleExpand,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: theme.pillBackground,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      LucideIcons.expand,
                                      size: 20,
                                      color: theme.primaryText,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              key: const ValueKey('expanded_actions'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: onRepeatToggle,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: theme.pillBackground,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          LucideIcons.repeat,
                                          size: 20,
                                          color:
                                              repeatMode != AudioRepeatMode.none
                                              ? theme.accentColor
                                              : theme.primaryText,
                                        ),
                                      ),
                                      if (repeatMode != AudioRepeatMode.none)
                                        Positioned(
                                          top: -4,
                                          right: -4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            constraints: const BoxConstraints(
                                              minWidth: 16,
                                              minHeight: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.accentColor,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              repeatCount == 0
                                                  ? '∞'
                                                  : '$repeatCount',
                                              style: TextStyle(
                                                color: theme.scaffoldBackground,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: GeistTypography
                                                    .primaryFontFamily,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: onSettingsTapped,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: theme.pillBackground,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      LucideIcons.slidersHorizontal,
                                      size: 20,
                                      color: theme.primaryText,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: onToggleExpand,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: theme.pillBackground,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      LucideIcons.minimize2,
                                      size: 20,
                                      color: theme.primaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomScrubber(ThemeProvider theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final safeProgress = progress.clamp(0.0, 1.0);
        final activeWidth = width * safeProgress;

        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            final newProgress = (details.localPosition.dx / width).clamp(
              0.0,
              1.0,
            );
            onSeek(newProgress);
          },
          onTapDown: (details) {
            final newProgress = (details.localPosition.dx / width).clamp(
              0.0,
              1.0,
            );
            onSeek(newProgress);
          },
          child: Container(
            height: 24, // Touch target height
            color: Colors.transparent,
            alignment: Alignment.center,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // Inactive track
                Container(
                  height: 4,
                  width: width,
                  decoration: BoxDecoration(
                    color: theme.sliderInactive,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Active track
                Container(
                  height: 4,
                  width: activeWidth,
                  decoration: BoxDecoration(
                    color: theme.sliderActive,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Thumb
                Positioned(
                  left: (activeWidth - 6).clamp(0.0, width - 12),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.sliderActive,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
