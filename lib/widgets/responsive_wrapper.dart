import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

/// A wrapper widget that constrains layout on larger screens (tablet/web/desktop).
///
/// If screen width is > 768px:
/// - Constrains the child to a max-width of 680px.
/// - Centers it horizontally.
/// - Draws a premium background with a soft gradient.
/// - Adds a subtle 1px glassmorphic card border and drop shadow.
///
/// If screen width is <= 768px, it returns the child directly.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth <= 768) {
      return child;
    }

    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDark;

    // Premium background gradient colors (soft, atmospheric/ambient)
    final List<Color> gradientColors = isDark
        ? const [
            Color(0xFF0F1719), // Deep atmospheric teal
            Color(0xFF08090A), // Ambient dark gray
            Color(0xFF0D0D12), // Deep ambient indigo/black
          ]
        : const [
            Color(0xFFF1F5F7), // Soft clean cool gray
            Color(0xFFFBF8F3), // Soft alabaster/cream
            Color(0xFFEFF2F6), // Soft lavender tint
          ];

    final Color cardBg = themeProvider.scaffoldBackground;

    // Subtle 1px glassmorphic card border color
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    // Multi-layered drop shadows for premium depth
    final List<BoxShadow> cardShadows = [
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.65)
            : Colors.black.withValues(alpha: 0.08),
        blurRadius: 36,
        spreadRadius: 4,
        offset: const Offset(0, 16),
      ),
      BoxShadow(
        color: isDark
            ? Colors.black.withValues(alpha: 0.35)
            : Colors.black.withValues(alpha: 0.03),
        blurRadius: 18,
        spreadRadius: -4,
        offset: const Offset(0, 4),
      ),
    ];

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── Premium atmospheric background gradient ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // ── Centered and constrained content card ──
          Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 680,
              ),
              decoration: BoxDecoration(
                color: cardBg,
                boxShadow: cardShadows,
                border: Border.symmetric(
                  vertical: BorderSide(
                    color: borderColor,
                    width: 1,
                  ),
                ),
              ),
              child: ClipRect(
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
