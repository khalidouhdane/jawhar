import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/plan_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/hifz/session_screen.dart';

/// Lightweight bottom sheet that replaces the old full-page pre-session screen.
/// Shows active phases with offline-skip toggles and a prominent Start button.
class PreSessionSheet extends StatefulWidget {
  const PreSessionSheet({super.key});

  /// Show as a modal bottom sheet and return true if session was started.
  static Future<bool?> show(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PreSessionSheet(),
    );
  }

  @override
  State<PreSessionSheet> createState() => _PreSessionSheetState();
}

class _PreSessionSheetState extends State<PreSessionSheet> {
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

  bool get _allDone => _sabaqOffline && _sabqiOffline && _manzilOffline;

  int _activeMinutes(DailyPlan plan) {
    int total = 0;
    if (!_sabaqOffline) total += plan.sabaqTargetMinutes;
    if (!_sabqiOffline) total += plan.sabqiTargetMinutes;
    if (!_manzilOffline) total += plan.manzilTargetMinutes;
    return total;
  }

  Future<void> _startSession() async {
    final pp = context.read<PlanProvider>();
    final nav = Navigator.of(context);

    // Apply offline markings
    if (_sabaqOffline) await pp.markPhaseOffline(SessionPhase.sabaq);
    if (_sabqiOffline) await pp.markPhaseOffline(SessionPhase.sabqi);
    if (_manzilOffline) await pp.markPhaseOffline(SessionPhase.manzil);

    if (!mounted) return;

    final updatedPlan = pp.todayPlan;
    if (updatedPlan != null) {
      // Close the sheet first, then navigate
      nav.pop(true);
      nav.push(
        MaterialPageRoute(
          builder: (_) => SessionScreen(plan: updatedPlan),
        ),
      );
    }
  }

  /// Mark all phases as done offline and complete the session.
  Future<void> _markAllDone() async {
    final pp = context.read<PlanProvider>();
    final nav = Navigator.of(context);

    // Mark every phase as offline-completed
    await pp.markPhaseOffline(SessionPhase.sabaq);
    await pp.markPhaseOffline(SessionPhase.sabqi);
    await pp.markPhaseOffline(SessionPhase.manzil);

    // Complete the plan
    await pp.completePlan();

    if (!mounted) return;
    nav.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final planProvider = context.watch<PlanProvider>();
    final plan = planProvider.todayPlan;

    if (plan == null) {
      return const SizedBox.shrink();
    }

    final hasSabqi = plan.sabqiPages.isNotEmpty;
    final hasManzil = plan.manzilPages.isNotEmpty;
    final estMinutes = _activeMinutes(plan);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag Handle ──
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Done any offline?',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Check phases you\'ve already completed to skip them',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: theme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                // Estimated time badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '~${estMinutes}m',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Phase Rows ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Sabaq (always present)
                _phaseRow(
                  theme,
                  icon: LucideIcons.bookOpen,
                  iconColor: const Color(0xFF4ECDC4),
                  title: 'Sabaq · New',
                  detail: 'Page ${plan.sabaqPage} · Lines ${plan.sabaqLineStart}–${plan.sabaqLineEnd}',
                  minutes: plan.sabaqTargetMinutes,
                  isDone: _sabaqOffline,
                  onToggle: (val) => setState(() => _sabaqOffline = val),
                ),

                // Sabqi
                if (hasSabqi) ...[
                  const SizedBox(height: 8),
                  _phaseRow(
                    theme,
                    icon: LucideIcons.repeat,
                    iconColor: const Color(0xFF6C63FF),
                    title: 'Sabqi · Review',
                    detail: '${plan.sabqiPages.length} page${plan.sabqiPages.length > 1 ? 's' : ''}',
                    minutes: plan.sabqiTargetMinutes,
                    isDone: _sabqiOffline,
                    onToggle: (val) => setState(() => _sabqiOffline = val),
                  ),
                ],

                // Manzil
                if (hasManzil) ...[
                  const SizedBox(height: 8),
                  _phaseRow(
                    theme,
                    icon: LucideIcons.library,
                    iconColor: const Color(0xFFF5A623),
                    title: 'Manzil · Revision',
                    detail: 'Juz ${plan.manzilJuz} · ${plan.manzilPages.length} pages',
                    minutes: plan.manzilTargetMinutes,
                    isDone: _manzilOffline,
                    onToggle: (val) => setState(() => _manzilOffline = val),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Start Button ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: _allDone ? _markAllDone : _startSession,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _allDone
                      ? theme.accentColor.withValues(alpha: 0.7)
                      : theme.accentColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
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
                      _allDone ? LucideIcons.checkCircle : LucideIcons.play,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _allDone ? 'Mark Session as Done' : 'Start Session',
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
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _phaseRow(
    ThemeProvider theme, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String detail,
    required int minutes,
    required bool isDone,
    required ValueChanged<bool> onToggle,
  }) {
    return GestureDetector(
      onTap: () => onToggle(!isDone),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDone
              ? theme.scaffoldBackground.withValues(alpha: 0.5)
              : theme.scaffoldBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDone
                ? theme.dividerColor.withValues(alpha: 0.4)
                : theme.dividerColor,
          ),
        ),
        child: Row(
          children: [
            // Phase icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (isDone ? Colors.grey : iconColor)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: isDone ? Colors.grey : iconColor,
              ),
            ),
            const SizedBox(width: 12),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDone ? theme.mutedText : theme.primaryText,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    '$detail · ~${minutes}m',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: isDone
                          ? theme.mutedText.withValues(alpha: 0.6)
                          : theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            // Checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone
                    ? theme.accentColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDone ? theme.accentColor : theme.dividerColor,
                  width: isDone ? 2 : 1.5,
                ),
              ),
              child: isDone
                  ? Icon(LucideIcons.check,
                      size: 14, color: theme.accentColor)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
