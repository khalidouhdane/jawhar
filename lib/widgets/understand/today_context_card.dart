import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_app/data/surah_metadata.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/plan_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/widgets/context/tafsir_sheet.dart'
    show showTafsirSheet;
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/l10n/app_localizations.dart';

/// Contextual header card shown at the top of the Understand tab
/// when the user has an active hifz plan with a sabaq page.
///
/// Surfaces the surah context for today's memorization assignment
/// and provides quick access to tafsir, translation, and the reading screen.
class TodayContextCard extends StatelessWidget {
  const TodayContextCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = context.watch<ThemeProvider>();
    final plan = context.watch<PlanProvider>();
    final todayPlan = plan.todayPlan;

    if (todayPlan == null || todayPlan.sabaqPage <= 0) {
      return const SizedBox.shrink();
    }

    final sabaqPage = todayPlan.sabaqPage;

    // Find which surah this page belongs to
    final rewaya = context.watch<QuranReadingProvider>().selectedRewaya;
    final surahs = getAllSurahs(rewaya: rewaya);
    SurahInfo? surah;
    for (int i = surahs.length - 1; i >= 0; i--) {
      if (surahs[i].startPage <= sabaqPage) {
        surah = surahs[i];
        break;
      }
    }

    // Use invertedForeground for text on the dark hero card
    final heroText = theme.invertedForeground;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.isDark ? const Color(0xFF1A1A1A) : const Color(0xFF171717),
        borderRadius: BorderRadius.circular(theme.radiusLg),
        boxShadow: theme.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: heroText.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(theme.radiusLg),
                ),
                child: Center(
                  child: Icon(LucideIcons.sparkles, size: 16, color: heroText),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.todaysStudyContext,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: heroText,
                      ),
                    ),
                    Text(
                      l10n.yourSabaqIsOnPage(sabaqPage),
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 12,
                        color: heroText.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Surah info
          if (surah != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: heroText.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(theme.radiusLg),
              ),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Text(
                      surah.nameArabic,
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: heroText.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.surahInfoLabel(
                        surah.nameSimple,
                        surah.isMeccan
                            ? l10n.revelationMeccan
                            : l10n.revelationMedinan,
                        surah.versesCount,
                      ),
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 12,
                        color: heroText.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action chips
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionChip(
                  label: l10n.readingTafsir,
                  icon: LucideIcons.bookMarked,
                  onTap: () => _openTafsir(context, sabaqPage),
                  theme: theme,
                  heroText: heroText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionChip(
                  label: l10n.readingRead,
                  icon: LucideIcons.bookOpen,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReadingScreen(initialPage: sabaqPage),
                    ),
                  ),
                  theme: theme,
                  heroText: heroText,
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openTafsir(BuildContext context, int sabaqPage) {
    final rewaya = context.read<QuranReadingProvider>().selectedRewaya;
    final surahs = getAllSurahs(rewaya: rewaya);
    SurahInfo? surah;
    for (int i = surahs.length - 1; i >= 0; i--) {
      if (surahs[i].startPage <= sabaqPage) {
        surah = surahs[i];
        break;
      }
    }
    final verseKey = '${surah?.id ?? 1}:1';
    showTafsirSheet(context, verseKey: verseKey, surahName: surah?.nameSimple);
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final ThemeProvider theme;
  final Color heroText;
  final bool isPrimary;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.theme,
    required this.heroText,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary
          ? theme.scaffoldBackground
          : heroText.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isPrimary
                    ? theme.primaryText
                    : heroText.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? theme.primaryText
                      : heroText.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
