import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/audio_provider.dart';
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
    });
  }

  void _showOverlay(Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.1,
          ),
          child: DefaultTextStyle(
            style: const TextStyle(fontFamily: 'Inter'),
            child: sheet,
          ),
        );
      },
    );
  }

  void _openReciterMenu() {
    _showOverlay(ReciterMenuSheet(onClose: () => Navigator.pop(context)));
  }

  void _openAudioSettings() {
    _showOverlay(AudioSettingsSheet(onClose: () => Navigator.pop(context)));
  }

  void _openNavMenu() {
    _showOverlay(NavMenuSheet(onClose: () => Navigator.pop(context)));
  }

  void _goToPage(int page) {
    final readingProvider = context.read<QuranReadingProvider>();
    readingProvider.loadPage(page);
    _pageController.jumpToPage(_totalPages - page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          reciterName: audioProvider.reciterName,
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
          ],
        ),
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

    if (_isLoading || _verses == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A454E)),
      );
    }

    if (_verses!.isEmpty) {
      return const Center(
        child: Text('Page not available', style: TextStyle(color: Colors.grey)),
      );
    }

    return ReadingCanvas(
      verses: _verses!,
      selectedVerseId: _selectedVerseId,
      onVerseSelected: (id) => setState(() => _selectedVerseId = id),
      onCanvasTapped: widget.onCanvasTapped,
    );
  }
}
