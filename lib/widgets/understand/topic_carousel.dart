import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/data/quran_topics.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/screens/topic_detail_screen.dart';
import 'package:quran_app/l10n/app_localizations.dart';

/// A horizontal-scrolling section of topic/story cards.
///
/// Cards bleed past the screen edge, encouraging the user to swipe.
/// Tapping a card opens a full-screen detail page for that topic.
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

  void _openTopicDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicDetailScreen(topic: topic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.of(context)!.localeName == 'ar';
    return SizedBox(
      width: 150,
      child: Material(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusXl),
        child: InkWell(
          onTap: () => _openTopicDetail(context),
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
