import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class ProgressStrip extends StatelessWidget {
  final int memorizedPages;
  final int currentJuz;
  final VoidCallback onTap;

  const ProgressStrip({
    super.key,
    required this.memorizedPages,
    required this.currentJuz,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final double pct = (memorizedPages / 604) * 100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent, // Ensure it's tappable
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Thin progress bar
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: memorizedPages / 604,
                  minHeight: 4,
                  backgroundColor: theme.dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.accentColor),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Text(
              '${pct.toStringAsFixed(1)}% · $memorizedPages pages · Juz $currentJuz',
              style: theme.textCaption.copyWith(
                color: theme.mutedText,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 14,
              color: theme.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}
