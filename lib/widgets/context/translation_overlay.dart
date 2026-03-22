import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/context_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compact overlay widget that shows the translation of a verse.
///
/// Designed to be positioned below verse text in the reading canvas or
/// session screen. Accepts a verse key and fetches/shows the translation.
///
/// Usage:
/// ```dart
/// TranslationOverlay(verseKey: '2:255')
/// ```
class TranslationOverlay extends StatelessWidget {
  final String verseKey;

  /// Optional: provide the translation text directly instead of loading.
  final String? translationText;

  /// Whether to show a close button.
  final bool showDismiss;

  /// Called when the close button is tapped.
  final VoidCallback? onDismiss;

  const TranslationOverlay({
    super.key,
    required this.verseKey,
    this.translationText,
    this.showDismiss = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.pillBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.dividerColor,
          width: 0.5,
        ),
      ),
      child: translationText != null
          ? _buildContent(theme, translationText!)
          : _buildFromProvider(context, theme),
    );
  }

  Widget _buildFromProvider(BuildContext context, ThemeProvider theme) {
    final ctx = context.watch<ContextProvider>();

    // Check page-level cache first
    final pageTranslation = ctx.pageTranslations[verseKey];
    if (pageTranslation != null) {
      return _buildContent(theme, pageTranslation.text);
    }

    // Check active translation
    if (ctx.activeVerseKey == verseKey && ctx.activeTranslation != null) {
      return _buildContent(theme, ctx.activeTranslation!.text);
    }

    if (ctx.isLoadingTranslation && ctx.activeVerseKey == verseKey) {
      return _buildShimmer(theme);
    }

    // Trigger load if we don't have data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ctx.activeVerseKey != verseKey) {
        ctx.loadTranslation(verseKey);
      }
    });

    return _buildShimmer(theme);
  }

  Widget _buildContent(ThemeProvider theme, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row
        Row(
          children: [
            Icon(
              Icons.translate,
              size: 14,
              color: theme.accentColor,
            ),
            const SizedBox(width: 6),
            Text(
              verseKey,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
            const Spacer(),
            if (showDismiss)
              GestureDetector(
                onTap: onDismiss,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: theme.mutedText,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        // Translation text — wrapped in ExcludeSemantics to avoid
        // Windows accessibility bridge crashes with dynamic text.
        ExcludeSemantics(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.5,
              color: theme.secondaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(Icons.translate, size: 14, color: theme.accentColor),
            const SizedBox(width: 6),
            Text(
              verseKey,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Shimmer loading lines
        _ShimmerLine(width: double.infinity, color: theme.dividerColor),
        const SizedBox(height: 4),
        _ShimmerLine(width: 200, color: theme.dividerColor),
      ],
    );
  }
}

/// A simple shimmer placeholder line.
class _ShimmerLine extends StatelessWidget {
  final double width;
  final Color color;

  const _ShimmerLine({required this.width, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
