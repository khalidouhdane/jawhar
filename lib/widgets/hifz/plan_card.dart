import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/theme_provider.dart';

/// Dashboard card showing today's Hifz plan with full daily goal info.
/// CE-8: Rich plan card showing what the user needs to do today.
class PlanCard extends StatelessWidget {
  final DailyPlan plan;
  final ThemeProvider theme;
  final VoidCallback onStartSession;
  final MemoryProfile? profile;

  const PlanCard({
    super.key,
    required this.plan,
    required this.theme,
    required this.onStartSession,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.accentColor,
            theme.accentColor.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.accentColor.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with daily goal
          Row(
            children: [
              const Icon(LucideIcons.calendarCheck, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Today\'s Plan',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // Daily goal badge (CE-8.4)
              if (profile != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _goalBadgeText(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Sabaq phase — with page + line/verse details
          _phaseRow(
            '📖',
            'Sabaq · New',
            plan.sabaqStartVerse != null
                ? 'Page ${plan.sabaqPage} · from verse ${plan.sabaqStartVerse}'
                : 'Page ${plan.sabaqPage} · Lines ${plan.sabaqLineStart}–${plan.sabaqLineEnd}',
            plan.sabaqDoneOffline,
            timeMinutes: plan.sabaqTargetMinutes,
            extraDetail: '${plan.sabaqRepetitionTarget} reps target',
          ),
          const SizedBox(height: 10),

          // Sabqi phase — with page numbers (CE-8.2)
          _phaseRow(
            '🔁',
            'Sabqi · Review',
            plan.sabqiPages.isEmpty
                ? 'No review yet'
                : _formatPageList(plan.sabqiPages),
            plan.sabqiDoneOffline,
            timeMinutes: plan.sabqiTargetMinutes,
          ),
          const SizedBox(height: 10),

          // Manzil phase — with juz info
          _phaseRow(
            '📚',
            'Manzil · Revision',
            plan.manzilPages.isNotEmpty
                ? 'Juz ${plan.manzilJuz} · ${plan.manzilPages.length} pages'
                : 'Not started yet',
            plan.manzilDoneOffline,
            timeMinutes: plan.manzilTargetMinutes,
          ),
          const SizedBox(height: 14),

          // Time allocation summary (CE-8.3)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.clock, size: 12, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  '~${plan.estimatedMinutes} min total',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                if (_hasMultiplePhases()) ...[
                  const Text(' · ', style: TextStyle(color: Colors.white38)),
                  Text(
                    _timeBreakdown(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Start Session button
          GestureDetector(
            onTap: plan.isCompleted ? null : onStartSession,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: plan.isCompleted
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    plan.isCompleted ? LucideIcons.check : LucideIcons.play,
                    size: 16,
                    color: plan.isCompleted
                        ? Colors.white
                        : theme.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    plan.isCompleted ? 'Completed ✨' : 'Start Session',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: plan.isCompleted
                          ? Colors.white
                          : theme.accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _phaseRow(String emoji, String title, String detail, bool doneOffline, {
    int timeMinutes = 0,
    String? extraDetail,
  }) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: doneOffline ? 0.5 : 1.0),
                  decoration: doneOffline ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                detail,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: doneOffline ? 0.3 : 0.7),
                ),
              ),
            ],
          ),
        ),
        if (timeMinutes > 0 && !doneOffline)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '~${timeMinutes}m',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ),
        if (doneOffline)
          Icon(LucideIcons.check, size: 16,
              color: Colors.white.withValues(alpha: 0.5)),
      ],
    );
  }

  // ── Helpers ──

  String _goalBadgeText() {
    if (profile == null) return '~${plan.estimatedMinutes} min';
    final goal = profile!.goal;
    switch (goal) {
      case HifzGoal.fullQuran:
        return 'Full Quran';
      case HifzGoal.specificJuz:
        return '${profile!.goalDetails}';
      case HifzGoal.specificSurahs:
        return '${profile!.goalDetails}';
    }
  }

  String _formatPageList(List<int> pages) {
    if (pages.length <= 3) {
      return 'Pages ${pages.join(', ')}';
    }
    return 'Pages ${pages.take(3).join(', ')}… (+${pages.length - 3})';
  }

  bool _hasMultiplePhases() {
    int active = 0;
    if (!plan.sabaqDoneOffline) active++;
    if (!plan.sabqiDoneOffline && plan.sabqiPages.isNotEmpty) active++;
    if (!plan.manzilDoneOffline && plan.manzilPages.isNotEmpty) active++;
    return active > 1;
  }

  String _timeBreakdown() {
    final parts = <String>[];
    if (!plan.sabaqDoneOffline && plan.sabaqTargetMinutes > 0) {
      parts.add('${plan.sabaqTargetMinutes}m new');
    }
    if (!plan.sabqiDoneOffline && plan.sabqiTargetMinutes > 0) {
      parts.add('${plan.sabqiTargetMinutes}m review');
    }
    if (!plan.manzilDoneOffline && plan.manzilTargetMinutes > 0) {
      parts.add('${plan.manzilTargetMinutes}m revision');
    }
    return parts.join(' / ');
  }
}
