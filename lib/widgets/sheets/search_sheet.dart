import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

// ─── Search Sheet ───

class SearchSheet extends StatefulWidget {
  final VoidCallback onClose;
  final ValueChanged<int> onPageSelected;

  const SearchSheet({
    super.key,
    required this.onClose,
    required this.onPageSelected,
  });

  @override
  State<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<SearchSheet> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

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
                      'Search',
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
                TextField(
                  autofocus: true,
                  onChanged: (value) => setState(() => searchQuery = value),
                  style: TextStyle(color: theme.primaryText),
                  decoration: InputDecoration(
                    hintText: 'Search surah name or number...',
                    hintStyle: TextStyle(color: theme.mutedText, fontSize: 14),
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
          Expanded(
            child: Consumer<QuranReadingProvider>(
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

                if (chapters.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.search,
                          size: 48,
                          color: theme.dividerColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No results found',
                          style: TextStyle(
                            color: theme.mutedText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: chapters.length,
                  itemBuilder: (context, index) {
                    final surah = chapters[index];
                    // Navigate to the surah's first page
                    // Each surah's pages can be roughly estimated;
                    // for now, use surah.id as a page reference
                    // The Quran API provides page numbers per verse

                    return ListTile(
                      onTap: () {
                        // Navigate to surah — use page lookup
                        // For simplicity, compute starting page from chapter
                        // This is approximate; a full solution would need a chapter->page map
                        widget.onPageSelected(_getFirstPage(surah.id));
                      },
                      leading: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: theme.pillBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          surah.id.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.accentColor,
                          ),
                        ),
                      ),
                      title: Text(
                        surah.nameSimple,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryText,
                        ),
                      ),
                      subtitle: Text(
                        "${surah.versesCount} Ayahs",
                        style: TextStyle(fontSize: 12, color: theme.mutedText),
                      ),
                      trailing: Text(
                        surah.nameArabic,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.mutedText,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Approximate first page for each chapter (first 30 chapters)
  /// Falls back to chapter number for unknown chapters
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
}
