import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
import 'package:quran_app/theme/semantic_colors.dart';

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

    // Use practiceCyan for study tab accent
    final accentColor = SemanticColors.practiceCyan.fg(theme.isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: BorderDirectional(
          start: BorderSide(
            color: accentColor,
            width: 4,
          ),
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
          end: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
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
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(theme.radiusLg),
                ),
                child: Center(
                  child: Icon(LucideIcons.sparkles, size: 16, color: accentColor),
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
                        color: theme.primaryText,
                      ),
                    ),
                    Text(
                      l10n.yourSabaqIsOnPage(sabaqPage),
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 12,
                        color: theme.secondaryText,
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
                color: theme.dividerColor.withValues(alpha: 0.2),
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
                        color: theme.primaryText,
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
                        color: theme.secondaryText,
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
                  accentColor: accentColor,
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
                  accentColor: accentColor,
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
  final Color accentColor;
  final bool isPrimary;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.theme,
    required this.accentColor,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary
          ? accentColor.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isPrimary 
                  ? accentColor.withValues(alpha: 0.3)
                  : theme.dividerColor,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: accentColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
