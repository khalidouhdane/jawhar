import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';

/// CTA card shown to users without a Hifz profile.
/// Invites them to start their memorization journey.
class HifzCtaCard extends StatefulWidget {
  final ThemeProvider theme;
  final VoidCallback onTap;

  const HifzCtaCard({super.key, required this.theme, required this.onTap});

  @override
  State<HifzCtaCard> createState() => _HifzCtaCardState();
}

class _HifzCtaCardState extends State<HifzCtaCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    Color bgColor = widget.theme.buttonDefaultBg;
    if (_isPressed) {
      bgColor = bgColor.withValues(alpha: 0.8);
    } else if (_isHovered) {
      bgColor = bgColor.withValues(alpha: 0.9);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(
              11,
            ), // Matching Figma design exactly
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l.hifzCtaTitle,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.buttonDefaultText,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.sparkles,
                size: 20,
                color: widget.theme.buttonDefaultText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
