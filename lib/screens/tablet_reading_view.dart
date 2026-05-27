import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/widgets/floating_corner_card.dart';
import 'package:quran_app/widgets/top_nav_bar.dart';
import 'package:quran_app/widgets/bottom_dock.dart';
import 'package:quran_app/widgets/audio_player_bridge.dart';
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
import 'package:quran_app/utils/tablet_layout_math.dart';
import 'package:quran_app/utils/verse_ref_formatter.dart';
import 'package:quran_app/widgets/context/tafsir_sheet.dart';
import 'package:quran_app/widgets/overlays.dart';
import 'package:quran_app/utils/app_logger.dart';

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
  late final ScrollController _tafsirScrollController;
  String? _lastScrolledVerseKey;
  final Map<String, double> _measuredHeights = {};
  double? _lastFontSize;
  AppTheme? _lastThemeMode;

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
    _tafsirScrollController = ScrollController();
    final startPage = widget.initialPage;

    // Initialize PageController based on the default 'read' mode spreads or 'tafsir' mode pages.
    if (readMode == 'read') {
      final startSpread = TabletLayoutMath.pageToSpread(startPage);
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
      final startSpread = TabletLayoutMath.pageToSpread(startPage);
      _startPagesReadTimer({
        TabletLayoutMath.spreadToRightPage(startSpread),
        TabletLayoutMath.spreadToLeftPage(startSpread),
      });
    } else {
      _startPagesReadTimer({startPage});
    }
  }

  @override
  void dispose() {
    _pageReadTimer?.cancel();
    _audioProvider.removeListener(_onAudioChanged);
    _pageController.dispose();
    _tafsirScrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
      final currentS = TabletLayoutMath.pageToSpread(readingProvider.activePage);
      final rightP = TabletLayoutMath.spreadToRightPage(currentS);
      final leftP = TabletLayoutMath.spreadToLeftPage(currentS);

      // In read mode, only flip pages if playing verse page is outside visible spread
      if (playingPage == rightP || playingPage == leftP) {
        if (readingProvider.activePage != playingPage) {
          readingProvider.setActivePage(playingPage);
        }
        return;
      }

      final targetSpread = TabletLayoutMath.pageToSpread(playingPage);
      _goToSpread(targetSpread);
    } else {
      // In tafsir mode, flip pages immediately when the active verse crosses the page boundary
      if (readingProvider.activePage == playingPage) {
        final verses = readingProvider.getPageVerses(playingPage);
        final index = verses.indexWhere((v) => v.verseKey == verseKey);
        if (index >= 0) {
          _scrollToVerse(index, verseKey);
        }
        return;
      }
      _goToPage(playingPage);
    }
  }

  void _scrollToVerse(int index, String verseKey) {
    if (!mounted) return;

    final activeVerseKey = context.read<AudioProvider>().activeVerseKey;
    final highlightKey = context.read<ContextProvider>().highlightVerseKey;
    final currentKey = activeVerseKey ?? highlightKey;
    if (currentKey != verseKey) return; // Stale scroll target

    if (!_tafsirScrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 50), () => _scrollToVerse(index, verseKey));
      return;
    }

    final readingProvider = context.read<QuranReadingProvider>();
    final activePage = readingProvider.activePage;
    final verses = readingProvider.getPageVerses(activePage);

    // Check if we have measured the heights of the target verse and all preceding verses
    bool allMeasured = true;
    for (int i = 0; i <= index; i++) {
      if (i >= verses.length) break;
      if (!_measuredHeights.containsKey(verses[i].verseKey)) {
        allMeasured = false;
        break;
      }
    }

    if (!allMeasured) {
      AppLogger.warn('TafsirScroll', 'Tablet Scroll index $index ($verseKey): waiting for measurements...');
      Future.delayed(const Duration(milliseconds: 50), () => _scrollToVerse(index, verseKey));
      return;
    }

    final maxScroll = _tafsirScrollController.position.maxScrollExtent;
    _lastScrolledVerseKey = verseKey;

    final double viewportHeight = _tafsirScrollController.position.viewportDimension;
    
    // Sum exact heights of preceding verses
    final double topPadding = MediaQuery.paddingOf(context).top > 0
        ? MediaQuery.paddingOf(context).top + 60
        : 60;

    double offset = topPadding;
    for (int i = 0; i < index; i++) {
      if (i >= verses.length) break;
      offset += _measuredHeights[verses[i].verseKey]!;
    }

    final targetHeight = _measuredHeights[verseKey]!;
    double targetOffset = offset - (viewportHeight / 2) + (targetHeight / 2);
    targetOffset = targetOffset.clamp(0.0, maxScroll);

    AppLogger.warn('TafsirScroll', 'Tablet Scroll index $index ($verseKey): offset: $targetOffset, maxScroll: $maxScroll, viewport: $viewportHeight, topPadding: $topPadding');

    _tafsirScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToSpread(int spread) {
    final readingProvider = context.read<QuranReadingProvider>();
    final rightPage = TabletLayoutMath.spreadToRightPage(spread);
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
      final startSpread = TabletLayoutMath.pageToSpread(activePage);
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
      final spread = TabletLayoutMath.pageToSpread(activePage);
      _startPagesReadTimer({
        TabletLayoutMath.spreadToRightPage(spread),
        TabletLayoutMath.spreadToLeftPage(spread),
      });
    } else {
      _startPagesReadTimer({activePage});
    }
  }

  void _handlePageSelected(int page) {
    final readingProvider = context.read<QuranReadingProvider>();
    readingProvider.loadPage(page);
    if (readMode == 'read') {
      final spread = TabletLayoutMath.pageToSpread(page);
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
    final rightPage = TabletLayoutMath.spreadToRightPage(S);
    final leftPage = TabletLayoutMath.spreadToLeftPage(S);

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
    _lastScrolledVerseKey = null;
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
    if (translations.isEmpty && !contextProvider.isPageLoading(pageNumber)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          contextProvider.loadPageTranslations(pageNumber);
        }
      });
    }

    if (contextProvider.isPageLoading(pageNumber) && translations.isEmpty) {
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
    final activeVerseKey = context.watch<AudioProvider>().activeVerseKey;

    final scrollKey = activeVerseKey ?? highlightKey;
    if (scrollKey != null && scrollKey != _lastScrolledVerseKey) {
      final index = verses.indexWhere((v) => v.verseKey == scrollKey);
      if (index >= 0) {
        _lastScrolledVerseKey = scrollKey;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _scrollToVerse(index, scrollKey);
          if (scrollKey == highlightKey) {
            context.read<ContextProvider>().clearHighlightVerse();
          }
        });
      }
    }

    // Clear height cache if typography/theme parameters change
    if (_lastFontSize != theme.quranFontSize || _lastThemeMode != theme.theme) {
      _lastFontSize = theme.quranFontSize;
      _lastThemeMode = theme.theme;
      _measuredHeights.clear();
      _lastScrolledVerseKey = null;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _toggleFullScreen,
      child: SingleChildScrollView(
        controller: _tafsirScrollController,
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top > 0
              ? MediaQuery.paddingOf(context).top + 60
              : 60,
          bottom: 120,
          left: 20,
          right: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(verses.length, (index) {
            final verse = verses[index];
            final verseText = verse.words
                .where((w) => w.charTypeName != 'end')
                .map((w) => w.textUthmani)
                .join(' ');
            final translation = translations[verse.verseKey];
            final isHighlighted = (activeVerseKey != null && verse.verseKey == activeVerseKey) ||
                                  (highlightKey != null && verse.verseKey == highlightKey);

            return LayoutBuilder(
              builder: (context, constraints) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null && renderBox.hasSize) {
                    final height = renderBox.size.height;
                    if (_measuredHeights[verse.verseKey] != height) {
                      _measuredHeights[verse.verseKey] = height;
                    }
                  }
                });

                return GestureDetector(
            onTap: _toggleFullScreen,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? theme.verseHighlight
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(theme.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
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
                                color: theme.pillBackground,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                size: 12,
                                color: theme.accentColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Tafsir button
                          GestureDetector(
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
                                initialTabIndex: 0,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.pillBackground,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.bookOpen, size: 12, color: theme.accentColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    l.contextTafsir,
                                    style: TextStyle(
                                      fontFamily: GeistTypography.primaryFontFamily,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.primaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (contextProvider.asbabService.hasOccasionByKey(verse.verseKey)) ...[
                            const SizedBox(width: 8),
                            // Reason button
                            GestureDetector(
                              onTap: () {
                                final readingProv = context.read<QuranReadingProvider>();
                                final chapterId = int.tryParse(verse.verseKey.split(':').first) ?? 1;
                                String? surahName;
                                try {
                                  surahName = readingProv.chapters
                                      .firstWhere((c) => c.id == chapterId)
                                      .nameSimple;
                                } catch (_) {}
                                context.read<ContextProvider>().loadAsbabNuzul(verse.verseKey);
                                showTafsirSheet(
                                  context,
                                  verseKey: verse.verseKey,
                                  surahName: surahName,
                                  initialTabIndex: 2,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.accentColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: theme.accentColor.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.history_edu, size: 12, color: theme.accentColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppLocalizations.of(context)?.asbabNuzulTitle ?? 'Reason',
                                      style: TextStyle(
                                        fontFamily: GeistTypography.primaryFontFamily,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: theme.accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
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
                      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: theme.accentColor.withValues(alpha: 0.5),
                            width: 3,
                          ),
                        ),
                      ),
                      margin: const EdgeInsets.only(top: 8),
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
                      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.3),
                            width: 3,
                          ),
                        ),
                      ),
                      margin: const EdgeInsets.only(top: 8),
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
    }),
  ),
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
                              final rightPage = TabletLayoutMath.spreadToRightPage(S);
                              final leftPage = TabletLayoutMath.spreadToLeftPage(S);

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

            // Split-Corner overlay layout for tablets
            Consumer3<QuranReadingProvider, AudioProvider, BookmarkProvider>(
              builder: (context, readingProvider, audioProvider, bookmarkProvider, child) {
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

                final isBookmarked = bookmarkProvider.isPageBookmarked(
                  readingProvider.activePage,
                );

                final werdProvider = context.watch<WerdProvider>();
                final hasWerd = werdProvider.hasWerd && werdProvider.config?.isEnabled == true;
                final config = werdProvider.config;
                final progressToday = hasWerd && config != null && config.todayTarget > 0
                    ? (config.pagesReadToday / config.todayTarget).clamp(0.0, 1.0)
                    : 0.0;

                bool isViewingPlayingPage = true;
                int? targetPage;
                if (audioProvider.activeVerseKey != null) {
                  final playingPage = _getVersePage(audioProvider.activeVerseKey!);
                  if (readMode == 'read') {
                    final spread = TabletLayoutMath.pageToSpread(readingProvider.activePage);
                    final rightPage = TabletLayoutMath.spreadToRightPage(spread);
                    final leftPage = TabletLayoutMath.spreadToLeftPage(spread);
                    isViewingPlayingPage = (playingPage == rightPage || playingPage == leftPage);
                  } else {
                    isViewingPlayingPage = (readingProvider.activePage == playingPage);
                  }
                  if (!isViewingPlayingPage) {
                    targetPage = playingPage;
                  }
                }

                return Stack(
                  children: [
                    // ── Card 1: Top-Start (Back & Mode Toggle) ──
                    FloatingCornerCard(
                      alignment: AlignmentDirectional.topStart,
                      slideOffset: const Offset(-1.2, -1.2),
                      isFullScreen: isFullScreen,
                      maxWidth: 320,
                      padding: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TopLeftNavBar(
                          readMode: readMode,
                          onReadModeChanged: (v) {
                            _onReadModeChanged(v);
                          },
                        ),
                      ),
                    ),

                    // ── Card 2: Top-End (Surah Info & Actions) ──
                    FloatingCornerCard(
                      alignment: AlignmentDirectional.topEnd,
                      slideOffset: const Offset(1.2, -1.2),
                      isFullScreen: isFullScreen,
                      maxWidth: 360,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                surahName,
                                style: TextStyle(
                                  fontFamily: GeistTypography.primaryFontFamily,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryText,
                                ),
                              ),
                              Text(
                                hizbName,
                                style: TextStyle(
                                  fontFamily: GeistTypography.primaryFontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: theme.secondaryText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(color: theme.dividerColor.withValues(alpha: 0.1), height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${l.readingJuz} ${readingProvider.verses.isNotEmpty ? readingProvider.verses.first.juzNumber : "..."} · ${l.homePage} ${readingProvider.activePage}',
                                style: TextStyle(
                                  fontFamily: GeistTypography.primaryFontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: theme.mutedText,
                                ),
                              ),
                              TopRightNavBar(
                                isBookmarked: isBookmarked,
                                onThemeTapped: _openThemePicker,
                                onNavMenuTapped: _openNavMenu,
                                onBookmarkTapped: _togglePageBookmark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Card 3: Bottom-Start (Audio Hub) ──
                    FloatingCornerCard(
                      alignment: AlignmentDirectional.bottomStart,
                      slideOffset: const Offset(-1.2, 1.2),
                      isFullScreen: isFullScreen,
                      maxWidth: 360,
                      padding: EdgeInsets.zero,
                      child: AudioPlayerBridge(
                        margin: EdgeInsets.zero,
                        decoration: const BoxDecoration(color: Colors.transparent),
                        isExpanded: isAudioExpanded,
                        isPlaying: audioProvider.isPlaying,
                        isLoading: audioProvider.isLoading,
                        isViewingPlayingPage: isViewingPlayingPage,
                        currentPositionText: currentPosStr,
                        totalDurationText: totalDurStr,
                        progress: progress,
                        playingTitle: playingVerseLabel,
                        reciterId: audioProvider.reciterId,
                        reciterName: audioProvider.reciterName,
                        repeatMode: audioProvider.repeatMode,
                        repeatCount: audioProvider.repeatCount,
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
                        onJumpToPlayingVerse: targetPage != null
                            ? () => _handlePageSelected(targetPage!)
                            : null,
                      ),
                    ),

                    // ── Card 4: Bottom-End (Quick Navigation & Werd) ──
                    FloatingCornerCard(
                      alignment: AlignmentDirectional.bottomEnd,
                      slideOffset: const Offset(1.2, 1.2),
                      isFullScreen: isFullScreen,
                      maxWidth: 360,
                      padding: EdgeInsets.zero,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BottomDock(
                            margin: EdgeInsets.zero,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            decoration: const BoxDecoration(color: Colors.transparent),
                            activePage: readingProvider.activePage,
                            paginationArray: List.generate(
                              604,
                              (index) => index + 1,
                            ),
                            surahName: surahName,
                            hizbName: hizbName,
                            onPageSelected: _handlePageSelected,
                          ),
                          if (hasWerd && config != null) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        l.localeName == 'ar' ? 'الورد اليومي' : 'Daily Werd',
                                        style: TextStyle(
                                          fontFamily: GeistTypography.primaryFontFamily,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: theme.secondaryText,
                                        ),
                                      ),
                                      Text(
                                        '${config.pagesReadToday} / ${config.todayTarget} ${l.localeName == 'ar' ? 'صفحة' : 'pages'}',
                                        style: TextStyle(
                                          fontFamily: GeistTypography.primaryFontFamily,
                                          fontSize: 9,
                                          color: theme.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progressToday,
                                      minHeight: 3,
                                      backgroundColor: theme.sliderInactive,
                                      valueColor: AlwaysStoppedAnimation<Color>(theme.accentColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
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
