import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/theme_provider.dart';

/// Adaptive suggestion card for the dashboard.
/// Displays a non-intrusive suggestion with Accept/Dismiss/Remind Later actions.
/// Designed to be placed independently on the dashboard by the Core Engine agent.
class SuggestionCard extends StatelessWidget {
  final Suggestion suggestion;
  final ThemeProvider theme;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;
  final VoidCallback? onRemindLater;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.theme,
    required this.onAccept,
    required this.onDismiss,
    this.onRemindLater,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _accentForType.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Text(
                suggestion.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  suggestion.title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryText,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    LucideIcons.x,
                    size: 16,
                    color: theme.mutedText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Message ──
          Text(
            suggestion.message,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: theme.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),

          // ── Actions ──
          Row(
            children: [
              // Accept button
              Expanded(
                child: GestureDetector(
                  onTap: onAccept,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _accentForType,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _acceptLabel,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (onRemindLater != null) ...[
                const SizedBox(width: 8),
                // Remind later button
                GestureDetector(
                  onTap: onRemindLater,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Later',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.secondaryText,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Accent color based on suggestion type.
  Color get _accentForType {
    switch (suggestion.type) {
      case SuggestionType.increaseLoad:
      case SuggestionType.aheadOfSchedule:
        return const Color(0xFF4DB6AC); // Teal — positive
      case SuggestionType.decreaseLoad:
      case SuggestionType.takeBreak:
        return const Color(0xFF7986CB); // Indigo — gentle
      case SuggestionType.moreReview:
      case SuggestionType.strugglePage:
        return const Color(0xFFFFB74D); // Amber — attention
      case SuggestionType.neglectedJuz:
        return const Color(0xFF90CAF9); // Blue — informational
    }
  }

  /// Context-appropriate accept button label.
  String get _acceptLabel {
    switch (suggestion.type) {
      case SuggestionType.increaseLoad:
        return 'Increase Load';
      case SuggestionType.decreaseLoad:
      case SuggestionType.takeBreak:
        return 'Lighten Plan';
      case SuggestionType.moreReview:
        return 'Add Review';
      case SuggestionType.aheadOfSchedule:
        return 'Keep Going!';
      case SuggestionType.neglectedJuz:
        return 'Review Now';
      case SuggestionType.strugglePage:
        return 'Practice Cards';
    }
  }
}
