import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/semantic_colors.dart';
import 'package:quran_app/widgets/geist_button.dart';

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
        borderRadius: BorderRadius.circular(theme.radiusLg),
        boxShadow: theme.shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _colorForType.bg(theme.isDark),
                  borderRadius: BorderRadius.circular(theme.radiusMd),
                ),
                child: Icon(
                  _iconForType,
                  size: 20,
                  color: _colorForType.fg(theme.isDark),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(suggestion.title, style: theme.textBodyStrong),
              ),
              GestureDetector(
                onTap: onDismiss,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(LucideIcons.x, size: 16, color: theme.mutedText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Message ──
          Text(
            suggestion.message,
            style: theme.textBodySmall.copyWith(color: theme.secondaryText),
          ),
          const SizedBox(height: 14),

          // ── Actions ──
          Row(
            children: [
              // Accept button
              Expanded(
                child: GeistButton(
                  onPressed: onAccept,
                  label: _acceptLabel,
                  type: GeistButtonType.primary,
                  size: GeistButtonSize.small,
                ),
              ),
              if (onRemindLater != null) ...[
                const SizedBox(width: 8),
                // Remind later button
                GeistButton(
                  onPressed: onRemindLater,
                  label: 'Later',
                  type: GeistButtonType.secondary,
                  size: GeistButtonSize.small,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Semantic color pair based on suggestion type.
  SemanticPair get _colorForType {
    switch (suggestion.type) {
      case SuggestionType.increaseLoad:
      case SuggestionType.aheadOfSchedule:
        return SemanticColors.suggPositive;
      case SuggestionType.decreaseLoad:
      case SuggestionType.takeBreak:
        return SemanticColors.suggGentle;
      case SuggestionType.moreReview:
      case SuggestionType.strugglePage:
        return SemanticColors.suggAttention;
      case SuggestionType.neglectedJuz:
        return SemanticColors.suggInfo;
    }
  }

  /// Icon based on suggestion type.
  IconData get _iconForType {
    switch (suggestion.type) {
      case SuggestionType.increaseLoad:
        return LucideIcons.trendingUp;
      case SuggestionType.aheadOfSchedule:
        return LucideIcons.award;
      case SuggestionType.decreaseLoad:
      case SuggestionType.takeBreak:
        return LucideIcons.coffee;
      case SuggestionType.moreReview:
        return LucideIcons.rotateCcw;
      case SuggestionType.strugglePage:
        return LucideIcons.alertCircle;
      case SuggestionType.neglectedJuz:
        return LucideIcons.info;
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
