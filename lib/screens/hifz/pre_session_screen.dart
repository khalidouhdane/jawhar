import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/plan_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/hifz/session_screen.dart';

/// Pre-session screen — plan review, offline checkboxes, estimated time.
/// Entry point between dashboard and active session.
/// 📄 Reference: session-design.md § Pre-Session
class PreSessionScreen extends StatefulWidget {
  const PreSessionScreen({super.key});

  @override
  State<PreSessionScreen> createState() => _PreSessionScreenState();
}

class _PreSessionScreenState extends State<PreSessionScreen> {
  bool _sabaqOffline = false;
  bool _sabqiOffline = false;
  bool _manzilOffline = false;

  @override
  void initState() {
    super.initState();
    final plan = context.read<PlanProvider>().todayPlan;
    if (plan != null) {
      _sabaqOffline = plan.sabaqDoneOffline;
      _sabqiOffline = plan.sabqiDoneOffline;
      _manzilOffline = plan.manzilDoneOffline;
    }
  }

  int get _activePhasesCount =>
      (_sabaqOffline ? 0 : 1) +
      (_sabqiOffline ? 0 : 1) +
      (_manzilOffline ? 0 : 1);

  bool get _allDone => _sabaqOffline && _sabqiOffline && _manzilOffline;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final planProvider = context.watch<PlanProvider>();
    final plan = planProvider.todayPlan;

    if (plan == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackground,
        body: Center(
          child: Text('No plan available',
              style: TextStyle(color: theme.secondaryText)),
        ),
      );
    }

    // Calculate estimated minutes for active phases only
    int estMinutes = 0;
    if (!_sabaqOffline) estMinutes += plan.sabaqTargetMinutes;
    if (!_sabqiOffline) estMinutes += plan.sabqiTargetMinutes;
    if (!_manzilOffline) estMinutes += plan.manzilTargetMinutes;

    final today = DateTime.now();
    final dayNames = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
    ];
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dateStr =
        '${dayNames[today.weekday - 1]}, ${monthNames[today.month - 1]} ${today.day}';

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar
              Row(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today\'s Plan',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.primaryText,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: theme.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Phase Cards ──
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sabaq
                      _phaseCard(
                        theme,
                        emoji: '📖',
                        title: 'Sabaq · New Memorization',
                        detail: 'Page ${plan.sabaqPage}',
                        timeDetail: '~${plan.sabaqTargetMinutes} min · ${plan.sabaqRepetitionTarget} reps target',
                        isDone: _sabaqOffline,
                        isEmpty: false,
                        onToggle: (val) =>
                            setState(() => _sabaqOffline = val),
                      ),
                      const SizedBox(height: 12),

                      // Sabqi
                      if (plan.sabqiPages.isNotEmpty)
                        _phaseCard(
                          theme,
                          emoji: '🔁',
                          title: 'Sabqi · Recent Review',
                          detail: '${plan.sabqiPages.length} pages (${plan.sabqiPages.join(", ")})',
                          timeDetail: '~${plan.sabqiTargetMinutes} min',
                          isDone: _sabqiOffline,
                          isEmpty: false,
                          onToggle: (val) =>
                              setState(() => _sabqiOffline = val),
                        )
                      else
                        _emptyPhaseCard(theme, '🔁', 'Sabqi · Recent Review',
                            'No pages to review yet'),
                      const SizedBox(height: 12),

                      // Manzil
                      if (plan.manzilPages.isNotEmpty)
                        _phaseCard(
                          theme,
                          emoji: '📚',
                          title: 'Manzil · Long-term Review',
                          detail: 'Juz ${plan.manzilJuz} · ${plan.manzilPages.length} pages',
                          timeDetail: '~${plan.manzilTargetMinutes} min',
                          isDone: _manzilOffline,
                          isEmpty: false,
                          onToggle: (val) =>
                              setState(() => _manzilOffline = val),
                        )
                      else
                        _emptyPhaseCard(theme, '📚', 'Manzil · Long-term Review',
                            'Not yet started'),
                      const SizedBox(height: 20),

                      // ── Offline Section ──
                      Container(
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
                              'Already done offline?',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Mark any phases you\'ve already completed with your physical Quran today.',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: theme.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom ──
              const SizedBox(height: 12),

              // Estimated time
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text(
                    _allDone
                        ? '✨ All phases done for today!'
                        : '⏱ Estimated: ~$estMinutes min · $_activePhasesCount phase${_activePhasesCount == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.secondaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Start Session
              GestureDetector(
                onTap: _allDone
                    ? null
                    : () async {
                        // Apply offline markings to the plan
                        final pp = context.read<PlanProvider>();
                        final nav = Navigator.of(context);
                        if (_sabaqOffline) {
                          await pp.markPhaseOffline(SessionPhase.sabaq);
                        }
                        if (_sabqiOffline) {
                          await pp.markPhaseOffline(SessionPhase.sabqi);
                        }
                        if (_manzilOffline) {
                          await pp.markPhaseOffline(SessionPhase.manzil);
                        }

                        if (mounted) {
                          final updatedPlan = pp.todayPlan;
                          if (updatedPlan != null) {
                            nav.pushReplacement(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SessionScreen(plan: updatedPlan),
                              ),
                            );
                          }
                        }
                      },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _allDone
                        ? theme.mutedText.withValues(alpha: 0.3)
                        : theme.accentColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _allDone
                        ? null
                        : [
                            BoxShadow(
                              color: theme.accentColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _allDone ? LucideIcons.check : LucideIcons.play,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _allDone
                            ? 'All Done for Today'
                            : 'Start Session',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phaseCard(
    ThemeProvider theme, {
    required String emoji,
    required String title,
    required String detail,
    required String timeDetail,
    required bool isDone,
    required bool isEmpty,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone
            ? theme.cardColor.withValues(alpha: 0.5)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? theme.dividerColor.withValues(alpha: 0.5)
              : theme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          Text(emoji,
              style: TextStyle(
                  fontSize: 24,
                  color: isDone ? Colors.grey : null)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDone
                        ? theme.mutedText
                        : theme.primaryText,
                    decoration:
                        isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: isDone
                        ? theme.mutedText.withValues(alpha: 0.6)
                        : theme.secondaryText,
                  ),
                ),
                Text(
                  timeDetail,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: theme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          // Offline toggle
          GestureDetector(
            onTap: () => onToggle(!isDone),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isDone
                    ? theme.accentColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: isDone
                      ? theme.accentColor
                      : theme.dividerColor,
                  width: isDone ? 2 : 1.5,
                ),
              ),
              child: isDone
                  ? Icon(LucideIcons.check,
                      size: 16, color: theme.accentColor)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPhaseCard(
      ThemeProvider theme, String emoji, String title, String detail) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.mutedText,
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: theme.mutedText.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.minus, size: 16, color: theme.mutedText),
        ],
      ),
    );
  }
}
