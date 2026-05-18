import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/data/quran_topics.dart';
import 'package:quran_app/data/surah_metadata.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/widgets/understand/surah_detail_sheet.dart';
import 'package:quran_app/l10n/app_localizations.dart';

/// A horizontal-scrolling section of topic/story cards.
///
/// Cards bleed past the screen edge, encouraging the user to swipe.
/// Tapping a card opens a sheet listing the surahs related to that topic.
class TopicCarousel extends StatelessWidget {
  final String sectionTitle;
  final List<QuranTopic> topics;
  final bool hideLabel;

  const TopicCarousel({
    super.key,
    required this.sectionTitle,
    required this.topics,
    this.hideLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        if (!hideLabel)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              sectionTitle,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
          ),

        // Horizontal scroll — no padding end so last card peeks
        SizedBox(
          height: 144,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20, right: 12),
            itemCount: topics.length,
            separatorBuilder: (context2, index2) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _TopicCard(topic: topics[index], theme: theme);
            },
          ),
        ),
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  final QuranTopic topic;
  final ThemeProvider theme;

  const _TopicCard({required this.topic, required this.theme});

  void _showRelatedSurahs(BuildContext context) {
    final rewaya = context.read<QuranReadingProvider>().selectedRewaya;
    final surahs = getAllSurahs(rewaya: rewaya);
    final relatedSurahs = topic.surahIds
        .where((id) => id >= 1 && id <= 114)
        .map((id) => surahs[id - 1])
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (ctx, scrollController) {
          final l10n = AppLocalizations.of(ctx)!;
          final isArabic = l10n.localeName == 'ar';
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackground,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
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

                // Topic header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(
                            theme.radiusLg + 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            topic.icon,
                            size: 20,
                            color: theme.secondaryText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (!isArabic) ...[
                        ExcludeSemantics(
                          child: Text(
                            topic.titleAr,
                            style: GoogleFonts.amiri(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: theme.secondaryText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        isArabic ? topic.titleAr : topic.title,
                        style: isArabic
                            ? GoogleFonts.amiri(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: theme.primaryText,
                              )
                            : TextStyle(
                                fontFamily: GeistTypography.primaryFontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.primaryText,
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArabic ? topic.subtitleAr : topic.subtitle,
                        style: isArabic
                            ? GoogleFonts.amiri(
                                fontSize: 16,
                                color: theme.secondaryText,
                              )
                            : TextStyle(
                                fontFamily: GeistTypography.primaryFontFamily,
                                fontSize: 13,
                                color: theme.secondaryText,
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(
                          context,
                        )!.topicSurahsCount(relatedSurahs.length),
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 12,
                          color: theme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                Divider(
                  height: 1,
                  color: theme.dividerColor.withValues(alpha: 0.5),
                ),

                // Related surah list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: relatedSurahs.length,
                    itemBuilder: (ctx, i) {
                      final surah = relatedSurahs[i];
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => DraggableScrollableSheet(
                                initialChildSize: 0.65,
                                maxChildSize: 0.95,
                                minChildSize: 0.3,
                                builder: (sheetCtx, sheetController) =>
                                    SurahDetailSheet(surah: surah),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(theme.radiusLg),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 4,
                            ),
                            child: Row(
                              children: [
                                // Surah number
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: theme.isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.black.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(
                                      theme.radiusLg,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${surah.id}',
                                      style: TextStyle(
                                        fontFamily:
                                            GeistTypography.primaryFontFamily,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: theme.secondaryText,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isArabic ? surah.nameArabic : surah.nameSimple,
                                        style: TextStyle(
                                          fontFamily: isArabic
                                              ? GoogleFonts.amiri().fontFamily
                                              : GeistTypography.primaryFontFamily,
                                          fontSize: isArabic ? 18 : 15,
                                          fontWeight: FontWeight.w600,
                                          color: theme.primaryText,
                                        ),
                                      ),
                                      Text(
                                        '${surah.isMeccan ? l10n.meccan : l10n.medinan} · ${l10n.undVersesCount(surah.versesCount)}',
                                        style: TextStyle(
                                          fontFamily:
                                              GeistTypography.primaryFontFamily,
                                          fontSize: 12,
                                          color: theme.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ExcludeSemantics(
                                  child: Text(
                                    surah.nameArabic,
                                    style: GoogleFonts.amiri(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: theme.secondaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusXl),
        child: InkWell(
          onTap: () => _showRelatedSurahs(context),
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
                // Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(theme.radiusLg),
                  ),
                  child: Center(
                    child: Icon(
                      topic.icon,
                      size: 16,
                      color: theme.secondaryText,
                    ),
                  ),
                ),
                const Spacer(),
                // Title
                Text(
                  isArabic ? topic.titleAr : topic.title,
                  style: isArabic
                      ? GoogleFonts.amiri(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText,
                          height: 1.2,
                        )
                      : TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText,
                          height: 1.2,
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                // Secondary text / subtitle
                if (AppLocalizations.of(context)!.localeName != 'ar') ...[
                  ExcludeSemantics(
                    child: Text(
                      topic.titleAr,
                      style: GoogleFonts.amiri(
                        fontSize: 13,
                        color: theme.secondaryText,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ] else ...[
                  Text(
                    topic.subtitleAr,
                    style: GoogleFonts.amiri(
                      fontSize: 12,
                      color: theme.secondaryText,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                // Surah count pill
                Text(
                  AppLocalizations.of(
                    context,
                  )!.topicSurahsCount(topic.surahIds.length),
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 11,
                    color: theme.mutedText,
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
