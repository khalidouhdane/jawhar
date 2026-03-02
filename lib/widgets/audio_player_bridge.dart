import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/audio_provider.dart' show AudioRepeatMode;
import 'package:quran_app/providers/theme_provider.dart';

class AudioPlayerBridge extends StatelessWidget {
  final bool isExpanded;
  final bool isPlaying;
  final String currentPositionText;
  final String totalDurationText;
  final double progress;
  final String playingTitle;
  final int reciterId;
  final String reciterName;
  final AudioRepeatMode repeatMode;
  final VoidCallback onToggleExpand;
  final VoidCallback onTogglePlay;
  final VoidCallback onReciterMenuTapped;
  final VoidCallback onSettingsTapped;
  final VoidCallback onSkipNext;
  final VoidCallback onSkipPrevious;
  final VoidCallback onJumpForward;
  final VoidCallback onJumpBackward;
  final VoidCallback onRepeatToggle;
  final ValueChanged<double> onSeek;

  const AudioPlayerBridge({
    super.key,
    required this.isExpanded,
    required this.isPlaying,
    required this.currentPositionText,
    required this.totalDurationText,
    required this.progress,
    required this.playingTitle,
    required this.reciterId,
    required this.reciterName,
    required this.repeatMode,
    required this.onToggleExpand,
    required this.onTogglePlay,
    required this.onReciterMenuTapped,
    required this.onSettingsTapped,
    required this.onSkipNext,
    required this.onSkipPrevious,
    required this.onJumpForward,
    required this.onJumpBackward,
    required this.onRepeatToggle,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return GestureDetector(
      onTap: !isExpanded ? onToggleExpand : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        margin: EdgeInsets.only(
          bottom: isExpanded ? 24 : 16,
          left: isExpanded ? 16 : 24,
          right: isExpanded ? 16 : 24,
        ),
        height: isExpanded ? 210 : 68,
        decoration: BoxDecoration(
          color: theme.playerBackground,
          borderRadius: BorderRadius.circular(isExpanded ? 24 : 34),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor,
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Collapsed State
            AnimatedOpacity(
              opacity: isExpanded ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: isExpanded,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            onReciterMenuTapped();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.playerBackground,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.pillBackground,
                                    border: Border.all(
                                      color: theme.dividerColor,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/reciters/$reciterId.jpg',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.network(
                                          "https://api.dicebear.com/7.x/avataaars/png?seed=$reciterName&backgroundColor=f0f7f8",
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                      const SizedBox(height: 6),
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
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onTogglePlay,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: theme.pillBackground,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPlaying
                                    ? LucideIcons.pause
                                    : LucideIcons.play,
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
                                LucideIcons.expand,
                                size: 24,
                                color: theme.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Expanded State
            AnimatedOpacity(
              opacity: isExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: IgnorePointer(
                ignoring: !isExpanded,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Scrubber
                      Column(
                        children: [
                          SizedBox(
                            height: 12,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                activeTrackColor: theme.sliderActive,
                                inactiveTrackColor: theme.sliderInactive,
                                thumbColor: theme.sliderActive,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14,
                                ),
                                trackShape: const RoundedRectSliderTrackShape(),
                              ),
                              child: ExcludeSemantics(
                                child: Slider(
                                  value: progress.clamp(0.0, 1.0),
                                  onChanged: (val) {
                                    onSeek(val);
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                currentPositionText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: theme.mutedText,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                totalDurationText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: theme.mutedText,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Playback Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildJumpButton(
                            isForward: false,
                            onTap: onJumpBackward,
                            theme: theme,
                          ),
                          GestureDetector(
                            onTap: onSkipPrevious,
                            child: Icon(
                              LucideIcons.skipBack,
                              size: 24,
                              color: theme.accentColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: onTogglePlay,
                            child: Icon(
                              isPlaying ? LucideIcons.pause : LucideIcons.play,
                              size: 36,
                              color: theme.accentColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: onSkipNext,
                            child: Icon(
                              LucideIcons.skipForward,
                              size: 24,
                              color: theme.accentColor,
                            ),
                          ),
                          _buildJumpButton(
                            isForward: true,
                            onTap: onJumpForward,
                            theme: theme,
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Bottom Tools
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: onReciterMenuTapped,
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey,
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          "https://api.dicebear.com/7.x/avataaars/png?seed=Maher&backgroundColor=f0f7f8",
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                reciterName,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.accentColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Icon(
                                              LucideIcons.chevronDown,
                                              size: 12,
                                              color: theme.mutedText,
                                            ),
                                          ],
                                        ),
                                        Text(
                                          playingTitle,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: theme.mutedText,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: onRepeatToggle,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    LucideIcons.repeat,
                                    size: 18,
                                    color: repeatMode != AudioRepeatMode.none
                                        ? theme.accentColor
                                        : theme.mutedText,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: onSettingsTapped,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    LucideIcons.slidersHorizontal,
                                    size: 18,
                                    color: theme.mutedText,
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: theme.pillBackground,
                                  shape: BoxShape.circle,
                                ),
                                child: GestureDetector(
                                  onTap: onToggleExpand,
                                  child: Icon(
                                    LucideIcons.minimize2,
                                    size: 16,
                                    color: theme.mutedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJumpButton({
    required bool isForward,
    required VoidCallback onTap,
    required ThemeProvider theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            "10",
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: theme.accentColor,
            ),
          ),
          Icon(
            isForward ? LucideIcons.rotateCw : LucideIcons.rotateCcw,
            size: 18,
            color: theme.accentColor,
          ),
        ],
      ),
    );
  }
}
