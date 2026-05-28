import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';

/// Bottom navigation bar — Figma "V4 Top Accent" variant.
///
/// Spec (from Figma node `2316:5587`):
/// - 390×70 frame, HORIZONTAL auto-layout, 16px horizontal padding
/// - Background: `accents 1` (#111111 dark / #FAFAFA light)
/// - Top border: `accents 2` (#333333 dark / #EAEAEA light), 1px
/// - 5 tabs: Home / Read / Understand / Practice / Profile
/// - Each tab: 59×70 vertical column, center-aligned
/// - Active: 2px accent line (geist foreground) + icon + label in foreground
/// - Inactive: transparent accent line + icon + label in accents 3
/// - Icons: house, book-open, lightbulb, puzzle, user-round (22×22, stroke 2px)
/// - Labels: Geist 12px Regular
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  // Tab order: Home / Read / Understand / Practice / Profile
  static const _icons = [
    LucideIcons.home,
    LucideIcons.bookOpen,
    LucideIcons.lightbulb,
    LucideIcons.puzzle,
    LucideIcons.user,
  ];

  String _label(AppLocalizations l, int i) {
    switch (i) {
      case 0:
        return l.navHome;
      case 1:
        return l.navRead;
      case 2:
        return l.navUnderstand;
      case 3:
        return l.navPractice;
      case 4:
        return l.navProfile;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final theme = context.watch<ThemeProvider>();
    final l = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 768;

    Widget navContent = Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(_icons.length, (i) {
        final isActive = nav.currentIndex == i;
        final color = isActive ? theme.foregroundColor : theme.accent3;

        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => nav.setTab(i),
            child: SizedBox(
              height: 70,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // ── Accent line (2px) ──
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    height: 2,
                    width: isActive ? 19 : 24,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.foregroundColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  // ── Icon (22×22, stroke 2px) ──
                  Icon(_icons[i], size: 22, color: color),
                  const SizedBox(height: 10),
                  // ── Label (Geist 12px Regular) ──
                  Text(
                    _label(l, i),
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: color,
                      height: 1.33,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );

    if (isWide) {
      navContent = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: navContent,
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.systemOverlayStyle,
      child: Container(
        height: 70 + (bottomPadding > 0 ? bottomPadding : 0),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: bottomPadding > 0 ? bottomPadding : 0,
        ),
        decoration: BoxDecoration(
          color: theme.navBarBackground,
          border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
        ),
        child: navContent,
      ),
    );
  }
}
