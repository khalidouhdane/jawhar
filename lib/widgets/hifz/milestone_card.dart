import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/social_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/services/sharing_service.dart';

/// Widget for shareable milestone completion cards.
/// Displays juz completion, khatm completion, or streak milestones
/// with a beautiful design and a share button.
class MilestoneCard extends StatelessWidget {
  final MilestoneType type;
  final String profileName;
  final int? juzNumber;
  final int? streakDays;
  final int? pagesMemorized;

  const MilestoneCard({
    super.key,
    required this.type,
    required this.profileName,
    this.juzNumber,
    this.streakDays,
    this.pagesMemorized,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final social = context.read<SocialProvider>();

    final config = _getConfig(theme);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: config.gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: config.gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Icon ──
          Text(
            config.emoji,
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 14),

          // ── Title ──
          Text(
            config.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),

          // ── Subtitle ──
          Text(
            config.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 20),

          // ── Share Button ──
          GestureDetector(
            onTap: () => _share(social),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.share2,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Share',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Branding ──
          Text(
            'Le Quran',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  void _share(SocialProvider social) {
    switch (type) {
      case MilestoneType.juzComplete:
        social.shareJuzMilestone(
          profileName: profileName,
          juzNumber: juzNumber ?? 30,
        );
      case MilestoneType.khatmComplete:
        social.shareKhatmMilestone(profileName: profileName);
      case MilestoneType.streakMilestone:
        social.shareStreakMilestone(
          profileName: profileName,
          streakDays: streakDays ?? 0,
        );
    }
  }

  _MilestoneConfig _getConfig(ThemeProvider theme) {
    switch (type) {
      case MilestoneType.juzComplete:
        return _MilestoneConfig(
          emoji: '🎉',
          title: 'Juz $juzNumber Complete!',
          subtitle: 'Alhamdulillah — $profileName has completed Juz $juzNumber of the Quran.',
          gradientColors: [
            const Color(0xFF1A454E),
            const Color(0xFF2D7A6F),
          ],
        );
      case MilestoneType.khatmComplete:
        return _MilestoneConfig(
          emoji: '🏆',
          title: 'Quran Complete!',
          subtitle: 'MashaAllah — $profileName has memorized the entire Quran! May Allah accept it.',
          gradientColors: [
            const Color(0xFFB8860B),
            const Color(0xFFDAA520),
          ],
        );
      case MilestoneType.streakMilestone:
        return _MilestoneConfig(
          emoji: '🔥',
          title: '$streakDays-Day Streak!',
          subtitle: '$profileName has been consistent for $streakDays days. Consistency is key!',
          gradientColors: [
            const Color(0xFFD84315),
            const Color(0xFFFF6D00),
          ],
        );
    }
  }
}

class _MilestoneConfig {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;

  const _MilestoneConfig({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
  });
}
