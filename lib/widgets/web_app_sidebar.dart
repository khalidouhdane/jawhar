import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';

class WebAppSidebar extends StatelessWidget {
  const WebAppSidebar({super.key});

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
    final profile = context.watch<HifzProfileProvider>();
    final l = AppLocalizations.of(context)!;

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: theme.navBarBackground,
        border: Border(right: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Branding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/diamond_logo.png',
                  width: 24,
                  height: 24,
                  filterQuality: FilterQuality.high,
                ),
                const SizedBox(width: 12),
                Text(
                  'Jawhar',
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: theme.foregroundColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 16),
          // Menu Items
          Expanded(
            child: ListView.builder(
              itemCount: _icons.length,
              itemBuilder: (context, i) {
                final isActive = nav.currentIndex == i;
                final color = isActive ? theme.accentColor : theme.accent3;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => nav.setTab(i),
                  child: Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.accentColor.withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 3,
                          height: isActive ? 24 : 0,
                          decoration: BoxDecoration(
                            color: theme.accentColor,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(_icons[i], size: 20, color: color),
                        const SizedBox(width: 16),
                        Text(
                          _label(l, i),
                          style: TextStyle(
                            fontFamily: GeistTypography.primaryFontFamily,
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Profile switcher footer
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.accentColor.withValues(alpha: 0.1),
                  child: Icon(
                    LucideIcons.user,
                    color: theme.accentColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    profile.activeProfile?.name ?? 'Profile',
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.foregroundColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
