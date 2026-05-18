import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/l10n/app_localizations.dart';

class UnderstandingSpotlight extends StatelessWidget {
  final int sabaqPage;

  const UnderstandingSpotlight({super.key, required this.sabaqPage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = context.watch<ThemeProvider>();

    if (sabaqPage <= 0 || sabaqPage > 604) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReadingScreen(initialPage: sabaqPage),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(theme.radiusLg),
          boxShadow: theme.shadowCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.sparkles, size: 14, color: theme.accentColor),
                const SizedBox(width: 6),
                Text(
                  l10n.understandingContext,
                  style: theme.textCaption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.understandingContextDesc(sabaqPage),
              style: theme.textCaption.copyWith(
                color: theme.secondaryText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
