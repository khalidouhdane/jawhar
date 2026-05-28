import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/werd_models.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/semantic_colors.dart';
import 'package:quran_app/providers/werd_provider.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/widgets/sheets/werd_setup_sheet.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/theme/geist_typography.dart';

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
    final l = AppLocalizations.of(context)!;

    if (!werd.hasWerd) {
      return _buildEmptyState(context, theme, l);
    }
    return _buildActiveState(context, theme, werd, l);
  }

  // ── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(
    BuildContext context,
    ThemeProvider theme,
    AppLocalizations l,
  ) {
    final accentColor = SemanticColors.pillarRead.fg(theme.isDark);

    return GestureDetector(
      onTap: () => _openSetupSheet(context),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(theme.radiusLg),
          border: Border.all(color: theme.dividerColor, width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Start-edge accent spine
            PositionedDirectional(
              start: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: Container(color: accentColor),
            ),
            // Main Content
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 24,
                end: 20,
                top: 20,
                bottom: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.calendarCheck,
                      size: 18,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(l.werdSetTitle, style: theme.textBodyStrong),
                  const SizedBox(height: 6),
                  Text(
                    l.werdSetDesc,
                    textAlign: TextAlign.start,
                    style: theme.textBodySmall,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: theme.buttonDefaultBg,
                      borderRadius: BorderRadius.circular(theme.radiusMd),
                    ),
                    child: Text(
                      l.werdGetStarted,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: theme.buttonDefaultText,
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
  }

  // ── Active State ─────────────────────────────────────────────────────────

  Widget _buildActiveState(
    BuildContext context,
    ThemeProvider theme,
    WerdProvider werd,
    AppLocalizations l,
  ) {
    final config = werd.config!;
    final isComplete = config.isComplete;
    final accentColor = isComplete
        ? SemanticColors.progressMemorized
        : SemanticColors.pillarRead.fg(theme.isDark);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: Border.all(color: theme.dividerColor, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Start-edge accent spine
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(color: accentColor),
          ),
          // Main Content
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
                      color: accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.werdDaily,
                      style: theme.textCaption.copyWith(color: accentColor),
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
                      accentColor: accentColor,
                      trackColor: theme.dividerColor,
                      textColor: theme.primaryText,
                      completeColor: SemanticColors.progressMemorized,
                    ),

                    const SizedBox(width: 20),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.isComplete
                                ? l.werdComplete
                                : '${config.pagesReadToday} ${l.werdPagesOf} ${config.todayTarget} ${l.werdPagesLabel}',
                            style: theme.textBodyStrong,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            config.isComplete
                                ? l.werdCompleteDesc
                                : _subtitle(config, l),
                            style: theme.textBodySmall,
                          ),
                          const SizedBox(height: 14),
                          if (!config.isComplete)
                            GestureDetector(
                              onTap: () =>
                                  _startReading(context, config.startPage),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.buttonDefaultBg,
                                  borderRadius: BorderRadius.circular(
                                    theme.radiusMd,
                                  ),
                                ),
                                child: Text(
                                  l.werdStartReading,
                                  style: TextStyle(
                                    fontFamily:
                                        GeistTypography.primaryFontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.buttonDefaultText,
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

  String _subtitle(WerdConfig config, AppLocalizations l) {
    if (config.mode == WerdMode.fixedRange) {
      return '${l.werdPagesRange} ${config.startPage}–${config.endPage}';
    }
    final remaining = config.todayTarget - config.pagesReadToday;
    return '$remaining ${l.werdPagesRemaining}';
  }

  void _openSetupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WerdSetupSheet(),
    );
  }

  void _startReading(BuildContext context, int page) {
    if (onStartReading != null) {
      onStartReading!(page);
      return;
    }

    final nav = context.read<NavigationProvider>();
    nav.enterReadingView();
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => ReadingScreen(initialPage: page)),
        )
        .then((_) => nav.exitReadingView());
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
      builder: (_, _) {
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
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
