import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/hifz_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';

class HifzScreen extends StatelessWidget {
  const HifzScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = context.watch<ThemeProvider>();
    final hifz = context.watch<HifzProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Header ──
              Text(
                l.t('hifz_title'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.t('hifz_subtitle'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.secondaryText,
                ),
              ),
              const SizedBox(height: 24),

              // ── Streak & Stats Row ──
              _buildStreakRow(context, theme, hifz),
              const SizedBox(height: 20),

              // ── Sabaq / Sabqi / Manzil Progress ──
              _buildProgressSection(context, theme, hifz),
              const SizedBox(height: 24),

              // ── Overall Progress Bar ──
              _buildOverallProgress(context, theme, hifz),
              const SizedBox(height: 24),

              // ── Surah Grid ──
              _buildSectionHeader(
                context,
                theme,
                l.t('hifz_all_surahs'),
                '${hifz.totalMemorized}/114',
              ),
              const SizedBox(height: 12),
              _buildSurahGrid(context, theme, hifz),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Streak Row ──
  Widget _buildStreakRow(
    BuildContext context,
    ThemeProvider theme,
    HifzProvider hifz,
  ) {
    final l = AppLocalizations.of(context);
    final streak = hifz.streak;
    return Row(
      children: [
        // Current streak
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF9800),
                  const Color(0xFFFF9800).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.flame, size: 28, color: Colors.white),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${streak.currentStreak}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Day streak',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Best streak
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.trophy, size: 28, color: theme.accentColor),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${streak.longestStreak}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText,
                      ),
                    ),
                    Text(
                      l.t('hifz_best_streak'),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: theme.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Sabaq / Sabqi / Manzil ──
  Widget _buildProgressSection(
    BuildContext context,
    ThemeProvider theme,
    HifzProvider hifz,
  ) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        _buildProgressRing(
          theme,
          label: l.t('hifz_sabaq'),
          subtitle: l.t('hifz_sabaq_desc'),
          count: hifz.sabaqSurahs.length,
          color: const Color(0xFF4CAF50),
          icon: LucideIcons.bookPlus,
        ),
        const SizedBox(width: 10),
        _buildProgressRing(
          theme,
          label: l.t('hifz_sabqi'),
          subtitle: l.t('hifz_sabqi_desc'),
          count: hifz.sabqiSurahs.length,
          color: const Color(0xFF2196F3),
          icon: LucideIcons.refreshCw,
        ),
        const SizedBox(width: 10),
        _buildProgressRing(
          theme,
          label: l.t('hifz_manzil'),
          subtitle: l.t('hifz_manzil_desc'),
          count: hifz.manzilSurahs.length,
          color: theme.accentColor,
          icon: LucideIcons.checkCircle,
        ),
      ],
    );
  }

  Widget _buildProgressRing(
    ThemeProvider theme, {
    required String label,
    required String subtitle,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            // Ring
            SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: count / max(1, 114).toDouble(),
                    strokeWidth: 4,
                    backgroundColor: theme.dividerColor,
                    color: color,
                  ),
                  Icon(icon, size: 18, color: color),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: theme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Overall Progress ──
  Widget _buildOverallProgress(
    BuildContext context,
    ThemeProvider theme,
    HifzProvider hifz,
  ) {
    final l = AppLocalizations.of(context);
    final pct = (hifz.overallProgress * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.t('hifz_overall'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: hifz.overallProgress,
              minHeight: 8,
              backgroundColor: theme.dividerColor,
              color: theme.accentColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${hifz.totalMemorized} ${l.t('hifz_of_surahs')}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: theme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ──
  Widget _buildSectionHeader(
    BuildContext context,
    ThemeProvider theme,
    String title,
    String trailing,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        Text(
          trailing,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.accentColor,
          ),
        ),
      ],
    );
  }

  // ── Surah Grid ──
  Widget _buildSurahGrid(
    BuildContext context,
    ThemeProvider theme,
    HifzProvider hifz,
  ) {
    final chapters = context.read<QuranReadingProvider>().chapters;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: 114,
      itemBuilder: (context, index) {
        final surahId = index + 1;
        final record = hifz.getRecord(surahId);

        Color bgColor;
        Color textColor;
        switch (record.status) {
          case HifzStatus.none:
            bgColor = theme.cardColor;
            textColor = theme.mutedText;
            break;
          case HifzStatus.learning:
            bgColor = const Color(0xFF4CAF50).withValues(alpha: 0.15);
            textColor = const Color(0xFF4CAF50);
            break;
          case HifzStatus.reviewing:
            bgColor = const Color(0xFF2196F3).withValues(alpha: 0.15);
            textColor = const Color(0xFF2196F3);
            break;
          case HifzStatus.memorized:
            bgColor = theme.accentColor.withValues(alpha: 0.15);
            textColor = theme.accentColor;
            break;
        }

        return GestureDetector(
          onTap: () => hifz.cycleStatus(surahId),
          onLongPress: () => _showSurahDetail(
            context,
            theme,
            hifz,
            surahId,
            chapters.length >= surahId ? chapters[surahId - 1].nameSimple : '',
          ),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: record.status != HifzStatus.none
                    ? textColor.withValues(alpha: 0.3)
                    : theme.dividerColor,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$surahId',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: record.status != HifzStatus.none
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSurahDetail(
    BuildContext context,
    ThemeProvider theme,
    HifzProvider hifz,
    int surahId,
    String name,
  ) {
    final record = hifz.getRecord(surahId);
    final l = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.sheetDragHandle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '$surahId. $name',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                record.lastReviewed != null
                    ? '${l.t('hifz_last_reviewed')} ${_formatDate(record.lastReviewed!)}'
                    : l.t('hifz_never_reviewed'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: theme.mutedText,
                ),
              ),
              const SizedBox(height: 20),
              // Status options
              _statusOption(
                ctx,
                theme,
                hifz,
                surahId,
                HifzStatus.none,
                'Not Started',
                LucideIcons.circle,
                Colors.grey,
              ),
              _statusOption(
                ctx,
                theme,
                hifz,
                surahId,
                HifzStatus.learning,
                l.t('hifz_learning'),
                LucideIcons.bookPlus,
                const Color(0xFF4CAF50),
              ),
              _statusOption(
                ctx,
                theme,
                hifz,
                surahId,
                HifzStatus.reviewing,
                l.t('hifz_reviewing'),
                LucideIcons.refreshCw,
                const Color(0xFF2196F3),
              ),
              _statusOption(
                ctx,
                theme,
                hifz,
                surahId,
                HifzStatus.memorized,
                l.t('hifz_memorized'),
                LucideIcons.checkCircle,
                theme.accentColor,
              ),
              const SizedBox(height: 12),
              // Mark reviewed button
              if (record.status != HifzStatus.none)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      hifz.markReviewed(surahId);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(LucideIcons.checkCheck, size: 18),
                    label: Text(
                      'Mark Reviewed Today (${record.reviewCount} ${l.t('hifz_total')})',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _statusOption(
    BuildContext ctx,
    ThemeProvider theme,
    HifzProvider hifz,
    int surahId,
    HifzStatus status,
    String label,
    IconData icon,
    Color color,
  ) {
    final isActive = hifz.getRecord(surahId).status == status;
    return GestureDetector(
      onTap: () {
        hifz.setStatus(surahId, status);
        Navigator.pop(ctx);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: color.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? color : theme.primaryText,
              ),
            ),
            const Spacer(),
            if (isActive) Icon(LucideIcons.check, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
