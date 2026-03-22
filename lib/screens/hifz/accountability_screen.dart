import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/social_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/hifz/share_progress_screen.dart';

/// Accountability & sharing hub screen.
/// Explains accountability partner concept and provides sharing tools.
class AccountabilityScreen extends StatelessWidget {
  const AccountabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final hifz = context.watch<HifzProfileProvider>();
    final social = context.watch<SocialProvider>();
    final profile = hifz.activeProfile;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Accountability',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.accentColor.withValues(alpha: 0.12),
                    theme.accentColor.withValues(alpha: 0.04),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.accentColor.withValues(alpha: 0.15),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.users,
                    size: 36,
                    color: theme.accentColor,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Stay Accountable Together',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Share your progress with friends, family, or your Quran teacher to stay motivated on your memorization journey.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: theme.secondaryText,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Sharing Options ──
            Text(
              'Sharing Tools',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 14),

            // Share Progress Report
            _featureCard(
              context,
              theme,
              icon: LucideIcons.barChart3,
              title: 'Share Progress',
              subtitle: 'Send a snapshot of your progress as text or PDF',
              enabled: profile != null,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ShareProgressScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // Teacher Mode
            _featureCard(
              context,
              theme,
              icon: LucideIcons.graduationCap,
              title: 'Teacher Report',
              subtitle: 'Generate a detailed PDF report for your teacher or mentor',
              enabled: profile != null,
              onTap: () {
                if (profile != null) {
                  social.shareProgressPdf(
                    profile: profile,
                    streak: hifz.streak,
                  );
                }
              },
            ),
            const SizedBox(height: 10),

            // Share Streak
            _featureCard(
              context,
              theme,
              icon: LucideIcons.flame,
              title: 'Share Streak',
              subtitle: '${hifz.streak.totalActiveDays}-day active streak — celebrate your consistency!',
              enabled: profile != null && hifz.streak.totalActiveDays > 0,
              onTap: () {
                if (profile != null) {
                  social.shareStreakMilestone(
                    profileName: profile.name,
                    streakDays: hifz.streak.totalActiveDays,
                  );
                }
              },
            ),
            const SizedBox(height: 28),

            // ── How It Works ──
            Text(
              'How It Works',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 14),

            _stepTile(theme, '1', 'Choose what to share',
                'Pick a progress report, milestone, or streak.'),
            const SizedBox(height: 8),
            _stepTile(theme, '2', 'Share via any app',
                'Send via WhatsApp, email, or any messaging app.'),
            const SizedBox(height: 8),
            _stepTile(theme, '3', 'Stay motivated',
                'Regular check-ins with friends keep you on track.'),
            const SizedBox(height: 24),

            // ── Privacy Note ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.shield,
                    size: 16,
                    color: theme.accentColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your data stays on your device. Sharing sends a one-time snapshot — no accounts, no servers, no tracking.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: theme.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (profile == null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      size: 16,
                      color: Colors.amber.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Create a Hifz profile first to start sharing your progress.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: theme.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _featureCard(
    BuildContext context,
    ThemeProvider theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        fontSize: 11,
                        color: theme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: theme.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepTile(
    ThemeProvider theme,
    String number,
    String title,
    String desc,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
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
                  desc,
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
