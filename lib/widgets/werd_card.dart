import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/werd_models.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/werd_provider.dart';
import 'package:quran_app/widgets/sheets/werd_setup_sheet.dart';

/// Home-screen card for the daily recitation (werd) feature.
///
/// Shows an empty prompt when no werd is configured, and an active
/// progress card with a circular ring once the user sets one up.
class WerdCard extends StatelessWidget {
  /// Called when the user taps "Start Reading" on an active werd.
  final void Function(int page)? onStartReading;

  const WerdCard({super.key, this.onStartReading});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final werd = context.watch<WerdProvider>();

    if (!werd.hasWerd) {
      return _buildEmptyState(context, theme);
    }
    return _buildActiveState(context, theme, werd);
  }

  // ── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, ThemeProvider theme) {
    return GestureDetector(
      onTap: () => _openSetupSheet(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.accentColor.withValues(alpha: 0.25),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.calendarCheck,
                size: 24,
                color: theme.accentColor,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Set Your Daily Werd',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create a daily recitation goal to\nstay consistent with your reading',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: theme.secondaryText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: theme.accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active State ─────────────────────────────────────────────────────────

  Widget _buildActiveState(
    BuildContext context,
    ThemeProvider theme,
    WerdProvider werd,
  ) {
    final config = werd.config!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          // ── Top accent bar ──
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.accentColor.withValues(alpha: 0.7),
                  theme.accentColor,
                  theme.accentColor.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                // ── Header Row ──
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendarCheck,
                      size: 16,
                      color: theme.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daily Werd',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.accentColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _openSetupSheet(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.pillBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          LucideIcons.settings2,
                          size: 14,
                          color: theme.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Progress Ring + Info ──
                Row(
                  children: [
                    // Circular progress
                    _ProgressRing(
                      progress: config.progress,
                      isComplete: config.isComplete,
                      accentColor: theme.accentColor,
                      trackColor: theme.dividerColor,
                      textColor: theme.primaryText,
                      completeColor: const Color(0xFF4CAF50),
                    ),

                    const SizedBox(width: 20),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.isComplete
                                ? 'Masha\'Allah! 🎉'
                                : '${config.pagesReadToday} of ${config.todayTarget} pages',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.primaryText,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            config.isComplete
                                ? 'You completed your daily werd'
                                : _subtitle(config),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: theme.secondaryText,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (!config.isComplete)
                            GestureDetector(
                              onTap: () =>
                                  onStartReading?.call(config.startPage),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.accentColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'Start Reading',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(WerdConfig config) {
    if (config.mode == WerdMode.fixedRange) {
      return 'Pages ${config.startPage}–${config.endPage}';
    }
    final remaining = config.todayTarget - config.pagesReadToday;
    return '$remaining pages remaining today';
  }

  void _openSetupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WerdSetupSheet(),
    );
  }
}

// ── Animated Progress Ring ─────────────────────────────────────────────────

class _ProgressRing extends StatefulWidget {
  final double progress;
  final bool isComplete;
  final Color accentColor;
  final Color trackColor;
  final Color textColor;
  final Color completeColor;

  const _ProgressRing({
    required this.progress,
    required this.isComplete,
    required this.accentColor,
    required this.trackColor,
    required this.textColor,
    required this.completeColor,
  });

  @override
  State<_ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<_ProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prev = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _prev = widget.progress;
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _prev = oldWidget.progress;
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isComplete ? widget.completeColor : widget.accentColor;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final value = _prev + (_anim.value * (widget.progress - _prev));
        return SizedBox(
          width: 68,
          height: 68,
          child: CustomPaint(
            painter: _RingPainter(
              progress: value,
              trackColor: widget.trackColor,
              progressColor: color,
              strokeWidth: 5,
            ),
            child: Center(
              child: widget.isComplete
                  ? Icon(LucideIcons.check, size: 24, color: color)
                  : Text(
                      '${(value * 100).round()}%',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.textColor,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}
