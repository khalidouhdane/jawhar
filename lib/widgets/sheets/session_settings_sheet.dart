import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/session_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/theme/geist_typography.dart';

/// Bottom sheet for session configuration settings (Guided vs Free Mode).
class SessionSettingsSheet extends StatelessWidget {
  const SessionSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final session = context.watch<SessionProvider>();
    final storage = context.read<LocalStorageService>();
    final l = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.sheetDragHandle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  Icon(LucideIcons.sliders, size: 20, color: theme.accentColor),
                  const SizedBox(width: 10),
                  Text(
                    'Session Settings',
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Configure how you want to track your memorization during this session.', // Need to check if there is a localization for this, or use fallback
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 13,
                    color: theme.secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Session Style ──
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Session Style',
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryText,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.pillBackground,
                  borderRadius: BorderRadius.circular(theme.radiusLg),
                ),
                child: Row(
                  children: [
                    _modeChip(
                      theme,
                      label: l?.overlayGuidedMode ?? 'Guided Mode',
                      icon: LucideIcons.bookOpen,
                      selected: session.isGuidedMode,
                      onTap: () {
                        if (!session.hasRecipes) return;
                        session.setGuidedMode(true);
                        storage.saveSessionGuidedMode(true);
                      },
                      disabled: !session.hasRecipes,
                    ),
                    const SizedBox(width: 4),
                    _modeChip(
                      theme,
                      label: l?.overlayFreeMode ?? 'Free Mode',
                      icon: LucideIcons.move,
                      selected: !session.isGuidedMode,
                      onTap: () {
                        session.setGuidedMode(false);
                        storage.saveSessionGuidedMode(false);
                      },
                      disabled: false,
                    ),
                  ],
                ),
              ),

              if (!session.hasRecipes && session.isGuidedMode)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Guided mode requires a generated plan with recipes.',
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 12,
                      color: theme.mutedText,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeChip(
    ThemeProvider theme, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required bool disabled,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? theme.accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(theme.radiusMd),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: disabled
                    ? theme.mutedText
                    : selected
                    ? theme.scaffoldBackground
                    : theme.secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: disabled
                      ? theme.mutedText
                      : selected
                      ? theme.scaffoldBackground
                      : theme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
