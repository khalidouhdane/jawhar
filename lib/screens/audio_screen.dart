import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/reading_screen.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // ── Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Listen',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Explore reciters and listen to the Quran',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.secondaryText,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Now Playing Mini Bar ──
            _buildNowPlayingBar(theme),

            // ── Search Bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: theme.inputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: theme.primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search reciters or surahs...',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: theme.mutedText,
                    ),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 18,
                      color: theme.mutedText,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tab Switcher ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: theme.pillBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: theme.accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.secondaryText,
                  labelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Reciters'),
                    Tab(text: 'Surahs'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Tab Content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildRecitersTab(theme), _buildSurahsTab(theme)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Now Playing Bar ──
  Widget _buildNowPlayingBar(ThemeProvider theme) {
    return Consumer<AudioProvider>(
      builder: (context, audio, _) {
        if (audio.activeVerseKey == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: GestureDetector(
            onTap: () {
              // Navigate to reading screen at the currently playing page
              final readingProvider = context.read<QuranReadingProvider>();
              final page = readingProvider.activePage;
              final nav = context.read<NavigationProvider>();
              nav.enterReadingView();
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => ReadingScreen(initialPage: page),
                    ),
                  )
                  .then((_) => nav.exitReadingView());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.accentColor,
                    theme.accentColor.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: theme.accentColor.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Animated equalizer indicator
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      audio.isPlaying ? LucideIcons.volume2 : LucideIcons.pause,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Now Playing — ${audio.activeVerseKey}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          audio.reciterName,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => audio.togglePlay(),
                    child: Icon(
                      audio.isPlaying ? LucideIcons.pause : LucideIcons.play,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Reciters Tab ──
  Widget _buildRecitersTab(ThemeProvider theme) {
    return Consumer<QuranReadingProvider>(
      builder: (context, provider, _) {
        final reciters = provider.reciters;
        if (reciters.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.accentColor,
            ),
          );
        }

        final filtered = _searchQuery.isEmpty
            ? reciters
            : reciters
                  .where(
                    (r) => r.reciterName.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final reciter = filtered[index];
            return _buildReciterTile(theme, reciter);
          },
        );
      },
    );
  }

  Widget _buildReciterTile(ThemeProvider theme, Reciter reciter) {
    final audio = context.watch<AudioProvider>();
    final isActive = audio.reciterId == reciter.id;

    return GestureDetector(
      onTap: () {
        // Select this reciter and switch to Surahs tab
        audio.setReciter(reciter.id, name: reciter.reciterName);
        _tabController.animateTo(1);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive
              ? theme.accentColor.withValues(alpha: 0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? theme.accentColor.withValues(alpha: 0.3)
                : theme.dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Reciter avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(
                  alpha: isActive ? 0.15 : 0.08,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  reciter.reciterName.isNotEmpty
                      ? reciter.reciterName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reciter.reciterName,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isActive ? theme.accentColor : theme.primaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (reciter.style != null)
                    Text(
                      reciter.style!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: theme.mutedText,
                      ),
                    ),
                ],
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Icon(LucideIcons.chevronRight, size: 18, color: theme.mutedText),
          ],
        ),
      ),
    );
  }

  // ── Surahs Tab ──
  Widget _buildSurahsTab(ThemeProvider theme) {
    return Consumer2<QuranReadingProvider, AudioProvider>(
      builder: (context, readingProvider, audio, _) {
        final chapters = readingProvider.chapters;
        if (chapters.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.accentColor,
            ),
          );
        }

        final filtered = _searchQuery.isEmpty
            ? chapters
            : chapters
                  .where(
                    (c) =>
                        c.nameSimple.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        c.nameArabic.contains(_searchQuery),
                  )
                  .toList();

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final chapter = filtered[index];
            return _buildSurahTile(theme, chapter, audio, readingProvider);
          },
        );
      },
    );
  }

  Widget _buildSurahTile(
    ThemeProvider theme,
    Chapter chapter,
    AudioProvider audio,
    QuranReadingProvider readingProvider,
  ) {
    // Check if currently playing this chapter
    final isPlaying =
        audio.activeVerseKey != null &&
        audio.activeVerseKey!.startsWith('${chapter.id}:');

    return GestureDetector(
      onTap: () => _playSurah(chapter, audio, readingProvider),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPlaying
              ? theme.accentColor.withValues(alpha: 0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPlaying
                ? theme.accentColor.withValues(alpha: 0.3)
                : theme.dividerColor,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Surah number
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${chapter.id}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.accentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chapter.nameSimple,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPlaying ? theme.accentColor : theme.primaryText,
                    ),
                  ),
                  Text(
                    '${chapter.versesCount} verses',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: theme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            // Arabic name
            Text(
              chapter.nameArabic,
              style: TextStyle(
                fontFamily: 'KFGQPC HAFS Uthmanic Script',
                fontSize: 18,
                color: isPlaying
                    ? theme.accentColor
                    : theme.primaryText.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(width: 12),
            // Play/pause button
            GestureDetector(
              onTap: () {
                if (isPlaying) {
                  audio.togglePlay();
                } else {
                  _playSurah(chapter, audio, readingProvider);
                }
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isPlaying
                      ? theme.accentColor
                      : theme.accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying && audio.isPlaying
                      ? LucideIcons.pause
                      : LucideIcons.play,
                  size: 16,
                  color: isPlaying ? Colors.white : theme.accentColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Start playing a surah from its first verse
  Future<void> _playSurah(
    Chapter chapter,
    AudioProvider audio,
    QuranReadingProvider readingProvider,
  ) async {
    // Get the first page of this surah
    // Use the surah starting pages from the Quran metadata
    final startPage = _surahStartPages[chapter.id] ?? 1;
    final verses = await readingProvider.getPageVerses(startPage);
    if (verses.isNotEmpty) {
      // Find the first verse of THIS surah on the page
      final startIndex = verses.indexWhere(
        (v) => v.verseKey.startsWith('${chapter.id}:'),
      );
      audio.playVerseList(verses, startIndex: startIndex >= 0 ? startIndex : 0);
    }
  }

  // Surah starting pages (1-indexed)
  static const Map<int, int> _surahStartPages = {
    1: 1,
    2: 2,
    3: 50,
    4: 77,
    5: 106,
    6: 128,
    7: 151,
    8: 177,
    9: 187,
    10: 208,
    11: 221,
    12: 235,
    13: 249,
    14: 255,
    15: 262,
    16: 267,
    17: 282,
    18: 293,
    19: 305,
    20: 312,
    21: 322,
    22: 332,
    23: 342,
    24: 350,
    25: 359,
    26: 367,
    27: 377,
    28: 385,
    29: 396,
    30: 404,
    31: 411,
    32: 415,
    33: 418,
    34: 428,
    35: 434,
    36: 440,
    37: 446,
    38: 453,
    39: 458,
    40: 467,
    41: 477,
    42: 483,
    43: 489,
    44: 496,
    45: 499,
    46: 502,
    47: 507,
    48: 511,
    49: 515,
    50: 518,
    51: 520,
    52: 523,
    53: 526,
    54: 528,
    55: 531,
    56: 534,
    57: 537,
    58: 542,
    59: 545,
    60: 549,
    61: 551,
    62: 553,
    63: 554,
    64: 556,
    65: 558,
    66: 560,
    67: 562,
    68: 564,
    69: 566,
    70: 568,
    71: 570,
    72: 572,
    73: 574,
    74: 575,
    75: 577,
    76: 578,
    77: 580,
    78: 582,
    79: 583,
    80: 585,
    81: 586,
    82: 587,
    83: 587,
    84: 589,
    85: 590,
    86: 591,
    87: 591,
    88: 592,
    89: 593,
    90: 594,
    91: 595,
    92: 595,
    93: 596,
    94: 596,
    95: 597,
    96: 597,
    97: 598,
    98: 598,
    99: 599,
    100: 599,
    101: 600,
    102: 600,
    103: 601,
    104: 601,
    105: 601,
    106: 602,
    107: 602,
    108: 602,
    109: 603,
    110: 603,
    111: 603,
    112: 604,
    113: 604,
    114: 604,
  };
}
