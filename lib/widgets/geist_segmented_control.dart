import 'package:flutter/material.dart';
import 'package:quran_app/theme/geist_tokens.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/providers/theme_provider.dart';

/// A Vercel/Geist inspired segmented control (pill tabs).
/// Uses a fluid sliding animation for the active selection.
class GeistSegmentedControl<T> extends StatelessWidget {
  final Map<T, String> tabs;
  final T selectedTab;
  final ValueChanged<T> onTabChanged;
  final ThemeProvider theme;

  const GeistSegmentedControl({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onTabChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final keys = tabs.keys.toList();
    final selectedIndex = keys.indexOf(selectedTab);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.isDark
            ? GeistTokens.darkSubtle
            : GeistTokens.lightSubtle, // Very subtle background (Gray-50/Gray-900)
        borderRadius: BorderRadius.circular(GeistTokens.radiusXl),
        boxShadow: [
          BoxShadow(
            color: theme.isDark ? const Color(0x33000000) : const Color(0x0A000000),
            spreadRadius: 1,
            blurRadius: 0,
          ),
        ], // Subtle inner-ring-like shadow
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / keys.length;
          final isRtl = Directionality.of(context) == TextDirection.rtl;

          return SizedBox(
            height: 40, // Fixed comfortable height (40 + 8 padding = 48dp minimum touch target)
            child: Stack(
              children: [
                // ── Animated Selection Pill ──
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  left: isRtl ? null : selectedIndex * tabWidth,
                  right: isRtl ? selectedIndex * tabWidth : null,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.primaryText, // Inverted appearance (dark in light mode, white in dark mode)
                      borderRadius: BorderRadius.circular(GeistTokens.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: theme.isDark
                              ? const Color(0x40000000)
                              : const Color(0x1A000000),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                        BoxShadow(
                          color: theme.isDark
                              ? const Color(0x1FFFFFFF)
                              : const Color(0x14000000),
                          spreadRadius: 1,
                          blurRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Tab Labels ──
                Row(
                  children: keys.map((key) {
                    final isActive = key == selectedTab;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTabChanged(key),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 13,
                              fontWeight: isActive
                                  ? GeistTypography.semiBold
                                  : GeistTypography.medium,
                              color: isActive
                                  ? theme.scaffoldBackground
                                  : theme.mutedText,
                            ),
                            child: Text(tabs[key]!),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
