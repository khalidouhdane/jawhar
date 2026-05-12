import 'package:flutter/material.dart';
import 'package:quran_app/services/cloud_sync_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/plan_provider.dart';
import 'package:quran_app/providers/locale_provider.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/services/ai_plan_service.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/screens/onboarding_screen.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/screens/hifz/assessment_screen.dart';
import 'package:quran_app/widgets/sheets/nav_menu_sheet.dart';
import 'package:quran_app/widgets/sheets/notification_settings_sheet.dart';
import 'package:quran_app/screens/hifz/accountability_screen.dart';
import 'package:quran_app/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final hifzProfile = context.watch<HifzProfileProvider>();
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
                l!.profileTitle,
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
                l.profileSubtitle,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.secondaryText,
                ),
              ),
              const SizedBox(height: 24),

              // ── Reading Stats ──
              _buildStatsCard(context, theme, hifzProfile, lastRead, l),
              const SizedBox(height: 20),

              // ── Language Selector ──
              _buildSectionLabel(theme, l.profileLanguage),
              const SizedBox(height: 10),
              _buildLanguageSelector(context, theme, locale),
              const SizedBox(height: 24),

              // ── Rewaya (Reading) Selector ──
              _buildSectionLabel(theme, l.profileReading),
              const SizedBox(height: 10),
              _buildRewayaSelector(context, theme, reading),
              const SizedBox(height: 24),

              // ── Theme Selector ──
              _buildSectionLabel(theme, l.profileAppearance),
              const SizedBox(height: 10),
              _buildThemeSelector(context, theme, l),
              const SizedBox(height: 24),

              // ── Bookmarks ──
              _buildSectionLabel(theme, l.profileBookmarksTitle),
              const SizedBox(height: 10),
              _buildBookmarksCard(context, theme, l),
              const SizedBox(height: 24),

              // ── Notifications ──
              _buildSectionLabel(theme, AppLocalizations.of(context)!.profileNotificationsTitle),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const NotificationSettingsSheet(),
                  );
                },
                child: _buildSettingsTile(
                  theme,
                  icon: LucideIcons.bell,
                  title: AppLocalizations.of(context)!.profileSessionReminders,
                  subtitle: AppLocalizations.of(context)!.profileSessionRemindersDesc,
                ),
              ),
              const SizedBox(height: 24),

              // ── Social & Accountability ──
              _buildSectionLabel(theme, AppLocalizations.of(context)!.profileSocialSharingSection),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AccountabilityScreen(),
                    ),
                  );
                },
                child: _buildSettingsTile(
                  theme,
                  icon: LucideIcons.users,
                  title: AppLocalizations.of(context)!.profileAccountabilityTitle,
                  subtitle: AppLocalizations.of(context)!.profileAccountabilityDesc,
                ),
              ),
              const SizedBox(height: 24),

              // ── Hifz Profile Management (CE-11) ──
              if (hifzProfile.hasActiveProfile) ...[
                _buildSectionLabel(theme, AppLocalizations.of(context)!.profileHifzSection),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AssessmentScreen(isRetake: true)),
                    );
                  },
                  child: _buildSettingsTile(
                    theme,
                    icon: LucideIcons.refreshCw,
                    title: AppLocalizations.of(context)!.profileRetakeAssessment,
                    subtitle: AppLocalizations.of(context)!.profileRetakeAssessmentDesc,
                  ),
                ),
                const SizedBox(height: 6),
                // AI Model selector (dev testing)
                Builder(
                  builder: (ctx) {
                    return FutureBuilder<SharedPreferences>(
                      future: SharedPreferences.getInstance(),
                      builder: (ctx, snap) {
                        final prefs = snap.data;
                        final currentModel = prefs?.getString('ai_model') ?? AIPlanService.modelFlash;
                        final isFlash = currentModel.contains('flash');
                        return GestureDetector(
                          onTap: () async {
                            if (prefs == null) return;
                            final newModel = isFlash ? AIPlanService.modelPro : AIPlanService.modelFlash;
                            await prefs.setString('ai_model', newModel);
                            // Trigger rebuild
                            (ctx as Element).markNeedsBuild();
                          },
                          child: _buildSettingsTile(
                            theme,
                            icon: LucideIcons.cpu,
                            title: AppLocalizations.of(context)!.profileAiModel,
                            subtitle: isFlash ? AppLocalizations.of(context)!.profileAiModelFlash : AppLocalizations.of(context)!.profileAiModelPro,
                          ),
                        );
                      },
                    );
                  },
                ),
                GestureDetector(
                  onTap: () => _showResetProgressDialog(context, theme, hifzProfile),
                  child: _buildSettingsTile(
                    theme,
                    icon: LucideIcons.trash2,
                    title: AppLocalizations.of(context)!.profileResetProgress,
                    subtitle: AppLocalizations.of(context)!.profileResetProgressDesc,
                    danger: true,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _showDeleteProfileDialog(context, theme, hifzProfile),
                  child: _buildSettingsTile(
                    theme,
                    icon: LucideIcons.userX,
                    title: AppLocalizations.of(context)!.profileDeleteProfile,
                    subtitle: AppLocalizations.of(context)!.profileDeleteProfileDesc,
                    danger: true,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Cloud & Account ──
              _buildSectionLabel(theme, AppLocalizations.of(context)!.profileCloudAccountSection),
              const SizedBox(height: 10),
              _buildCloudAccountCard(context, theme),
              const SizedBox(height: 24),

              // ── About ──
              _buildSectionLabel(theme, l.profileAbout),
              const SizedBox(height: 10),
              _buildSettingsTile(
                theme,
                icon: LucideIcons.info,
                title: 'Le Quran',
                subtitle: l.profileVersion,
              ),
              const SizedBox(height: 6),
              _buildSettingsTile(
                theme,
                icon: LucideIcons.heart,
                title: l.profileMadeWith,
                subtitle: l.profileCompanion,
              ),
              const SizedBox(height: 6),
              _buildSettingsTile(
                theme,
                icon: LucideIcons.globe,
                title: l.profileData,
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
                  title: l.profileReplayOnboarding,
                  subtitle: l.profileReplayOnboardingDesc,
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
    HifzProfileProvider hifzProfile,
    LastReadPosition? lastRead,
    AppLocalizations l,
  ) {
    final activeDays = hifzProfile.streak.totalActiveDays;
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
            l.profileJourney,
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
                value: '$activeDays',
                label: l.profileMemorized,
                icon: LucideIcons.brain,
              ),
              _statDivider(theme),
              _statItem(
                theme,
                value: '${hifzProfile.streak.totalActiveDays}',
                label: l.hifzDayStreak,
                icon: LucideIcons.flame,
              ),
              _statDivider(theme),
              _statItem(
                theme,
                value: lastRead != null ? '${lastRead.page}' : '-',
                label: l.profileLastPage,
                icon: LucideIcons.bookOpen,
              ),
              _statDivider(theme),
              _statItem(
                theme,
                value: '${context.watch<BookmarkProvider>().count}',
                label: l.profileBookmarksTitle,
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
                    l.profileBookmarksTitle,
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
                        : l.profileBookmarksDesc,
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
          l.profileThemeClassic,
          Colors.white,
          const Color(0xFF1A454E),
        ),
        const SizedBox(width: 10),
        _themeOption(
          context,
          theme,
          AppTheme.warm,
          l.profileThemeWarm,
          const Color(0xFFF5F0E8),
          const Color(0xFF1A454E),
        ),
        const SizedBox(width: 10),
        _themeOption(
          context,
          theme,
          AppTheme.dark,
          l.profileThemeDark,
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

  // ── Cloud Account Card ──
  Widget _buildCloudAccountCard(BuildContext context, ThemeProvider theme) {
    final auth = context.watch<AuthService>();

    if (auth.isSignedIn) {
      // Signed-in state: show user info + sync status + sign out
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // User avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: theme.accentColor.withValues(alpha: 0.1),
                  backgroundImage: auth.photoUrl != null
                      ? NetworkImage(auth.photoUrl!)
                      : null,
                  child: auth.photoUrl == null
                      ? Icon(LucideIcons.user, size: 20, color: theme.accentColor)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.displayName ?? 'Signed In',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                      Text(
                        auth.email ?? '',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: theme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                // Live sync indicator
                Consumer<CloudSyncService>(
                  builder: (_, sync, _) {
                    final Color color;
                    final IconData icon;
                    final String label;
                    switch (sync.status) {
                      case SyncStatus.syncing:
                        color = Colors.orange;
                        icon = LucideIcons.refreshCw;
                        label = AppLocalizations.of(context)!.syncSyncing;
                        break;
                      case SyncStatus.synced:
                        color = const Color(0xFF4CAF50);
                        icon = LucideIcons.cloud;
                        label = AppLocalizations.of(context)!.syncSynced;
                        break;
                      case SyncStatus.error:
                        color = Colors.red;
                        icon = LucideIcons.cloudOff;
                        label = AppLocalizations.of(context)!.syncError;
                        break;
                      case SyncStatus.idle:
                        color = theme.mutedText;
                        icon = LucideIcons.cloud;
                        label = AppLocalizations.of(context)!.syncIdle;
                        break;
                    }
                    return GestureDetector(
                      onTap: auth.isSignedIn && !sync.isSyncing
                          ? () => sync.syncAll(auth.uid!)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 12, color: color),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Sign-out button
            GestureDetector(
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.profileSignOutDialogTitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: theme.primaryText,
                      ),
                    ),
                    content: Text(
                      AppLocalizations.of(context)!.profileSignOutDialogDesc,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: theme.secondaryText,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          AppLocalizations.of(context)!.profileActionCancel,
                          style: TextStyle(color: theme.secondaryText),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          AppLocalizations.of(context)!.profileSignOut,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await auth.signOut();
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.profileSignOut,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.secondaryText,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Delete Account button
            GestureDetector(
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.profileDeleteAccountDialogTitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.red,
                      ),
                    ),
                    content: Text(
                      AppLocalizations.of(context)!.profileDeleteAccountDialogDesc,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: theme.secondaryText,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          AppLocalizations.of(context)!.profileActionCancel,
                          style: TextStyle(color: theme.secondaryText),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          AppLocalizations.of(context)!.actionDelete,
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  final sync = Provider.of<CloudSyncService>(context, listen: false);
                  try {
                    await sync.deleteAccount(auth.uid!);
                    if (context.mounted) {
                      await auth.signOut();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.profileAccountDeleted)),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${AppLocalizations.of(context)!.profileError}: $e')),
                      );
                    }
                  }
                }
              },
              child: Text(
                AppLocalizations.of(context)!.profileDeleteAccount,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Colors.red.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Signed-out state: Google Sign-In button
    return GestureDetector(
      onTap: auth.isLoading
          ? null
          : () async {
              final success = await auth.signInWithGoogle();
              if (success && auth.uid != null && context.mounted) {
                // Trigger initial sync
                final syncService = context.read<CloudSyncService>();
                syncService.performInitialSync(auth.uid!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.profileSyncing),
                      backgroundColor: theme.accentColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (auth.error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(auth.error!),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: auth.isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.accentColor,
                        ),
                      )
                    : Icon(LucideIcons.cloud, size: 20, color: theme.accentColor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.profileSignInGoogle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.profileSignInGoogleDesc,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: 18, color: theme.mutedText),
          ],
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
    bool danger = false,
  }) {
    final iconColor = danger ? Colors.red.shade400 : theme.accentColor;
    final titleColor = danger ? Colors.red.shade400 : theme.primaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: danger ? Colors.red.withValues(alpha: 0.2) : theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
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
                    color: titleColor,
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

  // ── CE-11: Dialog methods ──

  void _showResetProgressDialog(
      BuildContext context, ThemeProvider theme, HifzProfileProvider hifz) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.profileResetProgress,
            style: TextStyle(fontFamily: 'Inter', color: theme.primaryText)),
        content: Text(
          AppLocalizations.of(context)!.profileResetProgressDesc,
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: theme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.actionCancel, style: TextStyle(color: theme.mutedText)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final db = context.read<HifzDatabaseService>();
              await db.resetProgress(hifz.activeProfile!.id);
              // Clear the plan so it regenerates fresh
              if (context.mounted) {
                context.read<PlanProvider>().clearPlan();
              }
              await hifz.refresh();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context)!.profileProgressReset)),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.actionReset, style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  void _showDeleteProfileDialog(
      BuildContext context, ThemeProvider theme, HifzProfileProvider hifz) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.profileDeleteProfile,
            style: TextStyle(fontFamily: 'Inter', color: theme.primaryText)),
        content: Text(
          AppLocalizations.of(context)!.profileDeleteProfileDesc,
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: theme.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.actionCancel, style: TextStyle(color: theme.mutedText)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final profileId = hifz.activeProfile!.id;
              // Use provider's deleteProfile which handles switching to next profile
              await hifz.deleteProfile(profileId);
              // Clear old plan so it doesn't linger
              if (context.mounted) {
                final planProvider = context.read<PlanProvider>();
                planProvider.clearPlan();
                // If there's still an active profile, load its plan
                if (hifz.hasActiveProfile) {
                  planProvider.loadOrGeneratePlan(hifz.activeProfile!);
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.actionDelete, style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
}
