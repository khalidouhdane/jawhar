import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';

class ReciterMenuSheet extends StatefulWidget {
  final VoidCallback onClose;

  const ReciterMenuSheet({super.key, required this.onClose});

  @override
  State<ReciterMenuSheet> createState() => _ReciterMenuSheetState();
}

class _ReciterMenuSheetState extends State<ReciterMenuSheet> {
  late String activeTab;
  String searchQuery = '';

  // Static so favorites & recents persist across popup open/close
  static final Set<int> _favoriteIds = {};
  static final List<int> _recentIds = [];

  @override
  void initState() {
    super.initState();
    activeTab = _favoriteIds.isNotEmpty ? 'favorites' : 'all';
  }

  void _addToRecent(int id) {
    _recentIds.remove(id);
    _recentIds.insert(0, id);
    if (_recentIds.length > 10) _recentIds.removeLast();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
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
                      l.t('reciter_title'),
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
                Consumer<QuranReadingProvider>(
                  builder: (context, rp, _) => Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            rp.setRewaya(1);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: rp.selectedRewaya == 1
                                  ? theme.accentColor
                                  : theme.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              l.t('reciter_hafs'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: rp.selectedRewaya == 1
                                    ? Colors.white
                                    : theme.primaryText,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            rp.setRewaya(2);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: rp.selectedRewaya == 2
                                  ? theme.accentColor
                                  : theme.inputFill,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              l.t('reciter_warsh'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: rp.selectedRewaya == 2
                                    ? Colors.white
                                    : theme.primaryText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  style: TextStyle(color: theme.primaryText),
                  decoration: InputDecoration(
                    hintText: l.t('reciter_search_hint'),
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
                            l.t('reciter_tab_favorites'),
                            'favorites',
                            icon: LucideIcons.heart,
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildTab(
                            l.t('reciter_tab_recent'),
                            'recent',
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildTab(
                            l.t('reciter_tab_all'),
                            'all',
                            theme: theme,
                          ),
                        ]
                      : [
                          _buildTab(
                            l.t('reciter_tab_all'),
                            'all',
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildTab(
                            l.t('reciter_tab_recent'),
                            'recent',
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildTab(
                            l.t('reciter_tab_favorites'),
                            'favorites',
                            icon: LucideIcons.heart,
                            theme: theme,
                          ),
                        ],
                ),
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

                // Sort reciters alphabetically
                var reciters = List.of(readingProvider.reciters)
                  ..sort((a, b) => a.reciterName.compareTo(b.reciterName));

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
                              ? l.t('reciter_no_favorites')
                              : activeTab == 'recent'
                              ? l.t('reciter_no_recent')
                              : l.t('reciter_no_found'),
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

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? theme.accentColor.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: isActive
                            ? Border.all(
                                color: theme.accentColor.withValues(alpha: 0.3),
                                width: 1.5,
                              )
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        onTap: () {
                          audioProvider.setReciter(
                            reciter.id,
                            name: reciter.reciterName,
                            apiSource: reciter.apiSource,
                            serverUrl: reciter.serverUrl,
                            moshafId: reciter.moshafId,
                          );
                          _addToRecent(reciter.id);
                          widget.onClose();
                        },
                        leading: Stack(
                          children: [
                            CircleAvatar(
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
                            if (isActive)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: theme.accentColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.sheetBackground,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    LucideIcons.check,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(
                          reciter.reciterName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.bold,
                            color: isActive
                                ? theme.accentColor
                                : theme.primaryText,
                          ),
                        ),
                        subtitle: !reciter.hasTimingData
                            ? Text(
                                '⚠ No verse sync',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.mutedText.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : null,
                        trailing: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isFavorite) {
                                _favoriteIds.remove(reciter.id);
                              } else {
                                _favoriteIds.add(reciter.id);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              isFavorite
                                  ? LucideIcons.heartHandshake
                                  : LucideIcons.heart,
                              size: 22,
                              color: isFavorite
                                  ? Colors.red[400]
                                  : theme.dividerColor,
                            ),
                          ),
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
