import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_app/data/surah_metadata.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/context_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/services/asbab_nuzul_service.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/widgets/context/surah_intro_card.dart';
import 'package:quran_app/widgets/geist_button.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/theme/semantic_colors.dart';

/// Bottom sheet showing surah detail: intro, themes, asbab al-nuzul.
///
/// Uses curated [SurahIntroData] when available (24 surahs),
/// otherwise shows basic info + asbab entries from the dataset.
class SurahDetailSheet extends StatelessWidget {
  final SurahInfo surah;

  const SurahDetailSheet({super.key, required this.surah});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final contextProvider = context.watch<ContextProvider>();
    final rewaya = context.read<QuranReadingProvider>().selectedRewaya;
    final asbabService = contextProvider.asbabService;
    final intro = surahIntroductions[surah.id];
    final asbabEntries = asbabService.isLoaded
        ? asbabService.getEntriesForSurah(surah.id)
        : <AsbabNuzulEntry>[];

    final isMeccan = surah.isMeccan;
    final displayVersesCount = getVersesCount(surah.id, rewaya: rewaya);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Center(
                    child: Column(
                      children: [
                        ExcludeSemantics(
                          child: Text(
                            surah.nameArabic,
                            style: GoogleFonts.amiri(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: theme.accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          surah.nameSimple,
                          style: TextStyle(
                            fontFamily: GeistTypography.primaryFontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                        ),
                        if (intro != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            intro.meaningOfName,
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 13,
                              color: theme.secondaryText,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Badge(
                              label: surah.revelationType,
                              icon: isMeccan
                                  ? Icons.mosque_outlined
                                  : Icons.location_city_outlined,
                              color: isMeccan
                                  ? SemanticColors.practiceAmber.fg(
                                      theme.isDark,
                                    )
                                  : SemanticColors.practiceEmerald.fg(
                                      theme.isDark,
                                    ),
                              theme: theme,
                            ),
                            const SizedBox(width: 8),
                            _Badge(
                              label: '$displayVersesCount verses',
                              icon: Icons.format_list_numbered,
                              color: theme.accentColor,
                              theme: theme,
                            ),
                            const SizedBox(width: 8),
                            _Badge(
                              label: 'Page ${surah.startPage}',
                              icon: LucideIcons.bookOpen,
                              color: theme.secondaryText,
                              theme: theme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Summary ──
                  if (intro != null) ...[
                    _SectionTitle(title: 'Overview', theme: theme),
                    const SizedBox(height: 8),
                    Text(
                      intro.summary,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 14,
                        height: 1.6,
                        color: theme.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Key Themes ──
                  if (intro != null && intro.keyThemes.isNotEmpty) ...[
                    _SectionTitle(title: 'Key Themes', theme: theme),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: intro.keyThemes.map((t) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: theme.pillBackground,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: theme.secondaryText,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Asbab al-Nuzul ──
                  if (asbabEntries.isNotEmpty) ...[
                    _SectionTitle(
                      title: 'Reasons of Revelation',
                      subtitle: '${asbabEntries.length} entries',
                      theme: theme,
                    ),
                    const SizedBox(height: 8),
                    ...asbabEntries.take(5).map((entry) {
                      final verseRef = entry.ayahs.length == 1
                          ? 'Verse ${entry.ayahs.first}'
                          : 'Verses ${entry.ayahs.first}–${entry.ayahs.last}';
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              verseRef,
                              style: TextStyle(
                                fontFamily: GeistTypography.primaryFontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.accentColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...entry.occasions.map(
                              (o) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  o,
                                  style: TextStyle(
                                    fontFamily:
                                        GeistTypography.primaryFontFamily,
                                    fontSize: 13,
                                    height: 1.5,
                                    color: theme.secondaryText,
                                  ),
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (asbabEntries.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+ ${asbabEntries.length - 5} more entries',
                          style: TextStyle(
                            fontFamily: GeistTypography.primaryFontFamily,
                            fontSize: 12,
                            color: theme.mutedText,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  // ── No data fallback ──
                  if (intro == null && asbabEntries.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.bookMarked,
                            size: 24,
                            color: theme.mutedText,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Detailed introduction coming soon.\nOpen the surah to explore translations and tafsir.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 13,
                              color: theme.secondaryText,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Read Surah button ──
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: GeistButton(
                      label: 'Read Surah',
                      type: GeistButtonType.primary,
                      size: GeistButtonSize.large,
                      onPressed: () {
                        Navigator.pop(context); // Close sheet
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ReadingScreen(initialPage: surah.startPage),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final ThemeProvider theme;

  const _SectionTitle({
    required this.title,
    this.subtitle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(
            subtitle!,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 12,
              color: theme.mutedText,
            ),
          ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final ThemeProvider theme;

  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
