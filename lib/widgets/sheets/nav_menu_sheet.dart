import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';

// ─── Nav Menu Sheet ───

class NavMenuSheet extends StatefulWidget {
  final VoidCallback onClose;
  final ValueChanged<int> onPageSelected;

  const NavMenuSheet({
    super.key,
    required this.onClose,
    required this.onPageSelected,
  });

  @override
  State<NavMenuSheet> createState() => _NavMenuSheetState();
}

class _NavMenuSheetState extends State<NavMenuSheet> {
  String activeTab = 'surah';
  String searchQuery = '';
  // Simple in-memory bookmarks (page number -> surah name)
  static final Map<int, String> _bookmarks = {};

  void _toggleBookmark(int page, String name) {
    setState(() {
      if (_bookmarks.containsKey(page)) {
        _bookmarks.remove(page);
      } else {
        _bookmarks[page] = name;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final l = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 6,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: theme.sheetDragHandle,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l.t('nav_index'),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.accentColor,
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: theme.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.pillBackground,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children:
                        [
                          {'label': l.t('nav_tab_surah'), 'key': 'surah'},
                          {'label': l.t('nav_tab_juz'), 'key': 'juz'},
                          {
                            'label': l.t('nav_tab_bookmarks'),
                            'key': 'bookmarks',
                          },
                        ].map((tab) {
                          final tabKey = tab['key']!;
                          final isSelected = activeTab == tabKey;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => activeTab = tabKey),
                              child: Container(
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.cardColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: theme.shadowColor.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  tab['label']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? theme.accentColor
                                        : theme.chipUnselectedText,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                if (activeTab == 'surah')
                  TextField(
                    onChanged: (v) => setState(() => searchQuery = v),
                    style: TextStyle(color: theme.primaryText),
                    decoration: InputDecoration(
                      hintText: l.t('nav_search_hint'),
                      hintStyle: TextStyle(
                        color: theme.mutedText,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        LucideIcons.search,
                        size: 18,
                        color: theme.mutedText,
                      ),
                      filled: true,
                      fillColor: theme.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(child: _buildTabContent(theme, l)),
        ],
      ),
    );
  }

  Widget _buildTabContent(ThemeProvider theme, AppLocalizations l) {
    if (activeTab == 'surah') return _buildSurahList(theme, l);
    if (activeTab == 'bookmarks') return _buildBookmarksList(theme, l);
    // Juz tab
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.bookOpen, size: 48, color: theme.dividerColor),
          const SizedBox(height: 12),
          Text(
            l.t('nav_juz_coming'),
            style: TextStyle(
              color: theme.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList(ThemeProvider theme, AppLocalizations l) {
    return Consumer<QuranReadingProvider>(
      builder: (context, readingProvider, child) {
        if (readingProvider.chapters.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: theme.accentColor),
          );
        }

        var chapters = readingProvider.chapters;
        if (searchQuery.isNotEmpty) {
          chapters = chapters
              .where(
                (c) =>
                    c.nameSimple.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    c.nameArabic.contains(searchQuery) ||
                    c.id.toString() == searchQuery,
              )
              .toList();
        }

        final currentPage = readingProvider.activePage;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: chapters.length,
          itemBuilder: (context, index) {
            final surah = chapters[index];
            final surahPage = _getFirstPage(surah.id);
            final isCurrent = surahPage == currentPage;
            final isBookmarked = _bookmarks.containsKey(surahPage);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isCurrent ? theme.inputFill : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent
                      ? theme.accentColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
              ),
              child: ListTile(
                onTap: () {
                  widget.onPageSelected(surahPage);
                },
                leading: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrent ? theme.accentColor : theme.pillBackground,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    surah.id.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCurrent
                          ? Colors.white
                          : theme.chipUnselectedText,
                    ),
                  ),
                ),
                title: Text(
                  surah.nameSimple,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCurrent ? theme.accentColor : theme.primaryText,
                  ),
                ),
                subtitle: Text(
                  "${surah.versesCount} ${l.t('nav_ayahs')}",
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.mutedText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _toggleBookmark(surahPage, surah.nameSimple),
                      child: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        size: 20,
                        color: isBookmarked
                            ? theme.accentColor
                            : theme.mutedText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      surah.nameArabic,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCurrent ? theme.accentColor : theme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBookmarksList(ThemeProvider theme, AppLocalizations l) {
    if (_bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bookmark, size: 48, color: theme.dividerColor),
            const SizedBox(height: 12),
            Text(
              l.t('nav_no_bookmarks'),
              style: TextStyle(
                color: theme.mutedText,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l.t('nav_bookmark_hint'),
              style: TextStyle(color: theme.mutedText, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final entries = _bookmarks.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () {
              widget.onPageSelected(entry.key);
            },
            leading: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.pillBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.bookmark,
                size: 18,
                color: theme.accentColor,
              ),
            ),
            title: Text(
              entry.value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.primaryText,
              ),
            ),
            subtitle: Text(
              "${l.t('nav_page')} ${entry.key}",
              style: TextStyle(fontSize: 12, color: theme.mutedText),
            ),
            trailing: GestureDetector(
              onTap: () => _toggleBookmark(entry.key, entry.value),
              child: Icon(
                LucideIcons.trash2,
                size: 18,
                color: Colors.red.shade400,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Chapter ID → first Quran page mapping
int _getFirstPage(int chapterId) {
  const chapterPages = {
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
  return chapterPages[chapterId] ?? chapterId;
}
