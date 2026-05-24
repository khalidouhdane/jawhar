import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/widgets/sheets/profile_switcher_sheet.dart';

class AppHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? action;
  final VoidCallback? onAvatarTap;

  const AppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.action,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final profileProvider = context.watch<HifzProfileProvider>();
    final hasProfile = profileProvider.hasActiveProfile;
    final name = hasProfile ? profileProvider.activeProfile!.name : '';
    // Use the first letter of the name if available, else standard icon
    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : null;

    final l10n = AppLocalizations.of(context)!;
    final isBrand = title == null || title!.toLowerCase() == 'jawhar';
    final displayText = title ?? l10n.appName;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Area
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayText,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 24, // Consistent unified size
                  fontWeight: isBrand ? FontWeight.w800 : FontWeight.w700,
                  letterSpacing: isBrand ? -1.0 : -0.5,
                  color: theme.primaryText,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.secondaryText,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Actions Area
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (action != null) ...[action!, const SizedBox(width: 12)],
            // Avatar
            GestureDetector(
              onTap:
                  onAvatarTap ??
                  () {
                    ProfileSwitcherSheet.show(context);
                  },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.cardColor,
                  border: Border.all(color: theme.dividerColor, width: 1),
                ),
                child: Center(
                  child: initial != null
                      ? Text(
                          initial,
                          style: TextStyle(
                            fontFamily: GeistTypography.primaryFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.primaryText,
                          ),
                        )
                      : Icon(
                          LucideIcons.user,
                          size: 16,
                          color: theme.secondaryText,
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
