import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/screens/hifz/page_understanding_screen.dart';
import 'package:quran_app/theme/semantic_colors.dart';
import 'package:quran_app/theme/geist_typography.dart';
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

    final accentColor = SemanticColors.pillarUnderstand.fg(theme.isDark);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PageUnderstandingScreen(sabaqPage: sabaqPage),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(theme.radiusLg),
          border: Border.all(color: theme.dividerColor, width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Start-edge accent spine (4dp width)
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: accentColor),
            ),
            // Main Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.sparkles, size: 14, color: accentColor),
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
                  const SizedBox(height: 12),
                  // Action button: "Explore Today's Page" / "فهم الصفحة اليوم"
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.buttonDefaultBg,
                      borderRadius: BorderRadius.circular(theme.radiusMd),
                      boxShadow: theme.shadowRing,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.compass,
                          size: 14,
                          color: theme.buttonDefaultText,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isArabic
                              ? "فهم الصفحة اليوم"
                              : "Explore Today's Page",
                          style: TextStyle(
                            fontFamily: GeistTypography.primaryFontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.buttonDefaultText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
