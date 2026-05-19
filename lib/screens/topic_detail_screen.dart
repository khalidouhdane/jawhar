import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/data/quran_topics.dart';
import 'package:quran_app/data/surah_metadata.dart';
import 'package:quran_app/data/topic_content.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/theme/geist_tokens.dart';
import 'package:quran_app/widgets/understand/topic_section_card.dart';

/// Full-screen topic detail page showing curated narrative content,
/// per-surah perspectives, and key verses with translations.
///
/// For topics with curated content (isComplete == true), displays a rich
/// editorial experience. For uncurated topics, shows a simple surah list
/// with direct navigation to the reading screen.
class TopicDetailScreen extends StatelessWidget {
  final QuranTopic topic;

  const TopicDetailScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final content = topicContentRegistry[topic.id];

    final primaryColor = isDark ? GeistTokens.darkPrimary : GeistTokens.lightPrimary;
    final secondaryColor = isDark ? GeistTokens.darkSecondary : GeistTokens.lightSecondary;
    final scaffoldColor = isDark ? GeistTokens.darkScaffold : GeistTokens.lightScaffold;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, size: 20, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isArabic ? topic.titleAr : topic.title,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryColor,
            letterSpacing: -0.32,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Section ──
            _buildHero(context, l10n, isArabic, isDark, primaryColor, secondaryColor),

            const SizedBox(height: 24),

            // ── Content ──
            if (content != null)
              _buildCuratedContent(context, content, l10n, isArabic, isDark, primaryColor, secondaryColor)
            else
              _buildFallbackContent(context, l10n, isArabic, isDark, primaryColor, secondaryColor),
          ],
        ),
      ),
    );
  }

  /// Hero section with icon, title, Arabic name, and surah count.
  Widget _buildHero(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    bool isDark,
    Color primaryColor,
    Color secondaryColor,
  ) {
    final borderColor = isDark ? GeistTokens.darkDivider : GeistTokens.lightDivider;

    return Column(
      children: [
        // Icon container
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: topic.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(GeistTokens.radiusXl),
            ),
            child: Icon(
              topic.icon,
              size: 24,
              color: topic.color,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Center(
          child: Text(
            isArabic ? topic.titleAr : topic.title,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: primaryColor,
              letterSpacing: -0.96,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),

        // Arabic name (show when in English mode)
        if (!isArabic)
          Center(
            child: Text(
              topic.titleAr,
              style: GoogleFonts.amiri(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),

        const SizedBox(height: 8),

        // Subtitle
        Center(
          child: Text(
            isArabic ? topic.subtitleAr : topic.subtitle,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: secondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),

        // Surah count badge
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: topic.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(GeistTokens.radiusPill),
              border: Border.all(color: borderColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              l10n.topicMentionedIn(topic.surahIds.length),
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: topic.color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Curated content: narrative + section cards.
  Widget _buildCuratedContent(
    BuildContext context,
    TopicContent content,
    AppLocalizations l10n,
    bool isArabic,
    bool isDark,
    Color primaryColor,
    Color secondaryColor,
  ) {
    final borderColor = isDark ? GeistTokens.darkDivider : GeistTokens.lightDivider;
    final allExpanded = content.sections.length <= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Overview section ──
        _sectionHeader(l10n.topicOverview, primaryColor),
        const SizedBox(height: 8),
        Text(
          isArabic ? content.narrativeAr : content.narrative,
          style: isArabic
              ? GoogleFonts.amiri(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: primaryColor,
                  height: 1.9,
                )
              : TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: secondaryColor,
                  height: 1.7,
                ),
        ),

        const SizedBox(height: 24),

        // ── Divider ──
        Container(height: 1, color: borderColor),

        const SizedBox(height: 24),

        // ── Surah sections ──
        _sectionHeader(
          '${l10n.topicKeyVerses} · ${content.sections.length}',
          primaryColor,
        ),
        const SizedBox(height: 12),

        ...content.sections.map(
          (section) => TopicSectionCard(
            section: section,
            initiallyExpanded: allExpanded,
            accentColor: topic.color,
          ),
        ),
      ],
    );
  }

  /// Fallback for uncurated topics: simple surah list.
  Widget _buildFallbackContent(
    BuildContext context,
    AppLocalizations l10n,
    bool isArabic,
    bool isDark,
    Color primaryColor,
    Color secondaryColor,
  ) {
    final borderColor = isDark ? GeistTokens.darkDivider : GeistTokens.lightDivider;
    final surfaceColor = isDark ? GeistTokens.darkSurface : GeistTokens.lightSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coming soon notice
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(GeistTokens.radiusLg),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.5),
                blurRadius: 0,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(LucideIcons.info, size: 16, color: secondaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.topicComingSoon,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: secondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Surah list
        _sectionHeader(
          l10n.topicMentionedIn(topic.surahIds.length),
          primaryColor,
        ),
        const SizedBox(height: 12),

        ...topic.surahIds.map(
          (id) => _buildSurahRow(context, id, isArabic, isDark, surfaceColor, primaryColor, secondaryColor, borderColor),
        ),
      ],
    );
  }

  Widget _buildSurahRow(
    BuildContext context,
    int surahId,
    bool isArabic,
    bool isDark,
    Color surfaceColor,
    Color primaryColor,
    Color secondaryColor,
    Color borderColor,
  ) {
    final surahInfo = allSurahs[surahId - 1];

    final surahName = isArabic ? surahInfo.nameArabic : surahInfo.nameSimple;
    final versesCount = surahInfo.versesCount;
    final startPage = surahStartPages[surahId];

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(GeistTokens.radiusMd),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.4),
            blurRadius: 0,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: topic.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(GeistTokens.radiusSm),
          ),
          child: Center(
            child: Text(
              '$surahId',
              style: TextStyle(
                fontFamily: 'GeistMono',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: topic.color,
              ),
            ),
          ),
        ),
        title: Text(
          surahName,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: primaryColor,
            letterSpacing: -0.32,
          ),
        ),
        subtitle: Text(
          '$versesCount verses · Page $startPage',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: secondaryColor,
          ),
        ),
        trailing: Icon(LucideIcons.chevronRight, size: 16, color: secondaryColor),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReadingScreen(initialPage: startPage),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Geist',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.32,
      ),
    );
  }
}
