import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/providers/theme_provider.dart';

/// Bottom sheet dialog shown when the user returns after missed days.
class MissedDayDialog extends StatelessWidget {
  final int missedDays;
  final ThemeProvider theme;
  final VoidCallback onAcceptReview;
  final VoidCallback onStartNormal;
  final VoidCallback onDismiss;

  const MissedDayDialog({
    super.key,
    required this.missedDays,
    required this.theme,
    required this.onAcceptReview,
    required this.onStartNormal,
    required this.onDismiss,
  });

  /// Show the missed day dialog as a bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required int missedDays,
    required ThemeProvider theme,
    required VoidCallback onAcceptReview,
    required VoidCallback onStartNormal,
    required VoidCallback onDismiss,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MissedDayDialog(
        missedDays: missedDays,
        theme: theme,
        onAcceptReview: onAcceptReview,
        onStartNormal: onStartNormal,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Welcome back
          const Text('🌅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Welcome back!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _getMessage(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: theme.secondaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Suggestion card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.accentColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.lightbulb, size: 18, color: theme.accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We suggest starting with a review-only session to warm up.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: theme.accentColor,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Accept review
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              onAcceptReview();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: theme.accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Start Review Session',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Start normal
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              onStartNormal();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                'Start Normal Plan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Dismiss
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              onDismiss();
            },
            child: Text(
              'Maybe later',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: theme.mutedText,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getMessage() {
    if (missedDays == 1) {
      return 'You missed yesterday. No worries—\nlet\'s get back on track!';
    } else if (missedDays <= 3) {
      return 'It\'s been $missedDays days since your last session.\nLet\'s ease back in with a review.';
    } else {
      return 'It\'s been $missedDays days.\nBut don\'t worry—every return is a fresh start! 🌱';
    }
  }
}
