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
  late String activeTab;
  String searchQuery = '';
  String _selectedStyle = 'All';

  // Static so favorites & recents persist across popup open/close
  static final Set<int> _favoriteIds = {};
  static final List<int> _recentIds = [];

  @override
  void initState() {
    super.initState();
    // Default to Favorites tab if user has any favorites
    activeTab = _favoriteIds.isNotEmpty ? 'favorites' : 'all';
  }

  // Style priority for sorting (lower = first)
  static const _stylePriority = {
    'Murattal': 0,
    'Mujawwad': 1,
    'Muallim': 2,
    'Kids repeat': 3,
  };

  int _styleOrder(String? style) => _stylePriority[style] ?? 99;

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
                  children: _favoriteIds.isNotEmpty
                      ? [
                          _buildTab(
                            'Favorites',
                            'favorites',
                            icon: LucideIcons.heart,
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildTab('Recent', 'recent', theme: theme),
                          const SizedBox(width: 8),
                          _buildTab('All', 'all', theme: theme),
                        ]
                      : [
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
                const SizedBox(height: 12),
                SizedBox(
                  height: 32,
                  child: Consumer<QuranReadingProvider>(
                    builder: (context, rp, _) {
                      // Collect unique styles from reciter data
                      final styles = <String>{'All'};
                      for (final r in rp.reciters) {
                        if (r.style != null && r.style!.isNotEmpty) {
                          styles.add(r.style!);
                        }
                      }
                      final orderedStyles = styles.toList()
                        ..sort((a, b) {
                          if (a == 'All') return -1;
                          if (b == 'All') return 1;
                          return (_stylePriority[a] ?? 99).compareTo(
                            _stylePriority[b] ?? 99,
                          );
                        });

                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: orderedStyles.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final style = orderedStyles[index];
                          final isSelected = _selectedStyle == style;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedStyle = style),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.accentColor.withValues(alpha: 0.15)
                                    : theme.chipUnselected,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? Border.all(
                                        color: theme.accentColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: Text(
                                style,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? theme.accentColor
                                      : theme.mutedText,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
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

                // Sort reciters: Murattal first, then by style priority, then alphabetically
                var reciters = List.of(readingProvider.reciters)
                  ..sort((a, b) {
                    final styleCmp = _styleOrder(
                      a.style,
                    ).compareTo(_styleOrder(b.style));
                    if (styleCmp != 0) return styleCmp;
                    return a.reciterName.compareTo(b.reciterName);
                  });

                // Filter by style
                if (_selectedStyle != 'All') {
                  reciters = reciters
                      .where((r) => r.style == _selectedStyle)
                      .toList();
                }

                // Filter by tab
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

                // Filter by search
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
