import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';

/// A diamond-shaped number marker used for surah numbers, verse end markers,
/// hizb numbers, and any index indicator throughout the app.
///
/// The diamond is a 45°-rotated square with slightly rounded corners.
/// The number text sits centered and un-rotated on top.
///
/// Comes in three sizes:
/// - [DiamondSize.inline]  — 22px, for verse end markers inside Quran text
/// - [DiamondSize.small]   — 28px, the standard list-tile size
/// - [DiamondSize.medium]  — 40px, for larger list indicators
enum DiamondSize { inline, small, medium }

class DiamondNumber extends StatelessWidget {
  final int number;
  final DiamondSize size;

  /// If true, uses highlighted/active styling (filled background).
  final bool isHighlighted;

  /// If true, uses "current" styling (accent fill with white text).
  final bool isCurrent;

  /// Optional custom color override for the border and text.
  final Color? color;

  const DiamondNumber({
    super.key,
    required this.number,
    this.size = DiamondSize.small,
    this.isHighlighted = false,
    this.isCurrent = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    final double outerSize;
    final double innerSize;
    final double fontSize;
    final double borderWidth;
    final double borderRadius;

    switch (size) {
      case DiamondSize.inline:
        outerSize = 22.0;
        innerSize = 16.0;
        fontSize = 8.5;
        borderWidth = 1.0;
        borderRadius = 2.5;
      case DiamondSize.small:
        outerSize = 40.0;
        innerSize = 28.0;
        fontSize = 12.0;
        borderWidth = 1.2;
        borderRadius = 4.0;
      case DiamondSize.medium:
        outerSize = 40.0;
        innerSize = 28.0;
        fontSize = 12.0;
        borderWidth = 1.2;
        borderRadius = 4.0;
    }

    // Resolve colors
    final effectiveColor = color ?? theme.accentColor;

    Color borderColor;
    Color? fillColor;
    Color textColor;

    if (isHighlighted) {
      borderColor = theme.verseMarkerHighlightBorder;
      fillColor = theme.verseMarkerHighlight;
      textColor = theme.scaffoldBackground;
    } else if (isCurrent) {
      borderColor = effectiveColor;
      fillColor = effectiveColor;
      textColor = Colors.white;
    } else {
      borderColor = effectiveColor.withValues(alpha: 0.3);
      fillColor = null;
      textColor = effectiveColor;
    }

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: Container(
              width: innerSize,
              height: innerSize,
              decoration: BoxDecoration(
                color: fillColor,
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
          Text(
            '$number',
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
