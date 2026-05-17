import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Resolves string-based icon keys to [IconData] from the LucideIcons library.
///
/// Used by data models that previously stored emoji strings (e.g., `'📖'`)
/// and now store semantic icon keys (e.g., `'book_open'`).
///
/// Usage:
/// ```dart
/// final iconData = IconResolver.resolve(step.icon);
/// Icon(iconData, size: 16, color: theme.accentColor)
/// ```
class IconResolver {
  IconResolver._();

  static const Map<String, IconData> _map = {
    // ── Reading & Study ──
    'book_open': LucideIcons.bookOpen,
    'book': LucideIcons.book,
    'library': LucideIcons.library,
    'scroll': LucideIcons.scroll,
    'pencil': LucideIcons.pencil,
    'notebook': LucideIcons.stickyNote,

    // ── Audio ──
    'headphones': LucideIcons.headphones,
    'volume_2': LucideIcons.volume2,

    // ── Memory & Brain ──
    'brain': LucideIcons.brain,
    'lightbulb': LucideIcons.lightbulb,
    'puzzle': LucideIcons.puzzle,

    // ── Progress & Status ──
    'check_circle': LucideIcons.checkCircle,
    'check': LucideIcons.check,
    'target': LucideIcons.target,
    'trophy': LucideIcons.trophy,
    'award': LucideIcons.award,
    'sparkles': LucideIcons.sparkles,

    // ── Actions ──
    'repeat': LucideIcons.repeat,
    'rotate_ccw': LucideIcons.rotateCcw,
    'layers': LucideIcons.layers,
    'shuffle': LucideIcons.shuffle,

    // ── Nature & Growth ──
    'sprout': LucideIcons.sprout,
    'leaf': LucideIcons.leaf,
    'tree_deciduous': LucideIcons.treePine,
    'flower': LucideIcons.flower2,

    // ── Motivation & Celebration ──
    'flame': LucideIcons.flame,
    'star': LucideIcons.star,
    'sun': LucideIcons.sun,
    'sunrise': LucideIcons.sunrise,
    'sunset': LucideIcons.sunset,
    'moon': LucideIcons.moon,
    'crown': LucideIcons.crown,
    'heart': LucideIcons.heart,
    'zap': LucideIcons.zap,
    'party_popper': LucideIcons.partyPopper,

    // ── Navigation & Places ──
    'landmark': LucideIcons.landmark,
    'building': LucideIcons.building,
    'diamond': LucideIcons.diamond,

    // ── Alerts ──
    'alert_triangle': LucideIcons.alertTriangle,
    'alert_circle': LucideIcons.alertCircle,
    'info': LucideIcons.info,

    // ── Exercise & Effort ──
    'dumbbell': LucideIcons.dumbbell,
    'gauge': LucideIcons.gauge,

    // ── Weather & Time ──
    'cloud_sun': LucideIcons.cloudSun,

    // ── Visual & Linking ──
    'eye': LucideIcons.eye,
    'link': LucideIcons.link,
    'coffee': LucideIcons.coffee,
    'rocket': LucideIcons.rocket,
  };

  /// Resolve an icon key string to [IconData].
  /// Returns [LucideIcons.bookOpen] as the default fallback.
  static IconData resolve(String key) {
    return _map[key] ?? LucideIcons.bookOpen;
  }

  /// Profile avatar icons — replaces the old emoji avatar array.
  /// Must maintain the same length (8) for backward compatibility
  /// with stored avatar index values.
  static const List<IconData> avatarIcons = [
    LucideIcons.moon, // was 🌙
    LucideIcons.star, // was ⭐
    LucideIcons.bookOpen, // was 📖
    LucideIcons.landmark, // was 🕌
    LucideIcons.leaf, // was 🌿
    LucideIcons.building, // was 🕋
    LucideIcons.diamond, // was 💎
    LucideIcons.flower2, // was 🌸
  ];

  /// Day-of-week icons for schedule display.
  static const List<IconData> dayIcons = [
    LucideIcons.moon, // Mon (was 🌙)
    LucideIcons.moon, // Tue
    LucideIcons.moon, // Wed
    LucideIcons.moon, // Thu
    LucideIcons.landmark, // Fri (was 🕌)
    LucideIcons.sun, // Sat (was ☀️)
    LucideIcons.sun, // Sun
  ];
}
