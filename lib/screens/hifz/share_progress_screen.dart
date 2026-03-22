import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/social_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/services/hifz_database_service.dart';

/// Screen for sharing Hifz progress as text or PDF report.
class ShareProgressScreen extends StatefulWidget {
  const ShareProgressScreen({super.key});

  @override
  State<ShareProgressScreen> createState() => _ShareProgressScreenState();
}

class _ShareProgressScreenState extends State<ShareProgressScreen> {
  int _pagesMemorized = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final hifz = context.read<HifzProfileProvider>();
    final db = context.read<HifzDatabaseService>();
    final profile = hifz.activeProfile;
    if (profile == null) return;

    final statusCounts = await db.getPageStatusCounts(profile.id);
    if (mounted) {
      setState(() {
        _pagesMemorized = statusCounts[PageStatus.memorized] ?? 0;
        _loadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final hifz = context.watch<HifzProfileProvider>();
    final social = context.watch<SocialProvider>();
    final profile = hifz.activeProfile;

    if (profile == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: theme.primaryText),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'No active profile',
            style: TextStyle(color: theme.secondaryText, fontFamily: 'Inter'),
          ),
        ),
      );
    }

    final streak = hifz.streak;

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
          'Share Progress',
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
            // ── Preview Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.accentColor.withValues(alpha: 0.15),
                    theme.accentColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.accentColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    LucideIcons.bookOpen,
                    size: 40,
                    color: theme.accentColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.name,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hifz Progress Report',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: theme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stats Row
                  if (_loadingStats)
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.accentColor,
                        ),
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statColumn(
                          theme,
                          icon: LucideIcons.bookMarked,
                          value: '$_pagesMemorized',
                          label: 'Pages',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: theme.dividerColor,
                        ),
                        _statColumn(
                          theme,
                          icon: LucideIcons.flame,
                          value: '${streak.totalActiveDays}',
                          label: 'Active Days',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: theme.dividerColor,
                        ),
                        _statColumn(
                          theme,
                          icon: LucideIcons.target,
                          value:
                              '${(_pagesMemorized / 604 * 100).toStringAsFixed(1)}%',
                          label: 'Complete',
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Started: ${profile.startDate.toString().split(' ').first}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: theme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ── Share Options ──
            Text(
              'Share as',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 14),

            // Share as Text
            _shareOption(
              context,
              theme,
              icon: LucideIcons.messageSquare,
              title: 'Share as Text',
              subtitle: 'Quick summary for messaging apps',
              isLoading: false,
              onTap: () => social.shareProgressText(
                profile: profile,
                streak: streak,
              ),
            ),
            const SizedBox(height: 10),

            // Share as PDF
            _shareOption(
              context,
              theme,
              icon: LucideIcons.fileText,
              title: 'Share as PDF',
              subtitle: 'Detailed report for teachers & mentors',
              isLoading: social.isGenerating,
              onTap: () => social.shareProgressPdf(
                profile: profile,
                streak: streak,
              ),
            ),
            const SizedBox(height: 24),

            // ── Info ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 16,
                    color: theme.accentColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your progress is shared as a snapshot. No live data is sent.',
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

            // ── Error ──
            if (social.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.alertCircle,
                      size: 16,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        social.error!,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Colors.red.shade400,
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

  Widget _statColumn(
    ThemeProvider theme, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: theme.accentColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
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
    );
  }

  Widget _shareOption(
    BuildContext context,
    ThemeProvider theme, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: theme.accentColor),
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
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.accentColor,
                ),
              )
            else
              Icon(
                LucideIcons.share2,
                size: 18,
                color: theme.mutedText,
              ),
          ],
        ),
      ),
    );
  }
}
