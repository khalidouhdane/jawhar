import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

// ─── Theme Picker Sheet ───

class ThemePickerSheet extends StatelessWidget {
  final VoidCallback onClose;

  const ThemePickerSheet({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

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
                    'Appearance',
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
                    label: 'Classic',
                    targetTheme: AppTheme.classic,
                    bgColor: Colors.white,
                    textColor: const Color(0xFF1A454E),
                    icon: LucideIcons.sparkles,
                  ),
                  const SizedBox(width: 12),
                  _buildThemeOption(
                    context: context,
                    theme: theme,
                    label: 'Warm',
                    targetTheme: AppTheme.warm,
                    bgColor: const Color(0xFFF5F0E8),
                    textColor: const Color(0xFF1A454E),
                    icon: LucideIcons.sun,
                  ),
                  const SizedBox(width: 12),
                  _buildThemeOption(
                    context: context,
                    theme: theme,
                    label: 'Dark',
                    targetTheme: AppTheme.dark,
                    bgColor: const Color(0xFF0A1E24),
                    textColor: const Color(0xFFD4E8EC),
                    icon: LucideIcons.moon,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Font Size Control ──
              _DebouncedSliderControl(
                label: 'Font Size',
                initialValue: theme.quranFontSize,
                min: 14,
                max: 40,
                step: 1,
                displayFormat: (v) => v.round().toString(),
                onChanged: (v) => theme.setQuranFontSize(v),
                theme: theme,
              ),
              const SizedBox(height: 20),

              // ── Line Height Control ──
              _DebouncedSliderControl(
                label: 'Line Spacing',
                initialValue: theme.quranLineHeight,
                min: 1.4,
                max: 3.6,
                step: 0.1,
                displayFormat: (v) => v.toStringAsFixed(1),
                onChanged: (v) => theme.setQuranLineHeight(v),
                theme: theme,
              ),
              const SizedBox(height: 28),

              // ── Page Edge Effect ──
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
                              'Page Layout & Effects',
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
                                  backgroundColor: Colors.black.withValues(
                                    alpha: 0.05,
                                  ),
                                  thumbColor: theme.canvasBackground,
                                  children: {
                                    PageIndicatorEffect.center: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Text(
                                        'Center Spine',
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
                                        'Outer Edge',
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
                          // ── Dynamic Info Toggle ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Dynamic Page Info',
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
                          // ── Book Icon Toggle ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Show Book Icon Indicator',
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
                                  onChanged: (v) =>
                                      theme.setShowBookIconIndicator(v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Divider(color: Colors.black.withValues(alpha: 0.05)),
                          const SizedBox(height: 16),
                          _DebouncedSliderControl(
                            label: 'Intensity',
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
                            label: 'Edge Width',
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
                            label: 'Edge Padding',
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
