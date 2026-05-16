import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final localStorage = context.read<LocalStorageService>();
    
    final lastReadPage = localStorage.getLastReadPage();
    final lastReadSurah = localStorage.getLastReadSurahName() ?? 'Al-Fatihah';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTINUE READING',
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: theme.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastReadSurah,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Page $lastReadPage',
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 14,
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  final nav = context.read<NavigationProvider>();
                  nav.enterReadingView();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReadingScreen(initialPage: lastReadPage),
                    ),
                  ).then((_) => nav.exitReadingView());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.foregroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.bookOpen, size: 16, color: theme.scaffoldBackground),
                      const SizedBox(width: 8),
                      Text(
                        'Resume',
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.scaffoldBackground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
