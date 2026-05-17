import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Geist Design System Typography constants.
/// Centralized font family variables to allow global switching.
class GeistTypography {
  GeistTypography._();

  // ── Global Font Variables ──
  /// ⚠️ WARNING: DO NOT use `const` on `Text` or `TextStyle` when using these variables.
  /// They are dynamically evaluated at runtime by `GoogleFonts` and will cause compilation errors.
  static String? get primaryFontFamily => GoogleFonts.geist().fontFamily;
  static String? get monoFontFamily => GoogleFonts.geistMono().fontFamily;
  static String? get arabicFontFamily => GoogleFonts.ibmPlexSansArabic().fontFamily;

  // ── Font Weights ──
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700; // Only for micro-badges

  // ── Vercel / Figma Typography Scale ──

  // Headings
  static TextStyle get heading72 => GoogleFonts.geist(fontSize: 72, fontWeight: semiBold, height: 1.1, letterSpacing: -3.6);
  static TextStyle get heading64 => GoogleFonts.geist(fontSize: 64, fontWeight: semiBold, height: 1.1, letterSpacing: -3.2);
  static TextStyle get heading56 => GoogleFonts.geist(fontSize: 56, fontWeight: semiBold, height: 1.1, letterSpacing: -2.8);
  static TextStyle get heading48 => GoogleFonts.geist(fontSize: 48, fontWeight: semiBold, height: 1.1, letterSpacing: -2.4);
  static TextStyle get heading40 => GoogleFonts.geist(fontSize: 40, fontWeight: semiBold, height: 1.2, letterSpacing: -2.0);
  static TextStyle get heading32 => GoogleFonts.geist(fontSize: 32, fontWeight: semiBold, height: 1.25, letterSpacing: -1.28);
  static TextStyle get heading24 => GoogleFonts.geist(fontSize: 24, fontWeight: semiBold, height: 1.33, letterSpacing: -0.96);
  static TextStyle get heading20 => GoogleFonts.geist(fontSize: 20, fontWeight: semiBold, height: 1.4, letterSpacing: -0.8);
  static TextStyle get heading16 => GoogleFonts.geist(fontSize: 16, fontWeight: semiBold, height: 1.5, letterSpacing: -0.32);

  // Text / Normal Variants
  static TextStyle text24({FontWeight weight = regular}) => GoogleFonts.geist(fontSize: 24, fontWeight: weight, height: 1.33);
  static TextStyle text20({FontWeight weight = regular}) => GoogleFonts.geist(fontSize: 20, fontWeight: weight, height: 1.4);
  static TextStyle text16({FontWeight weight = regular}) => GoogleFonts.geist(fontSize: 16, fontWeight: weight, height: 1.5);
  static TextStyle text14({FontWeight weight = regular}) => GoogleFonts.geist(fontSize: 14, fontWeight: weight, height: 1.5);
  static TextStyle text13({FontWeight weight = regular}) => GoogleFonts.geist(fontSize: 13, fontWeight: weight, height: 1.5);
  static TextStyle text12({FontWeight weight = regular}) => GoogleFonts.geist(fontSize: 12, fontWeight: weight, height: 1.33);
  static TextStyle text10({FontWeight weight = regular}) => GoogleFonts.geist(fontSize: 10, fontWeight: weight, height: 1.2);

  // Text / Mono Variants
  static TextStyle mono24({FontWeight weight = regular}) => GoogleFonts.geistMono(fontSize: 24, fontWeight: weight, height: 1.33);
  static TextStyle mono20({FontWeight weight = regular}) => GoogleFonts.geistMono(fontSize: 20, fontWeight: weight, height: 1.4);
  static TextStyle mono16({FontWeight weight = regular}) => GoogleFonts.geistMono(fontSize: 16, fontWeight: weight, height: 1.5);
  static TextStyle mono14({FontWeight weight = regular}) => GoogleFonts.geistMono(fontSize: 14, fontWeight: weight, height: 1.5);
  static TextStyle mono13({FontWeight weight = regular}) => GoogleFonts.geistMono(fontSize: 13, fontWeight: weight, height: 1.5);
  static TextStyle mono12({FontWeight weight = regular}) => GoogleFonts.geistMono(fontSize: 12, fontWeight: weight, height: 1.33);
  static TextStyle mono10({FontWeight weight = regular}) => GoogleFonts.geistMono(fontSize: 10, fontWeight: weight, height: 1.2);

  // Semantic Aliases (Preserved for backwards compatibility)
  static TextStyle get display => heading48;
  static TextStyle get headingXLarge => heading40;
  static TextStyle get headingLarge => heading32;
  static TextStyle get heading => heading24;
  static TextStyle get headingLight => text24(weight: medium);
  static TextStyle get bodyLarge => text20();
  static TextStyle get body => text16();
  static TextStyle get bodyMedium => text16(weight: medium);
  static TextStyle get bodyStrong => text16(weight: semiBold).copyWith(letterSpacing: -0.32);
  static TextStyle get bodySmall => text14();
  static TextStyle get button => text14(weight: medium);
  static TextStyle get caption => text12(weight: medium);
  static TextStyle get monoBody => mono16();

  /// Micro Badge (7px to 10px) - Tiny badges, uppercase
  static TextStyle get microBadge => GoogleFonts.geist(
    fontSize: 9, // Using 9px for mobile legibility
    fontWeight: bold,
    height: 1.0,
    letterSpacing: 0.5, // Uppercase needs slight positive spacing
  );
}
