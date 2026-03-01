import 'package:flutter/material.dart';

/// App theme modes
enum AppTheme { light, dark }

/// Provides theme colors for the entire app.
/// Light = Warm parchment (beige) with teal accents
/// Dark = Deep teal/navy with cyan highlights
class ThemeProvider extends ChangeNotifier {
  AppTheme _theme = AppTheme.light;

  AppTheme get theme => _theme;
  bool get isDark => _theme == AppTheme.dark;

  void setTheme(AppTheme theme) {
    if (_theme == theme) return;
    _theme = theme;
    notifyListeners();
  }

  void toggleTheme() {
    _theme = _theme == AppTheme.light ? AppTheme.dark : AppTheme.light;
    notifyListeners();
  }

  // ── Background colors ──
  Color get scaffoldBackground =>
      isDark ? const Color(0xFF0A1E24) : const Color(0xFFF5F0E8);

  Color get canvasBackground =>
      isDark ? const Color(0xFF0A1E24) : const Color(0xFFF5F0E8);

  Color get surfaceColor => isDark ? const Color(0xFF0F2B33) : Colors.white;

  Color get cardColor => isDark ? const Color(0xFF122F38) : Colors.white;

  // ── Text colors ──
  Color get primaryText =>
      isDark ? const Color(0xFFD4E8EC) : const Color(0xFF1A454E);

  Color get secondaryText =>
      isDark ? const Color(0xFF7FABB5) : const Color(0xFF6B7D82);

  Color get mutedText => isDark ? const Color(0xFF4A7A86) : Colors.grey;

  Color get quranText =>
      isDark ? const Color(0xFFD4E8EC) : const Color(0xFF1A454E);

  // ── Accent / Brand colors ──
  Color get accentColor =>
      isDark ? const Color(0xFF4DB6AC) : const Color(0xFF1A454E);

  Color get accentLight =>
      isDark ? const Color(0xFF1A454E) : const Color(0xFFEFF3F5);

  // ── Highlight colors (verse highlighting) ──
  Color get verseHighlight =>
      isDark ? const Color(0xFF1A3A42) : const Color(0xFFE0F2F1);

  Color get verseMarkerColor =>
      isDark ? const Color(0xFF2A6A6E) : const Color(0xFFB2DFDB);

  Color get verseMarkerHighlight =>
      isDark ? const Color(0xFF4DB6AC) : const Color(0xFF4DB6AC);

  Color get verseMarkerBorder =>
      isDark ? const Color(0xFF3A8A8E) : const Color(0xFF80CBC4);

  Color get verseMarkerHighlightBorder =>
      isDark ? Colors.teal.shade400 : Colors.teal.shade600;

  // ── UI element colors ──
  Color get navBarBackground => isDark ? const Color(0xFF0F2B33) : Colors.white;

  Color get dockBackground => isDark ? const Color(0xFF0F2B33) : Colors.white;

  Color get playerBackground => isDark ? const Color(0xFF122F38) : Colors.white;

  Color get pillBackground =>
      isDark ? const Color(0xFF1A3A42) : const Color(0xFFEFF3F5);

  Color get iconColor =>
      isDark ? const Color(0xFFB0D4DA) : const Color(0xFF172A30);

  Color get dividerColor =>
      isDark ? const Color(0xFF1A3A42) : Colors.grey.shade200;

  Color get sliderActive =>
      isDark ? const Color(0xFF4DB6AC) : const Color(0xFF1A454E);

  Color get sliderInactive =>
      isDark ? const Color(0xFF1A3A42) : Colors.grey.shade200;

  // ── Overlay / Sheet colors ──
  Color get sheetBackground => isDark ? const Color(0xFF0F2B33) : Colors.white;

  Color get sheetDragHandle =>
      isDark ? const Color(0xFF1A3A42) : Colors.grey.shade200;

  Color get inputFill => isDark ? const Color(0xFF1A3A42) : Colors.grey.shade50;

  Color get chipSelected =>
      isDark ? const Color(0xFF4DB6AC) : const Color(0xFF1A454E);

  Color get chipUnselected =>
      isDark ? const Color(0xFF1A3A42) : Colors.grey.shade50;

  Color get chipSelectedText => isDark ? const Color(0xFF0A1E24) : Colors.white;

  Color get chipUnselectedText =>
      isDark ? const Color(0xFF7FABB5) : Colors.grey.shade500;

  // ── Shadows ──
  Color get shadowColor =>
      isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1);

  // ── Mode toggle gradient ──
  List<Color> get modeToggleGradient => isDark
      ? [const Color(0xFF2A6A72), const Color(0xFF1A454E)]
      : [const Color(0xFF1C4F5F), const Color(0xFF102E37)];

  // ── Contextual menu ──
  Color get contextMenuBackground =>
      isDark ? const Color(0xFF1A454E) : const Color(0xFF1A454E);
}
