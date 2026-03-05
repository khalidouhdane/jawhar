import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({super.key});

  static const _icons = [
    LucideIcons.home,
    LucideIcons.bookOpen,
    LucideIcons.headphones,
    LucideIcons.brain,
    LucideIcons.user,
  ];

  static const _labelKeys = [
    'nav_home',
    'nav_read',
    'nav_audio',
    'nav_hifz',
    'nav_profile',
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final theme = context.watch<ThemeProvider>();
    final l = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.canvasBackground,
        border: Border(
          top: BorderSide(
            color: theme.mutedText.withValues(alpha: 0.1),
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding > 0 ? bottomPadding : 8),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_icons.length, (i) {
            final isActive = nav.currentIndex == i;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => nav.setTab(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.accentColor.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _icons[i],
                        size: 20,
                        color: isActive
                            ? theme.accentColor
                            : theme.mutedText.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.t(_labelKeys[i]),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isActive
                            ? theme.accentColor
                            : theme.mutedText.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
