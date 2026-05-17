import 'package:quran_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/semantic_colors.dart';

/// Dashboard card showing rich memorization progress summary.
/// CE-10: Shows active juz progress bar, pace, streak, last session.
class ProgressCard extends StatelessWidget {
  final int totalPagesDone;
  final int activeDays;
  final Map<PageStatus, int> statusCounts;
  final ThemeProvider theme;
  final VoidCallback? onTap;
  final StreakData? streak;
  final int? currentJuz;
  final int? currentJuzProgress; // pages memorized in current juz
  final int? currentJuzTotal; // total pages in current juz
  final SessionRecord? lastSession;
  final double? pagesPerWeek;

  const ProgressCard({
    super.key,
    required this.totalPagesDone,
    required this.activeDays,
    required this.statusCounts,
    required this.theme,
    this.onTap,
    this.streak,
    this.currentJuz,
    this.currentJuzProgress,
    this.currentJuzTotal,
    this.lastSession,
    this.pagesPerWeek,
  });

  @override
  Widget build(BuildContext context) {
    final memorized = statusCounts[PageStatus.memorized] ?? 0;
    final learning = statusCounts[PageStatus.learning] ?? 0;
    final reviewing = statusCounts[PageStatus.reviewing] ?? 0;
    final total = memorized + learning + reviewing;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(theme.radiusLg),
          boxShadow: theme.shadowCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  LucideIcons.trendingUp,
                  size: 16,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.progYourProgress,
                  style: theme.textBodyStrong,
                ),
                const Spacer(),
                // Streak (CE-10.4)
                if (activeDays > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: SemanticColors.practiceAmber.bg(theme.isDark),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.flame,
                          size: 12,
                          color: SemanticColors.practiceAmber.fg(theme.isDark),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$activeDays ${AppLocalizations.of(context)!.progressDays}',
                          style: theme.textCaption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: SemanticColors.practiceAmber.fg(
                              theme.isDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: theme.mutedText,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Active juz progress bar (CE-10.1)
            if (currentJuz != null &&
                currentJuzTotal != null &&
                currentJuzTotal! > 0) ...[
              _buildJuzProgress(context),
              const SizedBox(height: 14),
            ],

            // Overall progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Row(
                  children: [
                    if (memorized > 0)
                      Expanded(
                        flex: memorized,
                        child: Container(color: theme.accentColor),
                      ),
                    if (reviewing > 0)
                      Expanded(
                        flex: reviewing,
                        child: Container(
                          color: theme.accentColor.withValues(alpha: 0.5),
                        ),
                      ),
                    if (learning > 0)
                      Expanded(
                        flex: learning,
                        child: Container(
                          color: theme.accentColor.withValues(alpha: 0.25),
                        ),
                      ),
                    Expanded(
                      flex: (604 - total).clamp(1, 604),
                      child: Container(color: theme.dividerColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Percentage label
            Text(
              '${(total / 604 * 100).toStringAsFixed(1)}% ${AppLocalizations.of(context)!.progOfQuran} · $total/604 ${AppLocalizations.of(context)!.progPages}',
              style: theme.textCaption.copyWith(color: theme.mutedText),
            ),
            const SizedBox(height: 14),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(
                  '$memorized',
                  AppLocalizations.of(context)!.progMemorized,
                  SemanticColors.progressMemorized,
                ),
                _statDivider(),
                _statItem(
                  '$reviewing',
                  AppLocalizations.of(context)!.progReviewing,
                  SemanticColors.progressReviewing,
                ),
                _statDivider(),
                _statItem(
                  '$learning',
                  AppLocalizations.of(context)!.progLearning,
                  SemanticColors.progressLearning,
                ),
                _statDivider(),
                if (pagesPerWeek != null) ...[
                  _statItem(
                    pagesPerWeek!.toStringAsFixed(1),
                    AppLocalizations.of(context)!.progPagesPerWeek,
                    theme.accentColor,
                  ),
                ] else ...[
                  _statItem(
                    '$activeDays',
                    AppLocalizations.of(context)!.progActiveDays,
                    theme.accentColor,
                  ),
                ],
              ],
            ),

            // Last session (CE-10.3)
            if (lastSession != null) ...[
              const SizedBox(height: 14),
              _buildLastSession(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJuzProgress(BuildContext context) {
    final progress = currentJuzProgress ?? 0;
    final total = currentJuzTotal ?? 1;
    final pct = (progress / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(theme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${AppLocalizations.of(context)!.readTabJuz} $currentJuz',
                style: theme.textCaption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
              const Spacer(),
              Text(
                '$pct% · $progress/$total pages',
                style: theme.textCaption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress / total,
              minHeight: 6,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation(theme.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastSession(BuildContext context) {
    final session = lastSession!;
    final time =
        '${session.date.hour.toString().padLeft(2, '0')}:'
        '${session.date.minute.toString().padLeft(2, '0')}';
    final assessment = session.sabaqAssessment != null
        ? _assessmentText(context, session.sabaqAssessment!)
        : '';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.scaffoldBackground,
        borderRadius: BorderRadius.circular(theme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.clock, size: 12, color: theme.mutedText),
          const SizedBox(width: 6),
          Text(
            '${AppLocalizations.of(context)!.progressLast}: $time · ${session.durationMinutes}${AppLocalizations.of(context)!.timeMin}',
            style: theme.textCaption.copyWith(color: theme.secondaryText),
          ),
          if (session.sabaqPage != null) ...[
            Text(
              ' · p.${session.sabaqPage}',
              style: theme.textCaption.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.primaryText,
              ),
            ),
          ],
          if (assessment.isNotEmpty) ...[
            const Spacer(),
            Text(
              assessment,
              style: theme.textMicroBadge.copyWith(color: theme.accentColor),
            ),
          ],
        ],
      ),
    );
  }

  String _assessmentText(BuildContext context, SelfAssessment a) {
    return switch (a) {
      SelfAssessment.strong => AppLocalizations.of(context)!.progAssStrong,
      SelfAssessment.okay => AppLocalizations.of(context)!.progAssOkay,
      SelfAssessment.needsWork => AppLocalizations.of(
        context,
      )!.progAssNeedsWork,
    };
  }

  Widget _statItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textBodyLarge.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textMicroBadge.copyWith(color: theme.mutedText),
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 30, color: theme.dividerColor);
  }
}
