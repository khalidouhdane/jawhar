import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/utils/verse_ref_formatter.dart';
import 'package:quran_app/widgets/reciter_avatar.dart';
import 'package:quran_app/widgets/sheets/reciter_menu_sheet.dart';

/// Compact header pill shown while audio is playing anywhere in the app.
///
/// Renders nothing when no verse is active, so it can sit permanently in
/// [AppHeader]'s actions row. Tapping it opens [NowPlayingSheet] with
/// playback controls.
class NowPlayingPill extends StatelessWidget {
  const NowPlayingPill({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final theme = context.watch<ThemeProvider>();

    if (audio.activeVerseKey == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: GestureDetector(
        onTap: () => NowPlayingSheet.show(context),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(6, 5, 12, 5),
          decoration: BoxDecoration(
            color: theme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReciterAvatar(
                reciterId: audio.reciterId,
                reciterName: audio.reciterName,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                audio.reciterName.split(' ').first,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.accentColor,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                audio.isPlaying ? LucideIcons.volume2 : LucideIcons.pause,
                size: 12,
                color: theme.accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with in-app playback controls for the active audio.
class NowPlayingSheet extends StatelessWidget {
  const NowPlayingSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 680),
      builder: (_) => const NowPlayingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final audio = context.watch<AudioProvider>();
    final locale = Localizations.localeOf(context).toString();
    final verseKey = audio.activeVerseKey;

    // Playback was stopped while the sheet was open.
    if (verseKey == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Reciter + verse info ──
            Row(
              children: [
                ReciterAvatar(
                  reciterId: audio.reciterId,
                  reciterName: audio.reciterName,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audio.reciterName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        VerseRefFormatter.format(verseKey, locale: locale),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 13,
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).modalBarrierDismissLabel,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    LucideIcons.chevronDown,
                    size: 20,
                    color: theme.mutedText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Controls ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ControlButton(
                  icon: LucideIcons.square,
                  size: 18,
                  onTap: () => audio.stop(),
                ),
                _ControlButton(
                  icon: LucideIcons.skipBack,
                  size: 22,
                  onTap: () => audio.skipToPreviousVerse(),
                ),
                // Play / Pause (primary)
                GestureDetector(
                  onTap: () => audio.togglePlay(),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.accentColor,
                    ),
                    child: Icon(
                      audio.isPlaying ? LucideIcons.pause : LucideIcons.play,
                      size: 24,
                      color: theme.scaffoldBackground,
                    ),
                  ),
                ),
                _ControlButton(
                  icon: LucideIcons.skipForward,
                  size: 22,
                  onTap: () => audio.skipToNextVerse(),
                ),
                // Current reciter — tap to switch
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      constraints: const BoxConstraints(maxWidth: 680),
                      builder: (ctx) =>
                          ReciterMenuSheet(onClose: () => Navigator.pop(ctx)),
                    );
                  },
                  child: ReciterAvatar(
                    reciterId: audio.reciterId,
                    reciterName: audio.reciterName,
                    size: 44,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.inputFill,
        ),
        child: Icon(icon, size: size, color: theme.primaryText),
      ),
    );
  }
}
