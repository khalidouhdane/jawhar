import 'package:flutter/material.dart';

/// Geist Design System neutral gray scale.
/// Reference: DESIGN.md
class GeistTokens {
  GeistTokens._();

  // ── Light Mode Neutrals ──
  static const lightScaffold = Color(0xFFFAFAFA); // background-200 (page)
  static const lightSurface = Color(0xFFFFFFFF);  // background-100 (card/surface)
  static const lightSubtle = Color(0xFFFAFAFA); // Gray-50
  static const lightDivider = Color(0xFFEAEAEA); // Gray-200
  static const lightPrimary = Color(0xFF171717); // Gray-900
  static const lightSecondary = Color(0xFF666666); // Gray-500
  static const lightMuted = Color(0xFF999999); // Gray-400
  static const lightIcon = Color(0xFF171717); // Gray-900
  static const lightForeground = Color(0xFF000000); // geist foreground
  static const lightAccent3 = Color(0xFF999999); // accents 3

  // ── Dark Mode Neutrals ──
  static const darkScaffold = Color(0xFF000000);
  static const darkSurface = Color(0xFF0A0A0A);
  static const darkSubtle = Color(0xFF111111);
  static const darkDivider = Color(0xFF333333);
  static const darkPrimary = Color(0xFFEDEDED);
  static const darkSecondary = Color(0xFFA1A1A1);
  static const darkMuted = Color(0xFF666666);
  static const darkIcon = Color(0xFFEDEDED);
  static const darkForeground = Color(0xFFFFFFFF); // geist foreground
  static const darkAccent3 = Color(0xFF444444); // accents 3

  // ── Button Specific Tokens (ds/* mappings) ──
  static const lightGray1000 = Color(0xFF171717);
  static const darkGray1000 = Color(0xFFEDEDED);

  static const lightBackground100 = Color(0xFFFFFFFF);
  static const darkBackground100 = Color(0xFF000000);

  static const lightGray400 = Color(0xFFEAEAEA); // Closer to accents 2 for light borders
  static const darkGray400 = Color(0xFF333333); // Closer to accents 2 for dark borders

  static const lightGrayAlpha1000 = Color(0xFF171717);
  static const darkGrayAlpha1000 = Color(0xFFEDEDED);

  static const amber800 = Color(0xFFF5A623); // Geist Warning
  static const red800 = Color(0xFFE00000); // Geist Error

  // ── Border Radius Scale ──
  static const radiusSm = 4.0;
  static const radiusMd = 6.0;
  static const radiusLg = 8.0;
  static const radiusXl = 12.0;
  static const radiusPill = 9999.0;
}
