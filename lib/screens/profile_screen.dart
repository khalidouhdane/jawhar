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
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/screens/splash_screen.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/screens/hifz/assessment_screen.dart';
import 'package:quran_app/widgets/sheets/nav_menu_sheet.dart';
import 'package:quran_app/widgets/sheets/notification_settings_sheet.dart';
import 'package:quran_app/screens/hifz/accountability_screen.dart';
import 'package:quran_app/services/auth_service.dart';
import 'package:quran_app/services/qf_user_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/theme/geist_tokens.dart';
import 'package:quran_app/widgets/app_header.dart';
import 'package:quran_app/widgets/geist_button.dart';
import 'package:quran_app/widgets/geist_segmented_control.dart';

enum ProfileTab { settings, hifz, account }

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileTab _activeTab = ProfileTab.settings;

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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppHeader(
                      title: l!.profileTitle,
                      subtitle: l.profileSubtitle,
                      // Remove avatar tap action here so it just shows the avatar without infinite looping to profile
                      onAvatarTap: () {},
                    ),
                  ),
                  const SizedBox(height: 24),
                  GeistSegmentedControl<ProfileTab>(
                    theme: theme,
                    selectedTab: _activeTab,
                    onTabChanged: (tab) => setState(() => _activeTab = tab),
                    tabs: {
                      ProfileTab.settings: l.profileTabSettings,
                      ProfileTab.hifz: l.profileTabHifz,
                      ProfileTab.account: l.profileTabAccount,
                    },
                  ),
                ],
              ),
            ),

            // ── Scrollable Tab Content ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: _buildActiveTabContent(
                  context,
                  theme,
                  hifzProfile,
                  locale,
                  reading,
                  l,
                  lastRead,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildActiveTabContent(
    BuildContext context,
    ThemeProvider theme,
    HifzProfileProvider hifzProfile,
    LocaleProvider locale,
    QuranReadingProvider reading,
    AppLocalizations l,
    LastReadPosition? lastRead,
  ) {
    switch (_activeTab) {
      case ProfileTab.settings:
        return _buildSettingsTab(context, theme, locale, reading, l);
      case ProfileTab.hifz:
        return _buildHifzTab(context, theme, hifzProfile, l, lastRead);
      case ProfileTab.account:
        return _buildAccountTab(context, theme, l);
    }
  }

  Widget _buildSettingsTab(
    BuildContext context,
    ThemeProvider theme,
    LocaleProvider locale,
    QuranReadingProvider reading,
    AppLocalizations l,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ═══════════════════════════════════════════
        // GROUP 1: Preferences
        // ═══════════════════════════════════════════
        _buildSectionLabel(theme, l.profilePreferences),
        const SizedBox(height: 8),

        // Language
        _buildLanguageSelector(context, theme, locale),
        const SizedBox(height: 12),

        // Rewaya
        _buildRewayaSelector(context, theme, reading),
        const SizedBox(height: 12),

        // Theme
        _buildThemeSelector(context, theme, l),
        const SizedBox(height: 32),

        // ═══════════════════════════════════════════
        // GROUP 2: Features
        // ═══════════════════════════════════════════
        _buildSectionLabel(theme, l.profileFeatures),
        const SizedBox(height: 8),

        // Bookmarks
        _buildBookmarksCard(context, theme, l),
        const SizedBox(height: 6),

        // Notifications
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              constraints: const BoxConstraints(maxWidth: 680),
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
        const SizedBox(height: 6),

        // Accountability
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountabilityScreen()),
            );
          },
          child: _buildSettingsTile(
            theme,
            icon: LucideIcons.users,
            title: AppLocalizations.of(context)!.profileAccountabilityTitle,
            subtitle: AppLocalizations.of(context)!.profileAccountabilityDesc,
          ),
        ),
      ],
    );
  }

  Widget _buildHifzTab(
    BuildContext context,
    ThemeProvider theme,
    HifzProfileProvider hifzProfile,
    AppLocalizations l,
    LastReadPosition? lastRead,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Reading Stats ──
        _buildStatsCard(context, theme, hifzProfile, lastRead, l),
        const SizedBox(height: 32),

        // ═══════════════════════════════════════════
        // GROUP 3: Hifz Profile
        // ═══════════════════════════════════════════
        if (hifzProfile.hasActiveProfile) ...[
          _buildSectionLabel(
            theme,
            AppLocalizations.of(context)!.profileHifzSection,
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AssessmentScreen(isRetake: true),
                ),
              );
            },
            child: _buildSettingsTile(
              theme,
              icon: LucideIcons.refreshCw,
              title: AppLocalizations.of(context)!.profileRetakeAssessment,
              subtitle: AppLocalizations.of(
                context,
              )!.profileRetakeAssessmentDesc,
            ),
          ),
          const SizedBox(height: 6),
          const SizedBox(height: 6),
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
        ] else ...[
          // Show something if no active profile, or let it be empty
          _buildSettingsTile(
            theme,
            icon: LucideIcons.info,
            title: 'No Hifz Profile',
            subtitle: 'Start an assessment from the Dashboard to create one.',
            showChevron: false,
          ),
        ],
      ],
    );
  }

  Widget _buildAccountTab(
    BuildContext context,
    ThemeProvider theme,
    AppLocalizations l,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ═══════════════════════════════════════════
        // GROUP 4: Accounts
        // ═══════════════════════════════════════════
        _buildSectionLabel(theme, l.profileAccounts),
        const SizedBox(height: 8),
        _buildCloudAccountCard(context, theme),
        const SizedBox(height: 6),
        _buildQfAccountCard(context, theme),
        const SizedBox(height: 32),

        // ═══════════════════════════════════════════
        // GROUP 5: About
        // ═══════════════════════════════════════════
        _buildSectionLabel(theme, l.profileAbout),
        const SizedBox(height: 8),
        _buildSettingsTile(
          theme,
          icon: LucideIcons.info,
          title: 'Jawhar',
          subtitle: l.profileVersion,
          showChevron: false,
        ),
        const SizedBox(height: 6),
        _buildSettingsTile(
          theme,
          icon: LucideIcons.heart,
          title: l.profileMadeWith,
          subtitle: l.profileCompanion,
          showChevron: false,
        ),
        const SizedBox(height: 6),
        _buildSettingsTile(
          theme,
          icon: LucideIcons.globe,
          title: l.profileData,
          subtitle: 'Quran.com API',
          showChevron: false,
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('onboarding_complete', false);
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SplashScreen()),
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
      ],
    );
  }

  // ── Language Selector (compact inline row) ──
  Widget _buildLanguageSelector(
    BuildContext context,
    ThemeProvider theme,
    LocaleProvider locale,
  ) {
    final isEnglish = locale.locale == const Locale('en');
    return _buildPreferenceRow(
      theme: theme,
      icon: LucideIcons.globe,
      label: AppLocalizations.of(context)!.profileLanguage,
      options: ['English', 'العربية'],
      selectedIndex: isEnglish ? 0 : 1,
      onSelected: (index) {
        locale.setLocale(index == 0 ? const Locale('en') : const Locale('ar'));
      },
    );
  }

  // ── Rewaya (Reading) Selector (compact inline row) ──
  Widget _buildRewayaSelector(
    BuildContext context,
    ThemeProvider theme,
    QuranReadingProvider reading,
  ) {
    final isHafs = reading.selectedRewaya == 1;
    return _buildPreferenceRow(
      theme: theme,
      icon: LucideIcons.bookOpen,
      label: AppLocalizations.of(context)!.profileReading,
      options: ['Hafs', 'Warsh'],
      selectedIndex: isHafs ? 0 : 1,
      onSelected: (index) {
        reading.setRewaya(index == 0 ? 1 : 2);
      },
    );
  }

  // ── Theme Selector (compact inline row) ──
  Widget _buildThemeSelector(
    BuildContext context,
    ThemeProvider theme,
    AppLocalizations l,
  ) {
    final isLight = theme.theme == AppTheme.light;
    return _buildPreferenceRow(
      theme: theme,
      icon: isLight ? LucideIcons.sun : LucideIcons.moon,
      label: l.profileAppearance,
      options: [l.profileThemeLight, l.profileThemeDark],
      selectedIndex: isLight ? 0 : 1,
      onSelected: (index) {
        theme.setTheme(index == 0 ? AppTheme.light : AppTheme.dark);
      },
    );
  }

  /// Compact preference row: icon + label on left, mini segmented control on right.
  Widget _buildPreferenceRow({
    required ThemeProvider theme,
    required IconData icon,
    required String label,
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.secondaryText),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.primaryText,
              ),
            ),
          ),
          // ── Mini Segmented Control ──
          _MiniSegmentedControl(
            theme: theme,
            options: options,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.profileJourney,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSingleStatCard(
                theme,
                value: '$activeDays',
                label: l.profileMemorized,
                icon: LucideIcons.brain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSingleStatCard(
                theme,
                value: '${hifzProfile.streak.totalActiveDays}',
                label: l.hifzDayStreak,
                icon: LucideIcons.flame,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSingleStatCard(
                theme,
                value: lastRead != null ? '${lastRead.page}' : '-',
                label: l.profileLastPage,
                icon: LucideIcons.bookOpen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSingleStatCard(
                theme,
                value: '${context.watch<BookmarkProvider>().count}',
                label: l.profileBookmarksTitle,
                icon: LucideIcons.bookmark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleStatCard(
    ThemeProvider theme, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.accentColor),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.mutedText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
          constraints: const BoxConstraints(maxWidth: 680),
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
      child: _buildSettingsTile(
        theme,
        icon: LucideIcons.bookmark,
        title: l.profileBookmarksTitle,
        subtitle: count > 0
            ? '$count ${count == 1 ? 'bookmark' : 'bookmarks'}'
            : l.profileBookmarksDesc,
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
          borderRadius: BorderRadius.circular(theme.radiusLg),
          boxShadow: theme.shadowCard,
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
                      ? Icon(
                          LucideIcons.user,
                          size: 20,
                          color: theme.accentColor,
                        )
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
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                      Text(
                        auth.email ?? '',
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
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
                        color = GeistTokens.amber800;
                        icon = LucideIcons.refreshCw;
                        label = AppLocalizations.of(context)!.syncSyncing;
                        break;
                      case SyncStatus.synced:
                        color = const Color(0xFF0A7B3E);
                        icon = LucideIcons.cloud;
                        label = AppLocalizations.of(context)!.syncSynced;
                        break;
                      case SyncStatus.error:
                        color = GeistTokens.red800;
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(theme.radiusMd),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 12, color: color),
                            const SizedBox(width: 4),
                            Text(
                              label,
                              style: TextStyle(
                                fontFamily: GeistTypography.primaryFontFamily,
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
                      borderRadius: BorderRadius.circular(theme.radiusLg),
                    ),
                    title: Text(
                      AppLocalizations.of(context)!.profileSignOutDialogTitle,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        color: theme.primaryText,
                      ),
                    ),
                    content: Text(
                      AppLocalizations.of(context)!.profileSignOutDialogDesc,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 13,
                        color: theme.secondaryText,
                      ),
                    ),
                    actions: [
                      GeistButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        label: AppLocalizations.of(
                          context,
                        )!.profileActionCancel,
                        type: GeistButtonType.tertiary,
                        size: GeistButtonSize.small,
                      ),
                      GeistButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        label: AppLocalizations.of(context)!.profileSignOut,
                        type: GeistButtonType.error,
                        size: GeistButtonSize.small,
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
                  borderRadius: BorderRadius.circular(theme.radiusMd),
                  boxShadow: theme.shadowCard,
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.profileSignOut,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
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
                      borderRadius: BorderRadius.circular(theme.radiusLg),
                    ),
                    title: Text(
                      AppLocalizations.of(
                        context,
                      )!.profileDeleteAccountDialogTitle,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        color: GeistTokens.red800,
                      ),
                    ),
                    content: Text(
                      AppLocalizations.of(
                        context,
                      )!.profileDeleteAccountDialogDesc,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 13,
                        color: theme.secondaryText,
                      ),
                    ),
                    actions: [
                      GeistButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        label: AppLocalizations.of(
                          context,
                        )!.profileActionCancel,
                        type: GeistButtonType.tertiary,
                        size: GeistButtonSize.small,
                      ),
                      GeistButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        label: AppLocalizations.of(context)!.actionDelete,
                        type: GeistButtonType.error,
                        size: GeistButtonSize.small,
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  final sync = Provider.of<CloudSyncService>(
                    context,
                    listen: false,
                  );
                  try {
                    await sync.deleteAccount(auth.uid!);
                    if (context.mounted) {
                      await auth.signOut();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.profileAccountDeleted,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${AppLocalizations.of(context)!.profileError}: $e',
                          ),
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(
                AppLocalizations.of(context)!.profileDeleteAccount,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 12,
                  color: GeistTokens.red800.withValues(alpha: 0.6),
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
                      content: Text(
                        AppLocalizations.of(context)!.profileSyncing,
                      ),
                      backgroundColor: theme.accentColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (auth.error != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(auth.error!),
                    backgroundColor: GeistTokens.red800,
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
          borderRadius: BorderRadius.circular(theme.radiusLg),
          boxShadow: theme.shadowCard,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(theme.radiusMd),
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
                    : Icon(
                        LucideIcons.cloud,
                        size: 20,
                        color: theme.accentColor,
                      ),
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
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.profileSignInGoogleDesc,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
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

  // ── Quran Foundation Account Card ──
  Widget _buildQfAccountCard(BuildContext context, ThemeProvider theme) {
    final qfAuth = context.watch<QfUserAuthService>();

    if (qfAuth.isSignedIn) {
      // Signed-in state
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(theme.radiusLg),
          boxShadow: theme.shadowCard,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(theme.radiusLg),
                  ),
                  child: Icon(
                    LucideIcons.bookOpen,
                    size: 20,
                    color: theme.accentColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.profileQfTitle,
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.primaryText,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.profileQfConnected,
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 11,
                          color: const Color(0xFF0A7B3E),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A7B3E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(theme.radiusMd),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.check,
                        size: 12,
                        color: const Color(0xFF0A7B3E),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.profileQfActive,
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0A7B3E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Sign-out button
            GestureDetector(
              onTap: () async {
                await qfAuth.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.profileQfDisconnected,
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(theme.radiusMd),
                  boxShadow: theme.shadowCard,
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.profileQfDisconnect,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.secondaryText,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Signed-out state: QF Sign-In button
    return GestureDetector(
      onTap: qfAuth.isSigningIn
          ? null
          : () async {
              final success = await qfAuth.signIn();
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.profileQfConnectedSuccess,
                      ),
                      backgroundColor: theme.accentColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else if (!qfAuth.isSigningIn) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.profileQfSignInFailed,
                      ),
                      backgroundColor: GeistTokens.red800,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(theme.radiusLg),
          boxShadow: theme.shadowCard,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(theme.radiusMd),
              ),
              child: Center(
                child: qfAuth.isSigningIn
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.accentColor,
                        ),
                      )
                    : Icon(
                        LucideIcons.bookOpen,
                        size: 20,
                        color: theme.accentColor,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.profileQfSignIn,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.profileQfSignInDesc,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
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
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: GeistTypography.primaryFontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: theme.mutedText,
          letterSpacing: -0.2,
        ),
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
    bool showChevron = true,
  }) {
    final dangerColor = GeistTokens.red800;
    final iconColor = danger ? dangerColor : theme.secondaryText;
    final titleColor = danger ? dangerColor : theme.primaryText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusLg),
        boxShadow: theme.shadowCard,
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
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 12,
                    color: theme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          if (showChevron)
            Icon(LucideIcons.chevronRight, size: 16, color: theme.mutedText),
        ],
      ),
    );
  }

  // ── CE-11: Dialog methods ──

  void _showResetProgressDialog(
    BuildContext context,
    ThemeProvider theme,
    HifzProfileProvider hifz,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.radiusLg),
        ),
        title: Text(
          AppLocalizations.of(context)!.profileResetProgress,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            color: theme.primaryText,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.profileResetProgressDesc,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 13,
            color: theme.secondaryText,
          ),
        ),
        actions: [
          GeistButton(
            onPressed: () => Navigator.pop(ctx),
            label: AppLocalizations.of(context)!.actionCancel,
            type: GeistButtonType.tertiary,
            size: GeistButtonSize.small,
          ),
          GeistButton(
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
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context)!.profileProgressReset,
                    ),
                  ),
                );
              }
            },
            label: AppLocalizations.of(context)!.actionReset,
            type: GeistButtonType.error,
            size: GeistButtonSize.small,
          ),
        ],
      ),
    );
  }

  void _showDeleteProfileDialog(
    BuildContext context,
    ThemeProvider theme,
    HifzProfileProvider hifz,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.radiusLg),
        ),
        title: Text(
          AppLocalizations.of(context)!.profileDeleteProfile,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            color: theme.primaryText,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.profileDeleteProfileDesc,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 13,
            color: theme.secondaryText,
          ),
        ),
        actions: [
          GeistButton(
            onPressed: () => Navigator.pop(ctx),
            label: AppLocalizations.of(context)!.actionCancel,
            type: GeistButtonType.tertiary,
            size: GeistButtonSize.small,
          ),
          GeistButton(
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
            label: AppLocalizations.of(context)!.actionDelete,
            type: GeistButtonType.error,
            size: GeistButtonSize.small,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MINI SEGMENTED CONTROL — compact inline toggle for settings rows
// ═══════════════════════════════════════════════════════════════════════════════

class _MiniSegmentedControl extends StatelessWidget {
  final ThemeProvider theme;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _MiniSegmentedControl({
    required this.theme,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final isActive = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? theme.primaryText : Colors.transparent,
                borderRadius: BorderRadius.circular(theme.radiusMd),
              ),
              child: Text(
                options[i],
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? theme.scaffoldBackground : theme.mutedText,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
