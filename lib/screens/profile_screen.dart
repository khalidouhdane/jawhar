import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/hifz_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/services/local_storage_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final hifz = context.watch<HifzProvider>();
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
                'Settings',
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
                'Customize your experience',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.secondaryText,
                ),
              ),
              const SizedBox(height: 24),

              // ── Reading Stats ──
              _buildStatsCard(theme, hifz, lastRead),
              const SizedBox(height: 20),

              // ── Theme Selector ──
              _buildSectionLabel(theme, 'Appearance'),
              const SizedBox(height: 10),
              _buildThemeSelector(context, theme),
              const SizedBox(height: 24),

              // ── Bookmarks ──
              _buildSectionLabel(theme, 'Bookmarks'),
              const SizedBox(height: 10),
              _buildPlaceholderCard(
                theme,
                icon: LucideIcons.bookmark,
                title: 'Your Bookmarks',
                subtitle: 'Save and organize your favorite verses',
              ),
              const SizedBox(height: 24),

              // ── About ──
              _buildSectionLabel(theme, 'About'),
              const SizedBox(height: 10),
              _buildSettingsTile(
                theme,
                icon: LucideIcons.info,
                title: 'Le Quran',
                subtitle: 'Version 1.0.0',
              ),
              const SizedBox(height: 6),
              _buildSettingsTile(
                theme,
                icon: LucideIcons.heart,
                title: 'Made with love',
                subtitle: 'A modern Quran companion',
              ),
              const SizedBox(height: 6),
              _buildSettingsTile(
                theme,
                icon: LucideIcons.globe,
                title: 'Data Source',
                subtitle: 'Quran.com API',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats Card ──
  Widget _buildStatsCard(
    ThemeProvider theme,
    HifzProvider hifz,
    LastReadPosition? lastRead,
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
            'Your Journey',
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
                label: 'Memorized',
                icon: LucideIcons.brain,
              ),
              _statDivider(theme),
              _statItem(
                theme,
                value: '${hifz.streak.currentStreak}',
                label: 'Day streak',
                icon: LucideIcons.flame,
              ),
              _statDivider(theme),
              _statItem(
                theme,
                value: lastRead != null ? '${lastRead.page}' : '-',
                label: 'Last page',
                icon: LucideIcons.bookOpen,
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

  // ── Theme Selector ──
  Widget _buildThemeSelector(BuildContext context, ThemeProvider theme) {
    return Row(
      children: [
        _themeOption(
          context,
          theme,
          AppTheme.classic,
          'Classic',
          Colors.white,
          const Color(0xFF1A454E),
        ),
        const SizedBox(width: 10),
        _themeOption(
          context,
          theme,
          AppTheme.warm,
          'Warm',
          const Color(0xFFF5F0E8),
          const Color(0xFF1A454E),
        ),
        const SizedBox(width: 10),
        _themeOption(
          context,
          theme,
          AppTheme.dark,
          'Dark',
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
              // Preview circle
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

  // ── Placeholder Card ──
  Widget _buildPlaceholderCard(
    ThemeProvider theme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
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
            child: Icon(icon, size: 20, color: theme.accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryText,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: theme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.pillBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Soon',
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
