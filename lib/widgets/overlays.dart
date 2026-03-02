import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

class ReciterMenuSheet extends StatefulWidget {
  final VoidCallback onClose;

  const ReciterMenuSheet({super.key, required this.onClose});

  @override
  State<ReciterMenuSheet> createState() => _ReciterMenuSheetState();
}

class _ReciterMenuSheetState extends State<ReciterMenuSheet> {
  String activeTab = 'all';
  String searchQuery = '';
  final Set<int> _favoriteIds = {};
  final List<int> _recentIds = [];

  void _addToRecent(int id) {
    _recentIds.remove(id);
    _recentIds.insert(0, id);
    if (_recentIds.length > 10) _recentIds.removeLast();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
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
                      'Select Reciter',
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
                  onChanged: (value) => setState(() => searchQuery = value),
                  style: TextStyle(color: theme.primaryText),
                  decoration: InputDecoration(
                    hintText: 'Search by reciter name...',
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
                Row(
                  children: [
                    _buildTab('All', 'all', theme: theme),
                    const SizedBox(width: 8),
                    _buildTab('Recent', 'recent', theme: theme),
                    const SizedBox(width: 8),
                    _buildTab(
                      'Favorites',
                      'favorites',
                      icon: LucideIcons.heart,
                      theme: theme,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: theme.dividerColor),
              ],
            ),
          ),
          Expanded(
            child: Consumer<QuranReadingProvider>(
              builder: (context, readingProvider, child) {
                if (readingProvider.reciters.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(color: theme.accentColor),
                  );
                }

                // Filter reciters based on tab and search
                var reciters = readingProvider.reciters;

                if (activeTab == 'favorites') {
                  reciters = reciters
                      .where((r) => _favoriteIds.contains(r.id))
                      .toList();
                } else if (activeTab == 'recent') {
                  reciters = _recentIds
                      .map(
                        (id) =>
                            readingProvider.reciters.where((r) => r.id == id),
                      )
                      .where((matches) => matches.isNotEmpty)
                      .map((matches) => matches.first)
                      .toList();
                }

                if (searchQuery.isNotEmpty) {
                  reciters = reciters
                      .where(
                        (r) => r.reciterName.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                      )
                      .toList();
                }

                if (reciters.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          activeTab == 'favorites'
                              ? LucideIcons.heart
                              : LucideIcons.search,
                          size: 48,
                          color: theme.dividerColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          activeTab == 'favorites'
                              ? 'No favorite reciters yet'
                              : activeTab == 'recent'
                              ? 'No recent reciters'
                              : 'No reciters found',
                          style: TextStyle(
                            color: theme.mutedText,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: reciters.length,
                  itemBuilder: (context, index) {
                    final reciter = reciters[index];
                    final isActive = reciter.id == audioProvider.reciterId;
                    final isFavorite = _favoriteIds.contains(reciter.id);

                    return ListTile(
                      onTap: () {
                        audioProvider.setReciter(
                          reciter.id,
                          name: reciter.reciterName,
                        );
                        _addToRecent(reciter.id);
                        widget.onClose();
                      },
                      leading: CircleAvatar(
                        backgroundColor: theme.pillBackground,
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/reciters/${reciter.id}.jpg',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.network(
                                "https://api.dicebear.com/7.x/initials/png?seed=${reciter.reciterName}&backgroundColor=transparent&textColor=a1a1aa&fontWeight=600",
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              );
                            },
                          ),
                        ),
                      ),
                      title: Text(
                        reciter.reciterName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? theme.accentColor
                              : theme.primaryText,
                        ),
                      ),
                      subtitle: Text(
                        "${reciter.style ?? 'Standard'} Recitation",
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
                            onTap: () {
                              setState(() {
                                if (isFavorite) {
                                  _favoriteIds.remove(reciter.id);
                                } else {
                                  _favoriteIds.add(reciter.id);
                                }
                              });
                            },
                            child: Icon(
                              isFavorite
                                  ? LucideIcons.heartHandshake
                                  : LucideIcons.heart,
                              size: 18,
                              color: isFavorite
                                  ? Colors.red[400]
                                  : theme.dividerColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (isActive)
                            Icon(
                              LucideIcons.checkCircle2,
                              size: 20,
                              color: theme.accentColor,
                            )
                          else
                            const SizedBox(width: 20),
                        ],
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

  Widget _buildTab(
    String label,
    String tabKey, {
    IconData? icon,
    required ThemeProvider theme,
  }) {
    final isSelected = activeTab == tabKey;
    return GestureDetector(
      onTap: () => setState(() => activeTab = tabKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.chipSelected : theme.chipUnselected,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: isSelected
                    ? theme.chipSelectedText
                    : theme.chipUnselectedText,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? theme.chipSelectedText
                    : theme.chipUnselectedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Audio Settings Sheet (Functional) ───

class AudioSettingsSheet extends StatefulWidget {
  final VoidCallback onClose;

  const AudioSettingsSheet({super.key, required this.onClose});

  @override
  State<AudioSettingsSheet> createState() => _AudioSettingsSheetState();
}

class _AudioSettingsSheetState extends State<AudioSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final audioProvider = context.watch<AudioProvider>();

    return Container(
      decoration: BoxDecoration(
        color: theme.sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 6,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: theme.sheetDragHandle,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Audio Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.accentColor,
                ),
              ),
              GestureDetector(
                onTap: widget.onClose,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(LucideIcons.x, size: 18, color: theme.mutedText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Speed
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Playback Speed",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [0.75, 1.0, 1.25, 1.5].map((speed) {
                  final label = speed == 1.0 ? '1x' : '${speed}x';
                  final isSelected = audioProvider.playbackSpeed == speed;
                  return GestureDetector(
                    onTap: () => audioProvider.setPlaybackSpeed(speed),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.chipSelected
                            : theme.chipUnselected,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? theme.chipSelectedText
                              : theme.chipUnselectedText,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Repeat mode
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.inputFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.accentColor.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.repeat,
                      size: 18,
                      color: theme.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Repeat Mode",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildRepeatChip(
                      'Off',
                      AudioRepeatMode.none,
                      audioProvider,
                      theme,
                    ),
                    const SizedBox(width: 8),
                    _buildRepeatChip(
                      'Verse',
                      AudioRepeatMode.repeatVerse,
                      audioProvider,
                      theme,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Repeat times",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.secondaryText,
                        ),
                      ),
                      Row(
                        children: [3, 5, 10, 0].map((times) {
                          final isInfinite = times == 0;
                          final isSelected = audioProvider.repeatCount == times;
                          return GestureDetector(
                            onTap: () => audioProvider.setRepeatCount(times),
                            child: Container(
                              width: 32,
                              height: 32,
                              margin: const EdgeInsets.only(left: 6),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? theme.chipSelected
                                    : theme.chipUnselected,
                              ),
                              child: isInfinite
                                  ? Icon(
                                      LucideIcons.infinity,
                                      size: 16,
                                      color: isSelected
                                          ? theme.chipSelectedText
                                          : theme.chipUnselectedText,
                                    )
                                  : Text(
                                      '$times',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? theme.chipSelectedText
                                            : theme.chipUnselectedText,
                                      ),
                                    ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRepeatChip(
    String label,
    AudioRepeatMode mode,
    AudioProvider audioProvider,
    ThemeProvider theme,
  ) {
    final isSelected = audioProvider.repeatMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => audioProvider.setRepeatMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? theme.chipSelected : theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? theme.chipSelected : theme.dividerColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? theme.chipSelectedText
                  : theme.chipUnselectedText,
            ),
          ),
        ),
      ),
    );
  }
}

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
                      'Index',
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
                    children: ['Surah', 'Juz', 'Bookmarks'].map((tab) {
                      final tabKey = tab.toLowerCase();
                      final isSelected = activeTab == tabKey;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => activeTab = tabKey),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 8),
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
                              tab,
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
                      hintText: 'Search surah name or number...',
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
          Expanded(child: _buildTabContent(theme)),
        ],
      ),
    );
  }

  Widget _buildTabContent(ThemeProvider theme) {
    if (activeTab == 'surah') return _buildSurahList(theme);
    if (activeTab == 'bookmarks') return _buildBookmarksList(theme);
    // Juz tab
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.bookOpen, size: 48, color: theme.dividerColor),
          const SizedBox(height: 12),
          Text(
            "Juz list coming soon",
            style: TextStyle(
              color: theme.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahList(ThemeProvider theme) {
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
                  "${surah.versesCount} Ayahs",
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

  Widget _buildBookmarksList(ThemeProvider theme) {
    if (_bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bookmark, size: 48, color: theme.dividerColor),
            const SizedBox(height: 12),
            Text(
              "No bookmarks yet",
              style: TextStyle(
                color: theme.mutedText,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Tap the bookmark icon on any surah",
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
              "Page ${entry.key}",
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

// ─── Theme Picker Sheet ───

class ThemePickerSheet extends StatelessWidget {
  final VoidCallback onClose;

  const ThemePickerSheet({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Container(
      decoration: BoxDecoration(
        color: theme.sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 6,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: theme.sheetDragHandle,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Appearance',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.accentColor,
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(LucideIcons.x, size: 18, color: theme.mutedText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildThemeOption(
                context: context,
                theme: theme,
                label: 'Classic',
                targetTheme: AppTheme.classic,
                bgColor: Colors.white,
                textColor: const Color(0xFF1A454E),
                icon: LucideIcons.sparkles,
              ),
              const SizedBox(width: 12),
              _buildThemeOption(
                context: context,
                theme: theme,
                label: 'Warm',
                targetTheme: AppTheme.warm,
                bgColor: const Color(0xFFF5F0E8),
                textColor: const Color(0xFF1A454E),
                icon: LucideIcons.sun,
              ),
              const SizedBox(width: 12),
              _buildThemeOption(
                context: context,
                theme: theme,
                label: 'Dark',
                targetTheme: AppTheme.dark,
                bgColor: const Color(0xFF0A1E24),
                textColor: const Color(0xFFD4E8EC),
                icon: LucideIcons.moon,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeProvider theme,
    required String label,
    required AppTheme targetTheme,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
  }) {
    final isSelected = theme.theme == targetTheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => theme.setTheme(targetTheme),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? theme.accentColor : Colors.grey.shade300,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.accentColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, size: 28, color: textColor),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: theme.chipSelectedText,
                    ),
                  ),
                )
              else
                const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

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
