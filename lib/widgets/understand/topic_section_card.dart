import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/data/surah_metadata.dart';
import 'package:quran_app/data/topic_content.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/utils/verse_ref_formatter.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/providers/context_provider.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/services/tafsir_service.dart';
import 'package:quran_app/theme/geist_tokens.dart';
import 'package:provider/provider.dart';

/// A collapsible card showing one surah's contribution to a topic.
///
/// Displays the surah name, verse range, and perspective. When expanded,
/// lazily loads key verse translations from the API while showing Arabic
/// text from the bundled quran package immediately.
class TopicSectionCard extends StatefulWidget {
  final TopicSection section;
  final bool initiallyExpanded;
  final Color accentColor;

  const TopicSectionCard({
    super.key,
    required this.section,
    this.initiallyExpanded = false,
    this.accentColor = const Color(0xFF0072F5),
  });

  @override
  State<TopicSectionCard> createState() => _TopicSectionCardState();
}

class _TopicSectionCardState extends State<TopicSectionCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  // Verse translation loading state
  final Map<String, String?> _translations = {};
  bool _isLoadingTranslations = false;
  bool _loadedOnce = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (_isExpanded) {
      _controller.value = 1.0;
      _loadTranslations();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _controller.forward();
      if (!_loadedOnce) _loadTranslations();
    } else {
      _controller.reverse();
    }
  }

  Future<void> _loadTranslations() async {
    if (_isLoadingTranslations || _loadedOnce) return;
    setState(() => _isLoadingTranslations = true);

    final contextProvider = context.read<ContextProvider>();
    final translationId = contextProvider.selectedTranslationId;
    final tafsirService = TafsirService();

    for (final key in widget.section.keyVerseKeys) {
      try {
        final result = await tafsirService.getTranslation(
          key,
          translationId: translationId,
        );
        if (mounted) {
          setState(() => _translations[key] = result?.text);
        }
      } catch (_) {
        if (mounted) {
          setState(() => _translations[key] = null);
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingTranslations = false;
        _loadedOnce = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final section = widget.section;

    // Get surah metadata
    final surahInfo = allSurahs[section.surahId - 1];
    final surahName = isArabic ? surahInfo.nameArabic : surahInfo.nameSimple;

    final borderColor = isDark ? GeistTokens.darkDivider : GeistTokens.lightDivider;
    final surfaceColor = isDark ? GeistTokens.darkSurface : GeistTokens.lightSurface;
    final primaryColor = isDark ? GeistTokens.darkPrimary : GeistTokens.lightPrimary;
    final secondaryColor = isDark ? GeistTokens.darkSecondary : GeistTokens.lightSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (always visible, tappable) ──
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(GeistTokens.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Accent dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Surah name + verse range
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surahName,
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                            letterSpacing: -0.32,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.topicVerseRange(section.startVerse, section.endVerse),
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand/collapse icon
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded content ──
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Divider
                  Container(
                    height: 1,
                    color: borderColor.withValues(alpha: 0.5),
                    margin: const EdgeInsets.only(bottom: 12),
                  ),

                  // Perspective text
                  Text(
                    isArabic ? section.perspectiveAr : section.perspective,
                    style: isArabic
                        ? GoogleFonts.amiri(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: primaryColor,
                            height: 1.8,
                          )
                        : TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: secondaryColor,
                            height: 1.6,
                          ),
                  ),

                  const SizedBox(height: 16),

                  // Key verses header
                  Text(
                    l10n.topicKeyVerses,
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: secondaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Key verses list
                  ...section.keyVerseKeys.map((key) => _buildVerseItem(
                        key, primaryColor, secondaryColor, borderColor, isArabic, l10n)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseItem(
    String verseKey,
    Color primaryColor,
    Color secondaryColor,
    Color borderColor,
    bool isArabic,
    AppLocalizations l10n,
  ) {
    // Parse verse key
    final parts = verseKey.split(':');
    final surahNum = int.parse(parts[0]);
    final verseNum = int.parse(parts[1]);

    // Arabic text from bundled package (always available offline)
    final arabicText = quran.getVerse(surahNum, verseNum);

    // Translation (loaded async)
    final translation = _translations[verseKey];
    final isLoading = _isLoadingTranslations && !_translations.containsKey(verseKey);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: borderColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(GeistTokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse key label
          Text(
            VerseRefFormatter.format(verseKey, locale: l10n.localeName, tier: VerseRefFormat.compact),
            style: TextStyle(
              fontFamily: 'GeistMono',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: secondaryColor,
            ),
          ),
          const SizedBox(height: 8),

          // Arabic verse text
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              arabicText,
              style: GoogleFonts.amiri(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: primaryColor,
                height: 2.0,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(height: 8),

          // Translation or loading/fallback
          if (isLoading)
            _buildShimmer(borderColor)
          else if (translation != null)
            Text(
              translation,
              style: TextStyle(
                fontFamily: isArabic ? null : 'Geist',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: secondaryColor,
                height: 1.6,
              ),
            )
          else if (_loadedOnce)
            Text(
              l10n.topicOfflineVerse,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: secondaryColor.withValues(alpha: 0.6),
              ),
            ),

          const SizedBox(height: 12),

          // Read in Mushaf Action (Verse level)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final page = quran.getPageNumber(surahNum, verseNum);
                context.read<BookmarkProvider>().setHighlight(verseKey);
                context.read<ContextProvider>().setHighlightVerse(verseKey);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReadingScreen(
                      initialPage: page,
                    ),
                  ),
                );
              },
              icon: Icon(LucideIcons.bookOpen, size: 14, color: widget.accentColor),
              label: Text(
                l10n.topicReadInMushaf,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.accentColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: borderColor.withValues(alpha: 0.5)),
                backgroundColor: isDark 
                    ? widget.accentColor.withValues(alpha: 0.05) 
                    : widget.accentColor.withValues(alpha: 0.03),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GeistTokens.radiusMd),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(Color borderColor) {
    return Column(
      children: List.generate(
        2,
        (i) => Container(
          height: 12,
          margin: EdgeInsets.only(
            bottom: 4,
            right: i == 1 ? 60 : 0,
          ),
          decoration: BoxDecoration(
            color: borderColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
