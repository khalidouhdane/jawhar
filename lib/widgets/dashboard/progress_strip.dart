import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/theme/geist_typography.dart';

class ProgressStrip extends StatelessWidget {
  final int memorizedPages;
  final int streakDays;
  final int sessionCount;
  final VoidCallback onTap;

  const ProgressStrip({
    super.key,
    required this.memorizedPages,
    required this.streakDays,
    required this.sessionCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final double percentageVal = (memorizedPages / 604) * 100;
    final String percentage = percentageVal.toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusXl),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.radiusXl),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatColumn(
                          context,
                          theme: theme,
                          icon: LucideIcons.flame,
                          count: '$streakDays',
                          label: AppLocalizations.of(context)!.progressActiveDays(streakDays),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: theme.dividerColor,
                      ),
                      Expanded(
                        child: _buildStatColumn(
                          context,
                          theme: theme,
                          icon: LucideIcons.bookOpen,
                          count: '$memorizedPages',
                          label: AppLocalizations.of(context)!.progressLegendMemorized,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: theme.dividerColor,
                      ),
                      Expanded(
                        child: _buildStatColumn(
                          context,
                          theme: theme,
                          icon: LucideIcons.history,
                          count: '$sessionCount',
                          label: AppLocalizations.of(context)!.progressSessionsCount(sessionCount),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                    border: Border(
                      top: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "$percentage% - ${AppLocalizations.of(context)!.progressViewHistory}",
                          style: theme.textCaption.copyWith(
                            color: theme.mutedText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 14,
                        color: theme.mutedText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required ThemeProvider theme,
    required IconData icon,
    required String count,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.accentColor,
        ),
        const SizedBox(height: 6),
        Text(
          count,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textCaption.copyWith(
            color: theme.mutedText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
