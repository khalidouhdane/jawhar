import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/data/surah_metadata.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/utils/verse_ref_formatter.dart';

class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({super.key});

  static int _surahForPage(int page) {
    for (int i = 1; i <= 114; i++) {
      if (surahStartPages[i] > page) return i - 1;
    }
    return 114;
  }

  static SurahInfo _surahInfoForPage(int page) {
    final id = _surahForPage(page);
    return allSurahs.firstWhere((s) => s.id == id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = context.watch<ThemeProvider>();
    final localStorage = context.read<LocalStorageService>();
    final lastRead = localStorage.getLastRead();

    if (lastRead == null) {
      return const SizedBox.shrink();
    }

    final lastReadPage = lastRead.page;
    final surah = _surahInfoForPage(lastReadPage);

    final displaySurahName = VerseRefFormatter.surahName(surah.id, l10n.localeName);

    final surahStart = surah.startPage;
    final surahEnd = surah.id < 114 ? surahStartPages[surah.id + 1] - 1 : 604;
    final pagesInSurah = surahEnd - surahStart + 1;

    final progressInSurah = lastReadPage >= surahStart
        ? ((lastReadPage - surahStart + 1) / pagesInSurah).clamp(0.0, 1.0)
        : 0.0;
    final percentageText = '${(progressInSurah * 100).round()}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusXl),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.bookOpen,
                    size: 16,
                    color: theme.mutedText,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.homeContinue.toUpperCase(),
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: theme.mutedText,
                    ),
                  ),
                ],
              ),
              Text(
                '${l10n.homePage} $lastReadPage ${l10n.werdPagesOf} $pagesInSurah',
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: theme.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Progress circle (1:1 ratio, taking full height of content row)
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: progressInSurah,
                        strokeWidth: 4.5,
                        backgroundColor: theme.dividerColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.primaryText,
                        ),
                      ),
                    ),
                    Text(
                      percentageText,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Details Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displaySurahName,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        final nav = context.read<NavigationProvider>();
                        nav.enterReadingView();
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReadingScreen(initialPage: lastReadPage),
                              ),
                            )
                            .then((_) => nav.exitReadingView());
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.foregroundColor,
                          borderRadius: BorderRadius.circular(theme.radiusLg),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.bookOpen,
                              size: 16,
                              color: theme.scaffoldBackground,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.actionResume,
                              style: TextStyle(
                                fontFamily: GeistTypography.primaryFontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.scaffoldBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
