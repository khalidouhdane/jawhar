import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/flashcard_provider.dart';

class QuickActionsRow extends StatelessWidget {
  final VoidCallback onContinueReading;
  final VoidCallback onOpenReport;
  final VoidCallback onOpenPractice;

  const QuickActionsRow({
    super.key,
    required this.onContinueReading,
    required this.onOpenReport,
    required this.onOpenPractice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final flashcardProvider = context.watch<FlashcardProvider>();
    final dueCards = flashcardProvider.dueCardCount;

    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            theme: theme,
            icon: LucideIcons.bookOpen,
            label1: 'Continue',
            label2: 'Reading',
            onTap: onContinueReading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            theme: theme,
            icon: LucideIcons.layers,
            label1: dueCards > 0 ? '$dueCards due' : 'Cards',
            label2: dueCards > 0 ? 'Cards' : 'All clear',
            onTap: onOpenPractice,
            isAccent: dueCards > 0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            theme: theme,
            icon: LucideIcons.barChart2,
            label1: 'Weekly',
            label2: 'Report',
            onTap: onOpenReport,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final ThemeProvider theme;
  final IconData icon;
  final String label1;
  final String label2;
  final VoidCallback onTap;
  final bool isAccent;

  const _ActionTile({
    required this.theme,
    required this.icon,
    required this.label1,
    required this.label2,
    required this.onTap,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isAccent
              ? theme.accentColor.withValues(alpha: 0.1)
              : theme.pillBackground,
          borderRadius: BorderRadius.circular(theme.radiusMd),
          border: Border.all(
            color: isAccent
                ? theme.accentColor.withValues(alpha: 0.2)
                : theme.dividerColor,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isAccent ? theme.accentColor : theme.secondaryText,
            ),
            const SizedBox(height: 8),
            Text(
              label1,
              style: theme.textMicroBadge.copyWith(
                color: isAccent ? theme.accentColor : theme.primaryText,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              label2,
              style: theme.textMicroBadge.copyWith(
                color: theme.secondaryText,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
