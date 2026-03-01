import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/audio_provider.dart';

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

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 6,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
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
                    const Text(
                      'Select Reciter',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A454E),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search by reciter name...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildTab('All', 'all'),
                    const SizedBox(width: 8),
                    _buildTab('Recent', 'recent'),
                    const SizedBox(width: 8),
                    _buildTab(
                      'Favorites',
                      'favorites',
                      icon: LucideIcons.heart,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
              ],
            ),
          ),
          Expanded(
            child: Consumer<QuranReadingProvider>(
              builder: (context, readingProvider, child) {
                if (readingProvider.reciters.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1A454E)),
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
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          activeTab == 'favorites'
                              ? 'No favorite reciters yet'
                              : activeTab == 'recent'
                              ? 'No recent reciters'
                              : 'No reciters found',
                          style: TextStyle(
                            color: Colors.grey[400],
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
                        backgroundImage: NetworkImage(
                          "https://api.dicebear.com/7.x/avataaars/png?seed=${reciter.reciterName}&backgroundColor=f0f7f8",
                        ),
                        backgroundColor: Colors.grey[100],
                      ),
                      title: Text(
                        reciter.reciterName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? Colors.teal
                              : const Color(0xFF1A454E),
                        ),
                      ),
                      subtitle: Text(
                        "${reciter.style ?? 'Standard'} Recitation",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
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
                                  : Colors.grey[300],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (isActive)
                            const Icon(
                              LucideIcons.checkCircle2,
                              size: 20,
                              color: Colors.teal,
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

  Widget _buildTab(String label, String tabKey, {IconData? icon}) {
    final isSelected = activeTab == tabKey;
    return GestureDetector(
      onTap: () => setState(() => activeTab = tabKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A454E) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: isSelected ? Colors.white : Colors.grey[500],
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AudioSettingsSheet extends StatelessWidget {
  final VoidCallback onClose;

  const AudioSettingsSheet({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Audio Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A454E),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(LucideIcons.x, size: 18, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Speed
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Playback Speed",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['0.75x', '1x', '1.25x', '1.5x'].map((speed) {
                  final isSelected = speed == '1x';
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A454E)
                          : Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      speed,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Looping
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F8F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(
                      LucideIcons.repeat,
                      size: 18,
                      color: Color(0xFF1A454E),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Verse Looping (Memorize)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A454E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildDropdown("From Ayah", "1"),
                    const SizedBox(width: 12),
                    _buildDropdown("To Ayah", "5"),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[100]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Repeat times",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        children: ['3', '5', '10', '∞'].map((times) {
                          final isSelected = times == '∞';
                          return Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(left: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFF1A454E)
                                  : Colors.grey[50],
                            ),
                            child: isSelected
                                ? const Icon(
                                    LucideIcons.infinity,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : Text(
                                    times,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[500],
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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFF9FAFB),
                    child: Icon(
                      LucideIcons.clock,
                      size: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Sleep Timer",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Text(
                "Off",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A454E),
                  ),
                ),
              ],
            ),
            const Icon(LucideIcons.chevronDown, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class NavMenuSheet extends StatefulWidget {
  final VoidCallback onClose;

  const NavMenuSheet({super.key, required this.onClose});

  @override
  State<NavMenuSheet> createState() => _NavMenuSheetState();
}

class _NavMenuSheetState extends State<NavMenuSheet> {
  String activeTab = 'surah';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 6,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
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
                    const Text(
                      'Index',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A454E),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
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
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
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
                                    ? const Color(0xFF1A454E)
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search surah, verse, or juz...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
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
            child: activeTab == 'surah'
                ? Consumer<QuranReadingProvider>(
                    builder: (context, readingProvider, child) {
                      if (readingProvider.chapters.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1A454E),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: readingProvider.chapters.length,
                        itemBuilder: (context, index) {
                          final surah = readingProvider.chapters[index];
                          final isCurrent =
                              index ==
                              0; // Replace with actual current surah logic later

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFFF2F8F9)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrent
                                    ? Colors.teal.withOpacity(0.1)
                                    : Colors.transparent,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? const Color(0xFF1A454E)
                                      : Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  surah.id.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrent
                                        ? Colors.white
                                        : Colors.grey[500],
                                  ),
                                ),
                              ),
                              title: Text(
                                surah.nameSimple,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent
                                      ? const Color(0xFF1A454E)
                                      : Colors.grey[800],
                                ),
                              ),
                              subtitle: Text(
                                "Meccan • ${surah.versesCount} Ayahs",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isCurrent)
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.more_horiz,
                                          color: Color(0xFF1A454E),
                                        ),
                                        SizedBox(width: 8),
                                      ],
                                    ),
                                  Text(
                                    surah.nameArabic,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrent
                                          ? const Color(0xFF1A454E)
                                          : Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                : activeTab == 'bookmarks'
                ? const Center(
                    child: Text(
                      "Bookmarks will appear here",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : const Center(
                    child: Text(
                      "Juz list will appear here",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
