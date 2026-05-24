import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/providers/context_provider.dart';
import 'package:quran_app/providers/locale_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/werd_provider.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/utils/verse_ref_formatter.dart';
import 'package:quran_app/widgets/audio_player_bridge.dart';
import 'package:quran_app/widgets/bottom_dock.dart';
import 'package:quran_app/widgets/context/tafsir_sheet.dart';
import 'package:quran_app/widgets/overlays.dart';
import 'package:quran_app/widgets/top_nav_bar.dart';

class TabletReadingView extends StatefulWidget {
  final int initialPage;
  const TabletReadingView({super.key, required this.initialPage});

  @override
  State<TabletReadingView> createState() => _TabletReadingViewState();
}

class _TabletReadingViewState extends State<TabletReadingView> {
  String readMode = 'read';
  bool isAudioExpanded = false;
  bool isFullScreen = false;

  late PageController _pageController;

  // Lifted selection state
  int? _selectedVerseId;

  // Track audio active verse changes
  String? _lastActiveVerseKey;
  late final AudioProvider _audioProvider;

  // Werd progress tracking
  final Set<int> _readPagesInSession = {};
  Timer? _pageReadTimer;
  bool _hasExceededGoalThisSession = false;
  Set<int> _currentlyViewingPages = {};

  @override
  void initState() {
    super.initState();
    final startPage = widget.initialPage;

    // Initialize PageController based on the default 'read' mode spreads or 'tafsir' mode pages.
    if (readMode == 'read') {
      final startSpread = (startPage + 1) ~/ 2;
      _pageController = PageController(
        initialPage: 302 - startSpread,
        keepPage: false,
      );
    } else {
      _pageController = PageController(
        initialPage: 604 - startPage,
        keepPage: false,
      );
    }

    // Set initial active page and load translations locale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QuranReadingProvider>().setActivePage(startPage);

      final locale = context.read<LocaleProvider>().locale.languageCode;
      final ctxProvider = context.read<ContextProvider>();
      ctxProvider.setLocale(locale);
      ctxProvider.ensureAsbabLoaded();
    });

    _audioProvider = context.read<AudioProvider>();
    _lastActiveVerseKey = _audioProvider.activeVerseKey;
    _audioProvider.addListener(_onAudioChanged);

    // Initial page Werd tracking
    if (readMode == 'read') {
      final startSpread = (startPage + 1) ~/ 2;
      _startPagesReadTimer({2 * startSpread - 1, 2 * startSpread});
    } else {
      _startPagesReadTimer({startPage});
    }
  }

  @override
  void dispose() {
    _pageReadTimer?.cancel();
    _audioProvider.removeListener(_onAudioChanged);
    _pageController.dispose();
    super.dispose();
  }

  int _getVersePage(String verseKey) {
    final parts = verseKey.split(':');
    if (parts.length == 2) {
      final surah = int.tryParse(parts[0]);
      final ayah = int.tryParse(parts[1]);
      if (surah != null && ayah != null) {
        return quran.getPageNumber(surah, ayah);
      }
    }
    return 1;
  }

  void _onAudioChanged() {
    if (!mounted) return;

    final verseKey = _audioProvider.activeVerseKey;
    if (verseKey == null || verseKey == _lastActiveVerseKey) return;
    _lastActiveVerseKey = verseKey;

    final readingProvider = context.read<QuranReadingProvider>();
    final playingPage = _getVersePage(verseKey);

    if (readMode == 'read') {
      final currentS = (readingProvider.activePage + 1) ~/ 2;
      final rightP = 2 * currentS - 1;
      final leftP = 2 * currentS;

      // In read mode, only flip pages if playing verse page is outside visible spread
      if (playingPage == rightP || playingPage == leftP) {
        if (readingProvider.activePage != playingPage) {
          readingProvider.setActivePage(playingPage);
        }
        return;
      }

      final targetSpread = (playingPage + 1) ~/ 2;
      _goToSpread(targetSpread);
    } else {
      // In tafsir mode, flip pages immediately when the active verse crosses the page boundary
      if (readingProvider.activePage == playingPage) return;
      _goToPage(playingPage);
    }
  }

  void _goToSpread(int spread) {
    final readingProvider = context.read<QuranReadingProvider>();
    final rightPage = 2 * spread - 1;
    readingProvider.loadPage(rightPage);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(302 - spread);
    }
  }

  void _goToPage(int page) {
    final readingProvider = context.read<QuranReadingProvider>();
    readingProvider.loadPage(page);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(604 - page);
    }
  }

  void _updatePageController() {
    final readingProvider = context.read<QuranReadingProvider>();
    final activePage = readingProvider.activePage;

    if (_pageController.hasClients) {
      _pageController.dispose();
    }

    if (readMode == 'read') {
      final startSpread = (activePage + 1) ~/ 2;
      _pageController = PageController(
        initialPage: 302 - startSpread,
        keepPage: false,
      );
    } else {
      _pageController = PageController(
        initialPage: 604 - activePage,
        keepPage: false,
      );
    }
  }

  void _onReadModeChanged(String newMode) {
    if (newMode == readMode) return;
    setState(() {
      readMode = newMode;
      _updatePageController();
    });

    final activePage = context.read<QuranReadingProvider>().activePage;
    if (readMode == 'read') {
      final spread = (activePage + 1) ~/ 2;
      _startPagesReadTimer({2 * spread - 1, 2 * spread});
    } else {
      _startPagesReadTimer({activePage});
    }
  }

  void _handlePageSelected(int page) {
    final readingProvider = context.read<QuranReadingProvider>();
    readingProvider.loadPage(page);
    if (readMode == 'read') {
      final spread = (page + 1) ~/ 2;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(302 - spread);
      }
    } else {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(604 - page);
      }
    }
  }

  void _onSpreadPageChanged(int index) {
    final S = 302 - index;
    final rightPage = 2 * S - 1;
    final leftPage = 2 * S;

    final readingProvider = context.read<QuranReadingProvider>();
    final currentActive = readingProvider.activePage;

    int newActive = rightPage;
    if (currentActive == leftPage) {
      newActive = leftPage;
    }

    if (currentActive != newActive) {
      readingProvider.setActivePage(newActive);
    }

    _saveLastReadPosition(newActive, readingProvider);
    _startPagesReadTimer({rightPage, leftPage});
    context.read<ContextProvider>().prefetchAdjacentPages(newActive);
  }

  void _onTafsirPageChanged(int index) {
    final page = 604 - index;
    final readingProvider = context.read<QuranReadingProvider>();
    if (readingProvider.activePage != page) {
      readingProvider.setActivePage(page);
    }
    _saveLastReadPosition(page, readingProvider);
    _startPagesReadTimer({page});
    context.read<ContextProvider>().prefetchAdjacentPages(page);
  }

  void _toggleFullScreen() {
    setState(() {
      isFullScreen = !isFullScreen;
      if (isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  void _onVerseSelected(int? id, int pageNumber) {
    setState(() {
      _selectedVerseId = id;
      if (id == null) {
        context.read<ContextProvider>().disableTranslation();
      }
    });
  }

  void _switchToTranslationMode(String verseKey) {
    final ctxProvider = context.read<ContextProvider>();
    ctxProvider.setHighlightVerse(verseKey);
    setState(() {
      readMode = 'tafsir';
      _updatePageController();
    });
  }

  void _saveLastReadPosition(int page, QuranReadingProvider provider) {
    String surahName = 'Page $page';
    String? verseKey;
    if (provider.verses.isNotEmpty && provider.chapters.isNotEmpty) {
      final firstVerse = provider.verses.first;
      final chapterId = int.tryParse(firstVerse.verseKey.split(':').first) ?? 1;
      final chapter = provider.chapters.firstWhere(
        (c) => c.id == chapterId,
        orElse: () => provider.chapters.first,
      );
      surahName = chapter.nameSimple;
      verseKey = firstVerse.verseKey;
    }
    context.read<LocalStorageService>().saveLastRead(
      page: page,
      surahName: surahName,
      verseKey: verseKey,
    );
  }

  void _startPagesReadTimer(Set<int> pages) {
    _pageReadTimer?.cancel();

    final unreadPages = pages.where((p) => !_readPagesInSession.contains(p)).toSet();
    if (unreadPages.isEmpty) return;

    final werdProvider = context.read<WerdProvider>();
    if (!werdProvider.hasWerd || werdProvider.config?.isEnabled != true) return;

    _currentlyViewingPages = unreadPages;
    _pageReadTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      for (final p in _currentlyViewingPages) {
        _markPageAsRead(p);
      }
    });
  }

  void _markPageAsRead(int page) {
    final werdProvider = context.read<WerdProvider>();
    if (!werdProvider.hasWerd || werdProvider.config?.isEnabled != true) return;
    if (_readPagesInSession.contains(page)) return;

    _readPagesInSession.add(page);

    final config = werdProvider.config!;
    final int oldRead = config.pagesReadToday;
    final int target = config.todayTarget;

    werdProvider.incrementProgress(1);
    final int newRead = oldRead + 1;

    _checkWerdMilestones(oldRead, newRead, target);
  }

  void _checkWerdMilestones(int oldRead, int newRead, int target) {
    if (target == 0) return;

    String? message;
    IconData? icon;
    Color? iconColor;

    if (oldRead < target / 2 && newRead >= target / 2) {
      if (newRead < target) {
        message = "Halfway there! Keep it up.";
        icon = LucideIcons.star;
        iconColor = Colors.orangeAccent;
      }
    } else if (oldRead < target * 0.8 &&
        newRead >= target * 0.8 &&
        newRead < target) {
      message = "Almost there! Just a bit more.";
      icon = LucideIcons.flame;
      iconColor = Colors.orangeAccent;
    } else if (oldRead < target && newRead >= target) {
      message = "Masha'Allah! Daily Goal Completed!";
      icon = LucideIcons.checkCircle2;
      iconColor = Colors.green;
    } else if (oldRead == target &&
        newRead > target &&
        !_hasExceededGoalThisSession) {
      message = "Exceeding your daily goal! May Allah reward you.";
      icon = LucideIcons.heart;
      iconColor = Colors.pinkAccent;
      _hasExceededGoalThisSession = true;
    }

    if (message != null) {
      _showWerdSnackbar(message, icon, iconColor);
    }
  }

  void _showWerdSnackbar(String message, IconData? icon, Color? iconColor) {
    if (!mounted) return;
    final theme = context.read<ThemeProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? theme.accentColor, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.primaryText,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: theme.cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.radiusLg),
        ),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        duration: const Duration(seconds: 4),
        elevation: 4,
      ),
    );
  }

  void _showOverlay(Widget Function(BuildContext sheetContext) sheetBuilder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 680),
      builder: (sheetContext) {
        return ExcludeSemantics(
          child: Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(sheetContext).size.height * 0.1,
            ),
            child: DefaultTextStyle(
              style: const TextStyle(fontFamily: 'Inter'),
              child: sheetBuilder(sheetContext),
            ),
          ),
        );
      },
    );
  }

  void _openReciterMenu() {
    _showOverlay((ctx) => ReciterMenuSheet(onClose: () => Navigator.pop(ctx)));
  }

  void _openAudioSettings() {
    _showOverlay((ctx) => AudioSettingsSheet(onClose: () => Navigator.pop(ctx)));
  }

  void _openNavMenu() {
    _showOverlay(
      (ctx) => NavMenuSheet(
        onClose: () => Navigator.pop(ctx),
        onPageSelected: (page) {
          Navigator.pop(ctx);
          _handlePageSelected(page);
        },
      ),
    );
  }

  void _openThemePicker() {
    _showOverlay((ctx) => ThemePickerSheet(onClose: () => Navigator.pop(ctx)));
  }

  void _togglePageBookmark() {
    final rp = context.read<QuranReadingProvider>();
    final l = AppLocalizations.of(context);
    String sName = '';
    if (rp.verses.isNotEmpty && rp.chapters.isNotEmpty) {
      final chId = int.tryParse(rp.verses.first.verseKey.split(':')[0]) ?? 1;
      try {
        final ch = rp.chapters.firstWhere((c) => c.id == chId);
        sName = l!.localeName == 'ar' ? ch.nameArabic : ch.nameSimple;
      } catch (_) {
        sName = VerseRefFormatter.surahName(chId, l!.localeName);
      }
    }
    final added = context.read<BookmarkProvider>().togglePageBookmark(
      pageNumber: rp.activePage,
      surahName: sName,
    );
    final theme = context.read<ThemeProvider>();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? '${l!.homePage} ${rp.activePage} bookmarked'
              : 'Bookmark removed',
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 13,
          ),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.radiusMd),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildSpineDivider(ThemeProvider theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left side shadow
        Container(
          width: 12,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                Colors.black.withValues(alpha: theme.spineEffectIntensity * 0.15),
                Colors.black.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        // Central spine line
        Container(
          width: 1.5,
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
        // Right side shadow
        Container(
          width: 12,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withValues(alpha: theme.spineEffectIntensity * 0.15),
                Colors.black.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTafsirPanel(int pageNumber, ThemeProvider theme) {
    final contextProvider = context.watch<ContextProvider>();
    final l = AppLocalizations.of(context)!;
    final translations = contextProvider.getPageTranslations(pageNumber);

    // Load page translations if not already cached
    if (translations.isEmpty && !contextProvider.isLoadingTranslation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          contextProvider.loadPageTranslations(pageNumber);
        }
      });
    }

    if (contextProvider.isLoadingTranslation && translations.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: theme.accentColor),
            const SizedBox(height: 12),
            Text(
              l.translationLoading,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 13,
                color: theme.mutedText,
              ),
            ),
          ],
        ),
      );
    }

    final readingProvider = context.watch<QuranReadingProvider>();
    final verses = readingProvider.getPageVerses(pageNumber);

    if (verses.isEmpty) {
      return Center(
        child: Text(
          l.pageLoadError(pageNumber),
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 14,
            color: theme.mutedText,
          ),
        ),
      );
    }

    final highlightKey = contextProvider.highlightVerseKey;
    int? highlightIndex;
    if (highlightKey != null) {
      highlightIndex = verses.indexWhere((v) => v.verseKey == highlightKey);
      if (highlightIndex < 0) highlightIndex = null;
    }

    final scrollController = ScrollController();

    if (highlightIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final estimatedOffset = highlightIndex! * 180.0;
        if (scrollController.hasClients) {
          scrollController.animateTo(
            estimatedOffset,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
        context.read<ContextProvider>().clearHighlightVerse();
      });
    }

    return ListView.builder(
      controller: scrollController,
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top > 0
            ? MediaQuery.paddingOf(context).top + 60
            : 60,
        bottom: 120,
        left: 20,
        right: 20,
      ),
      itemCount: verses.length,
      itemBuilder: (context, index) {
        final verse = verses[index];
        final verseText = verse.words
            .where((w) => w.charTypeName != 'end')
            .map((w) => w.textUthmani)
            .join(' ');
        final translation = translations[verse.verseKey];
        final isHighlighted = verse.verseKey == highlightKey;

        return GestureDetector(
          onTap: () {
            final readingProv = context.read<QuranReadingProvider>();
            final chapterId = int.tryParse(verse.verseKey.split(':').first) ?? 1;
            String? surahName;
            try {
              surahName = readingProv.chapters
                  .firstWhere((c) => c.id == chapterId)
                  .nameSimple;
            } catch (_) {}
            showTafsirSheet(
              context,
              verseKey: verse.verseKey,
              surahName: surahName,
            );
          },
          onLongPress: () {
            final audioProvider = context.read<AudioProvider>();
            audioProvider.playSingleVerse(verse);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? theme.accentColor.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(theme.radiusMd),
            ),
            padding: isHighlighted
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                : EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final audioProvider = context.read<AudioProvider>();
                        audioProvider.playVerseList(
                          verses,
                          startIndex: index,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.accentColor.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.play,
                          size: 14,
                          color: theme.accentColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(theme.radiusLg),
                      ),
                      child: Text(
                        VerseRefFormatter.format(
                          verse.verseKey,
                          locale: l.localeName,
                          tier: VerseRefFormat.compact,
                        ),
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    verseText,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.amiriQuran(
                      fontSize: theme.quranFontSize,
                      height: theme.quranLineHeight,
                      fontWeight: FontWeight.w400,
                      color: theme.quranText,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (translation != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(theme.radiusLg),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      translation.text,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 14,
                        height: 1.6,
                        color: theme.secondaryText,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(theme.radiusLg),
                    ),
                    child: Text(
                      l.translationLoading,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: theme.mutedText,
                      ),
                    ),
                  ),
                if (contextProvider.asbabService.hasOccasionByKey(verse.verseKey))
                  _buildAsbabCard(
                    theme,
                    verse.verseKey,
                    contextProvider.asbabService.getOccasionsByKey(
                          verse.verseKey,
                        ) ??
                        [],
                  ),
                if (index < verses.length - 1)
                  Divider(
                    height: 32,
                    color: theme.dividerColor.withValues(alpha: 0.3),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAsbabCard(
    ThemeProvider theme,
    String verseKey,
    List<String> occasions,
  ) {
    if (occasions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: Border.all(color: theme.accentColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.history_edu, size: 16, color: theme.accentColor),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.asbabNuzulTitle ?? 'سبب النزول',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.accentColor,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)?.asbabOccasion ?? 'Occasion of Revelation',
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 10,
                  color: theme.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ExcludeSemantics(
            child: Text(
              occasions.first.length > 200
                  ? '${occasions.first.substring(0, 200)}…'
                  : occasions.first,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 15,
                height: 1.8,
                color: theme.primaryText,
              ),
              textDirection: TextDirection.rtl,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (occasions.first.length > 200 || occasions.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: GestureDetector(
                onTap: () {
                  final readingProv = context.read<QuranReadingProvider>();
                  final chapterId = int.tryParse(verseKey.split(':').first) ?? 1;
                  String? surahName;
                  try {
                    surahName = readingProv.chapters
                        .firstWhere((c) => c.id == chapterId)
                        .nameSimple;
                  } catch (_) {}
                  context.read<ContextProvider>().loadAsbabNuzul(verseKey);
                  showTafsirSheet(
                    context,
                    verseKey: verseKey,
                    surahName: surahName,
                  );
                },
                child: Text(
                  AppLocalizations.of(context)?.asbabReadFull ?? 'Read full narration →',
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.accentColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: ExcludeSemantics(
        child: Stack(
          children: [
            // Main Pages
            Positioned.fill(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1360),
                  child: Consumer<QuranReadingProvider>(
                    builder: (context, readingProvider, child) {
                      return Directionality(
                        textDirection: TextDirection.ltr,
                        child: PageView.builder(
                          key: ValueKey(readMode),
                          controller: _pageController,
                          reverse: false,
                          itemCount: readMode == 'read' ? 302 : 604,
                          onPageChanged: (index) {
                            if (readMode == 'read') {
                              _onSpreadPageChanged(index);
                            } else {
                              _onTafsirPageChanged(index);
                            }
                          },
                          itemBuilder: (context, index) {
                            if (readMode == 'read') {
                              final S = 302 - index;
                              final rightPage = 2 * S - 1;
                              final leftPage = 2 * S;

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Left Page
                                  Expanded(
                                    child: QuranPage(
                                      key: ValueKey('page_$leftPage'),
                                      pageNumber: leftPage,
                                      onCanvasTapped: _toggleFullScreen,
                                      readMode: 'read',
                                      onTranslateVerse: _switchToTranslationMode,
                                      selectedVerseId: _selectedVerseId,
                                      onVerseSelected: (id) => _onVerseSelected(id, leftPage),
                                    ),
                                  ),
                                  // Spine Divider
                                  _buildSpineDivider(theme),
                                  // Right Page
                                  Expanded(
                                    child: QuranPage(
                                      key: ValueKey('page_$rightPage'),
                                      pageNumber: rightPage,
                                      onCanvasTapped: _toggleFullScreen,
                                      readMode: 'read',
                                      onTranslateVerse: _switchToTranslationMode,
                                      selectedVerseId: _selectedVerseId,
                                      onVerseSelected: (id) => _onVerseSelected(id, rightPage),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              final p = 604 - index;
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Left Column: Translation Panel
                                  Expanded(
                                    child: _buildTafsirPanel(p, theme),
                                  ),
                                  // Subtle divider
                                  Container(
                                    width: 1,
                                    color: theme.dividerColor.withValues(alpha: 0.3),
                                  ),
                                  // Right Column: Quran Page Canvas
                                  Expanded(
                                    child: QuranPage(
                                      key: ValueKey('page_$p'),
                                      pageNumber: p,
                                      onCanvasTapped: _toggleFullScreen,
                                      readMode: 'read',
                                      onTranslateVerse: _switchToTranslationMode,
                                      selectedVerseId: _selectedVerseId,
                                      onVerseSelected: (id) => _onVerseSelected(id, p),
                                    ),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Top Nav Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                offset: isFullScreen ? const Offset(0, -1.2) : Offset.zero,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1360),
                    child: TopNavBar(
                      readMode: readMode,
                      onReadModeChanged: _onReadModeChanged,
                      onThemeTapped: _openThemePicker,
                      onNavMenuTapped: _openNavMenu,
                      isBookmarked: context
                          .watch<BookmarkProvider>()
                          .isPageBookmarked(
                            context.watch<QuranReadingProvider>().activePage,
                          ),
                      onBookmarkTapped: _togglePageBookmark,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Audio Bar & Pagination Dock
            Consumer2<QuranReadingProvider, AudioProvider>(
              builder: (context, readingProvider, audioProvider, child) {
                final l = AppLocalizations.of(context);
                String surahName = l!.loading;
                String hizbName = '...';

                if (readingProvider.verses.isNotEmpty &&
                    readingProvider.chapters.isNotEmpty) {
                  final firstVerse = readingProvider.verses.first;
                  hizbName = '${l.readingHizb} ${firstVerse.hizbNumber}';

                  int chapterId =
                      int.tryParse(firstVerse.verseKey.split(':')[0]) ?? 1;
                  try {
                    final chapter = readingProvider.chapters.firstWhere(
                      (c) => c.id == chapterId,
                    );
                    surahName = l.localeName == 'ar'
                        ? chapter.nameArabic
                        : chapter.nameSimple;
                  } catch (e) {
                    surahName = VerseRefFormatter.surahName(chapterId, l.localeName);
                  }
                }

                String formatDuration(Duration d) {
                  final minutes = d.inMinutes
                      .remainder(60)
                      .toString()
                      .padLeft(2, '0');
                  final seconds = d.inSeconds
                      .remainder(60)
                      .toString()
                      .padLeft(2, '0');
                  if (d.inHours > 0) return '${d.inHours}:$minutes:$seconds';
                  return '$minutes:$seconds';
                }

                final currentPosStr = formatDuration(audioProvider.currentPosition);
                final totalDurStr = formatDuration(audioProvider.totalDuration);
                final progress = audioProvider.totalDuration.inMilliseconds > 0
                    ? (audioProvider.currentPosition.inMilliseconds /
                              audioProvider.totalDuration.inMilliseconds)
                          .clamp(0.0, 1.0)
                    : 0.0;

                String playingVerseLabel = l.readingSelectVerse;
                if (audioProvider.activeVerseKey != null) {
                  playingVerseLabel = VerseRefFormatter.format(
                    audioProvider.activeVerseKey!,
                    locale: l.localeName,
                    tier: VerseRefFormat.standard,
                  );
                }

                bool isViewingPlayingPage = true;
                int? targetPage;
                if (audioProvider.activeVerseKey != null) {
                  final playingPage = _getVersePage(audioProvider.activeVerseKey!);
                  if (readMode == 'read') {
                    final currentS = (readingProvider.activePage + 1) ~/ 2;
                    final rightP = 2 * currentS - 1;
                    final leftP = 2 * currentS;
                    isViewingPlayingPage = (playingPage == rightP || playingPage == leftP);
                  } else {
                    isViewingPlayingPage = (playingPage == readingProvider.activePage);
                  }

                  if (!isViewingPlayingPage) {
                    targetPage = playingPage;
                  }
                }

                return Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    offset: isFullScreen ? const Offset(0, 1.2) : Offset.zero,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1360),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AudioPlayerBridge(
                              isExpanded: isAudioExpanded,
                              isPlaying: audioProvider.isPlaying,
                              isLoading: audioProvider.isLoading,
                              currentPositionText: currentPosStr,
                              totalDurationText: totalDurStr,
                              progress: progress,
                              isViewingPlayingPage: isViewingPlayingPage,
                              playingTitle: playingVerseLabel,
                              reciterId: audioProvider.reciterId,
                              reciterName: audioProvider.reciterName,
                              repeatMode: audioProvider.repeatMode,
                              repeatCount: audioProvider.repeatCount,
                              onJumpToPlayingVerse: targetPage != null
                                  ? () => _handlePageSelected(targetPage!)
                                  : null,
                              onToggleExpand: () => setState(
                                () => isAudioExpanded = !isAudioExpanded,
                              ),
                              onTogglePlay: () {
                                if (audioProvider.activeVerseKey == null &&
                                    readingProvider.verses.isNotEmpty) {
                                  audioProvider.playVerseList(
                                    readingProvider.verses,
                                  );
                                } else {
                                  audioProvider.togglePlay();
                                }
                              },
                              onReciterMenuTapped: _openReciterMenu,
                              onSettingsTapped: _openAudioSettings,
                              onSkipNext: () => audioProvider.skipToNextVerse(),
                              onSkipPrevious: () =>
                                  audioProvider.skipToPreviousVerse(),
                              onJumpForward: () => audioProvider.seekForward(10),
                              onJumpBackward: () => audioProvider.seekBackward(10),
                              onRepeatToggle: () =>
                                  audioProvider.toggleRepeatMode(),
                              onSeek: (val) => audioProvider.seekToFraction(val),
                            ),
                            BottomDock(
                              activePage: readingProvider.activePage,
                              paginationArray: List.generate(
                                604,
                                (index) => index + 1,
                              ),
                              surahName: surahName,
                              hizbName: hizbName,
                              onPageSelected: _handlePageSelected,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Fullscreen Overlay Info
            if (isFullScreen)
              Consumer2<QuranReadingProvider, AudioProvider>(
                builder: (context, readingProvider, audioProvider, child) {
                  final l = AppLocalizations.of(context);
                  String surahName = l!.loading;
                  String juzName = '...';
                  String hizbName = '...';

                  if (readingProvider.verses.isNotEmpty &&
                      readingProvider.chapters.isNotEmpty) {
                    final firstVerse = readingProvider.verses.first;
                    juzName =
                        '${l.readingJuz} ${firstVerse.juzNumber.toString().padLeft(2, '0')}';
                    hizbName = '${l.readingHizb} ${firstVerse.hizbNumber}';

                    int chapterId =
                        int.tryParse(firstVerse.verseKey.split(':')[0]) ?? 1;
                    try {
                      final chapter = readingProvider.chapters.firstWhere(
                        (c) => c.id == chapterId,
                      );
                      surahName = l.localeName == 'ar'
                          ? chapter.nameArabic
                          : chapter.nameSimple;
                    } catch (e) {
                      surahName = VerseRefFormatter.surahName(chapterId, l.localeName);
                    }
                  }

                  final isOddPage = readingProvider.activePage.isOdd;
                  final theme = context.watch<ThemeProvider>();

                  Alignment pageNumberAlignment = Alignment.bottomLeft;
                  Alignment? hizbAlignment;
                  Alignment? indicatorAlignment;

                  final effectiveShowBookIcon = theme.showBookIconIndicator;

                  if (effectiveShowBookIcon) {
                    indicatorAlignment = Alignment.bottomCenter;

                    if (theme.showJuzInfo) {
                      if (theme.dynamicPageInfoEnabled) {
                        pageNumberAlignment = isOddPage
                            ? Alignment.bottomRight
                            : Alignment.bottomLeft;
                        hizbAlignment = isOddPage
                            ? Alignment.bottomLeft
                            : Alignment.bottomRight;
                      } else {
                        pageNumberAlignment = Alignment.bottomLeft;
                        hizbAlignment = Alignment.bottomRight;
                      }
                    } else {
                      if (theme.dynamicPageInfoEnabled) {
                        pageNumberAlignment = isOddPage
                            ? Alignment.bottomRight
                            : Alignment.bottomLeft;
                      } else {
                        pageNumberAlignment = Alignment.bottomLeft;
                      }
                    }
                  } else {
                    if (theme.showJuzInfo) {
                      if (theme.dynamicPageInfoEnabled) {
                        pageNumberAlignment = isOddPage
                            ? Alignment.bottomRight
                            : Alignment.bottomLeft;
                        hizbAlignment = isOddPage
                            ? Alignment.bottomLeft
                            : Alignment.bottomRight;
                      } else {
                        pageNumberAlignment = Alignment.bottomLeft;
                        hizbAlignment = Alignment.bottomRight;
                      }
                    } else {
                      if (theme.dynamicPageInfoEnabled) {
                        pageNumberAlignment = isOddPage
                            ? Alignment.bottomRight
                            : Alignment.bottomLeft;
                      } else {
                        pageNumberAlignment = Alignment.bottomCenter;
                      }
                    }
                  }

                  return Positioned.fill(
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1360),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.only(
                                  left: 26,
                                  right: 26,
                                  top: MediaQuery.paddingOf(context).top > 0
                                      ? 20
                                      : 8,
                                  bottom: 10,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      theme.canvasBackground,
                                      theme.canvasBackground,
                                      theme.canvasBackground.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                                child: SafeArea(
                                  bottom: false,
                                  top: false,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      OverlayText(text: surahName),
                                      OverlayText(text: hizbName),
                                    ],
                                  ),
                                ),
                              ),

                              Container(
                                padding: EdgeInsets.only(
                                  left: 26,
                                  right: 26,
                                  top: 16,
                                  bottom: MediaQuery.paddingOf(context).bottom > 0
                                      ? 20
                                      : 18,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      theme.canvasBackground,
                                      theme.canvasBackground,
                                      theme.canvasBackground.withValues(alpha: 0.0),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                                child: SafeArea(
                                  top: false,
                                  bottom: false,
                                  child: SizedBox(
                                    height: 20,
                                    width: double.infinity,
                                    child: Stack(
                                      children: [
                                        Align(
                                          alignment: pageNumberAlignment,
                                          child: OverlayText(
                                            text: '${readingProvider.activePage}',
                                          ),
                                        ),
                                        if (hizbAlignment != null)
                                          Align(
                                            alignment: hizbAlignment,
                                            child: OverlayText(text: juzName),
                                          ),
                                        if (indicatorAlignment != null &&
                                            effectiveShowBookIcon)
                                          Align(
                                            alignment: indicatorAlignment,
                                            child: BookSideIndicator(
                                              isRightPage: isOddPage,
                                              theme: theme,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
