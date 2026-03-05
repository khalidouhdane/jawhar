import 'package:flutter/material.dart';

/// Page indicator effect
enum PageIndicatorEffect { center, edge }

/// App theme modes
enum AppTheme { classic, warm, dark }

enum QuranContentAlignment { top, center, bottom }

enum QuranTextAlign { right, center, justify }

/// Provides theme colors for the entire app.
/// Classic = Original brand colors (white surfaces, teal accents) — DEFAULT
/// Warm = Parchment/beige background with teal accents
/// Dark = Deep teal/navy with cyan highlights
class ThemeProvider extends ChangeNotifier {
  AppTheme _theme = AppTheme.classic;

  // Reading typography settings
  double _quranFontSize = 22;
  double _quranLineHeight = 1.8;
  bool _fitScreenHeight = true;

  // Overlay Typography settings
  double _overlayFontSize = 14;
  double _overlayOpacity = 1.0;

  // Alignment settings
  QuranContentAlignment _contentAlignment = QuranContentAlignment.top;
  QuranTextAlign _quranTextAlign = QuranTextAlign.center;

  // Spine effect (page shadow) settings
  bool _spineEffectEnabled = false;
  PageIndicatorEffect _pageIndicatorEffect = PageIndicatorEffect.center;
  double _spineEffectIntensity = 0.06;
  double _spineEffectWidth = 20;
  double _spineEffectPadding = 0;

  // Layout features
  bool _dynamicPageInfoEnabled = true;
  bool _showBookIconIndicator = true;
  bool _showJuzInfo = false;

  AppTheme get theme => _theme;
  bool get isDark => _theme == AppTheme.dark;
  bool get isWarm => _theme == AppTheme.warm;

  double get quranFontSize => _quranFontSize;
  double get quranLineHeight => _quranLineHeight;
  bool get fitScreenHeight => _fitScreenHeight;

  double get overlayFontSize => _overlayFontSize;
  double get overlayOpacity => _overlayOpacity;

  QuranContentAlignment get contentAlignment => _contentAlignment;
  QuranTextAlign get quranTextAlign => _quranTextAlign;

  bool get spineEffectEnabled => _spineEffectEnabled;
  PageIndicatorEffect get pageIndicatorEffect => _pageIndicatorEffect;
  double get spineEffectIntensity => _spineEffectIntensity;
  double get spineEffectWidth => _spineEffectWidth;
  double get spineEffectPadding => _spineEffectPadding;

  bool get dynamicPageInfoEnabled => _dynamicPageInfoEnabled;
  bool get showBookIconIndicator => _showBookIconIndicator;
  bool get showJuzInfo => _showJuzInfo;

  void setTheme(AppTheme theme) {
    if (_theme == theme) return;
    _theme = theme;
    notifyListeners();
  }

  void setQuranFontSize(double size) {
    _quranFontSize = size.clamp(14, 40);
    notifyListeners();
  }

  void setQuranLineHeight(double height) {
    // Round to 1 decimal place to avoid floating point precision issues and then clamp
    _quranLineHeight = double.parse(height.toStringAsFixed(1)).clamp(1.4, 3.6);
    notifyListeners();
  }

  void setFitScreenHeight(bool enabled) {
    if (_fitScreenHeight == enabled) return;
    _fitScreenHeight = enabled;
    notifyListeners();
  }

  void setOverlayFontSize(double size) {
    _overlayFontSize = size.clamp(10, 24);
    notifyListeners();
  }

  void setOverlayOpacity(double opacity) {
    _overlayOpacity = double.parse(opacity.toStringAsFixed(2)).clamp(0.1, 1.0);
    notifyListeners();
  }

  void setContentAlignment(QuranContentAlignment alignment) {
    if (_contentAlignment == alignment) return;
    _contentAlignment = alignment;
    notifyListeners();
  }

  void setQuranTextAlign(QuranTextAlign alignment) {
    if (_quranTextAlign == alignment) return;
    _quranTextAlign = alignment;
    notifyListeners();
  }

  void setSpineEffectEnabled(bool enabled) {
    if (_spineEffectEnabled == enabled) return;
    _spineEffectEnabled = enabled;
    notifyListeners();
  }

  void setPageIndicatorEffect(PageIndicatorEffect effect) {
    if (_pageIndicatorEffect == effect) return;
    _pageIndicatorEffect = effect;
    notifyListeners();
  }

  void setDynamicPageInfoEnabled(bool enabled) {
    if (_dynamicPageInfoEnabled == enabled) return;
    _dynamicPageInfoEnabled = enabled;
    notifyListeners();
  }

  void setShowBookIconIndicator(bool show) {
    if (_showBookIconIndicator == show) return;
    _showBookIconIndicator = show;
    notifyListeners();
  }

  void setShowHizbInfo(bool show) {
    if (_showJuzInfo == show) return;
    _showJuzInfo = show;
    notifyListeners();
  }

  void setSpineEffectIntensity(double intensity) {
    _spineEffectIntensity = double.parse(
      intensity.toStringAsFixed(2),
    ).clamp(0.0, 0.20);
    notifyListeners();
  }

  void setSpineEffectWidth(double width) {
    _spineEffectWidth = width.clamp(5, 60);
    notifyListeners();
  }

  void setSpineEffectPadding(double padding) {
    _spineEffectPadding = padding.clamp(0, 16);
    notifyListeners();
  }

  // Helper to pick color by theme
  Color _pick({
    required Color classic,
    required Color warm,
    required Color dark,
  }) {
    switch (_theme) {
      case AppTheme.classic:
        return classic;
      case AppTheme.warm:
        return warm;
      case AppTheme.dark:
        return dark;
    }
  }

  // ── Background colors ──
  Color get scaffoldBackground => _pick(
    classic: Colors.white,
    warm: const Color(0xFFF5F0E8),
    dark: const Color(0xFF0A1E24),
  );

  Color get canvasBackground => _pick(
    classic: Colors.white,
    warm: const Color(0xFFF5F0E8),
    dark: const Color(0xFF0A1E24),
  );

  Color get surfaceColor => _pick(
    classic: Colors.white,
    warm: Colors.white,
    dark: const Color(0xFF0F2B33),
  );

  Color get cardColor => _pick(
    classic: Colors.white,
    warm: Colors.white,
    dark: const Color(0xFF122F38),
  );

  // ── Text colors ──
  Color get primaryText => _pick(
    classic: const Color(0xFF1A454E),
    warm: const Color(0xFF1A454E),
    dark: const Color(0xFFD4E8EC),
  );

  Color get secondaryText => _pick(
    classic: const Color(0xFF6B7D82),
    warm: const Color(0xFF6B7D82),
    dark: const Color(0xFF7FABB5),
  );

  Color get mutedText => _pick(
    classic: Colors.grey,
    warm: Colors.grey,
    dark: const Color(0xFF4A7A86),
  );

  Color get overlayTextColor => _pick(
    classic: const Color(0xFF63777E),
    warm: const Color(0xFF63777E),
    dark: const Color(0xFF7FABB5),
  );

  Color get quranText => _pick(
    classic: const Color(0xFF1A454E),
    warm: const Color(0xFF1A454E),
    dark: const Color(0xFFD4E8EC),
  );

  // ── Accent / Brand colors ──
  Color get accentColor => _pick(
    classic: const Color(0xFF1A454E),
    warm: const Color(0xFF1A454E),
    dark: const Color(0xFF4DB6AC),
  );

  Color get accentLight => _pick(
    classic: const Color(0xFFEFF3F5),
    warm: const Color(0xFFEFF3F5),
    dark: const Color(0xFF1A454E),
  );

  // ── Highlight colors ──
  Color get verseHighlight => _pick(
    classic: const Color(0xFFE0F2F1),
    warm: const Color(0xFFF0E1C5),
    dark: const Color(0xFF1A3A42),
  );

  Color get verseMarkerColor => _pick(
    classic: const Color(0xFFB2DFDB),
    warm: const Color(0xFFE6D5B8),
    dark: const Color(0xFF2A6A6E),
  );

  Color get verseMarkerHighlight => _pick(
    classic: const Color(0xFF4DB6AC),
    warm: const Color(0xFFD4A373),
    dark: const Color(0xFF4DB6AC),
  );

  Color get verseMarkerBorder => _pick(
    classic: const Color(0xFF80CBC4),
    warm: const Color(0xFFD4A373),
    dark: const Color(0xFF3A8A8E),
  );

  Color get verseMarkerHighlightBorder => _pick(
    classic: Colors.teal.shade600,
    warm: const Color(0xFFB5835A),
    dark: Colors.teal.shade400,
  );

  // ── UI element colors ──
  Color get navBarBackground => _pick(
    classic: Colors.white,
    warm: Colors.white,
    dark: const Color(0xFF0F2B33),
  );

  Color get dockBackground => _pick(
    classic: Colors.white,
    warm: Colors.white,
    dark: const Color(0xFF0F2B33),
  );

  Color get playerBackground => _pick(
    classic: Colors.white,
    warm: Colors.white,
    dark: const Color(0xFF122F38),
  );

  Color get pillBackground => _pick(
    classic: const Color(0xFFEFF3F5),
    warm: const Color(0xFFEFF3F5),
    dark: const Color(0xFF1A3A42),
  );

  Color get iconColor => _pick(
    classic: const Color(0xFF172A30),
    warm: const Color(0xFF172A30),
    dark: const Color(0xFFB0D4DA),
  );

  Color get dividerColor => _pick(
    classic: Colors.grey.shade200,
    warm: Colors.grey.shade200,
    dark: const Color(0xFF1A3A42),
  );

  Color get sliderActive => _pick(
    classic: const Color(0xFF1A454E),
    warm: const Color(0xFF1A454E),
    dark: const Color(0xFF4DB6AC),
  );

  Color get sliderInactive => _pick(
    classic: Colors.grey.shade200,
    warm: Colors.grey.shade200,
    dark: const Color(0xFF1A3A42),
  );

  Color get indicatorInactive => _pick(
    classic: const Color(0xFFA9CBD6),
    warm: const Color(0xFFA9CBD6),
    dark: const Color(0xFF2A6A6E),
  );

  // ── Overlay / Sheet colors ──
  Color get sheetBackground => _pick(
    classic: Colors.white,
    warm: Colors.white,
    dark: const Color(0xFF0F2B33),
  );

  Color get sheetDragHandle => _pick(
    classic: Colors.grey.shade200,
    warm: Colors.grey.shade200,
    dark: const Color(0xFF1A3A42),
  );

  Color get inputFill => _pick(
    classic: Colors.grey.shade50,
    warm: Colors.grey.shade50,
    dark: const Color(0xFF1A3A42),
  );

  Color get chipSelected => _pick(
    classic: const Color(0xFF1A454E),
    warm: const Color(0xFF1A454E),
    dark: const Color(0xFF4DB6AC),
  );

  Color get chipUnselected => _pick(
    classic: Colors.grey.shade50,
    warm: Colors.grey.shade50,
    dark: const Color(0xFF1A3A42),
  );

  Color get chipSelectedText => _pick(
    classic: Colors.white,
    warm: Colors.white,
    dark: const Color(0xFF0A1E24),
  );

  Color get chipUnselectedText => _pick(
    classic: Colors.grey.shade500,
    warm: Colors.grey.shade500,
    dark: const Color(0xFF7FABB5),
  );

  // ── Shadows ──
  Color get shadowColor => isDark
      ? Colors.black.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.1);

  // ── Mode toggle gradient ──
  List<Color> get modeToggleGradient => [
    const Color(0xFF1C4F5F),
    const Color(0xFF102E37),
  ];

  // ── Contextual menu ──
  Color get contextMenuBackground => const Color(0xFF1A454E);
}
