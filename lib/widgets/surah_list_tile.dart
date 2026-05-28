import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/utils/verse_ref_formatter.dart';

class SurahListTile extends StatelessWidget {
  final int number;
  final String nameSimple;
  final String nameArabic;
  final int versesCount;
  final VoidCallback onTap;

  const SurahListTile({
    super.key,
    required this.number,
    required this.nameSimple,
    required this.nameArabic,
    required this.versesCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = context.watch<ThemeProvider>();

    final displayName = l10n.localeName.startsWith('en')
        ? VerseRefFormatter.surahName(number, l10n.localeName)
        : nameSimple;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Surah number in decorative diamond
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: 0.785398, // 45 degrees
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.accentColor.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text(
                    '$number',
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.accentColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // English name + verse count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$versesCount ${l10n.readVerses}',
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                ],
              ),
            ),

            // Arabic name
            Text(
              nameArabic,
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
