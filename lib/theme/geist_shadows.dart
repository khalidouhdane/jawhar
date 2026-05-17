import 'package:flutter/material.dart';

/// Shadow-as-border system from the Vercel Geist design spec.
/// Values extracted from vercel.com/geist/materials production CSS.
///
/// Replaces Border.all() across the app. Shadows create the card "material"
/// that distinguishes surfaces from the page background.
class GeistShadows {
  GeistShadows._();

  /// material-base: Ring border only — replaces Border.all()
  /// Light: rgba(0,0,0,0.08) 0 0 0 1px
  /// Dark:  rgba(255,255,255,0.145) 0 0 0 1px
  static List<BoxShadow> ring({bool isDark = false}) => [
    BoxShadow(
      color: isDark
          ? const Color(0x25FFFFFF) // white at ~14.5%
          : const Color(0x14000000), // black at ~8%
      spreadRadius: 1,
      blurRadius: 0,
    ),
  ];

  /// material-small: Ring + soft lift (slightly raised, 6px radius)
  /// Light: + rgba(0,0,0,0.04) 0 2px 2px
  /// Dark:  + rgba(0,0,0,0.16) 0 1px 2px
  static List<BoxShadow> subtleCard({bool isDark = false}) => [
    ...ring(isDark: isDark),
    BoxShadow(
      color: isDark
          ? const Color(0x29000000) // black at ~16%
          : const Color(0x0A000000), // black at ~4%
      offset: isDark ? const Offset(0, 1) : const Offset(0, 2),
      blurRadius: 2,
    ),
  ];

  /// material-medium: Ring + lift + depth (12px radius)
  /// Light: + rgba(0,0,0,0.04) 0 8px 8px -8px
  /// Dark:  + rgba(0,0,0,0.32) 0 2px 2px, rgba(0,0,0,0.16) 0 8px 8px -8px
  static List<BoxShadow> fullCard({bool isDark = false}) => [
    ...ring(isDark: isDark),
    BoxShadow(
      color: isDark
          ? const Color(0x52000000) // black at ~32%
          : const Color(0x0A000000), // black at ~4%
      offset: const Offset(0, 2),
      blurRadius: 2,
    ),
    BoxShadow(
      color: isDark
          ? const Color(0x29000000) // black at ~16%
          : const Color(0x0A000000), // black at ~4%
      offset: const Offset(0, 8),
      blurRadius: isDark ? 8 : 16,
      spreadRadius: isDark ? -8 : -4,
    ),
  ];
}
