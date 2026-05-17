import 'package:quran_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/flashcard_models.dart';
import 'package:quran_app/providers/flashcard_provider.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/hifz/flashcard_review_screen.dart';
import 'package:quran_app/screens/hifz/mutashabihat_screen.dart';
import 'package:quran_app/screens/hifz/mutashabihat_practice_screen.dart';
import 'package:quran_app/theme/geist_typography.dart';

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
        .push(
          MaterialPageRoute(
            builder: (_) => FlashcardReviewScreen(filterType: type),
          ),
        )
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
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context)!.pracStrengthen,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
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
                        context.read<FlashcardProvider>().forceRegenerate(
                          p.activeProfile!.id,
                        );
                      }
                    },
                    child: Text(
                      AppLocalizations.of(context)!.pracRegenCards,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 12,
                        color: theme.mutedText,
                        decoration: TextDecoration.underline,
                        decorationColor: theme.mutedText.withValues(alpha: 0.4),
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
    final heroText = theme.invertedForeground;

    return Material(
      color: hasDue
          ? (theme.isDark
                ? const Color(0xFF1A1A1A)
                : const Color(0xFF171717))
          : theme.cardColor,
      borderRadius: BorderRadius.circular(theme.radiusXl),
      child: InkWell(
        onTap: hasDue ? () => _openReview() : null,
        borderRadius: BorderRadius.circular(theme.radiusXl),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(theme.radiusXl),
            boxShadow: theme.shadowCard,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: hasDue
                      ? heroText.withValues(alpha: 0.1)
                      : (theme.isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(theme.radiusLg + 6),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.shuffle,
                    size: 22,
                    color: hasDue ? heroText : theme.primaryText,
                  ),
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
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: hasDue ? heroText : theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasDue
                          ? '$totalDue cards · ~${fc.estimatedMinutes} min · All types'
                          : AppLocalizations.of(context)!.pracNoFlashcards,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 12,
                        color: hasDue
                            ? heroText.withValues(alpha: 0.8)
                            : theme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasDue)
                Icon(
                  LucideIcons.arrowRight,
                  size: 20,
                  color: heroText.withValues(alpha: 0.8),
                ),
            ],
          ),
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
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _categoryCard(
                  theme: theme,
                  icon: LucideIcons.skipForward,
                  title: AppLocalizations.of(context)!.pracNextVerse,
                  subtitle: 'ما بعدها؟',
                  dueCount: fc.getDueCountForType(FlashcardType.nextVerse),
                  onTap: () => _openReview(type: FlashcardType.nextVerse),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _categoryCard(
                  theme: theme,
                  icon: LucideIcons.skipBack,
                  title: AppLocalizations.of(context)!.pracPrevVerse,
                  subtitle: 'ما قبلها؟',
                  dueCount: fc.getDueCountForType(FlashcardType.previousVerse),
                  onTap: () => _openReview(type: FlashcardType.previousVerse),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _categoryCard(
                  theme: theme,
                  icon: LucideIcons.pencil,
                  title: AppLocalizations.of(context)!.pracCompleteIt,
                  subtitle: 'أكمل الآية',
                  dueCount: fc.getDueCountForType(FlashcardType.verseCompletion),
                  onTap: () => _openReview(type: FlashcardType.verseCompletion),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _categoryCard(
                  theme: theme,
                  icon: LucideIcons.search,
                  title: AppLocalizations.of(context)!.pracSurahDetective,
                  subtitle: 'من أي سورة؟',
                  dueCount: fc.getDueCountForType(FlashcardType.surahDetective),
                  onTap: () => _openReview(type: FlashcardType.surahDetective),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _categoryCard(
                  theme: theme,
                  icon: LucideIcons.link,
                  title: AppLocalizations.of(context)!.pracSequence,
                  subtitle: 'رتب الآيات',
                  dueCount: fc.getDueCountForType(FlashcardType.connectSequence),
                  onTap: () => _openReview(type: FlashcardType.connectSequence),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _categoryCard(
                  theme: theme,
                  icon: LucideIcons.swords,
                  title: AppLocalizations.of(context)!.pracMutashabihat,
                  subtitle: AppLocalizations.of(context)!.pracMutArabic,
                  dueCount: fc.getDueCountForType(FlashcardType.mutashabihatDuel),
                  onTap: () => _openReview(type: FlashcardType.mutashabihatDuel),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _browseMutashabihatCard(theme),
      ],
    );
  }

  Widget _categoryCard({
    required ThemeProvider theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required int dueCount,
    required VoidCallback onTap,
  }) {
    final hasDue = dueCount > 0;
    final iconBg = theme.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(theme.radiusXl),
      child: InkWell(
        onTap: hasDue ? onTap : null,
        borderRadius: BorderRadius.circular(theme.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(theme.radiusXl),
            border: Border.all(color: theme.dividerColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon + badge
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(theme.radiusLg + 2),
                    ),
                    child: Center(child: Icon(icon, size: 16, color: theme.secondaryText)),
                  ),
                  const Spacer(),
                  if (hasDue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: theme.isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(theme.radiusLg),
                      ),
                      child: Text(
                        '$dueCount',
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.secondaryText,
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
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: hasDue ? theme.primaryText : theme.secondaryText,
                ),
              ),
              const SizedBox(height: 2),

              // Subtitle — Arabic text with Arabic font
              Text(
                subtitle,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(
                  fontSize: 12,
                  color: theme.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _browseMutashabihatCard(ThemeProvider theme) {
    final iconBg = theme.isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusXl),
        boxShadow: theme.shadowCard,
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
                  color: iconBg,
                  borderRadius: BorderRadius.circular(theme.radiusLg + 2),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.bookOpen,
                    size: 16,
                    color: theme.secondaryText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.pracMutSimilar,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.pracBrowseStudy,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
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
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(theme.radiusLg + 2),
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MutashabihatScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(theme.radiusLg + 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(theme.radiusLg + 2),
                        border: Border.all(color: theme.dividerColor, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.pracBrowse,
                          style: TextStyle(
                            fontFamily: GeistTypography.primaryFontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: theme.foregroundColor,
                  borderRadius: BorderRadius.circular(theme.radiusLg + 2),
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MutashabihatPracticeScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(theme.radiusLg + 2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.pracPractice,
                          style: TextStyle(
                            fontFamily: GeistTypography.primaryFontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.scaffoldBackground,
                          ),
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
        _statChip(
          theme,
          '${fc.totalCards}',
          AppLocalizations.of(context)!.pracTotalCards,
        ),
        const SizedBox(width: 10),
        _statChip(
          theme,
          '${fc.accuracyPercent}%',
          AppLocalizations.of(context)!.pracAccuracy,
        ),
      ],
    );
  }

  Widget _statChip(ThemeProvider theme, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(theme.radiusXl),
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.primaryText,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
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
        borderRadius: BorderRadius.circular(theme.radiusXl),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.layers, size: 32, color: theme.mutedText),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.pracCreateProfileUnlock,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
