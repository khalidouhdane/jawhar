import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/werd_provider.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/widgets/audio_player_bridge.dart';
import 'package:quran_app/widgets/bottom_dock.dart';
import 'package:quran_app/widgets/overlays.dart';
import 'package:quran_app/widgets/reading_canvas.dart';
import 'package:quran_app/providers/bookmark_provider.dart';

import 'package:quran_app/widgets/top_nav_bar.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran/quran.dart' as quran;

class ReadingScreen extends StatefulWidget {
  final int initialPage;
  const ReadingScreen({super.key, this.initialPage = 1});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  String readMode = 'read';

  bool isAudioExpanded = false;
  bool isFullScreen = false;

  // PageView for swipe navigation (RTL: page 1 is rightmost)
  late PageController _pageController;
  static const int _totalPages = 604;

  // Track audio verse changes for auto-page-sliding
  String? _lastActiveVerseKey;

  // Saved reference to avoid context.read in dispose
  late final AudioProvider _audioProvider;

  // Werd progress tracking
  final Set<int> _readPagesInSession = {};
  Timer? _pageReadTimer;
  bool _hasExceededGoalThisSession = false;

  @override
  void initState() {
    super.initState();
    final startPage = widget.initialPage;

    // RTL: page 1 starts at the end of the PageView.
    // keepPage: false prevents PageStorage from restoring the old position
    // when the Consumer rebuilds the PageView on subsequent visits.
    _pageController = PageController(
      initialPage: _totalPages - startPage,
      keepPage: false,
    );

    // Set provider state after the first frame to avoid rebuild race
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QuranReadingProvider>().setActivePage(startPage);
    });

    // Save ref for dispose, initialize _lastActiveVerseKey
    _audioProvider = context.read<AudioProvider>();
    _lastActiveVerseKey = _audioProvider.activeVerseKey;
    _audioProvider.addListener(_onAudioChanged);

    // Track initial page for Werd progress
    _startPageReadTimer(startPage);
  }

  @override
  void dispose() {
    _pageReadTimer?.cancel();
    _audioProvider.removeListener(_onAudioChanged);
    _pageController.dispose();
    super.dispose();
  }

  /// When the active verse key changes, check if we need to slide to a new page.
  void _onAudioChanged() {
    if (!mounted) return;

    final verseKey = _audioProvider.activeVerseKey;

    if (verseKey == null || verseKey == _lastActiveVerseKey) return;
    _lastActiveVerseKey = verseKey;

    // Check if the currently playing verse is on the current page
    final readingProvider = context.read<QuranReadingProvider>();
    final currentPageVerses = readingProvider.verses;

    final isOnCurrentPage = currentPageVerses.any(
      (v) => v.verseKey == verseKey,
    );
    if (isOnCurrentPage) return;

    // The verse is NOT on the current page — find which page it belongs to
    _findAndSlideTo(verseKey, readingProvider);
  }

  /// Find the page containing this verse key and slide to it
  void _findAndSlideTo(
    String verseKey,
    QuranReadingProvider readingProvider,
  ) async {
    final currentPage = readingProvider.activePage;

    // Try the next page first (most common case: audio advancing forward)
    final nextPage = currentPage + 1;
    if (nextPage <= _totalPages) {
      final nextVerses = await readingProvider.getPageVerses(nextPage);
      if (nextVerses.any((v) => v.verseKey == verseKey)) {
        _goToPage(nextPage);
        return;
      }
    }

    // Try previous page (less common but possible with RTL)
    final prevPage = currentPage - 1;
    if (prevPage >= 1) {
      final prevVerses = await readingProvider.getPageVerses(prevPage);
      if (prevVerses.any((v) => v.verseKey == verseKey)) {
        _goToPage(prevPage);
        return;
      }
    }
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

  void _showOverlay(Widget Function(BuildContext sheetContext) sheetBuilder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow sheets to be taller if needed
      backgroundColor: Colors.transparent, // Required for custom sheet shapes
      builder: (sheetContext) {
        return ExcludeSemantics(
          child: Padding(
            padding: EdgeInsets.only(
              top:
                  MediaQuery.of(sheetContext).size.height *
                  0.1, // Leave top space
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
    _showOverlay(
      (ctx) => AudioSettingsSheet(onClose: () => Navigator.pop(ctx)),
    );
  }

  void _openNavMenu() {
    _showOverlay(
      (ctx) => NavMenuSheet(
        onClose: () => Navigator.pop(ctx),
        onPageSelected: (page) {
          Navigator.pop(ctx); // Close sheet
          _goToPage(page);
        },
      ),
    );
  }

  void _openThemePicker() {
    _showOverlay(
      (ctx) => ThemePickerSheet(onClose: () => Navigator.pop(ctx)),
    );
  }


  void _goToPage(int page) {
    final readingProvider = context.read<QuranReadingProvider>();
    readingProvider.loadPage(page);
    _pageController.jumpToPage(_totalPages - page);
  }

  /// Persist the current reading position for the Home Screen hero card.
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

  // ── Werd Progress Tracking ───────────────────────────────────────────────

  void _startPageReadTimer(int page) {
    _pageReadTimer?.cancel();

    // If already read this session, don't start timer again
    if (_readPagesInSession.contains(page)) return;

    final werdProvider = context.read<WerdProvider>();
    if (!werdProvider.hasWerd || werdProvider.config?.isEnabled != true) return;

    _pageReadTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      _markPageAsRead(page);
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
        message = "Halfway there! Keep it up. 🌟";
        icon = LucideIcons.star;
        iconColor = Colors.orangeAccent;
      }
    } else if (oldRead < target * 0.8 &&
        newRead >= target * 0.8 &&
        newRead < target) {
      message = "Almost there! Just a bit more. 💪";
      icon = LucideIcons.flame;
      iconColor = Colors.orangeAccent;
    } else if (oldRead < target && newRead >= target) {
      message = "Masha'Allah! Daily Goal Completed! 🎉";
      icon = LucideIcons.checkCircle2;
      iconColor = Colors.green;
    } else if (oldRead == target &&
        newRead > target &&
        !_hasExceededGoalThisSession) {
      message = "Exceeding your daily goal! May Allah reward you. 🌺";
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
                  fontFamily: 'Inter',
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        duration: const Duration(seconds: 4),
        elevation: 4,
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
            // Reading Canvas — PageView for swipe navigation
             Consumer<QuranReadingProvider>(
              builder: (context, readingProvider, child) {
                // Force LTR so swipe direction is always consistent:
                // drag left→right = next page. Our index math already
                // handles the Quran's RTL page ordering.
                return Directionality(
                  textDirection: TextDirection.ltr,
                  child: PageView.builder(
                  controller: _pageController,
                  reverse: false,
                  itemCount: _totalPages,
                  onPageChanged: (index) {
                    final page = _totalPages - index;
                    readingProvider.setActivePage(page);

                    // Save last-read position for the Home Screen hero card
                    _saveLastReadPosition(page, readingProvider);

                    // Track Werd reading progress
                    _startPageReadTimer(page);
                  },
                  itemBuilder: (context, index) {
                    final page = _totalPages - index;
                    return _QuranPage(
                      pageNumber: page,
                      onCanvasTapped: _toggleFullScreen,
                    );
                  },
                ),
                );
              },
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
                child: TopNavBar(
                  readMode: readMode,
                  onReadModeChanged: (mode) => setState(() => readMode = mode),
                  onThemeTapped: _openThemePicker,
                  onNavMenuTapped: _openNavMenu,
                  isBookmarked: context.watch<BookmarkProvider>().isPageBookmarked(
                    context.watch<QuranReadingProvider>().activePage,
                  ),
                  onBookmarkTapped: () {
                    final rp = context.read<QuranReadingProvider>();
                    final l = AppLocalizations.of(context);
                    String sName = '';
                    if (rp.verses.isNotEmpty && rp.chapters.isNotEmpty) {
                      final chId = int.tryParse(rp.verses.first.verseKey.split(':')[0]) ?? 1;
                      try {
                        final ch = rp.chapters.firstWhere((c) => c.id == chId);
                        sName = l.locale.languageCode == 'ar' ? ch.nameArabic : ch.nameSimple;
                      } catch (_) {
                        sName = 'Surah $chId';
                      }
                    }
                    final added = context.read<BookmarkProvider>().togglePageBookmark(
                      pageNumber: rp.activePage,
                      surahName: sName,
                    );
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          added
                              ? '${l.t('home_page')} ${rp.activePage} bookmarked'
                              : 'Bookmark removed',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Bottom Layers
            Consumer2<QuranReadingProvider, AudioProvider>(
              builder: (context, readingProvider, audioProvider, child) {
                final l = AppLocalizations.of(context);
                String surahName = l.t('loading');
                String hizbName = '...';

                if (readingProvider.verses.isNotEmpty &&
                    readingProvider.chapters.isNotEmpty) {
                  final firstVerse = readingProvider.verses.first;
                  hizbName =
                      '${l.t('reading_hizb')} ${firstVerse.hizbNumber}';

                  int chapterId =
                      int.tryParse(firstVerse.verseKey.split(':')[0]) ?? 1;
                  try {
                    final chapter = readingProvider.chapters.firstWhere(
                      (c) => c.id == chapterId,
                    );
                    surahName = l.locale.languageCode == 'ar'
                        ? chapter.nameArabic
                        : chapter.nameSimple;
                  } catch (e) {
                    surahName = '${l.t('read_tab_surah')} $chapterId';
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

                final currentPosStr = formatDuration(
                  audioProvider.currentPosition,
                );
                final totalDurStr = formatDuration(audioProvider.totalDuration);
                final progress = audioProvider.totalDuration.inMilliseconds > 0
                    ? (audioProvider.currentPosition.inMilliseconds /
                              audioProvider.totalDuration.inMilliseconds)
                          .clamp(0.0, 1.0)
                    : 0.0;

                // Build the playing title from the ACTUAL playing verse, not the viewed page
                String playingVerseLabel = l.t('reading_select_verse');
                if (audioProvider.activeVerseKey != null) {
                  final parts = audioProvider.activeVerseKey!.split(':');
                  if (parts.length == 2) {
                    // Look up the playing verse's chapter
                    final playingChapterId = int.tryParse(parts[0]) ?? 0;
                    String playingSurahName = surahName; // fallback
                    if (readingProvider.chapters.isNotEmpty &&
                        playingChapterId > 0) {
                      try {
                        final playingChapter = readingProvider.chapters
                            .firstWhere((c) => c.id == playingChapterId);
                        playingSurahName = l.locale.languageCode == 'ar'
                            ? playingChapter.nameArabic
                            : playingChapter.nameSimple;
                      } catch (_) {}
                    }
                    playingVerseLabel =
                        '$playingSurahName - ${l.t('reading_verse')} ${parts[1]}';
                  } else {
                    playingVerseLabel =
                        '$surahName - ${l.t('reading_playing')}';
                  }
                }
                // Determine if we are currently viewing the page that is playing
                bool isViewingPlayingPage = true;
                int? targetPage;
                if (audioProvider.activeVerseKey != null &&
                    readingProvider.verses.isNotEmpty) {
                  isViewingPlayingPage = readingProvider.verses.any(
                    (v) => v.verseKey == audioProvider.activeVerseKey,
                  );



                  if (!isViewingPlayingPage) {
                    final parts = audioProvider.activeVerseKey!.split(':');
                    if (parts.length == 2) {
                      final surah = int.tryParse(parts[0]);
                      final ayah = int.tryParse(parts[1]);
                      if (surah != null && ayah != null) {
                        targetPage = quran.getPageNumber(surah, ayah);
                      }
                    }
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
                          onJumpToPlayingVerse: targetPage != null
                              ? () => _goToPage(targetPage!)
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
                          onPageSelected: _goToPage,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Fullscreen Overlay Info (separate Consumer so it doesn't block touches)
            if (isFullScreen)
              Consumer2<QuranReadingProvider, AudioProvider>(
                builder: (context, readingProvider, audioProvider, child) {
                  final l = AppLocalizations.of(context);
                  String surahName = l.t('loading');
                  String juzName = '...';
                  String hizbName = '...';

                  if (readingProvider.verses.isNotEmpty &&
                      readingProvider.chapters.isNotEmpty) {
                    final firstVerse = readingProvider.verses.first;
                    juzName =
                        '${l.t('reading_juz')} ${firstVerse.juzNumber.toString().padLeft(2, '0')}';
                    hizbName =
                        '${l.t('reading_hizb')} ${firstVerse.hizbNumber}';

                    int chapterId =
                        int.tryParse(firstVerse.verseKey.split(':')[0]) ?? 1;
                    try {
                      final chapter = readingProvider.chapters.firstWhere(
                        (c) => c.id == chapterId,
                      );
                      surahName = l.locale.languageCode == 'ar'
                          ? chapter.nameArabic
                          : chapter.nameSimple;
                    } catch (e) {
                      surahName = '${l.t('read_tab_surah')} $chapterId';
                    }
                  }

                  // Determine dynamic layout for bottom edge
                  final isOddPage = readingProvider.activePage.isOdd;
                  final theme = context.watch<ThemeProvider>();

                  // Logic for bottom row elements
                  Alignment pageNumberAlignment = Alignment.bottomLeft;
                  Alignment? hizbAlignment;
                  Alignment? indicatorAlignment;

                  final effectiveShowBookIcon = theme.showBookIconIndicator;

                  if (effectiveShowBookIcon) {
                    // Indicator is always bottom center
                    indicatorAlignment = Alignment.bottomCenter;

                    if (theme.showJuzInfo) {
                      if (theme.dynamicPageInfoEnabled) {
                        // Page and Hizb swap left/right
                        pageNumberAlignment = isOddPage
                            ? Alignment.bottomRight
                            : Alignment.bottomLeft;
                        hizbAlignment = isOddPage
                            ? Alignment.bottomLeft
                            : Alignment.bottomRight;
                      } else {
                        // Page takes Left, Hizb takes Right
                        pageNumberAlignment = Alignment.bottomLeft;
                        hizbAlignment = Alignment.bottomRight;
                      }
                    } else {
                      if (theme.dynamicPageInfoEnabled) {
                        // Page moves left/right
                        pageNumberAlignment = isOddPage
                            ? Alignment.bottomRight
                            : Alignment.bottomLeft;
                      } else {
                        // Page takes Bottom Left
                        pageNumberAlignment = Alignment.bottomLeft;
                      }
                    }
                  } else {
                    // Indicator is OFF
                    if (theme.showJuzInfo) {
                      if (theme.dynamicPageInfoEnabled) {
                        // Page and Hizb swap left/right
                        pageNumberAlignment = isOddPage
                            ? Alignment.bottomRight
                            : Alignment.bottomLeft;
                        hizbAlignment = isOddPage
                            ? Alignment.bottomLeft
                            : Alignment.bottomRight;
                      } else {
                        // Page takes Left, Hizb takes Right
                        pageNumberAlignment = Alignment.bottomLeft;
                        hizbAlignment = Alignment.bottomRight;
                      }
                    } else {
                      if (theme.dynamicPageInfoEnabled) {
                        // Page moves left/right
                        pageNumberAlignment = isOddPage
                            ? Alignment.bottomRight
                            : Alignment.bottomLeft;
                      } else {
                        // Page takes Bottom Center
                        pageNumberAlignment = Alignment.bottomCenter;
                      }
                    }
                  }

                  return Positioned.fill(
                    child: IgnorePointer(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // ── Top Row (2 Infos with Gradient) ──
                          Container(
                            padding: EdgeInsets.only(
                              left: 26,
                              right: 26,
                              top: MediaQuery.paddingOf(context).top > 0
                                  ? 20 // Smart padding: clears device corners but stays in 'ears'
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
                                  _OverlayText(text: surahName),
                                  _OverlayText(text: hizbName),
                                ],
                              ),
                            ),
                          ),

                          // ── Bottom Row (Dynamic with Gradient) ──
                          Container(
                            padding: EdgeInsets.only(
                              left: 26,
                              right: 26,
                              top: 16,
                              bottom: MediaQuery.paddingOf(context).bottom > 0
                                  ? 20 // Clears bottom swipe bar corners but stays low
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
                                        child: _OverlayText(
                                          text: '${readingProvider.activePage}',
                                        ),
                                      ),
                                      if (hizbAlignment != null)
                                        Align(
                                          alignment: hizbAlignment,
                                          child: _OverlayText(text: juzName),
                                        ),
                                    if (indicatorAlignment != null && effectiveShowBookIcon)
                                      Align(
                                        alignment: indicatorAlignment,
                                        child: _BookSideIndicator(
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
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _OverlayText extends StatelessWidget {
  final String text;

  const _OverlayText({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: theme.overlayFontSize,
        fontWeight: FontWeight.w500,
        color: theme.overlayTextColor.withValues(alpha: theme.overlayOpacity),
        letterSpacing: 0.5,
      ),
    );
  }
}

/// A single Quran page that loads its own data and manages its own selection
class _QuranPage extends StatefulWidget {
  final int pageNumber;
  final VoidCallback onCanvasTapped;

  const _QuranPage({required this.pageNumber, required this.onCanvasTapped});

  @override
  State<_QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<_QuranPage>
    with AutomaticKeepAliveClientMixin {
  List<Verse>? _verses;
  bool _isLoading = true;
  int? _selectedVerseId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    final provider = context.read<QuranReadingProvider>();
    final verses = await provider.getPageVerses(widget.pageNumber);
    if (mounted) {
      setState(() {
        _verses = verses;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = context.watch<ThemeProvider>();

    if (_isLoading || _verses == null) {
      return Center(child: CircularProgressIndicator(color: theme.accentColor));
    }

    if (_verses!.isEmpty) {
      return Center(
        child: Text(
          'Page not available',
          style: TextStyle(color: theme.mutedText),
        ),
      );
    }

    return ReadingCanvas(
      verses: _verses!,
      pageNumber: widget.pageNumber,
      selectedVerseId: _selectedVerseId,
      onVerseSelected: (id) => setState(() => _selectedVerseId = id),
      onCanvasTapped: widget.onCanvasTapped,
    );
  }
}

class _BookSideIndicator extends StatelessWidget {
  final bool isRightPage;
  final ThemeProvider theme;

  const _BookSideIndicator({required this.isRightPage, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Left Page
        Container(
          width: 14,
          height: 16,
          decoration: BoxDecoration(
            color: !isRightPage ? null : theme.indicatorInactive,
            gradient: !isRightPage
                ? LinearGradient(
                    colors: theme.modeToggleGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              bottomLeft: Radius.circular(3),
              topRight: Radius.circular(1),
              bottomRight: Radius.circular(1),
            ),
          ),
        ),
        const SizedBox(width: 1),
        // Right Page
        Container(
          width: 14,
          height: 16,
          decoration: BoxDecoration(
            color: isRightPage ? null : theme.indicatorInactive,
            gradient: isRightPage
                ? LinearGradient(
                    colors: theme.modeToggleGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(3),
              bottomRight: Radius.circular(3),
              topLeft: Radius.circular(1),
              bottomLeft: Radius.circular(1),
            ),
          ),
        ),
      ],
    );
  }
}
