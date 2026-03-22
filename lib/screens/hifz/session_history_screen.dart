import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/services/hifz_database_service.dart';

/// Session History — chronological log of all completed sessions.
/// CE-4: Grouped by date, with weekly summary.
class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final profile = context.watch<HifzProfileProvider>();

    if (!profile.hasActiveProfile) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: _buildAppBar(theme),
        body: Center(
          child: Text('No active profile',
              style: TextStyle(color: theme.mutedText)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: _buildAppBar(theme),
      body: FutureBuilder<List<SessionRecord>>(
        future: context
            .read<HifzDatabaseService>()
            .getSessionHistory(profile.activeProfile!.id, limit: 100),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return _buildEmpty(theme);
          }

          // Group sessions by date
          final grouped = _groupByDate(sessions);
          final dates = grouped.keys.toList();

          // Compute weekly stats from all sessions
          final weekStats = _computeWeekStats(sessions);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Weekly summary ──
                _buildWeekSummary(theme, weekStats),
                const SizedBox(height: 24),

                // ── Session list ──
                for (int i = 0; i < dates.length; i++) ...[
                  _buildDateHeader(theme, dates[i]),
                  const SizedBox(height: 8),
                  for (final session in grouped[dates[i]]!) ...[
                    _buildSessionTile(theme, session),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeProvider theme) {
    return AppBar(
      backgroundColor: theme.scaffoldBackground,
      elevation: 0,
      title: Text(
        'Session History',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: theme.primaryText,
        ),
      ),
      iconTheme: IconThemeData(color: theme.primaryText),
    );
  }

  Widget _buildEmpty(ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📋', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'No sessions yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Complete a session to see your history',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: theme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Group sessions by date ──

  Map<String, List<SessionRecord>> _groupByDate(List<SessionRecord> sessions) {
    final map = <String, List<SessionRecord>>{};
    for (final s in sessions) {
      final key = _formatDate(s.date);
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';

    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }

  // ── Weekly stats ──

  _WeekStats _computeWeekStats(List<SessionRecord> sessions) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final thisWeek =
        sessions.where((s) => s.date.isAfter(weekAgo)).toList();

    int totalMinutes = 0;
    int totalPages = 0;
    int strongCount = 0;
    int totalAssessments = 0;

    for (final s in thisWeek) {
      totalMinutes += s.durationMinutes;
      if (s.sabaqPage != null && s.sabaqCompleted) totalPages++;
      if (s.sabaqAssessment != null) {
        totalAssessments++;
        if (s.sabaqAssessment == SelfAssessment.strong) strongCount++;
      }
    }

    return _WeekStats(
      sessionCount: thisWeek.length,
      totalMinutes: totalMinutes,
      pagesCount: totalPages,
      avgRating: totalAssessments > 0
          ? (strongCount / totalAssessments * 100).round()
          : 0,
    );
  }

  Widget _buildWeekSummary(ThemeProvider theme, _WeekStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statChip(theme, LucideIcons.layers, '${stats.sessionCount}',
                  'sessions'),
              const SizedBox(width: 12),
              _statChip(theme, LucideIcons.clock, _formatMinutes(stats.totalMinutes),
                  'total'),
              const SizedBox(width: 12),
              _statChip(theme, LucideIcons.bookOpen, '${stats.pagesCount}',
                  'pages'),
              const SizedBox(width: 12),
              _statChip(theme, LucideIcons.thumbsUp, '${stats.avgRating}%',
                  'strong'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(ThemeProvider theme, IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: theme.accentColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: theme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Session tile ──

  Widget _buildDateHeader(ThemeProvider theme, String date) {
    return Text(
      date,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: theme.secondaryText,
      ),
    );
  }

  Widget _buildSessionTile(ThemeProvider theme, SessionRecord session) {
    final time = '${session.date.hour.toString().padLeft(2, '0')}:'
        '${session.date.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row — time + duration
          Row(
            children: [
              Icon(LucideIcons.clock, size: 14, color: theme.mutedText),
              const SizedBox(width: 6),
              Text(
                '$time · ${session.durationMinutes} min',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                ),
              ),
              const Spacer(),
              Text(
                '${session.repCount} reps',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: theme.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Phase rows
          if (session.sabaqCompleted)
            _phaseRow(theme, '📖', 'Sabaq',
                'Page ${session.sabaqPage ?? "?"}',
                session.sabaqAssessment),
          if (session.sabqiCompleted)
            _phaseRow(theme, '🔁', 'Sabqi',
                '${session.sabqiPages.length} pages',
                session.sabqiAssessment),
          if (session.manzilCompleted)
            _phaseRow(theme, '📚', 'Manzil',
                '${session.manzilPages.length} pages',
                session.manzilAssessment),
          if (!session.sabaqCompleted &&
              !session.sabqiCompleted &&
              !session.manzilCompleted)
            Text(
              'Skipped all phases',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: theme.mutedText,
                  fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }

  Widget _phaseRow(ThemeProvider theme, String emoji, String phase,
      String detail, SelfAssessment? assessment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Text(
            '$phase: $detail',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: theme.primaryText,
            ),
          ),
          if (assessment != null) ...[
            const Spacer(),
            _assessmentBadge(theme, assessment),
          ],
        ],
      ),
    );
  }

  Widget _assessmentBadge(ThemeProvider theme, SelfAssessment assessment) {
    final (emoji, label) = switch (assessment) {
      SelfAssessment.strong => ('💪', 'Strong'),
      SelfAssessment.okay => ('🤔', 'Okay'),
      SelfAssessment.needsWork => ('😬', 'Needs Work'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$emoji $label',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.accentColor,
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }
}

class _WeekStats {
  final int sessionCount;
  final int totalMinutes;
  final int pagesCount;
  final int avgRating;

  const _WeekStats({
    required this.sessionCount,
    required this.totalMinutes,
    required this.pagesCount,
    required this.avgRating,
  });
}
