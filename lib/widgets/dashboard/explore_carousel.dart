import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/data/quran_topics.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/widgets/understand/topic_carousel.dart';
import 'package:quran_app/l10n/app_localizations.dart';

/// A mixed carousel of Stories + Themes for the Dashboard's explore section.
///
/// Interleaves prophet stories and Quranic themes into a single
/// horizontal strip, giving the home screen a lightweight discovery entry
/// point without duplicating the full Understand tab.
class ExploreCarousel extends StatelessWidget {
  const ExploreCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    // Interleave stories and themes for variety
    final mixed = <QuranTopic>[];
    final maxLen = prophetStories.length > quranThemes.length
        ? prophetStories.length
        : quranThemes.length;
    for (int i = 0; i < maxLen; i++) {
      if (i < prophetStories.length) mixed.add(prophetStories[i]);
      if (i < quranThemes.length) mixed.add(quranThemes[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              Icon(LucideIcons.compass, size: 14, color: theme.secondaryText),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.dashboardExplore,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
        ),
        TopicCarousel(
          sectionTitle: '',
          topics: mixed,
          hideLabel: true,
        ),
      ],
    );
  }
}
