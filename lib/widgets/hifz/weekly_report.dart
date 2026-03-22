import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/theme_provider.dart';

/// Weekly/monthly report visualization widget.
/// Renders session activity chart, assessment breakdown, key stats,
/// and period comparison using custom painting.
class WeeklyReportWidget extends StatelessWidget {
  final WeeklySnapshot snapshot;
  final WeeklySnapshot? previousSnapshot;
  final Map<String, dynamic>? paceData;
  final ThemeProvider theme;

  const WeeklyReportWidget({
    super.key,
    required this.snapshot,
    this.previousSnapshot,
    this.paceData,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Key Stats Row ──
        _buildKeyStats(),
        const SizedBox(height: 20),

        // ── Session Activity Chart ──
        _buildSectionHeader('Session Activity'),
        const SizedBox(height: 12),
        _buildActivityChart(),
        const SizedBox(height: 24),

        // ── Assessment Breakdown ──
        if (snapshot.totalAssessments > 0) ...[
          _buildSectionHeader('Self-Assessment'),
          const SizedBox(height: 12),
          _buildAssessmentBreakdown(),
          const SizedBox(height: 24),
        ],

        // ── Period Comparison ──
        if (previousSnapshot != null && previousSnapshot!.hasEnoughData) ...[
          _buildSectionHeader('Compared to Last Week'),
          const SizedBox(height: 12),
          _buildComparison(),
          const SizedBox(height: 24),
        ],

        // ── Pace Projection ──
        if (paceData != null) ...[
          _buildPaceCard(),
        ],
      ],
    );
  }

  // ── Key Stats Row ──
  Widget _buildKeyStats() {
    return Row(
      children: [
        _buildStatChip(
          '${snapshot.totalSessions}',
          'Sessions',
          const Color(0xFF4DB6AC),
        ),
        const SizedBox(width: 10),
        _buildStatChip(
          '${snapshot.pagesMemorized}',
          'Pages New',
          const Color(0xFF7986CB),
        ),
        const SizedBox(width: 10),
        _buildStatChip(
          '${snapshot.completionRate > 0 ? (snapshot.completionRate * 100).round() : 0}%',
          'Completion',
          const Color(0xFFFFB74D),
        ),
        const SizedBox(width: 10),
        _buildStatChip(
          '${snapshot.avgDurationMinutes.round()}m',
          'Avg Time',
          const Color(0xFF90CAF9),
        ),
      ],
    );
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: theme.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Activity Chart ──
  Widget _buildActivityChart() {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxSessions = snapshot.sessionsPerDay.values.fold<int>(
        0, (max, v) => v > max ? v : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (i) {
            final day = i + 1; // 1=Mon..7=Sun
            final count = snapshot.sessionsPerDay[day] ?? 0;
            final barHeight = maxSessions > 0
                ? (count / maxSessions) * 80
                : 0.0;

            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (count > 0)
                    Text(
                      '$count',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: theme.accentColor,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    height: math.max(barHeight, 4),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: count > 0
                          ? theme.accentColor
                          : theme.dividerColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayLabels[i],
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: theme.mutedText,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Assessment Breakdown ──
  Widget _buildAssessmentBreakdown() {
    final total = snapshot.totalAssessments;
    if (total == 0) return const SizedBox.shrink();

    final strongPct = (snapshot.strongCount / total * 100).round();
    final okayPct = (snapshot.okayCount / total * 100).round();
    final needsWorkPct = (snapshot.needsWorkCount / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          // Horizontal stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (snapshot.strongCount > 0)
                    Flexible(
                      flex: snapshot.strongCount,
                      child: Container(color: const Color(0xFF66BB6A)),
                    ),
                  if (snapshot.okayCount > 0)
                    Flexible(
                      flex: snapshot.okayCount,
                      child: Container(color: const Color(0xFFFFCA28)),
                    ),
                  if (snapshot.needsWorkCount > 0)
                    Flexible(
                      flex: snapshot.needsWorkCount,
                      child: Container(color: const Color(0xFFEF5350)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('😊 Strong', '$strongPct%', const Color(0xFF66BB6A)),
              _buildLegendItem('😐 Okay', '$okayPct%', const Color(0xFFFFCA28)),
              _buildLegendItem('😟 Needs Work', '$needsWorkPct%', const Color(0xFFEF5350)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, String value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: theme.mutedText,
          ),
        ),
      ],
    );
  }

  // ── Period Comparison ──
  Widget _buildComparison() {
    final prev = previousSnapshot!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          _buildCompareItem(
            'Sessions',
            snapshot.totalSessions,
            prev.totalSessions,
          ),
          _buildCompareItem(
            'Pages',
            snapshot.pagesMemorized,
            prev.pagesMemorized,
          ),
          _buildCompareItem(
            'Completion',
            (snapshot.completionRate * 100).round(),
            (prev.completionRate * 100).round(),
            suffix: '%',
          ),
        ],
      ),
    );
  }

  Widget _buildCompareItem(
    String label,
    int current,
    int previous, {
    String suffix = '',
  }) {
    final diff = current - previous;
    final isUp = diff > 0;
    final isDown = diff < 0;

    return Expanded(
      child: Column(
        children: [
          Text(
            '$current$suffix',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          if (diff != 0)
            Text(
              '${isUp ? '↑' : '↓'} ${diff.abs()}$suffix',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isUp
                    ? const Color(0xFF66BB6A)
                    : isDown
                        ? const Color(0xFFEF5350)
                        : theme.mutedText,
              ),
            )
          else
            Text(
              '— same',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: theme.mutedText,
              ),
            ),
          const SizedBox(height: 4),
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

  // ── Pace Projection ──
  Widget _buildPaceCard() {
    final memorized = paceData!['memorizedPages'] as int;
    final total = paceData!['totalGoalPages'] as int;
    final months = paceData!['monthsRemaining'] as int;
    final progress = (paceData!['progressPercent'] as double).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.accentColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '🎯',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Pace Projection',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.dividerColor,
                valueColor:
                    AlwaysStoppedAnimation<Color>(theme.accentColor),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$memorized / $total pages',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
              Text(
                months > 0
                    ? 'Est. $months month${months > 1 ? 's' : ''} remaining'
                    : 'Goal reached! 🎉',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: theme.secondaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ──

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: theme.primaryText,
        letterSpacing: -0.2,
      ),
    );
  }
}
