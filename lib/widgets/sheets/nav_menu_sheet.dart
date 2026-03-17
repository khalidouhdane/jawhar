import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/models/bookmark_model.dart';
import 'package:quran_app/widgets/sheets/bookmark_edit_sheet.dart';
import 'package:quran_app/l10n/app_localizations.dart';

// ─── Nav Menu Sheet ───

class NavMenuSheet extends StatefulWidget {
  final VoidCallback onClose;
  final ValueChanged<int> onPageSelected;
  final String initialTab;

  const NavMenuSheet({
    super.key,
    required this.onClose,
    required this.onPageSelected,
    this.initialTab = 'surah',
  });

  @override
  State<NavMenuSheet> createState() => _NavMenuSheetState();
}

class _NavMenuSheetState extends State<NavMenuSheet> {
  late String activeTab;
  String searchQuery = '';
  String _bookmarkFilter = 'pages'; // 'pages' or 'verses'
  String? _selectedCollectionId; // null = show all

  @override
  void initState() {
    super.initState();
    activeTab = widget.initialTab;
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
            final isBookmarked = context.watch<BookmarkProvider>().isPageBookmarked(surahPage);

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
                      onTap: () => context.read<BookmarkProvider>().togglePageBookmark(pageNumber: surahPage, surahName: surah.nameSimple),
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
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final collections = bookmarkProvider.collections;

    // Filter by collection first, then by type
    final collectionBookmarks = _selectedCollectionId == null
        ? bookmarkProvider.getAll()
        : bookmarkProvider.getByCollection(_selectedCollectionId);
    final pageBookmarks = collectionBookmarks.where((b) => b.type == BookmarkType.page).toList();
    final verseBookmarks = collectionBookmarks.where((b) => b.type == BookmarkType.verse).toList();
    final filteredBookmarks = _bookmarkFilter == 'pages' ? pageBookmarks : verseBookmarks;

    return Column(
      children: [
        // ── Collection chips (horizontal scroll) ──
        if (collections.isNotEmpty) ...[
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _collectionChip(theme, l.t('bm_all'), null),
                const SizedBox(width: 8),
                ...collections.map((col) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _collectionChip(theme, col.name, col.id),
                )),
                _addCollectionChip(theme, l),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        // ── Segmented switcher ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: theme.pillBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _bookmarkSegment(
                        theme, l,
                        label: l.t('nav_pages'),
                        key: 'pages',
                        count: pageBookmarks.length,
                      ),
                      const SizedBox(width: 4),
                      _bookmarkSegment(
                        theme, l,
                        label: l.t('nav_verses'),
                        key: 'verses',
                        count: verseBookmarks.length,
                      ),
                    ],
                  ),
                ),
              ),
              if (filteredBookmarks.isNotEmpty) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => bookmarkProvider.shareBookmarks(
                    collectionId: _selectedCollectionId,
                  ),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.pillBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.share2,
                      size: 16,
                      color: theme.mutedText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Filtered list ──
        Expanded(
          child: filteredBookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _bookmarkFilter == 'pages'
                            ? LucideIcons.fileText
                            : LucideIcons.type,
                        size: 48,
                        color: theme.dividerColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _bookmarkFilter == 'pages'
                            ? l.t('nav_no_page_bookmarks')
                            : l.t('nav_no_verse_bookmarks'),
                        style: TextStyle(
                          color: theme.mutedText,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _bookmarkFilter == 'pages'
                            ? l.t('nav_page_bookmark_hint')
                            : l.t('nav_verse_bookmark_hint'),
                        style: TextStyle(color: theme.mutedText, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredBookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = filteredBookmarks[index];
                    final isVerse = bookmark.type == BookmarkType.verse;

                    // Subtitle: verse key or page, plus collection name if assigned
                    String subtitle = isVerse
                        ? '${bookmark.verseKey} · ${l.t('nav_page')} ${bookmark.pageNumber}'
                        : '${l.t('nav_page')} ${bookmark.pageNumber}';
                    if (bookmark.collectionId != null) {
                      final col = bookmarkProvider.getCollection(bookmark.collectionId!);
                      if (col != null) subtitle += ' · ${col.name}';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
                      ),
                      child: ListTile(
                        onTap: () {
                          if (isVerse && bookmark.verseKey != null) {
                            bookmarkProvider.setHighlight(bookmark.verseKey!);
                          }
                          widget.onPageSelected(bookmark.pageNumber);
                        },
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: theme.accentColor.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isVerse ? LucideIcons.type : LucideIcons.fileText,
                                size: 18,
                                color: theme.accentColor,
                              ),
                            ),
                            // Color dot
                            if (bookmark.colorIndex != null)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(BookmarkColors.palette[bookmark.colorIndex!]),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: theme.cardColor, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          bookmark.surahName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subtitle,
                              style: TextStyle(fontSize: 12, color: theme.mutedText),
                            ),
                            if (bookmark.note != null && bookmark.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  bookmark.note!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: theme.mutedText.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: GestureDetector(
                          onTap: () => _openEditSheet(bookmark.id),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              LucideIcons.moreHorizontal,
                              size: 18,
                              color: theme.mutedText,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openEditSheet(String bookmarkId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookmarkEditSheet(
        bookmarkId: bookmarkId,
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showCreateCollectionDialog(ThemeProvider theme, AppLocalizations l) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.scaffoldBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l.t('bm_new_collection'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(fontFamily: 'Inter', color: theme.primaryText),
          decoration: InputDecoration(
            hintText: l.t('bm_collection_name_hint'),
            hintStyle: TextStyle(fontFamily: 'Inter', color: theme.mutedText),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.accentColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.t('bm_cancel'),
                style: TextStyle(color: theme.mutedText)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<BookmarkProvider>().createCollection(
                  controller.text.trim(),
                );
                Navigator.pop(ctx);
              }
            },
            child: Text(l.t('bm_create'),
                style: TextStyle(color: theme.accentColor)),
          ),
        ],
      ),
    );
  }

  Widget _collectionChip(ThemeProvider theme, String label, String? collectionId) {
    final isActive = _selectedCollectionId == collectionId;
    return GestureDetector(
      onTap: () => setState(() => _selectedCollectionId = collectionId),
      onLongPress: collectionId != null
          ? () => _showCollectionOptions(theme, collectionId)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? theme.accentColor.withValues(alpha: 0.12)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? theme.accentColor : theme.dividerColor,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? theme.accentColor : theme.primaryText,
          ),
        ),
      ),
    );
  }

  Widget _addCollectionChip(ThemeProvider theme, AppLocalizations l) {
    return GestureDetector(
      onTap: () => _showCreateCollectionDialog(theme, l),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.plus, size: 14, color: theme.mutedText),
            const SizedBox(width: 4),
            Text(
              l.t('bm_add'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: theme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCollectionOptions(ThemeProvider theme, String collectionId) {
    final bp = context.read<BookmarkProvider>();
    final col = bp.getCollection(collectionId);
    if (col == null) return;
    final l = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              col.name,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(LucideIcons.pencil, color: theme.accentColor),
              title: Text(l.t('bm_rename'),
                  style: TextStyle(color: theme.primaryText)),
              onTap: () {
                Navigator.pop(ctx);
                _showRenameDialog(theme, l, collectionId, col.name);
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.trash2, color: Colors.red.shade400),
              title: Text(l.t('bm_delete_collection'),
                  style: TextStyle(color: Colors.red.shade400)),
              onTap: () {
                Navigator.pop(ctx);
                bp.deleteCollection(collectionId);
                if (_selectedCollectionId == collectionId) {
                  setState(() => _selectedCollectionId = null);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(
    ThemeProvider theme,
    AppLocalizations l,
    String collectionId,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.scaffoldBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l.t('bm_rename'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(fontFamily: 'Inter', color: theme.primaryText),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.accentColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.t('bm_cancel'),
                style: TextStyle(color: theme.mutedText)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context.read<BookmarkProvider>().renameCollection(
                  collectionId,
                  controller.text.trim(),
                );
                Navigator.pop(ctx);
              }
            },
            child: Text(l.t('bm_save'),
                style: TextStyle(color: theme.accentColor)),
          ),
        ],
      ),
    );
  }

  Widget _bookmarkSegment(
    ThemeProvider theme,
    AppLocalizations l, {
    required String label,
    required String key,
    required int count,
  }) {
    final isActive = _bookmarkFilter == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _bookmarkFilter = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? theme.cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? theme.accentColor : theme.chipUnselectedText,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive
                        ? theme.accentColor.withValues(alpha: 0.12)
                        : theme.pillBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? theme.accentColor : theme.mutedText,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
