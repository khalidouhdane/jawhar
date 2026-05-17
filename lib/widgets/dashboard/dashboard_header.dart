import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';

class DashboardHeader extends StatelessWidget {
  final VoidCallback onAvatarTap;

  const DashboardHeader({super.key, required this.onAvatarTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final profileProvider = context.watch<HifzProfileProvider>();
    final hasProfile = profileProvider.hasActiveProfile;
    final name = hasProfile ? profileProvider.activeProfile!.name : '';
    // Use the first letter of the name if available, else standard icon
    final initial = name.isNotEmpty ? name.trim()[0].toUpperCase() : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo
          Text(
            'jawhar',
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
              color: theme.primaryText,
            ),
          ),
          
          // Avatar / Settings
          GestureDetector(
            onTap: onAvatarTap,
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
    );
  }
}
