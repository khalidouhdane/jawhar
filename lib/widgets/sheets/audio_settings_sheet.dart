import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';

// ─── Audio Settings Sheet (Functional) ───

class AudioSettingsSheet extends StatefulWidget {
  final VoidCallback onClose;

  const AudioSettingsSheet({super.key, required this.onClose});

  @override
  State<AudioSettingsSheet> createState() => _AudioSettingsSheetState();
}

class _AudioSettingsSheetState extends State<AudioSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final l = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 6,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: theme.sheetDragHandle,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.t('audio_settings_title'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.accentColor,
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(LucideIcons.x, size: 18, color: theme.mutedText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Speed
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.t('audio_playback_speed'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [0.75, 1.0, 1.25, 1.5].map((speed) {
                  final label = speed == 1.0 ? '1x' : '${speed}x';
                  final isSelected = audioProvider.playbackSpeed == speed;
                  return GestureDetector(
                    onTap: () => audioProvider.setPlaybackSpeed(speed),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.chipSelected
                            : theme.chipUnselected,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? theme.chipSelectedText
                              : theme.chipUnselectedText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Repeat mode
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.inputFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.accentColor.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.repeat,
                      size: 18,
                      color: theme.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.t('audio_repeat_mode'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildRepeatChip(
                      l.t('audio_repeat_off'),
                      AudioRepeatMode.none,
                      audioProvider,
                      theme,
                    ),
                    const SizedBox(width: 8),
                    _buildRepeatChip(
                      l.t('audio_repeat_verse'),
                      AudioRepeatMode.repeatVerse,
                      audioProvider,
                      theme,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l.t('audio_repeat_times'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.secondaryText,
                        ),
                      ),
                      Row(
                        children: [3, 5, 10, 0].map((times) {
                          final isInfinite = times == 0;
                          final isSelected = audioProvider.repeatCount == times;
                          return GestureDetector(
                            onTap: () => audioProvider.setRepeatCount(times),
                            child: Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(left: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? theme.chipSelected
                                    : theme.chipUnselected,
                              ),
                              child: isInfinite
                                  ? Icon(
                                      LucideIcons.infinity,
                                      size: 16,
                                      color: isSelected
                                          ? theme.chipSelectedText
                                          : theme.chipUnselectedText,
                                    )
                                  : Text(
                                      '$times',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? theme.chipSelectedText
                                            : theme.chipUnselectedText,
                                      ),
                                    ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRepeatChip(
    String label,
    AudioRepeatMode mode,
    AudioProvider audioProvider,
    ThemeProvider theme,
  ) {
    final isSelected = audioProvider.repeatMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => audioProvider.setRepeatMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? theme.chipSelected : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.chipSelected : theme.dividerColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? theme.chipSelectedText
                  : theme.chipUnselectedText,
            ),
          ),
        ),
      ),
    );
  }
}
