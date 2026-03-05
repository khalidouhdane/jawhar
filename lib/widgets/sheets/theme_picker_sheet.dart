import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';

// ─── Theme Picker Sheet ───

class ThemePickerSheet extends StatelessWidget {
  final VoidCallback onClose;

  const ThemePickerSheet({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final l = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.only(top: 8, left: 24, right: 24, bottom: 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Indicator
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 48,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.sheetDragHandle,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.t('theme_appearance'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.accentColor,
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: theme.mutedText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildThemeOption(
                    context: context,
                    theme: theme,
                    label: l.t('theme_classic'),
                    targetTheme: AppTheme.classic,
                    bgColor: Colors.white,
                    textColor: const Color(0xFF1A454E),
                    icon: LucideIcons.sparkles,
                  ),
                  const SizedBox(width: 12),
                  _buildThemeOption(
                    context: context,
                    theme: theme,
                    label: l.t('theme_warm'),
                    targetTheme: AppTheme.warm,
                    bgColor: const Color(0xFFF5F0E8),
                    textColor: const Color(0xFF1A454E),
                    icon: LucideIcons.sun,
                  ),
                  const SizedBox(width: 12),
                  _buildThemeOption(
                    context: context,
                    theme: theme,
                    label: l.t('theme_dark'),
                    targetTheme: AppTheme.dark,
                    bgColor: const Color(0xFF0A1E24),
                    textColor: const Color(0xFFD4E8EC),
                    icon: LucideIcons.moon,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // ── Fit Screen Height Toggle ──
              Container(
                decoration: BoxDecoration(
                  color: theme.pillBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: Text(
                    l.t('theme_fit_screen'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      color: theme.primaryText,
                    ),
                  ),
                  subtitle: Text(
                    l.t('theme_fit_screen_desc'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                  value: theme.fitScreenHeight,
                  onChanged: (v) => theme.setFitScreenHeight(v),
                  activeColor: theme.accentColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Manual Typography Controls ──
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Font Size Control ──
                      Expanded(
                        child: IgnorePointer(
                          ignoring: theme.fitScreenHeight,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: theme.fitScreenHeight ? 0.4 : 1.0,
                            child: _DebouncedSliderControl(
                              label: l.t('theme_font_size'),
                              initialValue: theme.quranFontSize,
                              min: 14,
                              max: 40,
                              step: 1,
                              displayFormat: (v) => v.round().toString(),
                              onChanged: (v) {
                                if (!theme.fitScreenHeight)
                                  theme.setQuranFontSize(v);
                              },
                              theme: theme,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // ── Line Height Control ──
                      Expanded(
                        child: _DebouncedSliderControl(
                          label: l.t('theme_line_spacing'),
                          initialValue: theme.quranLineHeight,
                          min: 1.4,
                          max: 3.6,
                          step: 0.1,
                          displayFormat: (v) => v.toStringAsFixed(1),
                          onChanged: (v) {
                            theme.setQuranLineHeight(v);
                          },
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Text Alignment & Content Alignment ──
              Row(
                children: [
                  Expanded(
                    child: _AlignmentSelector<QuranTextAlign>(
                      label: l.t('theme_text_align'),
                      icon1: Icons.format_align_right,
                      icon2: Icons.format_align_center,
                      icon3: Icons.format_align_justify,
                      value1: QuranTextAlign.right,
                      value2: QuranTextAlign.center,
                      value3: QuranTextAlign.justify,
                      groupValue: theme.quranTextAlign,
                      onChanged: (v) => theme.setQuranTextAlign(v),
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _AlignmentSelector<QuranContentAlignment>(
                      label: l.t('theme_content_align'),
                      icon1: Icons.vertical_align_top,
                      icon2: Icons.vertical_align_center,
                      icon3: Icons.vertical_align_bottom,
                      value1: QuranContentAlignment.top,
                      value2: QuranContentAlignment.center,
                      value3: QuranContentAlignment.bottom,
                      groupValue: theme.contentAlignment,
                      onChanged: (v) => theme.setContentAlignment(v),
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Group 1: Overlay Typography ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.pillBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.type,
                          size: 16,
                          color: theme.accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.t('theme_overlay_typo'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DebouncedSliderControl(
                      label: l.t('theme_font_size'),
                      initialValue: theme.overlayFontSize,
                      min: 10,
                      max: 24,
                      step: 1,
                      displayFormat: (v) => v.round().toString(),
                      onChanged: (v) => theme.setOverlayFontSize(v),
                      theme: theme,
                    ),
                    const SizedBox(height: 12),
                    _DebouncedSliderControl(
                      label: l.t('theme_opacity'),
                      initialValue: theme.overlayOpacity,
                      min: 0.1,
                      max: 1.0,
                      step: 0.05,
                      displayFormat: (v) => '${(v * 100).round()}%',
                      onChanged: (v) => theme.setOverlayOpacity(v),
                      theme: theme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Group 2: Overlay Indicators ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.pillBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.layoutTemplate,
                          size: 16,
                          color: theme.accentColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.t('theme_overlay_indicators'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.t('theme_alternate_info'),
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.primaryText,
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          child: Switch.adaptive(
                            value: theme.dynamicPageInfoEnabled,
                            activeColor: theme.accentColor,
                            onChanged: (v) =>
                                theme.setDynamicPageInfoEnabled(v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.t('theme_show_juz'),
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.primaryText,
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          child: Switch.adaptive(
                            value: theme.showJuzInfo,
                            activeColor: theme.accentColor,
                            onChanged: (v) => theme.setShowHizbInfo(v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.t('theme_show_book_icon'),
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.primaryText,
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          child: Switch.adaptive(
                            value: theme.showBookIconIndicator,
                            activeColor: theme.accentColor,
                            onChanged: (v) => theme.setShowBookIconIndicator(v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Group 3: Page Shadow Effects ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.pillBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.bookOpen,
                              size: 16,
                              color: theme.accentColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l.t('theme_page_shadow'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.primaryText,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 28,
                          child: Switch.adaptive(
                            value: theme.spineEffectEnabled,
                            activeColor: theme.accentColor,
                            onChanged: (v) => theme.setSpineEffectEnabled(v),
                          ),
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 250),
                      crossFadeState: theme.spineEffectEnabled
                          ? CrossFadeState.showFirst
                          : CrossFadeState.showSecond,
                      firstChild: Column(
                        children: [
                          const SizedBox(height: 16),
                          // ── Indicator Style ──
                          SizedBox(
                            width: double.infinity,
                            child:
                                CupertinoSlidingSegmentedControl<
                                  PageIndicatorEffect
                                >(
                                  groupValue: theme.pageIndicatorEffect,
                                  backgroundColor: Colors.black.withOpacity(
                                    0.05,
                                  ),
                                  thumbColor: theme.canvasBackground,
                                  children: {
                                    PageIndicatorEffect.center: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        l.t('theme_center_spine'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              theme.pageIndicatorEffect ==
                                                  PageIndicatorEffect.center
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: theme.primaryText,
                                        ),
                                      ),
                                    ),
                                    PageIndicatorEffect.edge: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        l.t('theme_outer_edge'),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              theme.pageIndicatorEffect ==
                                                  PageIndicatorEffect.edge
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: theme.primaryText,
                                        ),
                                      ),
                                    ),
                                  },
                                  onValueChanged: (v) {
                                    if (v != null)
                                      theme.setPageIndicatorEffect(v);
                                  },
                                ),
                          ),
                          const SizedBox(height: 20),
                          _DebouncedSliderControl(
                            label: l.t('theme_intensity'),
                            initialValue: theme.spineEffectIntensity,
                            min: 0.0,
                            max: 0.20,
                            step: 0.01,
                            displayFormat: (v) => (v * 100).round().toString(),
                            onChanged: (v) => theme.setSpineEffectIntensity(v),
                            theme: theme,
                          ),
                          const SizedBox(height: 12),
                          _DebouncedSliderControl(
                            label:
                                theme.pageIndicatorEffect ==
                                    PageIndicatorEffect.center
                                ? l.t('theme_spine_width')
                                : l.t('theme_edge_width'),
                            initialValue: theme.spineEffectWidth,
                            min: 5,
                            max: 60,
                            step: 1,
                            displayFormat: (v) => '${v.round()}',
                            onChanged: (v) => theme.setSpineEffectWidth(v),
                            theme: theme,
                          ),
                          const SizedBox(height: 12),
                          _DebouncedSliderControl(
                            label:
                                theme.pageIndicatorEffect ==
                                    PageIndicatorEffect.center
                                ? l.t('theme_spine_padding')
                                : l.t('theme_edge_padding'),
                            initialValue: theme.spineEffectPadding,
                            min: 0,
                            max: 16,
                            step: 1,
                            displayFormat: (v) => '${v.round()}',
                            onChanged: (v) => theme.setSpineEffectPadding(v),
                            theme: theme,
                          ),
                        ],
                      ),
                      secondChild: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeProvider theme,
    required String label,
    required AppTheme targetTheme,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
  }) {
    final isSelected = theme.theme == targetTheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => theme.setTheme(targetTheme),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? theme.accentColor : Colors.grey.shade300,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.accentColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: textColor),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: theme.chipSelectedText,
                    ),
                  ),
                )
              else
                const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebouncedSliderControl extends StatefulWidget {
  final String label;
  final double initialValue;
  final double min;
  final double max;
  final double step;
  final String Function(double) displayFormat;
  final ValueChanged<double> onChanged;
  final ThemeProvider theme;

  const _DebouncedSliderControl({
    required this.label,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.step,
    required this.displayFormat,
    required this.onChanged,
    required this.theme,
  });

  @override
  State<_DebouncedSliderControl> createState() =>
      _DebouncedSliderControlState();
}

class _DebouncedSliderControlState extends State<_DebouncedSliderControl> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant _DebouncedSliderControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _currentValue = widget.initialValue;
    }
  }

  void _handleFinalChange(double val) {
    widget.onChanged(val);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: widget.theme.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Minus button
            GestureDetector(
              onTap: () {
                final newVal = _currentValue - widget.step;
                if (newVal >= widget.min) {
                  setState(() => _currentValue = newVal);
                  _handleFinalChange(newVal);
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.theme.chipUnselected,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.minus,
                  size: 14,
                  color: widget.theme.primaryText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Slider
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: widget.theme.sliderActive,
                  inactiveTrackColor: widget.theme.sliderInactive,
                  thumbColor: widget.theme.sliderActive,
                  overlayColor: widget.theme.sliderActive.withValues(
                    alpha: 0.15,
                  ),
                ),
                child: Slider(
                  value: _currentValue.clamp(widget.min, widget.max),
                  min: widget.min,
                  max: widget.max,
                  onChanged: (val) {
                    setState(() => _currentValue = val);
                  },
                  onChangeEnd: _handleFinalChange,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Plus button
            GestureDetector(
              onTap: () {
                final newVal = _currentValue + widget.step;
                if (newVal <= widget.max) {
                  setState(() => _currentValue = newVal);
                  _handleFinalChange(newVal);
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.theme.chipUnselected,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.plus,
                  size: 14,
                  color: widget.theme.primaryText,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Value display
            Container(
              width: 36,
              alignment: Alignment.center,
              child: Text(
                widget.displayFormat(_currentValue),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.theme.accentColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AlignmentSelector<T> extends StatelessWidget {
  final String label;
  final IconData icon1;
  final IconData icon2;
  final IconData icon3;
  final T value1;
  final T value2;
  final T value3;
  final T groupValue;
  final ValueChanged<T> onChanged;
  final ThemeProvider theme;

  const _AlignmentSelector({
    required this.label,
    required this.icon1,
    required this.icon2,
    required this.icon3,
    required this.value1,
    required this.value2,
    required this.value3,
    required this.groupValue,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.pillBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildSegment(icon1, value1),
              _buildSegment(icon2, value2),
              _buildSegment(icon3, value3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegment(IconData icon, T value) {
    final isSelected = groupValue == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.chipSelected : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected ? theme.chipSelectedText : theme.mutedText,
          ),
        ),
      ),
    );
  }
}
