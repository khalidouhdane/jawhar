import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/hifz_provider.dart';
import 'package:quran_app/providers/locale_provider.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/screens/onboarding_screen.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/widgets/sheets/nav_menu_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final hifz = context.watch<HifzProvider>();
    final locale = context.watch<LocaleProvider>();
    final reading = context.watch<QuranReadingProvider>();
    final l = AppLocalizations.of(context);
    final storage = context.read<LocalStorageService>();
    final lastRead = storage.getLastRead();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Header ──
              Text(
                l.t('profile_title'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.t('profile_subtitle'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.secondaryText,
                ),
              ),
              const SizedBox(height: 24),

              // ── Reading Stats ──
              _buildStatsCard(context, theme, hifz, lastRead, l),
              const SizedBox(height: 20),

              // ── Language Selector ──
              _buildSectionLabel(theme, l.t('profile_language')),
              const SizedBox(height: 10),
              _buildLanguageSelector(context, theme, locale),
              const SizedBox(height: 24),

              // ── Rewaya (Reading) Selector ──
              _buildSectionLabel(theme, l.t('profile_reading')),
              const SizedBox(height: 10),
              _buildRewayaSelector(context, theme, reading),
              const SizedBox(height: 24),

              // ── Theme Selector ──
              _buildSectionLabel(theme, l.t('profile_appearance')),
              const SizedBox(height: 10),
              _buildThemeSelector(context, theme, l),
              const SizedBox(height: 24),

              // ── Bookmarks ──
              _buildSectionLabel(theme, l.t('profile_bookmarks_title')),
              const SizedBox(height: 10),
              _buildBookmarksCard(context, theme, l),
              const SizedBox(height: 24),

              // ── About ──
              _buildSectionLabel(theme, l.t('profile_about')),
              const SizedBox(height: 10),
              _buildSettingsTile(
                theme,
                icon: LucideIcons.info,
                title: 'Le Quran',
                subtitle: l.t('profile_version'),
              ),
              const SizedBox(height: 6),
              _buildSettingsTile(
                theme,
                icon: LucideIcons.heart,
                title: l.t('profile_made_with'),
                subtitle: l.t('profile_companion'),
              ),
              const SizedBox(height: 6),
              _buildSettingsTile(
                theme,
                icon: LucideIcons.globe,
                title: l.t('profile_data'),
                subtitle: 'Quran.com API',
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboarding_complete', false);
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                child: _buildSettingsTile(
                  theme,
                  icon: LucideIcons.refreshCw,
                  title: l.t('profile_replay_onboarding'),
                  subtitle: l.t('profile_replay_onboarding_desc'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Language Selector ──
  Widget _buildLanguageSelector(
    BuildContext context,
    ThemeProvider theme,
    LocaleProvider locale,
  ) {
    return Row(
      children: [
        _langOption(
          context,
          theme,
          locale,
          const Locale('en'),
          'English',
          '🇬🇧',
        ),
        const SizedBox(width: 10),
        _langOption(
          context,
          theme,
          locale,
          const Locale('ar'),
          'العربية',
          '🇸🇦',
        ),
      ],
    );
  }

  Widget _langOption(
    BuildContext context,
    ThemeProvider theme,
    LocaleProvider locale,
    Locale target,
    String label,
    String flag,
  ) {
    final isActive = locale.locale == target;
    return Expanded(
      child: GestureDetector(
        onTap: () => locale.setLocale(target),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? theme.accentColor : theme.dividerColor,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? theme.accentColor : theme.secondaryText,
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 4),
                Icon(LucideIcons.check, size: 14, color: theme.accentColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Rewaya (Reading) Selector ──
  Widget _buildRewayaSelector(
    BuildContext context,
    ThemeProvider theme,
    QuranReadingProvider reading,
  ) {
    return Row(
      children: [
        _rewayaOption(context, theme, reading, 1, 'حفص', 'Hafs'),
        const SizedBox(width: 10),
        _rewayaOption(context, theme, reading, 2, 'ورش', 'Warsh'),
      ],
    );
  }

  Widget _rewayaOption(
    BuildContext context,
    ThemeProvider theme,
    QuranReadingProvider reading,
    int rewaya,
    String arabicLabel,
    String englishLabel,
  ) {
    final isActive = reading.selectedRewaya == rewaya;
    return Expanded(
      child: GestureDetector(
        onTap: () => reading.setRewaya(rewaya),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? theme.accentColor : theme.dividerColor,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                arabicLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isActive ? theme.accentColor : theme.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                englishLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? theme.accentColor : theme.secondaryText,
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 4),
                Icon(LucideIcons.check, size: 14, color: theme.accentColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats Card ──
  Widget _buildStatsCard(
    BuildContext context,
    ThemeProvider theme,
    HifzProvider hifz,
    LastReadPosition? lastRead,
    AppLocalizations l,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.t('profile_journey'),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statItem(
                theme,
                value: '${hifz.totalMemorized}',
                label: l.t('profile_memorized'),
                icon: LucideIcons.brain,
              ),
              _statDivider(theme),
              _statItem(
                theme,
                value: '${hifz.streak.currentStreak}',
                label: l.t('hifz_day_streak'),
                icon: LucideIcons.flame,
              ),
              _statDivider(theme),
              _statItem(
                theme,
                value: lastRead != null ? '${lastRead.page}' : '-',
                label: l.t('profile_last_page'),
                icon: LucideIcons.bookOpen,
              ),
              _statDivider(theme),
              _statItem(
                theme,
                value: '${context.watch<BookmarkProvider>().count}',
                label: l.t('profile_bookmarks_title'),
                icon: LucideIcons.bookmark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    ThemeProvider theme, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: theme.accentColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: theme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider(ThemeProvider theme) {
    return Container(width: 1, height: 36, color: theme.dividerColor);
  }

  // ── Bookmarks Card ──
  Widget _buildBookmarksCard(
    BuildContext context,
    ThemeProvider theme,
    AppLocalizations l,
  ) {
    final bp = context.watch<BookmarkProvider>();
    final count = bp.count;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => FractionallySizedBox(
            heightFactor: 0.75,
            child: NavMenuSheet(
              initialTab: 'bookmarks',
              onClose: () => Navigator.pop(ctx),
              onPageSelected: (page) {
                Navigator.pop(ctx);
                final nav = context.read<NavigationProvider>();
                nav.enterReadingView();
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => ReadingScreen(initialPage: page),
                      ),
                    )
                    .then((_) => nav.exitReadingView());
              },
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(LucideIcons.bookmark, size: 20, color: theme.accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.t('profile_bookmarks_title'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                  Text(
                    count > 0
                        ? '$count ${count == 1 ? 'bookmark' : 'bookmarks'}'
                        : l.t('profile_bookmarks_desc'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (count > 0)
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: theme.mutedText,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.pillBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '0',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.mutedText,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Theme Selector ──
  Widget _buildThemeSelector(
    BuildContext context,
    ThemeProvider theme,
    AppLocalizations l,
  ) {
    return Row(
      children: [
        _themeOption(
          context,
          theme,
          AppTheme.classic,
          l.t('profile_theme_classic'),
          Colors.white,
          const Color(0xFF1A454E),
        ),
        const SizedBox(width: 10),
        _themeOption(
          context,
          theme,
          AppTheme.warm,
          l.t('profile_theme_warm'),
          const Color(0xFFF5F0E8),
          const Color(0xFF1A454E),
        ),
        const SizedBox(width: 10),
        _themeOption(
          context,
          theme,
          AppTheme.dark,
          l.t('profile_theme_dark'),
          const Color(0xFF0A1E24),
          const Color(0xFF4DB6AC),
        ),
      ],
    );
  }

  Widget _themeOption(
    BuildContext context,
    ThemeProvider theme,
    AppTheme appTheme,
    String label,
    Color previewBg,
    Color previewAccent,
  ) {
    final isActive = theme.theme == appTheme;
    return Expanded(
      child: GestureDetector(
        onTap: () => theme.setTheme(appTheme),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? theme.accentColor : theme.dividerColor,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: previewBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: previewAccent.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: previewAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? theme.accentColor : theme.secondaryText,
                ),
              ),
              if (isActive) ...[
                const SizedBox(height: 4),
                Icon(LucideIcons.check, size: 14, color: theme.accentColor),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Label ──
  Widget _buildSectionLabel(ThemeProvider theme, String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: theme.primaryText,
      ),
    );
  }


  // ── Settings Tile ──
  Widget _buildSettingsTile(
    ThemeProvider theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.accentColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: theme.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
