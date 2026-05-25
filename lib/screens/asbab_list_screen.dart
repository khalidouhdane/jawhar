import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/data/surah_metadata.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/services/asbab_nuzul_service.dart';
import 'package:quran_app/screens/asbab_detail_screen.dart';
import 'package:quran_app/theme/geist_tokens.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/utils/verse_ref_formatter.dart';
import 'package:quran_app/widgets/directional_icon.dart';

/// A full-screen scrollable list displaying all asbab al-nuzul entries for a surah.
///
/// Each item displays the verse reference, the original Arabic verse text,
/// a snippet of the reason narrative, and a link to view the full detailed story.
class AsbabListScreen extends StatelessWidget {
  final SurahInfo surah;
  final List<AsbabNuzulEntry> entries;

  const AsbabListScreen({
    super.key,
    required this.surah,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';

    final surahName = isArabic ? surah.nameArabic : surah.nameSimple;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: DirectionalIcon(
            icon: LucideIcons.arrowLeft,
            color: theme.primaryText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$surahName — ${l10n.undSurahReasonsOfRevelation}',
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final verseRef = entry.ayahs.length == 1
                    ? l10n.undSurahVerse(entry.ayahs.first)
                    : l10n.undSurahVersesRange(
                        entry.ayahs.first,
                        entry.ayahs.last,
                      );

                // Join Arabic verse texts with end symbols
                final versesArabic = entry.ayahs
                    .map(
                      (a) =>
                          '${quran.getVerse(surah.id, a)} ﴿${VerseRefFormatter.delocalizeNumbers(quran.getVerseEndSymbol(a))}﴾',
                    )
                    .join(' ');

                final mainOccasion = entry.occasions.isNotEmpty
                    ? entry.occasions.first
                    : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(GeistTokens.radiusLg),
                    border: Border.all(color: theme.dividerColor),
                    boxShadow: theme.shadowCard,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(GeistTokens.radiusLg),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AsbabDetailScreen(entry: entry, surah: surah),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Verse number ref
                        Text(
                          verseRef,
                          style: TextStyle(
                            fontFamily: GeistTypography.primaryFontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: theme.accentColor,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Arabic verse snippet
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.isDark
                                ? theme.accentColor.withValues(alpha: 0.02)
                                : theme.accentColor.withValues(alpha: 0.01),
                            borderRadius: BorderRadius.circular(
                              GeistTokens.radiusMd,
                            ),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              versesArabic,
                              style: GoogleFonts.amiri(
                                fontSize: 16,
                                height: 1.8,
                                color: theme.primaryText,
                              ),
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Occasion snippet
                        if (mainOccasion.isNotEmpty) ...[
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              mainOccasion,
                              style: GoogleFonts.amiri(
                                fontSize: 14,
                                height: 1.6,
                                color: theme.secondaryText,
                              ),
                              textAlign: TextAlign.right,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Actions row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              l10n.asbabReadFull,
                              style: TextStyle(
                                fontFamily: GeistTypography.primaryFontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.accentColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            DirectionalIcon(
                              icon: LucideIcons.arrowRight,
                              size: 14,
                              color: theme.accentColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
