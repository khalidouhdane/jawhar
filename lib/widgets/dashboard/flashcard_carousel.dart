import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/flashcard_models.dart';
import 'package:quran_app/providers/flashcard_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/hifz/flashcard_review_screen.dart';
import 'package:quran_app/theme/geist_typography.dart';

/// Horizontal scrolling flashcard category strip for the Dashboard.
///
/// Shows each card type as a compact Geist-compliant card — monochromatic
/// with neutral icon circles and subtle due-count pills.
class FlashcardCarousel extends StatelessWidget {
  const FlashcardCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final fc = context.watch<FlashcardProvider>();
    final totalDue = fc.dueCardCount;

    // Build ordered list of categories
    final categories = <_CardCategory>[
      if (totalDue > 0)
        _CardCategory(
          icon: LucideIcons.shuffle,
          title: 'Mixed Review',
          titleAr: 'مراجعة شاملة',
          dueCount: totalDue,
          isHero: true,
          type: null,
        ),
      _CardCategory(
        icon: LucideIcons.skipForward,
        title: 'Next Verse',
        titleAr: 'ما بعدها؟',
        dueCount: fc.getDueCountForType(FlashcardType.nextVerse),
        type: FlashcardType.nextVerse,
      ),
      _CardCategory(
        icon: LucideIcons.skipBack,
        title: 'Previous Verse',
        titleAr: 'ما قبلها؟',
        dueCount: fc.getDueCountForType(FlashcardType.previousVerse),
        type: FlashcardType.previousVerse,
      ),
      _CardCategory(
        icon: LucideIcons.pencil,
        title: 'Complete It',
        titleAr: 'أكمل الآية',
        dueCount: fc.getDueCountForType(FlashcardType.verseCompletion),
        type: FlashcardType.verseCompletion,
      ),
      _CardCategory(
        icon: LucideIcons.search,
        title: 'Surah Detective',
        titleAr: 'من أي سورة؟',
        dueCount: fc.getDueCountForType(FlashcardType.surahDetective),
        type: FlashcardType.surahDetective,
      ),
      _CardCategory(
        icon: LucideIcons.link,
        title: 'Sequence',
        titleAr: 'رتب الآيات',
        dueCount: fc.getDueCountForType(FlashcardType.connectSequence),
        type: FlashcardType.connectSequence,
      ),
      _CardCategory(
        icon: LucideIcons.swords,
        title: 'Mutashabihat',
        titleAr: 'المتشابهات',
        dueCount: fc.getDueCountForType(FlashcardType.mutashabihatDuel),
        type: FlashcardType.mutashabihatDuel,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              Icon(LucideIcons.layers, size: 14, color: theme.secondaryText),
              const SizedBox(width: 6),
              Text(
                'Flashcards',
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
              if (totalDue > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$totalDue due',
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.secondaryText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16, right: 12),
            itemCount: categories.length,
            separatorBuilder: (ctx, idx) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final cat = categories[index];
              return _FlashcardCategoryCard(category: cat, theme: theme);
            },
          ),
        ),
      ],
    );
  }
}

class _CardCategory {
  final IconData icon;
  final String title;
  final String titleAr;
  final int dueCount;
  final bool isHero;
  final FlashcardType? type;

  const _CardCategory({
    required this.icon,
    required this.title,
    required this.titleAr,
    required this.dueCount,
    this.isHero = false,
    required this.type,
  });
}

class _FlashcardCategoryCard extends StatelessWidget {
  final _CardCategory category;
  final ThemeProvider theme;

  const _FlashcardCategoryCard({
    required this.category,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final hasDue = category.dueCount > 0;
    final iconBg = theme.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return SizedBox(
      width: category.isHero ? 160 : 140,
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusXl),
        child: InkWell(
          onTap: hasDue
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FlashcardReviewScreen(
                        filterType: category.type,
                      ),
                    ),
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(theme.radiusXl),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(theme.radiusXl),
              border: Border.all(color: theme.dividerColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon circle
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(theme.radiusLg),
                      ),
                      child: Center(
                        child: Icon(category.icon, size: 14, color: theme.secondaryText),
                      ),
                    ),
                    const Spacer(),
                    if (hasDue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${category.dueCount}',
                          style: TextStyle(
                            fontFamily: GeistTypography.primaryFontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.secondaryText,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Title
                Text(
                  category.title,
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                ExcludeSemantics(
                  child: Text(
                    category.titleAr,
                    style: GoogleFonts.amiri(
                      fontSize: 12,
                      color: theme.secondaryText,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
