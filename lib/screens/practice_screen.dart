import 'package:quran_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/flashcard_models.dart';
import 'package:quran_app/providers/flashcard_provider.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/hifz/flashcard_review_screen.dart';
import 'package:quran_app/screens/hifz/mutashabihat_screen.dart';
import 'package:quran_app/screens/hifz/mutashabihat_practice_screen.dart';

/// Practice tab — flashcard category hub + mutashabihat practice.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStats());
  }

  void _loadStats() {
    final profile = context.read<HifzProfileProvider>();
    if (profile.hasActiveProfile) {
      context.read<FlashcardProvider>().loadDueCards(profile.activeProfile!.id);
    }
  }

  void _openReview({FlashcardType? type}) {
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => FlashcardReviewScreen(filterType: type)))
        .then((_) => _loadStats());
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final profile = context.watch<HifzProfileProvider>();
    final fc = context.watch<FlashcardProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                AppLocalizations.of(context)!.pracPracticeTab,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.pracStrengthen,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: theme.secondaryText,
                ),
              ),
              const SizedBox(height: 24),

              if (profile.hasActiveProfile) ...[
                // ── Mixed Review Hero ──
                _buildMixedHero(theme, fc),
                const SizedBox(height: 16),

                // ── Type Category Grid ──
                _buildCategoryGrid(theme, fc),
                const SizedBox(height: 20),

                // ── Quick Stats ──
                if (fc.totalCards > 0) ...[
                  _buildStatsRow(theme, fc),
                  const SizedBox(height: 24),
                ],

                // ── Regenerate ──
                Center(
                  child: GestureDetector(
                    onTap: () {
                      final p = context.read<HifzProfileProvider>();
                      if (p.hasActiveProfile) {
                        context
                            .read<FlashcardProvider>()
                            .forceRegenerate(p.activeProfile!.id);
                      }
                    },
                    child: Text(
                      AppLocalizations.of(context)!.pracRegenCards,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: theme.mutedText,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                _buildNoProfileCard(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // MIXED REVIEW HERO
  // ═══════════════════════════════════════

  Widget _buildMixedHero(ThemeProvider theme, FlashcardProvider fc) {
    final totalDue = fc.dueCardCount;
    final hasDue = totalDue > 0;

    return GestureDetector(
      onTap: hasDue ? () => _openReview() : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: hasDue
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.accentColor,
                    theme.accentColor.withValues(alpha: 0.8),
                  ],
                )
              : null,
          color: hasDue ? null : theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: hasDue ? null : Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: hasDue
                    ? Colors.white.withValues(alpha: 0.2)
                    : theme.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text('🔀',
                    style: TextStyle(fontSize: hasDue ? 24 : 20)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasDue
                        ? AppLocalizations.of(context)!.pracMixedReview
                        : AppLocalizations.of(context)!.pracAllCaughtUp,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: hasDue ? Colors.white : theme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasDue
                        ? '$totalDue cards · ~${fc.estimatedMinutes} min · All types'
                        : AppLocalizations.of(context)!.pracNoFlashcards,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: hasDue
                          ? Colors.white.withValues(alpha: 0.8)
                          : theme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (hasDue)
              Icon(LucideIcons.arrowRight,
                  size: 20, color: Colors.white.withValues(alpha: 0.8)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // CATEGORY GRID
  // ═══════════════════════════════════════

  Widget _buildCategoryGrid(ThemeProvider theme, FlashcardProvider fc) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _categoryCard(
                theme: theme,
                emoji: '⏭️',
                title: AppLocalizations.of(context)!.pracNextVerse,
                subtitle: 'ما بعدها؟',
                dueCount: fc.getDueCountForType(FlashcardType.nextVerse),
                color: const Color(0xFF3B82F6), // blue
                onTap: () => _openReview(type: FlashcardType.nextVerse),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _categoryCard(
                theme: theme,
                emoji: '⏮️',
                title: AppLocalizations.of(context)!.pracPrevVerse,
                subtitle: 'ما قبلها؟',
                dueCount: fc.getDueCountForType(FlashcardType.previousVerse),
                color: const Color(0xFF06B6D4), // cyan
                onTap: () => _openReview(type: FlashcardType.previousVerse),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _categoryCard(
                theme: theme,
                emoji: '📝',
                title: AppLocalizations.of(context)!.pracCompleteIt,
                subtitle: 'أكمل الآية',
                dueCount:
                    fc.getDueCountForType(FlashcardType.verseCompletion),
                color: const Color(0xFF10B981), // emerald
                onTap: () =>
                    _openReview(type: FlashcardType.verseCompletion),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _categoryCard(
                theme: theme,
                emoji: '🔍',
                title: AppLocalizations.of(context)!.pracSurahDetective,
                subtitle: 'من أي سورة؟',
                dueCount: fc.getDueCountForType(FlashcardType.surahDetective),
                color: const Color(0xFF8B5CF6), // purple
                onTap: () => _openReview(type: FlashcardType.surahDetective),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _categoryCard(
                theme: theme,
                emoji: '🔗',
                title: AppLocalizations.of(context)!.pracSequence,
                subtitle: 'رتب الآيات',
                dueCount:
                    fc.getDueCountForType(FlashcardType.connectSequence),
                color: const Color(0xFFF59E0B), // amber
                onTap: () =>
                    _openReview(type: FlashcardType.connectSequence),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _categoryCard(
                theme: theme,
                emoji: '⚔️',
                title: AppLocalizations.of(context)!.pracMutashabihat,
                subtitle: AppLocalizations.of(context)!.pracMutArabic,
                dueCount:
                    fc.getDueCountForType(FlashcardType.mutashabihatDuel),
                color: const Color(0xFFEF4444), // red
                onTap: () =>
                    _openReview(type: FlashcardType.mutashabihatDuel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _browseMutashabihatCard(theme),
      ],
    );
  }

  Widget _categoryCard({
    required ThemeProvider theme,
    required String emoji,
    required String title,
    required String subtitle,
    required int dueCount,
    required Color color,
    required VoidCallback onTap,
  }) {
    final hasDue = dueCount > 0;

    return GestureDetector(
      onTap: hasDue ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasDue ? color.withValues(alpha: 0.3) : theme.dividerColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji + badge
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 16))),
                ),
                const Spacer(),
                if (hasDue)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$dueCount',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: hasDue ? theme.primaryText : theme.secondaryText,
              ),
            ),
            const SizedBox(height: 2),

            // Subtitle
            Text(
              subtitle,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: theme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _browseMutashabihatCard(ThemeProvider theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                    child: Text('📿', style: TextStyle(fontSize: 16))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.pracMutSimilar,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.pracBrowseStudy,
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MutashabihatScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.pracBrowse,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.accentColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MutashabihatPracticeScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.accentColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text(AppLocalizations.of(context)!.pracPractice,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // STATS ROW
  // ═══════════════════════════════════════

  Widget _buildStatsRow(ThemeProvider theme, FlashcardProvider fc) {
    return Row(
      children: [
        _statChip(theme, '${fc.totalCards}', AppLocalizations.of(context)!.pracTotalCards),
        const SizedBox(width: 10),
        _statChip(theme, '${fc.accuracyPercent}%', AppLocalizations.of(context)!.pracAccuracy),
      ],
    );
  }

  Widget _statChip(ThemeProvider theme, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.primaryText,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: theme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // NO PROFILE
  // ═══════════════════════════════════════

  Widget _buildNoProfileCard(ThemeProvider theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.layers, size: 32, color: theme.mutedText),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.pracCreateProfileUnlock,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
