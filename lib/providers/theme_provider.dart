import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/theme/geist_tokens.dart';
import 'package:quran_app/theme/geist_shadows.dart';
import 'package:quran_app/theme/geist_typography.dart';

/// Page indicator effect
enum PageIndicatorEffect { center, edge }

/// App theme modes
enum AppTheme { light, dark }

enum QuranContentAlignment { top, center, bottom }

enum QuranTextAlign { right, center, justify }

/// Spotlight pressure curve types
enum SpotlightCurveType { linear, quadratic, quartic, dualZone }

/// Provides theme colors for the entire app.
/// Defaults to system brightness; falls back to light mode.
class ThemeProvider extends ChangeNotifier {
  static const _themeKey = 'app_theme';
  SharedPreferences? _prefs;
  AppTheme _theme = AppTheme.light; // default fallback

  /// Initialize with SharedPreferences for persistence.
  /// If no saved preference, detects system brightness.
  /// Falls back to light mode if detection fails.
  void initWithPrefs(SharedPreferences prefs) {
    _prefs = prefs;
    final saved = prefs.getString(_themeKey);
    if (saved == 'light') {
      _theme = AppTheme.light;
    } else if (saved == 'dark') {
      _theme = AppTheme.dark;
    } else {
      // No saved preference — detect system brightness
      try {
        final brightness = ui.PlatformDispatcher.instance.platformBrightness;
        _theme = brightness == Brightness.dark ? AppTheme.dark : AppTheme.light;
      } catch (_) {
        // Detection failed — fallback to light (encouraged default)
        _theme = AppTheme.light;
      }
    }
    
    // Load spotlight settings
    _spotlightMinRadius = prefs.getDouble('spotlight_min_radius') ?? 40.0;
    _spotlightMidRadius = prefs.getDouble('spotlight_mid_radius') ?? 120.0;
    _spotlightMaskOpacity = prefs.getDouble('spotlight_mask_opacity') ?? 1.0;
    _spotlightFeathering = prefs.getDouble('spotlight_feathering') ?? 0.2;
    _spotlightSensitivity = prefs.getDouble('spotlight_sensitivity') ?? 1.0;
    
    final curveStr = prefs.getString('spotlight_curve_type');
    if (curveStr == 'linear') {
      _spotlightCurveType = SpotlightCurveType.linear;
    } else if (curveStr == 'quadratic') {
      _spotlightCurveType = SpotlightCurveType.quadratic;
    } else if (curveStr == 'quartic') {
      _spotlightCurveType = SpotlightCurveType.quartic;
    } else if (curveStr == 'dualZone') {
      _spotlightCurveType = SpotlightCurveType.dualZone;
    } else {
      _spotlightCurveType = SpotlightCurveType.dualZone;
    }

    notifyListeners();
  }

  // Reading typography settings
  double _quranFontSize = 22;
  double _quranLineHeight = 1.8;
  bool _fitScreenHeight = true;

  // Overlay Typography settings
  double _overlayFontSize = 14;
  double _overlayOpacity = 1.0;

  // Alignment settings
  QuranContentAlignment _contentAlignment = QuranContentAlignment.top;
  QuranTextAlign _quranTextAlign = QuranTextAlign.justify;

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

  // Spotlight settings
  double _spotlightMinRadius = 40.0;
  double _spotlightMidRadius = 120.0;
  SpotlightCurveType _spotlightCurveType = SpotlightCurveType.dualZone;
  double _spotlightMaskOpacity = 1.0;
  double _spotlightFeathering = 0.2;
  double _spotlightSensitivity = 1.0;

  AppTheme get theme => _theme;
  bool get isDark => _theme == AppTheme.dark;

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

  // Spotlight getters
  double get spotlightMinRadius => _spotlightMinRadius;
  double get spotlightMidRadius => _spotlightMidRadius;
  SpotlightCurveType get spotlightCurveType => _spotlightCurveType;
  double get spotlightMaskOpacity => _spotlightMaskOpacity;
  double get spotlightFeathering => _spotlightFeathering;
  double get spotlightSensitivity => _spotlightSensitivity;

  void setTheme(AppTheme theme) {
    if (_theme == theme) return;
    _theme = theme;
    _prefs?.setString(_themeKey, theme == AppTheme.dark ? 'dark' : 'light');
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

  void setSpotlightMinRadius(double radius) {
    _spotlightMinRadius = radius.clamp(10.0, 100.0);
    _prefs?.setDouble('spotlight_min_radius', _spotlightMinRadius);
    notifyListeners();
  }

  void setSpotlightMidRadius(double radius) {
    _spotlightMidRadius = radius.clamp(60.0, 300.0);
    _prefs?.setDouble('spotlight_mid_radius', _spotlightMidRadius);
    notifyListeners();
  }

  void setSpotlightMaskOpacity(double opacity) {
    _spotlightMaskOpacity = double.parse(opacity.toStringAsFixed(2)).clamp(0.5, 1.0);
    _prefs?.setDouble('spotlight_mask_opacity', _spotlightMaskOpacity);
    notifyListeners();
  }

  void setSpotlightFeathering(double feathering) {
    _spotlightFeathering = double.parse(feathering.toStringAsFixed(2)).clamp(0.0, 1.0);
    _prefs?.setDouble('spotlight_feathering', _spotlightFeathering);
    notifyListeners();
  }

  void setSpotlightSensitivity(double sensitivity) {
    _spotlightSensitivity = double.parse(sensitivity.toStringAsFixed(1)).clamp(0.2, 2.0);
    _prefs?.setDouble('spotlight_sensitivity', _spotlightSensitivity);
    notifyListeners();
  }

  void setSpotlightCurveType(SpotlightCurveType curveType) {
    if (_spotlightCurveType == curveType) return;
    _spotlightCurveType = curveType;
    _prefs?.setString('spotlight_curve_type', curveType.name);
    notifyListeners();
  }

  // ── Background colors ──
  Color get scaffoldBackground =>
      isDark ? GeistTokens.darkScaffold : GeistTokens.lightScaffold;

  Color get canvasBackground => scaffoldBackground; // Alias, same value

  Color get surfaceColor =>
      isDark ? GeistTokens.darkSurface : GeistTokens.lightSurface;

  Color get cardColor =>
      isDark ? GeistTokens.darkSurface : GeistTokens.lightSurface;

  // ── Text colors ──
  Color get primaryText =>
      isDark ? GeistTokens.darkPrimary : GeistTokens.lightPrimary;

  Color get secondaryText =>
      isDark ? GeistTokens.darkSecondary : GeistTokens.lightSecondary;

  Color get mutedText =>
      isDark ? GeistTokens.darkMuted : GeistTokens.lightMuted;

  Color get overlayTextColor => secondaryText;

  Color get quranText => primaryText;

  // ── Accent / Brand colors ──
  // In Geist, the primary CTA is black in light mode, white in dark mode
  Color get accentColor => primaryText;

  /// Pure foreground — `geist foreground` token.
  /// White in dark mode, Black in light mode. Used for active nav states.
  Color get foregroundColor =>
      isDark ? GeistTokens.darkForeground : GeistTokens.lightForeground;

  /// Inverted foreground — text color for dark hero/context cards.
  /// Always white because hero cards use a dark background in both modes.
  Color get invertedForeground => const Color(0xFFFFFFFF);

  /// Muted inactive — `accents 3` token.
  /// Used for inactive nav icons and labels.
  Color get accent3 =>
      isDark ? GeistTokens.darkAccent3 : GeistTokens.lightAccent3;

  Color get accentLight =>
      isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);

  // ── Highlight colors (verse reading) ──
  Color get verseHighlight =>
      isDark ? const Color(0xFF262626) : const Color(0xFFEBEBEB);

  Color get verseMarkerColor =>
      isDark ? const Color(0xFF333333) : GeistTokens.lightDivider;

  Color get verseMarkerHighlight =>
      isDark ? GeistTokens.darkPrimary : GeistTokens.lightPrimary;

  Color get verseMarkerBorder =>
      isDark ? const Color(0xFF444444) : const Color(0xFFCCCCCC);

  Color get verseMarkerHighlightBorder =>
      isDark ? const Color(0xFFCCCCCC) : const Color(0xFF444444);

  // ── UI element colors ──
  Color get navBarBackground =>
      isDark ? const Color(0xFF161616) : const Color(0xFFF5F5F5);

  Color get dockBackground => navBarBackground;

  Color get playerBackground =>
      isDark ? const Color(0xFF161616) : const Color(0xFFF5F5F5);

  /// ⚠️ RESTRICTED TOKEN — Only for tiny inline text badges (e.g., "AI", "30 due").
  /// NEVER use for card backgrounds, container fills, or any surface larger than
  /// a badge pill. For card/container backgrounds, use [cardColor] + Border.all(dividerColor).
  Color get pillBackground =>
      isDark ? const Color(0xFF262626) : const Color(0xFFEBEBEB);

  Color get iconColor => isDark ? GeistTokens.darkIcon : GeistTokens.lightIcon;

  Color get dividerColor =>
      isDark ? GeistTokens.darkDivider : GeistTokens.lightDivider;

  Color get sliderActive => primaryText;

  Color get sliderInactive =>
      isDark ? GeistTokens.darkDivider : GeistTokens.lightDivider;

  Color get indicatorInactive =>
      isDark ? const Color(0xFF444444) : const Color(0xFFCCCCCC);

  // ── Overlay / Sheet colors ──
  Color get sheetBackground =>
      isDark ? const Color(0xFF181715) : GeistTokens.lightSurface;

  Color get sheetDragHandle =>
      isDark ? GeistTokens.darkDivider : GeistTokens.lightDivider;

  Color get inputFill =>
      isDark ? GeistTokens.darkSubtle : GeistTokens.lightSubtle;

  Color get chipSelected => primaryText;

  Color get chipUnselected =>
      isDark ? GeistTokens.darkSubtle : GeistTokens.lightSubtle;

  Color get chipSelectedText => scaffoldBackground;

  Color get chipUnselectedText => secondaryText;

  // ── Button specific tokens ──
  Color get buttonDefaultBg =>
      isDark ? GeistTokens.darkGray1000 : GeistTokens.lightGray1000;
  Color get buttonDefaultText =>
      isDark ? GeistTokens.darkBackground100 : GeistTokens.lightBackground100;

  Color get buttonSecondaryBg =>
      isDark ? GeistTokens.darkBackground100 : GeistTokens.lightBackground100;
  Color get buttonSecondaryText =>
      isDark ? GeistTokens.darkGray1000 : GeistTokens.lightGray1000;
  Color get buttonSecondaryBorder =>
      isDark ? GeistTokens.darkGray400 : GeistTokens.lightGray400;

  Color get buttonTertiaryText => isDark
      ? GeistTokens.darkGrayAlpha1000.withValues(alpha: 0.8)
      : GeistTokens.lightGrayAlpha1000.withValues(alpha: 0.8);

  Color get buttonWarningBg => GeistTokens.amber800;
  Color get buttonWarningText =>
      isDark ? GeistTokens.darkBackground100 : GeistTokens.lightBackground100;

  Color get buttonErrorBg => GeistTokens.red800;
  Color get buttonErrorText =>
      isDark ? GeistTokens.darkBackground100 : GeistTokens.lightBackground100;

  // ── Shadows ──
  Color get shadowColor => isDark
      ? Colors.black.withValues(alpha: 0.3)
      : Colors.black.withValues(alpha: 0.1);

  /// Geist shadow-as-border: ring only
  List<BoxShadow> get shadowRing => GeistShadows.ring(isDark: isDark);

  /// Geist shadow-as-border: subtle card
  List<BoxShadow> get shadowCard => GeistShadows.subtleCard(isDark: isDark);

  /// Geist shadow-as-border: full card with depth
  List<BoxShadow> get shadowCardFull => GeistShadows.fullCard(isDark: isDark);

  // ── Mode toggle gradient ──
  List<Color> get modeToggleGradient => isDark
      ? [const Color(0xFF1A1A1A), const Color(0xFF111111)]
      : [const Color(0xFF171717), const Color(0xFF0A0A0A)];

  // ── Contextual menu ──
  Color get contextMenuBackground =>
      isDark ? GeistTokens.darkSurface : GeistTokens.lightPrimary;

  // ── Radii ──
  double get radiusSm => GeistTokens.radiusSm;
  double get radiusMd => GeistTokens.radiusMd;
  double get radiusLg => GeistTokens.radiusLg;
  double get radiusXl => GeistTokens.radiusXl;
  double get radiusPill => GeistTokens.radiusPill;

  // ── Typography ──
  TextStyle get textDisplay =>
      GeistTypography.display.copyWith(color: primaryText);
  TextStyle get textHeadingXLarge =>
      GeistTypography.headingXLarge.copyWith(color: primaryText);
  TextStyle get textHeadingLarge =>
      GeistTypography.headingLarge.copyWith(color: primaryText);
  TextStyle get textHeading =>
      GeistTypography.heading.copyWith(color: primaryText);
  TextStyle get textHeadingLight =>
      GeistTypography.headingLight.copyWith(color: primaryText);
  TextStyle get textBodyLarge =>
      GeistTypography.bodyLarge.copyWith(color: primaryText);
  TextStyle get textBody => GeistTypography.body.copyWith(color: primaryText);
  TextStyle get textBodyMedium =>
      GeistTypography.bodyMedium.copyWith(color: primaryText);
  TextStyle get textBodyStrong =>
      GeistTypography.bodyStrong.copyWith(color: primaryText);
  TextStyle get textBodySmall =>
      GeistTypography.bodySmall.copyWith(color: secondaryText);
  TextStyle get textButton =>
      GeistTypography.button.copyWith(color: primaryText);
  TextStyle get textCaption =>
      GeistTypography.caption.copyWith(color: mutedText);
  TextStyle get textMonoBody =>
      GeistTypography.monoBody.copyWith(color: primaryText);
  TextStyle get textMicroBadge =>
      GeistTypography.microBadge.copyWith(color: primaryText);
}
