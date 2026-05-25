import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/context_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/utils/verse_ref_formatter.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/data/quran_topics.dart';
import 'package:quran_app/screens/topic_detail_screen.dart';
import 'package:quran_app/widgets/geist_button.dart';
import 'package:quran_app/theme/geist_typography.dart';

/// Immersive, verse-by-verse exploration screen for a page's context.
class PageUnderstandingScreen extends StatefulWidget {
  final int sabaqPage;

  const PageUnderstandingScreen({super.key, required this.sabaqPage});

  @override
  State<PageUnderstandingScreen> createState() => _PageUnderstandingScreenState();
}

class _PageUnderstandingScreenState extends State<PageUnderstandingScreen> {
  late final List<Verse> _verses;
  final List<GlobalKey> _pillKeys = [];
  late final PageController _pageController;

  int _activeVerseIndex = 0;
  String _activeTab = 'translation';
  bool _showDetailedTafsir = false;
  bool _isTabInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isTabInitialized) {
      _activeTab = 'translation';
      _isTabInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _verses = context.read<QuranReadingProvider>().getPageVerses(widget.sabaqPage);
    _pillKeys.addAll(List.generate(_verses.length, (_) => GlobalKey()));
    _pageController = PageController(initialPage: _activeVerseIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_verses.isNotEmpty) {
        final ctxProvider = context.read<ContextProvider>();
        // Sync locale with ContextProvider for language-aware translations/tafsirs
        final l10n = AppLocalizations.of(context)!;
        ctxProvider.setLocale(l10n.localeName);

        // Ensure asbab is loaded
        await ctxProvider.ensureAsbabLoaded();
        // Load content for initial verse
        _loadVerseContent(_verses[_activeVerseIndex].verseKey);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadVerseContent(String verseKey, {bool updateDetailedTafsir = true}) {
    if (!mounted) return;
    final ctxProvider = context.read<ContextProvider>();
    final isArabic = AppLocalizations.of(context)!.localeName.startsWith('ar');

    ctxProvider.loadTranslation(verseKey);
    ctxProvider.loadBriefTafsir(verseKey);
    ctxProvider.loadAsbabNuzul(verseKey);

    if (isArabic) {
      ctxProvider.loadDetailedTafsir(verseKey);
      setState(() {
        _showDetailedTafsir = true;
      });
    } else if (updateDetailedTafsir) {
      setState(() {
        _showDetailedTafsir = false;
      });
    }
  }

  void _scrollToActivePill() {
    if (_activeVerseIndex >= 0 && _activeVerseIndex < _pillKeys.length) {
      final key = _pillKeys[_activeVerseIndex];
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 250),
          alignment: 0.5,
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final contextProvider = context.watch<ContextProvider>();
    final l10n = AppLocalizations.of(context)!;
    final localeName = l10n.localeName;

    if (_verses.isEmpty) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.chevronLeft, size: 20, color: theme.primaryText),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            localeName.startsWith('ar')
                ? 'لا توجد آيات في هذه الصفحة'
                : 'No verses found on this page',
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 16,
              color: theme.secondaryText,
            ),
          ),
        ),
      );
    }

    final activeVerseKey = _verses[_activeVerseIndex].verseKey;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, size: 20, color: theme.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localeName.startsWith('ar') ? 'فهم الصفحة' : 'Page Understanding',
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: theme.secondaryText,
              ),
            ),
            Text(
              VerseRefFormatter.format(
                activeVerseKey,
                locale: localeName,
                tier: VerseRefFormat.full,
              ),
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: theme.primaryText,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _buildTopVerseBar(theme, localeName),
            const SizedBox(height: 8),
            _buildPageView(theme, contextProvider, localeName),
          ],
        ),
      ),
    );
  }

  Widget _buildTopVerseBar(ThemeProvider theme, String localeName) {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _verses.length,
        itemBuilder: (context, index) {
          final verse = _verses[index];
          final isActive = index == _activeVerseIndex;
          final label = VerseRefFormatter.localizeNumbers(verse.verseNumber.toString(), localeName);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              key: _pillKeys[index],
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isActive ? theme.accentColor : theme.accentLight,
                  borderRadius: BorderRadius.circular(theme.radiusPill),
                  border: Border.all(
                    color: isActive ? theme.accentColor : theme.dividerColor,
                    width: 1,
                  ),
                  boxShadow: isActive ? theme.shadowRing : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? theme.scaffoldBackground : theme.primaryText,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageView(
    ThemeProvider theme,
    ContextProvider contextProvider,
    String localeName,
  ) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _verses.length,
            onPageChanged: (index) {
              final nextVerse = _verses[index];
              final nextHasAsbab = contextProvider.asbabService.hasOccasionByKey(nextVerse.verseKey);
              setState(() {
                _activeVerseIndex = index;
                _showDetailedTafsir = localeName.startsWith('ar');
                if (!nextHasAsbab && _activeTab == 'asbab') {
                  _activeTab = 'translation';
                }
              });
              _loadVerseContent(nextVerse.verseKey, updateDetailedTafsir: false);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToActivePill();
              });
            },
            itemBuilder: (context, index) {
              final verse = _verses[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildVerseDeepDiveCard(verse, theme, contextProvider, localeName),
              );
            },
          ),
          if (isDesktop && _activeVerseIndex > 0)
            Positioned(
              left: 8,
              child: _buildFloatingChevron(
                icon: LucideIcons.chevronLeft,
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                theme: theme,
              ),
            ),
          if (isDesktop && _activeVerseIndex < _verses.length - 1)
            Positioned(
              right: 8,
              child: _buildFloatingChevron(
                icon: LucideIcons.chevronRight,
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                theme: theme,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingChevron({
    required IconData icon,
    required VoidCallback onPressed,
    required ThemeProvider theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        boxShadow: theme.shadowCard,
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: theme.primaryText),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildVerseDeepDiveCard(
    Verse verse,
    ThemeProvider theme,
    ContextProvider contextProvider,
    String localeName,
  ) {
    final isArabic = localeName.startsWith('ar');
    final surahId = VerseRefFormatter.parse(verse.verseKey).$1;
    final hasAsbab = contextProvider.asbabService.hasOccasionByKey(verse.verseKey);

    // Reconstruct Arabic text
    final arabicText = verse.words.map((w) => w.textUthmani).join(' ').trim();

    // Filter topics
    final filteredProphetStories = prophetStories.where((t) => t.surahIds.contains(surahId)).toList();
    final filteredThemes = quranThemes.where((t) => t.surahIds.contains(surahId)).toList();
    final allRelatedTopics = [...filteredProphetStories, ...filteredThemes];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusXl),
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: theme.shadowCardFull,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Arabic text scrollable / centered
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    arabicText,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.amiriQuran(
                      fontSize: 24,
                      height: 1.8,
                      color: theme.primaryText,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Custom Segmented Tab Bar
          _buildCustomTabBar(theme, verse.verseKey, hasAsbab),

          const SizedBox(height: 16),

          // Active Tab Content
          Expanded(
            flex: 6,
            child: _buildActiveTabContent(verse, theme, contextProvider, isArabic),
          ),

          const SizedBox(height: 16),

          // Related Topics Title
          if (allRelatedTopics.isNotEmpty) ...[
            Text(
              isArabic ? 'مواضيع ذات صلة' : 'Related Topics',
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 8),
            _buildRelatedTopicsCarousel(allRelatedTopics, theme, isArabic),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomTabBar(ThemeProvider theme, String verseKey, bool hasAsbab) {
    final l10n = AppLocalizations.of(context)!;
    final tabs = [
      _TabItem(id: 'translation', label: l10n.readingTranslation),
      _TabItem(id: 'tafseer', label: l10n.readingTafsir),
      if (hasAsbab)
        _TabItem(id: 'asbab', label: l10n.tafsirTabOccasion),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.pillBackground,
        borderRadius: BorderRadius.circular(theme.radiusMd),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isActive = _activeTab == tab.id;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = tab.id;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? theme.accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(theme.radiusSm),
                ),
                child: Center(
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? theme.scaffoldBackground : theme.secondaryText,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActiveTabContent(
    Verse verse,
    ThemeProvider theme,
    ContextProvider contextProvider,
    bool isArabic,
  ) {
    final l10n = AppLocalizations.of(context)!;
    switch (_activeTab) {
      case 'translation':
        if (contextProvider.isLoadingTranslation) {
          return _buildLoadingPlaceholder(theme);
        }
        final translationText = contextProvider.activeTranslation?.text;
        if (translationText == null || translationText.isEmpty) {
          return Center(
            child: Text(
              isArabic ? 'الترجمة غير متوفرة' : 'Translation not available',
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 14,
                color: theme.mutedText,
              ),
            ),
          );
        }
        return SingleChildScrollView(
          child: Text(
            translationText,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            style: isArabic
                ? GoogleFonts.amiri(
                    fontSize: 16,
                    height: 1.8,
                    color: theme.primaryText,
                  )
                : TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 14,
                    height: 1.6,
                    color: theme.primaryText,
                  ),
          ),
        );

      case 'tafseer':
        if (isArabic) {
          if (contextProvider.isLoadingDetailedTafsir) {
            return _buildLoadingPlaceholder(theme);
          }
          final detailedTafsir = contextProvider.activeDetailedTafsir?.text;
          if (detailedTafsir == null || detailedTafsir.isEmpty) {
            return SingleChildScrollView(
              child: Text(
                l10n.tafsirEmptyDetailed,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 14,
                  color: theme.mutedText,
                ),
              ),
            );
          }
          return SingleChildScrollView(
            child: Text(
              detailedTafsir,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                fontSize: 16,
                height: 1.8,
                color: theme.primaryText,
              ),
            ),
          );
        }

        if (contextProvider.isLoadingBriefTafsir) {
          return _buildLoadingPlaceholder(theme);
        }
        final briefTafsir = contextProvider.activeBriefTafsir?.text;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (briefTafsir != null && briefTafsir.isNotEmpty)
                Text(
                  briefTafsir,
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  style: isArabic
                      ? GoogleFonts.amiri(
                          fontSize: 16,
                          height: 1.8,
                          color: theme.primaryText,
                        )
                      : TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 14,
                          height: 1.6,
                          color: theme.primaryText,
                        ),
                )
              else
                Text(
                  l10n.tafsirEmptyBrief,
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 14,
                    color: theme.mutedText,
                  ),
                ),
              const SizedBox(height: 16),
              if (!_showDetailedTafsir)
                Center(
                  child: GeistButton(
                    label: isArabic ? 'عرض التفسير المفصل' : 'Show Detailed Tafseer',
                    type: GeistButtonType.secondary,
                    size: GeistButtonSize.small,
                    onPressed: () {
                      setState(() {
                        _showDetailedTafsir = true;
                      });
                      context.read<ContextProvider>().loadDetailedTafsir(verse.verseKey);
                    },
                  ),
                )
              else ...[
                const Divider(height: 24),
                Text(
                  isArabic ? 'التفسير التفصيلي (ابن كثير)' : 'Detailed Tafseer (Ibn Kathir)',
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.accentColor,
                  ),
                ),
                const SizedBox(height: 8),
                if (contextProvider.isLoadingDetailedTafsir)
                  _buildLoadingPlaceholder(theme)
                else if (contextProvider.activeDetailedTafsir?.text != null)
                  Text(
                    contextProvider.activeDetailedTafsir!.text,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    style: isArabic
                        ? GoogleFonts.amiri(
                            fontSize: 16,
                            height: 1.8,
                            color: theme.primaryText,
                          )
                        : TextStyle(
                            fontFamily: GeistTypography.primaryFontFamily,
                            fontSize: 14,
                            height: 1.6,
                            color: theme.primaryText,
                          ),
                  )
                else
                  Text(
                    l10n.tafsirEmptyDetailed,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 14,
                      color: theme.mutedText,
                    ),
                  ),
              ],
            ],
          ),
        );

      case 'asbab':
        final occasions = contextProvider.activeAsbabNuzul;
        if (occasions == null || occasions.isEmpty) {
          return Center(
            child: Text(
              l10n.tafsirEmptyOccasion,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 14,
                color: theme.mutedText,
              ),
            ),
          );
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...occasions.asMap().entries.map((entry) {
                final index = entry.key;
                final text = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (occasions.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          l10n.tafsirNarrationLabel(index + 1),
                          style: GoogleFonts.amiri(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.accentColor,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    Text(
                      text,
                      style: GoogleFonts.amiri(
                        fontSize: 16,
                        height: 1.8,
                        color: theme.primaryText,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    if (index < occasions.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: theme.dividerColor),
                      ),
                  ],
                );
              }),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoadingPlaceholder(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 14,
            width: i == 3 ? 180 : double.infinity,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRelatedTopicsCarousel(
    List<QuranTopic> topics,
    ThemeProvider theme,
    bool isArabic,
  ) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: topics.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final topic = topics[index];
          return SizedBox(
            width: 160,
            child: Material(
              color: theme.accentLight,
              borderRadius: BorderRadius.circular(theme.radiusLg),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TopicDetailScreen(topic: topic),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(theme.radiusLg),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(theme.radiusLg),
                    border: Border.all(color: theme.dividerColor, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(topic.icon, size: 14, color: theme.accentColor),
                          const Spacer(),
                          Text(
                            AppLocalizations.of(context)!.topicSurahsCount(topic.surahIds.length),
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 10,
                              color: theme.mutedText,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        isArabic ? topic.titleAr : topic.title,
                        style: isArabic
                            ? GoogleFonts.amiri(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: theme.primaryText,
                              )
                            : TextStyle(
                                fontFamily: GeistTypography.primaryFontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: theme.primaryText,
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isArabic ? topic.subtitleAr : topic.subtitle,
                        style: isArabic
                            ? GoogleFonts.amiri(
                                fontSize: 11,
                                color: theme.secondaryText,
                              )
                            : TextStyle(
                                fontFamily: GeistTypography.primaryFontFamily,
                                fontSize: 10,
                                color: theme.secondaryText,
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabItem {
  final String id;
  final String label;
  const _TabItem({required this.id, required this.label});
}
