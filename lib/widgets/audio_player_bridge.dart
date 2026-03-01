import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AudioPlayerBridge extends StatelessWidget {
  final bool isExpanded;
  final bool isPlaying;
  final String currentPositionText;
  final String totalDurationText;
  final double progress;
  final String playingTitle;
  final String reciterName;
  final VoidCallback onToggleExpand;
  final VoidCallback onTogglePlay;
  final VoidCallback onReciterMenuTapped;
  final VoidCallback onSettingsTapped;

  const AudioPlayerBridge({
    super.key,
    required this.isExpanded,
    required this.isPlaying,
    required this.currentPositionText,
    required this.totalDurationText,
    required this.progress,
    required this.playingTitle,
    required this.reciterName,
    required this.onToggleExpand,
    required this.onTogglePlay,
    required this.onReciterMenuTapped,
    required this.onSettingsTapped,
  });

  @override
  Widget build(BuildContext context) {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(isExpanded ? 24 : 34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 40,
              offset: const Offset(0, 10),
            )
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            onReciterMenuTapped();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[200],
                                    border: Border.all(color: Colors.grey[100]!),
                                    image: const DecorationImage(
                                      image: NetworkImage("https://api.dicebear.com/7.x/avataaars/png?seed=Maher&backgroundColor=f0f7f8"),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        reciterName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0B2128)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        playingTitle,
                                        style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.normal),
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
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPlaying ? LucideIcons.pause : LucideIcons.play,
                                size: 20,
                                color: const Color(0xFF0B2128),
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
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.expand, size: 24, color: Color(0xFF0B2128)),
                            ),
                          ),
                        ],
                      )
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
                                activeTrackColor: const Color(0xFF1A454E),
                                inactiveTrackColor: Colors.grey[200],
                                thumbColor: const Color(0xFF1A454E),
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                trackShape: const RoundedRectSliderTrackShape(),
                              ),
                              child: ExcludeSemantics(
                                child: Slider(
                                  value: progress.clamp(0.0, 1.0),
                                  onChanged: (val) {
                                    // Seek logic placeholder
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(currentPositionText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey, letterSpacing: 0.5)),
                              Text(totalDurationText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey, letterSpacing: 0.5)),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Playback Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildJumpButton(isForward: false),
                          GestureDetector(onTap: () {}, child: const Icon(LucideIcons.skipBack, size: 24, color: Color(0xFF1A454E))),
                          GestureDetector(
                            onTap: onTogglePlay,
                            child: Icon(isPlaying ? LucideIcons.pause : LucideIcons.play, size: 36, color: const Color(0xFF1A454E)),
                          ),
                          GestureDetector(onTap: () {}, child: const Icon(LucideIcons.skipForward, size: 24, color: Color(0xFF1A454E))),
                          _buildJumpButton(isForward: true),
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
                                        image: NetworkImage("https://api.dicebear.com/7.x/avataaars/png?seed=Maher&backgroundColor=f0f7f8"),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(child: Text(reciterName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A454E)), overflow: TextOverflow.ellipsis)),
                                            const SizedBox(width: 4),
                                            const Icon(LucideIcons.chevronDown, size: 12, color: Colors.grey)
                                          ],
                                        ),
                                        Text(playingTitle, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(onTap: () {}, child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(LucideIcons.repeat, size: 18, color: Colors.grey))),
                              GestureDetector(onTap: onSettingsTapped, child: const Padding(padding: EdgeInsets.all(8.0), child: Icon(LucideIcons.slidersHorizontal, size: 18, color: Colors.grey))),
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
                                child: GestureDetector(onTap: onToggleExpand, child: const Icon(LucideIcons.minimize2, size: 16, color: Colors.grey)),
                              )
                            ],
                          )
                        ],
                      )
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

  Widget _buildJumpButton({required bool isForward}) {
    return Column(
      children: [
        const Text("10", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1A454E))),
        Icon(isForward ? LucideIcons.rotateCw : LucideIcons.rotateCcw, size: 18, color: const Color(0xFF1A454E)),
      ],
    );
  }
}
