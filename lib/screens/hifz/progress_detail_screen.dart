import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/screens/hifz/session_history_screen.dart';

/// Juz page ranges — Madani Mushaf layout (pages 1-604, 30 juz).
const List<List<int>> _juzPageRanges = [
  [1, 21], [22, 41], [42, 61], [62, 81], [82, 101],       // 1-5
  [102, 121], [122, 141], [142, 161], [162, 181], [182, 201], // 6-10
  [202, 221], [222, 241], [242, 261], [262, 281], [282, 301], // 11-15
  [302, 321], [322, 341], [342, 361], [362, 381], [382, 401], // 16-20
  [402, 421], [422, 441], [442, 461], [462, 481], [482, 501], // 21-25
  [502, 521], [522, 541], [542, 561], [562, 581], [582, 604], // 26-30
];

/// Progress detail screen — Pages (default) and Surahs tabs.
/// 📄 Reference: user-flows.md § Flow 7
class ProgressDetailScreen extends StatefulWidget {
  const ProgressDetailScreen({super.key});

  @override
  State<ProgressDetailScreen> createState() => _ProgressDetailScreenState();
}

class _ProgressDetailScreenState extends State<ProgressDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<int, PageProgress>? _allProgress;
  int? _expandedJuz;
  double _pagesPerWeek = 0;
  List<SessionRecord> _recentSessions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = context.read<HifzDatabaseService>();
    final profile = context.read<HifzProfileProvider>().activeProfile;
    if (profile == null) return;
    final progress = await db.getAllPageProgress(profile.id);
    final sessions = await db.getSessionHistory(profile.id, limit: 100);

    // CE-5.1: Calculate pace — pages with progress from last 7 days
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentPages = progress.values.where((p) =>
        p.lastReviewedAt != null && p.lastReviewedAt!.isAfter(weekAgo)).length;

    if (mounted) {
      setState(() {
        _allProgress = progress;
        _recentSessions = sessions;
        _pagesPerWeek = recentPages.toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final profile = context.watch<HifzProfileProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Icon(LucideIcons.arrowLeft,
                          size: 18, color: theme.primaryText),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: theme.primaryText,
                    ),
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: theme.accentColor,
                  borderRadius: BorderRadius.circular(11),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: theme.secondaryText,
                labelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                dividerHeight: 0,
                tabs: const [
                  Tab(text: 'Pages'),
                  Tab(text: 'Surahs'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Overall stats
            if (_allProgress != null && profile.hasActiveProfile)
              _buildOverallStats(theme, profile),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPagesTab(theme),
                  _buildSurahsTab(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats(ThemeProvider theme, HifzProfileProvider profile) {
    final total = _allProgress!.length;
    final memorized = _allProgress!.values
        .where((p) => p.status == PageStatus.memorized)
        .length;
    final pct = total > 0 ? (total / 604 * 100).toStringAsFixed(1) : '0.0';

    // CE-5.1: Estimated completion
    final remaining = 604 - total;
    String estCompletion = '--';
    if (_pagesPerWeek > 0 && remaining > 0) {
      final weeksLeft = (remaining / _pagesPerWeek).ceil();
      if (weeksLeft <= 52) {
        estCompletion = '$weeksLeft weeks';
      } else {
        estCompletion = '${(weeksLeft / 52).toStringAsFixed(1)} years';
      }
    } else if (remaining == 0) {
      estCompletion = 'Complete! 🎉';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$total/604 pages',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.accentColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total / 604,
                    minHeight: 8,
                    backgroundColor: theme.dividerColor,
                    valueColor: AlwaysStoppedAnimation(theme.accentColor),
                  ),
                ),
                const SizedBox(height: 10),
                // CE-5.1: Quick stats row
                Row(
                  children: [
                    _statChip(theme, '🔥', '${profile.streak.totalActiveDays} days'),
                    const SizedBox(width: 10),
                    _statChip(theme, '📗', '$memorized memorized'),
                    const SizedBox(width: 10),
                    _statChip(theme, '⚡', '${_pagesPerWeek.round()}/wk'),
                    const SizedBox(width: 10),
                    _statChip(theme, '🎯', estCompletion),
                  ],
                ),
              ],
            ),
          ),
          // CE-5.3: Session history link
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SessionHistoryScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.history, size: 16, color: theme.accentColor),
                  const SizedBox(width: 8),
                  Text(
                    'View Session History',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.accentColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_recentSessions.length} sessions',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(LucideIcons.chevronRight, size: 14, color: theme.mutedText),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(ThemeProvider theme, String emoji, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: theme.mutedText,
          ),
        ),
      ],
    );
  }

  // ── Pages Tab ──

  Widget _buildPagesTab(ThemeProvider theme) {
    if (_allProgress == null) {
      return Center(
        child: CircularProgressIndicator(color: theme.accentColor),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNum = 30 - index; // Show Juz 30 first (most common start)
        final range = _juzPageRanges[juzNum - 1];
        final startPage = range[0];
        final endPage = range[1];
        final pageCount = endPage - startPage + 1;

        // Count pages with progress in this juz
        int progressCount = 0;
        for (int p = startPage; p <= endPage; p++) {
          if (_allProgress!.containsKey(p)) progressCount++;
        }
        final pct = (progressCount / pageCount * 100).round();
        final isExpanded = _expandedJuz == juzNum;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => setState(() =>
                _expandedJuz = isExpanded ? null : juzNum),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isExpanded
                      ? theme.accentColor.withValues(alpha: 0.3)
                      : theme.dividerColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Juz $juzNum',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: pct > 0
                              ? theme.accentColor
                              : theme.mutedText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isExpanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 16,
                        color: theme.mutedText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressCount / pageCount,
                      minHeight: 6,
                      backgroundColor: theme.dividerColor,
                      valueColor: AlwaysStoppedAnimation(theme.accentColor),
                    ),
                  ),
                  // Expanded page grid
                  if (isExpanded) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: List.generate(pageCount, (i) {
                        final page = startPage + i;
                        final progress = _allProgress![page];
                        return _pageGridDot(theme, page, progress?.status);
                      }),
                    ),
                    const SizedBox(height: 8),
                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legendItem(theme, Colors.green, 'Memorized'),
                        const SizedBox(width: 8),
                        _legendItem(theme, Colors.amber, 'Learning'),
                        const SizedBox(width: 8),
                        _legendItem(theme, Colors.blue, 'Reviewing'),
                        const SizedBox(width: 8),
                        _legendItem(
                            theme, theme.dividerColor, 'Not started'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pageGridDot(ThemeProvider theme, int page, PageStatus? status) {
    Color dotColor;
    switch (status) {
      case PageStatus.memorized:
        dotColor = Colors.green;
        break;
      case PageStatus.learning:
        dotColor = Colors.amber;
        break;
      case PageStatus.reviewing:
        dotColor = Colors.blue;
        break;
      default:
        dotColor = theme.dividerColor;
    }

    return Tooltip(
      message: 'Page $page',
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: dotColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: status != null && status != PageStatus.notStarted
                  ? Colors.white
                  : theme.mutedText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendItem(ThemeProvider theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            color: theme.mutedText,
          ),
        ),
      ],
    );
  }

  // ── Surahs Tab (CE-5.2) ──

  /// Surah data: [name, startPage, endPage]
  static const _surahData = <List<dynamic>>[
    ['Al-Fatihah', 1, 1], ['Al-Baqarah', 2, 49], ['Aal-Imran', 50, 76],
    ['An-Nisa', 77, 106], ['Al-Maidah', 106, 127], ['Al-Anam', 128, 150],
    ['Al-Araf', 151, 176], ['Al-Anfal', 177, 186], ['At-Tawbah', 187, 207],
    ['Yunus', 208, 221], ['Hud', 221, 235], ['Yusuf', 235, 248],
    ['Ar-Rad', 249, 255], ['Ibrahim', 255, 261], ['Al-Hijr', 262, 267],
    ['An-Nahl', 267, 281], ['Al-Isra', 282, 293], ['Al-Kahf', 293, 304],
    ['Maryam', 305, 312], ['Taha', 312, 321], ['Al-Anbiya', 322, 331],
    ['Al-Hajj', 332, 341], ['Al-Muminun', 342, 349], ['An-Nur', 350, 359],
    ['Al-Furqan', 359, 366], ['Ash-Shuara', 367, 376], ['An-Naml', 377, 385],
    ['Al-Qasas', 385, 396], ['Al-Ankabut', 396, 404], ['Ar-Rum', 404, 410],
    ['Luqman', 411, 414], ['As-Sajdah', 415, 417], ['Al-Ahzab', 418, 427],
    ['Saba', 428, 434], ['Fatir', 434, 440], ['Ya-Sin', 440, 445],
    ['As-Saffat', 446, 452], ['Sad', 453, 458], ['Az-Zumar', 458, 467],
    ['Ghafir', 467, 476], ['Fussilat', 477, 482], ['Ash-Shura', 483, 489],
    ['Az-Zukhruf', 489, 495], ['Ad-Dukhan', 496, 498], ['Al-Jathiyah', 499, 502],
    ['Al-Ahqaf', 502, 506], ['Muhammad', 507, 510], ['Al-Fath', 511, 515],
    ['Al-Hujurat', 515, 517], ['Qaf', 518, 520], ['Adh-Dhariyat', 520, 523],
    ['At-Tur', 523, 525], ['An-Najm', 526, 528], ['Al-Qamar', 528, 531],
    ['Ar-Rahman', 531, 534], ['Al-Waqiah', 534, 537], ['Al-Hadid', 537, 541],
    ['Al-Mujadila', 542, 545], ['Al-Hashr', 545, 548], ['Al-Mumtahanah', 549, 551],
    ['As-Saff', 551, 552], ['Al-Jumuah', 553, 554], ['Al-Munafiqun', 554, 555],
    ['At-Taghabun', 556, 557], ['At-Talaq', 558, 559], ['At-Tahrim', 560, 561],
    ['Al-Mulk', 562, 564], ['Al-Qalam', 564, 566], ['Al-Haqqah', 566, 568],
    ['Al-Maarij', 568, 570], ['Nuh', 570, 571], ['Al-Jinn', 572, 573],
    ['Al-Muzzammil', 574, 575], ['Al-Muddaththir', 575, 577],
    ['Al-Qiyamah', 577, 578], ['Al-Insan', 578, 580], ['Al-Mursalat', 580, 581],
    ['An-Naba', 582, 583], ['An-Naziat', 583, 584], ['Abasa', 585, 585],
    ['At-Takwir', 586, 586], ['Al-Infitar', 587, 587], ['Al-Mutaffifin', 587, 589],
    ['Al-Inshiqaq', 589, 589], ['Al-Buruj', 590, 590], ['At-Tariq', 591, 591],
    ['Al-Ala', 591, 592], ['Al-Ghashiyah', 592, 592], ['Al-Fajr', 593, 594],
    ['Al-Balad', 594, 594], ['Ash-Shams', 595, 595], ['Al-Layl', 595, 596],
    ['Ad-Duha', 596, 596], ['Ash-Sharh', 596, 596], ['At-Tin', 597, 597],
    ['Al-Alaq', 597, 597], ['Al-Qadr', 598, 598], ['Al-Bayyinah', 598, 599],
    ['Az-Zalzalah', 599, 599], ['Al-Adiyat', 599, 600], ['Al-Qariah', 600, 600],
    ['At-Takathur', 600, 600], ['Al-Asr', 601, 601], ['Al-Humazah', 601, 601],
    ['Al-Fil', 601, 601], ['Quraysh', 602, 602], ['Al-Maun', 602, 602],
    ['Al-Kawthar', 602, 602], ['Al-Kafirun', 603, 603], ['An-Nasr', 603, 603],
    ['Al-Masad', 603, 603], ['Al-Ikhlas', 604, 604], ['Al-Falaq', 604, 604],
    ['An-Nas', 604, 604],
  ];

  Widget _buildSurahsTab(ThemeProvider theme) {
    if (_allProgress == null) {
      return Center(
        child: CircularProgressIndicator(color: theme.accentColor),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _surahData.length,
      itemBuilder: (context, index) {
        final surah = _surahData[index];
        final name = surah[0] as String;
        final startPage = surah[1] as int;
        final endPage = surah[2] as int;
        final pageCount = endPage - startPage + 1;
        final surahNum = index + 1;

        // Count how many pages have progress
        int progressCount = 0;
        for (int p = startPage; p <= endPage; p++) {
          if (_allProgress!.containsKey(p)) progressCount++;
        }
        final pct = (progressCount / pageCount * 100).round();

        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                // Surah number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: pct > 0
                        ? theme.accentColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$surahNum',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: pct > 0 ? theme.accentColor : theme.mutedText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name + page range
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                      Text(
                        pageCount == 1
                            ? 'Page $startPage'
                            : 'Pages $startPage–$endPage',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: theme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress
                SizedBox(
                  width: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: pct > 0 ? theme.accentColor : theme.mutedText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progressCount / pageCount,
                          minHeight: 4,
                          backgroundColor: theme.dividerColor,
                          valueColor: AlwaysStoppedAnimation(
                            pct == 100 ? Colors.green : theme.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
