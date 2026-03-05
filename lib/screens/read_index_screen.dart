import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/widgets/surah_list_tile.dart';
import 'package:quran_app/l10n/app_localizations.dart';

/// Static lookup: Surah number → starting Mushaf page (Madani/Standard)
const List<int> _surahStartPages = [
  0, // Index 0 unused (surahs are 1-indexed)
  1, 2, 50, 77, 106, 128, 151, 177, 187, 208, // 1-10
  221, 235, 249, 255, 262, 267, 282, 293, 305, 312, // 11-20
  322, 332, 342, 350, 359, 367, 377, 385, 396, 404, // 21-30
  411, 415, 418, 428, 434, 440, 446, 453, 458, 467, // 31-40
  477, 483, 489, 496, 499, 502, 507, 511, 515, 518, // 41-50
  520, 523, 526, 528, 531, 534, 537, 542, 545, 549, // 51-60
  551, 553, 554, 556, 558, 560, 562, 564, 566, 568, // 61-70
  570, 572, 574, 575, 577, 578, 580, 582, 583, 585, // 71-80
  586, 587, 587, 589, 590, 591, 591, 592, 593, 594, // 81-90
  595, 595, 596, 596, 597, 597, 598, 598, 599, 599, // 91-100
  600, 600, 601, 601, 601, 602, 602, 602, 603, 603, // 101-110
  603, 604, 604, 604, // 111-114
];

class ReadIndexScreen extends StatefulWidget {
  const ReadIndexScreen({super.key});

  @override
  State<ReadIndexScreen> createState() => _ReadIndexScreenState();
}

class _ReadIndexScreenState extends State<ReadIndexScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSurah(int chapterId) {
    final page = _surahStartPages[chapterId];
    final nav = context.read<NavigationProvider>();
    nav.enterReadingView();

    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => ReadingScreen(initialPage: page)),
        )
        .then((_) {
          nav.exitReadingView();
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final l = AppLocalizations.of(context);
    final readingProvider = context.watch<QuranReadingProvider>();
    final chapters = readingProvider.chapters;

    return Scaffold(
      backgroundColor: theme.canvasBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 8,
              ),
              child: Row(
                children: [
                  Text(
                    l.t('read_title'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                ],
              ),
            ),

            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: theme.inputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  focusNode: _searchFocusNode,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: theme.primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: l.t('read_search_hint'),
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: theme.mutedText,
                    ),
                    prefixIcon: Icon(
                      LucideIcons.search,
                      size: 18,
                      color: theme.mutedText,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),

            // ── Tab switcher: Surah | Juz | Hizb ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: theme.inputFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: theme.accentColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerHeight: 0,
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.mutedText,
                  labelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  tabs: [
                    Tab(text: l.t('read_tab_surah')),
                    Tab(text: l.t('read_tab_juz')),
                    Tab(text: l.t('read_tab_hizb')),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Tab content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSurahList(chapters, theme),
                  _buildJuzList(chapters, theme),
                  _buildHizbList(chapters, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahList(List<Chapter> chapters, ThemeProvider theme) {
    if (chapters.isEmpty) {
      return Center(child: CircularProgressIndicator(color: theme.accentColor));
    }

    final filtered = _searchQuery.isEmpty
        ? chapters
        : chapters.where((c) {
            final q = _searchQuery.toLowerCase();
            return c.nameSimple.toLowerCase().contains(q) ||
                c.nameArabic.contains(_searchQuery) ||
                c.id.toString() == _searchQuery;
          }).toList();

    return ListView.separated(
      itemCount: filtered.length,
      padding: const EdgeInsets.only(bottom: 16),
      separatorBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Divider(height: 1, color: theme.dividerColor),
      ),
      itemBuilder: (context, index) {
        final chapter = filtered[index];
        return SurahListTile(
          number: chapter.id,
          nameSimple: chapter.nameSimple,
          nameArabic: chapter.nameArabic,
          versesCount: chapter.versesCount,
          onTap: () => _openSurah(chapter.id),
        );
      },
    );
  }

  Widget _buildJuzList(List<Chapter> chapters, ThemeProvider theme) {
    return ListView.separated(
      itemCount: 30,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      separatorBuilder: (_, _) => Divider(height: 1, color: theme.dividerColor),
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        // Juz starting pages (standard Mushaf)
        const juzPages = [
          1,
          22,
          42,
          62,
          82,
          102,
          121,
          142,
          162,
          182,
          201,
          222,
          242,
          262,
          282,
          302,
          322,
          342,
          362,
          382,
          402,
          422,
          442,
          462,
          482,
          502,
          522,
          542,
          562,
          582,
        ];
        final page = juzPages[index];

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$juzNumber',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Juz $juzNumber',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Page $page',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: theme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: theme.mutedText.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHizbList(List<Chapter> chapters, ThemeProvider theme) {
    return ListView.separated(
      itemCount: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      separatorBuilder: (_, _) => Divider(height: 1, color: theme.dividerColor),
      itemBuilder: (context, index) {
        // Standard Mushaf hizb starting pages
        const hizbPages = [
          1, 12, 22, 32, 42, 52, 62, 72, 82, 92, // 1-10
          102, 112, 122, 132, 142, 152, 162, 172, 182, 192, // 11-20
          202, 212, 222, 232, 242, 252, 262, 272, 282, 292, // 21-30
          302, 312, 322, 332, 342, 352, 362, 372, 382, 392, // 31-40
          402, 412, 422, 432, 442, 452, 462, 472, 482, 492, // 41-50
          502, 512, 522, 532, 542, 552, 562, 572, 582, 592, // 51-60
        ];
        final page = hizbPages[index];
        final hizbNumber = index + 1;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.accentColor.withValues(alpha: 0.2),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$hizbNumber',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hizb $hizbNumber',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Page $page',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: theme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: theme.mutedText.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
