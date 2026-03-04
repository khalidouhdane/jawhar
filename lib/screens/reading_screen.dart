import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/widgets/audio_player_bridge.dart';
import 'package:quran_app/widgets/bottom_dock.dart';
import 'package:quran_app/widgets/overlays.dart';
import 'package:quran_app/widgets/reading_canvas.dart';
import 'package:quran_app/widgets/top_nav_bar.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    final readingProvider = context.read<QuranReadingProvider>();
    // RTL: page 1 starts at the end of the PageView
    _pageController = PageController(
      initialPage: _totalPages - readingProvider.activePage,
    );

    // Listen to audio provider for auto-page-sliding
    final audioProvider = context.read<AudioProvider>();
    audioProvider.addListener(_onAudioChanged);
  }

  @override
  void dispose() {
    context.read<AudioProvider>().removeListener(_onAudioChanged);
    _pageController.dispose();
    super.dispose();
  }

  /// When the active verse key changes, check if we need to slide to a new page
  void _onAudioChanged() {
    final audioProvider = context.read<AudioProvider>();
    final verseKey = audioProvider.activeVerseKey;

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
    // Look through cached pages first
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
    _showOverlay((ctx) => ThemePickerSheet(onClose: () => Navigator.pop(ctx)));
  }

  void _openSearch() {
    _showOverlay(
      (ctx) => SearchSheet(
        onClose: () => Navigator.pop(ctx),
        onPageSelected: (page) {
          Navigator.pop(ctx);
          _goToPage(page);
        },
      ),
    );
  }

  void _goToPage(int page) {
    final readingProvider = context.read<QuranReadingProvider>();
    readingProvider.loadPage(page);
    _pageController.jumpToPage(_totalPages - page);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: ExcludeSemantics(
        child: Stack(
          children: [
            // Swipeable Reading Canvas
            Consumer<QuranReadingProvider>(
              builder: (context, readingProvider, child) {
                return PageView.builder(
                  controller: _pageController,
                  reverse: false,
                  // RTL: swiping right goes to next page (higher index = lower page)
                  itemCount: _totalPages,
                  onPageChanged: (index) {
                    final page = _totalPages - index;
                    readingProvider.setActivePage(page);
                  },
                  itemBuilder: (context, index) {
                    final page = _totalPages - index;
                    return _QuranPage(
                      pageNumber: page,
                      onCanvasTapped: _toggleFullScreen,
                    );
                  },
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
                  onSearchTapped: _openSearch,
                ),
              ),
            ),

            // Bottom Layers
            Consumer2<QuranReadingProvider, AudioProvider>(
              builder: (context, readingProvider, audioProvider, child) {
                String surahName = 'Loading...';
                String juzName = '...';

                if (readingProvider.verses.isNotEmpty &&
                    readingProvider.chapters.isNotEmpty) {
                  final firstVerse = readingProvider.verses.first;
                  juzName =
                      'Juz ${firstVerse.juzNumber.toString().padLeft(2, '0')}';

                  int chapterId =
                      int.tryParse(firstVerse.verseKey.split(':')[0]) ?? 1;
                  try {
                    surahName = readingProvider.chapters
                        .firstWhere((c) => c.id == chapterId)
                        .nameSimple;
                  } catch (e) {
                    surahName = 'Surah $chapterId';
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

                String playingVerseLabel = 'Select a verse';
                if (audioProvider.activeVerseKey != null) {
                  final parts = audioProvider.activeVerseKey!.split(':');
                  if (parts.length == 2) {
                    playingVerseLabel = '$surahName - Verse ${parts[1]}';
                  } else {
                    playingVerseLabel = '$surahName - Playing...';
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
                          currentPositionText: currentPosStr,
                          totalDurationText: totalDurStr,
                          progress: progress,
                          playingTitle: playingVerseLabel,
                          reciterId: audioProvider.reciterId,
                          reciterName: audioProvider.reciterName,
                          repeatMode: audioProvider.repeatMode,
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
                          juzName: juzName,
                          onPageSelected: _goToPage,
                          onNavMenuTapped: _openNavMenu,
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
                  String surahName = 'Loading...';
                  String juzName = '...';
                  String hizbName = '...';

                  if (readingProvider.verses.isNotEmpty &&
                      readingProvider.chapters.isNotEmpty) {
                    final firstVerse = readingProvider.verses.first;
                    juzName =
                        'Juz ${firstVerse.juzNumber.toString().padLeft(2, '0')}';
                    hizbName = 'Hizb ${firstVerse.hizbNumber}';

                    int chapterId =
                        int.tryParse(firstVerse.verseKey.split(':')[0]) ?? 1;
                    try {
                      surahName = readingProvider.chapters
                          .firstWhere((c) => c.id == chapterId)
                          .nameSimple;
                    } catch (e) {
                      surahName = 'Surah $chapterId';
                    }
                  }

                  // Determine dynamic layout for bottom edge
                  final isOddPage = readingProvider.activePage.isOdd;
                  final theme = context.watch<ThemeProvider>();

                  // Logic for bottom row elements
                  Alignment pageNumberAlignment = Alignment.bottomLeft;
                  Alignment? hizbAlignment;
                  Alignment? indicatorAlignment;

                  if (theme.showBookIconIndicator) {
                    // Indicator is always bottom center
                    indicatorAlignment = Alignment.bottomCenter;

                    if (theme.showHizbInfo) {
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
                    if (theme.showHizbInfo) {
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
                                  _OverlayText(text: juzName),
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
                                        child: _OverlayText(text: hizbName),
                                      ),
                                    if (indicatorAlignment != null)
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
