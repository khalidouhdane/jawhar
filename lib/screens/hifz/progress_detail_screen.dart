import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/screens/hifz/session_history_screen.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/data/surah_metadata.dart';

/// Juz page ranges — Madani Mushaf layout (pages 1-604, 30 juz).
const List<List<int>> _juzPageRanges = [
  [1, 21], [22, 41], [42, 61], [62, 81], [82, 101], // 1-5
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
    final recentPages = progress.values
        .where(
          (p) => p.lastReviewedAt != null && p.lastReviewedAt!.isAfter(weekAgo),
        )
        .length;

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
                      child: Icon(
                        LucideIcons.arrowLeft,
                        size: 18,
                        color: theme.primaryText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.progressTitle,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
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
                labelStyle: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                dividerHeight: 0,
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.progressTabPages),
                  Tab(text: AppLocalizations.of(context)!.progressTabSurahs),
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
                children: [_buildPagesTab(theme), _buildSurahsTab(theme)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats(ThemeProvider theme, HifzProfileProvider profile) {
    final total = _allProgress!.length;
    final memorized = total;
    final pct = total > 0 ? (total / 604 * 100).toStringAsFixed(1) : '0.0';

    final l = AppLocalizations.of(context)!;
    
    // CE-5.1: Estimated completion
    final remaining = 604 - total;
    String estCompletion = '--';
    if (_pagesPerWeek > 0 && remaining > 0) {
      final weeksLeft = (remaining / _pagesPerWeek).ceil();
      if (weeksLeft <= 52) {
        estCompletion = l.progressEstWeeks(weeksLeft);
      } else {
        estCompletion = l.progressEstYears((weeksLeft / 52).toStringAsFixed(1));
      }
    } else if (remaining == 0) {
      estCompletion = l.progressComplete;
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
                      l.progressTotalPages(total),
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$pct%',
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
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
                    _statChip(
                      theme,
                      LucideIcons.flame,
                      l.progressActiveDays(profile.streak.totalActiveDays),
                    ),
                    const SizedBox(width: 10),
                    _statChip(
                      theme,
                      LucideIcons.bookOpen,
                      l.progressMemorized(memorized),
                    ),
                    const SizedBox(width: 10),
                    _statChip(
                      theme,
                      LucideIcons.zap,
                      l.progressPagesPerWeek(_pagesPerWeek.round()),
                    ),
                    const SizedBox(width: 10),
                    _statChip(theme, LucideIcons.target, estCompletion),
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
                    l.progressViewHistory,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.accentColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l.progressSessionsCount(_recentSessions.length),
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 14,
                    color: theme.mutedText,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(ThemeProvider theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: theme.accentColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
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
      return Center(child: CircularProgressIndicator(color: theme.accentColor));
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
            onTap: () =>
                setState(() => _expandedJuz = isExpanded ? null : juzNum),
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
                        AppLocalizations.of(context)!.progressJuz(juzNum),
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: pct > 0 ? theme.accentColor : theme.mutedText,
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
                        _legendItem(theme, theme.primaryText, AppLocalizations.of(context)!.progressLegendMemorized),
                        const SizedBox(width: 8),
                        _legendItem(theme, theme.dividerColor, AppLocalizations.of(context)!.progressLegendLearning),
                        const SizedBox(width: 8),
                        _legendItem(theme, theme.secondaryText, AppLocalizations.of(context)!.progressLegendReviewing),
                        const SizedBox(width: 8),
                        _legendItem(theme, theme.dividerColor.withValues(alpha: 0.2), AppLocalizations.of(context)!.progressLegendNotStarted),
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
    Color textColor;

    switch (status) {
      case PageStatus.memorized:
        dotColor = theme.primaryText;
        textColor = theme.scaffoldBackground;
        break;
      case PageStatus.reviewing:
        dotColor = theme.secondaryText;
        textColor = theme.scaffoldBackground;
        break;
      case PageStatus.learning:
        dotColor = theme.dividerColor;
        textColor = theme.primaryText;
        break;
      default:
        dotColor = theme.dividerColor.withValues(alpha: 0.2);
        textColor = theme.mutedText;
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
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 7,
              fontWeight: FontWeight.w600,
              color: textColor,
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
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 9,
            color: theme.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildSurahsTab(ThemeProvider theme) {
    if (_allProgress == null) {
      return Center(child: CircularProgressIndicator(color: theme.accentColor));
    }
    
    final l = AppLocalizations.of(context)!;
    final isAr = AppLocalizations.of(context)!.localeName == 'ar';

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: allSurahs.length,
      itemBuilder: (context, index) {
        final surah = allSurahs[index];
        final name = isAr ? surah.nameArabic : surah.nameSimple;
        final startPage = surah.startPage;
        final endPage = index < 113 ? allSurahs[index + 1].startPage - 1 : 604;
        final effectiveEndPage = endPage < startPage ? startPage : endPage;
        final pageCount = effectiveEndPage - startPage + 1;
        final surahNum = surah.id;

        // Count how many pages have progress
        int progressCount = 0;
        for (int p = startPage; p <= effectiveEndPage; p++) {
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
                        fontFamily: GeistTypography.primaryFontFamily,
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
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                      Text(
                        pageCount == 1
                            ? l.progressPageRangeSingle(startPage)
                            : l.progressPageRangeMultiple(startPage, effectiveEndPage),
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
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
                          fontFamily: GeistTypography.primaryFontFamily,
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
