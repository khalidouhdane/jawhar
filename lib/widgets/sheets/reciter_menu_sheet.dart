import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/utils/app_logger.dart';

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

  /// Reciter IDs that have an image in assets/images/reciters/
  static const _reciterImageIds = <int>{
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    12,
    13,
    19,
    97,
    158,
    159,
    160,
    161,
    173,
    174,
    175,
  };

  /// Build initials from a reciter name (first + last).
  static String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  Widget _buildReciterAvatar(dynamic reciter, ThemeProvider theme) {
    const double size = 44;
    if (_reciterImageIds.contains(reciter.id)) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: theme.pillBackground,
        backgroundImage: AssetImage('assets/images/reciters/${reciter.id}.jpg'),
        onBackgroundImageError: (e, _) {
          AppLogger.info(
            'ReciterMenu',
            '[ReciterImage] Asset decode error for ${reciter.id}',
          );
        },
      );
    }
    // Fallback: themed initials circle
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.inputFill,
      child: Text(
        _initials(reciter.reciterName),
        style: TextStyle(
          color: theme.mutedText,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
                      l!.reciterTitle,
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
                  builder: (context, rp, _) => Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: theme.pillBackground,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              rp.setRewaya(1);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: rp.selectedRewaya == 1
                                    ? theme.primaryText
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: rp.selectedRewaya == 1
                                    ? theme.shadowCard
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                l.reciterHafs,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: rp.selectedRewaya == 1
                                      ? theme.scaffoldBackground
                                      : theme.chipUnselectedText,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              rp.setRewaya(2);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: rp.selectedRewaya == 2
                                    ? theme.primaryText
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: rp.selectedRewaya == 2
                                    ? theme.shadowCard
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                l.reciterWarsh,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: rp.selectedRewaya == 2
                                      ? theme.scaffoldBackground
                                      : theme.chipUnselectedText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  style: TextStyle(color: theme.primaryText),
                  decoration: InputDecoration(
                    hintText: l.reciterSearchHint,
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
                            l.reciterTabFavorites,
                            'favorites',
                            icon: LucideIcons.heart,
                            theme: theme,
                          ),
                          const SizedBox(width: 8),
                          _buildTab(l.reciterTabRecent, 'recent', theme: theme),
                          const SizedBox(width: 8),
                          _buildTab(l.reciterTabAll, 'all', theme: theme),
                        ]
                      : [
                          _buildTab(l.reciterTabAll, 'all', theme: theme),
                          const SizedBox(width: 8),
                          _buildTab(l.reciterTabRecent, 'recent', theme: theme),
                          const SizedBox(width: 8),
                          _buildTab(
                            l.reciterTabFavorites,
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
                if (readingProvider.isLoadingReciters &&
                    readingProvider.reciters.isEmpty) {
                  return Center(
                    child: CircularProgressIndicator(color: theme.accentColor),
                  );
                }

                if (readingProvider.recitersError.isNotEmpty &&
                    readingProvider.reciters.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.wifiOff,
                            size: 48,
                            color: theme.dividerColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l.reciterNoFound,
                            style: TextStyle(
                              color: theme.mutedText,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => readingProvider.loadReciters(),
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
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
                              ? l.reciterNoFavorites
                              : activeTab == 'recent'
                              ? l.reciterNoRecent
                              : l.reciterNoFound,
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
                            _buildReciterAvatar(reciter, theme),
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
                        subtitle: _buildSyncSubtitle(
                          reciter, isActive, audioProvider, theme,
                        ),
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

  /// Build a sync quality subtitle for a reciter tile.
  /// Shows nothing for perfect sync, a subtle indicator for corrected sync,
  /// and a warning for reciters without timing data.
  Widget? _buildSyncSubtitle(
    dynamic reciter,
    bool isActive,
    AudioProvider audioProvider,
    ThemeProvider theme,
  ) {
    // No timing data at all
    if (!reciter.hasTimingData) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.wifiOff,
            size: 10,
            color: theme.mutedText.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            'No verse sync',
            style: TextStyle(
              fontSize: 10,
              color: theme.mutedText.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }



    return null;
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
