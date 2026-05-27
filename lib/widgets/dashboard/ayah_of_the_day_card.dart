import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/context_provider.dart';
import 'package:quran_app/services/tafsir_service.dart' show TafsirService;
import 'package:quran_app/utils/verse_ref_formatter.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/data/quran_topics.dart';
import 'package:quran_app/data/topic_content.dart';
import 'package:quran_app/screens/topic_detail_screen.dart';
import 'package:quran_app/widgets/context/tafsir_sheet.dart' show showTafsirSheet;

/// An expanded and rich card showing the Ayah of the Day.
/// Includes Uthmani text, translation, Tafsir sheet shortcuts,
/// and dynamically resolved connected stories & themes.
class AyahOfDayCard extends StatefulWidget {
  final String verseKey;
  final String arabicText;

  const AyahOfDayCard({
    super.key,
    required this.verseKey,
    required this.arabicText,
  });

  @override
  State<AyahOfDayCard> createState() => _AyahOfDayCardState();
}

class _AyahOfDayCardState extends State<AyahOfDayCard> {
  String? _translationText;
  bool _isLoading = true;
  bool _hasAsbab = false;
  List<QuranTopic> _connectedTopics = [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void didUpdateWidget(covariant AyahOfDayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verseKey != widget.verseKey) {
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final contextProvider = context.read<ContextProvider>();
      final translationId = contextProvider.selectedTranslationId;

      // 1. Fetch translation via TafsirService (which handles caching & offline bundled fallback)
      final trans = await TafsirService().getTranslation(
        widget.verseKey,
        translationId: translationId,
      );

      // 2. Check Asbab al-Nuzul data
      final hasAsbab = contextProvider.verseHasAsbabNuzul(widget.verseKey);

      // 3. Resolve connected stories & themes
      final topics = _findTopicsForVerse(widget.verseKey);

      if (mounted) {
        setState(() {
          _translationText = trans?.text;
          _hasAsbab = hasAsbab;
          _connectedTopics = topics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<QuranTopic> _findTopicsForVerse(String verseKey) {
    final parts = verseKey.split(':');
    if (parts.length != 2) return [];
    final surahId = int.tryParse(parts[0]);
    final verseNum = int.tryParse(parts[1]);
    if (surahId == null || verseNum == null) return [];

    final List<QuranTopic> matchedTopics = [];

    // Search both prophet stories and general Quranic themes
    for (final topic in [...prophetStories, ...quranThemes]) {
      final content = topicContentRegistry[topic.id];
      if (content == null) continue;

      for (final section in content.sections) {
        if (section.surahId == surahId &&
            verseNum >= section.startVerse &&
            verseNum <= section.endVerse) {
          if (!matchedTopics.any((t) => t.id == topic.id)) {
            matchedTopics.add(topic);
          }
        }
      }
    }
    return matchedTopics;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final locale = AppLocalizations.of(context)!.localeName;
    final isAr = locale == 'ar';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusXl),
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: theme.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header (Title + Sparkles icon) ──
          Row(
            children: [
              Icon(
                LucideIcons.sparkle,
                size: 16,
                color: theme.accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.homeAyahTitle,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Arabic Text ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              widget.arabicText,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 21,
                color: theme.primaryText,
                height: 1.9,
              ),
            ),
          ),

          // ── Reference Label ──
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '— ${VerseRefFormatter.format(widget.verseKey, locale: locale, tier: VerseRefFormat.standard)}',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                color: theme.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 16),

          // ── Translation Segment ──
          if (_isLoading)
            _buildSkeletonLoader(theme)
          else if (_translationText != null) ...[
            Text(
              _translationText!,
              textAlign: isAr ? TextAlign.right : TextAlign.left,
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              style: isAr
                  ? GoogleFonts.amiri(
                      fontSize: 16,
                      height: 1.8,
                      color: theme.secondaryText,
                    )
                  : TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      height: 1.5,
                      color: theme.secondaryText,
                    ),
            ),
            const SizedBox(height: 20),
          ] else ...[
            Text(
              AppLocalizations.of(context)!.homeAyahSubtitle,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: theme.mutedText,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Action Buttons (Tafsir & Occasion) ──
          Row(
            children: [
              // Tafsir Button
              _ActionButton(
                icon: LucideIcons.bookOpen,
                label: AppLocalizations.of(context)!.contextTafsir,
                theme: theme,
                onTap: () {
                  showTafsirSheet(
                    context,
                    verseKey: widget.verseKey,
                    initialTabIndex: 0, // Tafsir tab
                  );
                },
              ),
              if (_hasAsbab) ...[
                const SizedBox(width: 8),
                // Occasion of Revelation Button
                _ActionButton(
                  icon: LucideIcons.history,
                  label: isAr ? 'أسباب النزول' : 'Occasion',
                  theme: theme,
                  isHighlighted: true,
                  onTap: () {
                    showTafsirSheet(
                      context,
                      verseKey: widget.verseKey,
                      initialTabIndex: 2, // Occasion of Revelation tab
                    );
                  },
                ),
              ],
            ],
          ),

          // ── Connected Stories & Themes ──
          if (!_isLoading && _connectedTopics.isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(color: theme.dividerColor, height: 1),
            const SizedBox(height: 16),
            Text(
              isAr ? 'المواضيع والقصص المرتبطة' : 'Connected Themes & Stories',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _connectedTopics.map((topic) {
                final topicTitle = isAr ? topic.titleAr : topic.title;
                final topicBg = topic.color.withValues(alpha: theme.isDark ? 0.15 : 0.08);
                final topicBorder = topic.color.withValues(alpha: theme.isDark ? 0.4 : 0.3);

                return Material(
                  color: topicBg,
                  borderRadius: BorderRadius.circular(theme.radiusMd),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(theme.radiusMd),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TopicDetailScreen(topic: topic),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(theme.radiusMd),
                        border: Border.all(color: topicBorder, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            topic.icon,
                            size: 13,
                            color: topic.color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            topicTitle,
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
            height: 14,
            width: index == 2 ? MediaQuery.of(context).size.width * 0.5 : double.infinity,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeProvider theme;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.theme,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isHighlighted
        ? theme.accentColor.withValues(alpha: 0.08)
        : theme.pillBackground;
    final fgColor = isHighlighted ? theme.accentColor : theme.primaryText;
    final borderColor = isHighlighted
        ? theme.accentColor.withValues(alpha: 0.25)
        : theme.dividerColor;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(theme.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(theme.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(theme.radiusLg),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fgColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
