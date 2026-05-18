import 'package:quran_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/flashcard_models.dart';
import 'package:quran_app/providers/flashcard_provider.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/semantic_colors.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/widgets/geist_button.dart';

/// Full-screen flashcard review with actual Arabic verse text.
class FlashcardReviewScreen extends StatefulWidget {
  /// If null, shows all types (mixed). If set, filters to that type only.
  final FlashcardType? filterType;

  const FlashcardReviewScreen({super.key, this.filterType});

  @override
  State<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final profile = context.read<HifzProfileProvider>();
      final fc = context.read<FlashcardProvider>();

      if (!profile.hasActiveProfile || fc.totalCards == 0) {
        // Sandbox mode
        await fc.loadPlayfulCards(profile.activeProfile?.id ?? 'sandbox', widget.filterType);
      } else {
        // Normal mode
        if (widget.filterType != null) {
          await fc.loadDueCardsByType(profile.activeProfile!.id, widget.filterType);
        } else {
          await fc.loadDueCards(profile.activeProfile!.id, generate: false);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final fc = context.watch<FlashcardProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: fc.isLoading
            ? Center(child: CircularProgressIndicator(color: theme.accentColor))
            : fc.isSessionComplete
            ? _buildSummary(theme, fc)
            : fc.hasCards
            ? _buildCardView(theme, fc)
            : _buildNoCards(theme),
      ),
    );
  }

  // ════════════════════════════════
  // CARD VIEW
  // ════════════════════════════════

  Widget _buildCardView(ThemeProvider theme, FlashcardProvider fc) {
    final card = fc.currentCard!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Top bar
          Row(
            children: [
              GeistButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(LucideIcons.x, size: 18, color: theme.primaryText),
                type: GeistButtonType.secondary,
              ),
              const Spacer(),
              Text(
                fc.isSandbox 
                    ? '${fc.currentIndex + 1} / ${fc.dueCards.length}  |  Sandbox Mode 🎲'
                    : '${fc.currentIndex + 1} / ${fc.dueCards.length}',
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (fc.currentIndex + 1) / fc.dueCards.length,
              backgroundColor: theme.dividerColor,
              valueColor: AlwaysStoppedAnimation(theme.accentColor),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 16),

          // Card type badge
          _buildCardTypeBadge(theme, card.type),
          const Spacer(),

          // Card content — switches based on card type
          _buildCardContent(theme, fc, card),

          const Spacer(),

          // Rating buttons (visible only when revealed)
          if (fc.isRevealed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ratingButton(
                  theme,
                  fc,
                  LucideIcons.x,
                  'Forgot',
                  FlashcardRating.forgot,
                  SemanticColors.ratingForgot,
                ),
                _ratingButton(
                  theme,
                  fc,
                  LucideIcons.frown,
                  'Weak',
                  FlashcardRating.weak,
                  SemanticColors.ratingWeak,
                ),
                _ratingButton(
                  theme,
                  fc,
                  LucideIcons.minus,
                  'OK',
                  FlashcardRating.ok,
                  SemanticColors.ratingOk,
                ),
                _ratingButton(
                  theme,
                  fc,
                  LucideIcons.check,
                  'Strong',
                  FlashcardRating.strong,
                  SemanticColors.ratingStrong,
                ),
              ],
            )
          else
            GeistButton(
              onPressed: () => fc.skip(),
              label: '${AppLocalizations.of(context)!.actionSkip} →',
              type: GeistButtonType.tertiary,
              size: GeistButtonSize.small,
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCardContent(
    ThemeProvider theme,
    FlashcardProvider fc,
    Flashcard card,
  ) {
    switch (card.type) {
      case FlashcardType.nextVerse:
        return _buildNextVerseCard(theme, fc, card);
      case FlashcardType.surahDetective:
        return _buildSurahDetectiveCard(theme, fc, card);
      case FlashcardType.mutashabihatDuel:
        return _buildMutashabihatCard(theme, fc, card);
      case FlashcardType.verseCompletion:
        return _buildVerseCompletionCard(theme, fc, card);
      case FlashcardType.previousVerse:
        return _buildPreviousVerseCard(theme, fc, card);
      case FlashcardType.connectSequence:
        return _ConnectSequenceCard(
          theme: theme,
          fc: fc,
          card: card,
          verseWithMarker: _verseWithMarker,
          referenceBadge: _referenceBadge,
          cardDecoration: _cardDecoration,
        );
    }
  }

  // ── Next Verse Card ──

  Widget _buildNextVerseCard(
    ThemeProvider theme,
    FlashcardProvider fc,
    Flashcard card,
  ) {
    final questionVerse = card.questionData['verseText'] as String? ?? '';
    final surahName = card.questionData['surahName'] as String? ?? '';
    final surah = card.questionData['surah'];
    final verse = card.questionData['verse'];
    final page = card.questionData['page'];
    final answerVerse = card.answerData['verseText'] as String? ?? '';
    final answerVNum = card.answerData['verse'];

    return GestureDetector(
      onTap: () => fc.isRevealed ? null : fc.reveal(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(minHeight: 200),
        decoration: _cardDecoration(theme),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Reference badge with page number
            _referenceBadge(theme, '$surahName  ($surah:$verse) · p.$page'),
            const SizedBox(height: 16),

            // Question verse in Arabic
            _verseWithMarker(
              theme,
              questionVerse,
              verse is int ? verse : 0,
              theme.primaryText,
            ),
            const SizedBox(height: 16),

            // Instruction
            Text(
              'ما الآية التالية؟',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
            const SizedBox(height: 16),

            // Answer or reveal prompt
            if (!fc.isRevealed)
              _revealPrompt(theme)
            else
              Column(
                children: [
                  Container(width: 60, height: 1, color: theme.dividerColor),
                  const SizedBox(height: 16),
                  _referenceBadge(theme, '$surahName  ($surah:$answerVNum)'),
                  const SizedBox(height: 12),
                  _verseWithMarker(
                    theme,
                    answerVerse,
                    answerVNum is int ? answerVNum : 0,
                    Colors.green.shade700,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Surah Detective Card ──

  Widget _buildSurahDetectiveCard(
    ThemeProvider theme,
    FlashcardProvider fc,
    Flashcard card,
  ) {
    final verseText = card.questionData['verseText'] as String? ?? '';
    final surahName = card.answerData['surahName'] as String? ?? '';
    final surahNameEn = card.answerData['surahNameEn'] as String? ?? '';
    final surahNum = card.answerData['surahNumber'];
    final verseNum = card.questionData['verse'];

    return GestureDetector(
      onTap: () => fc.isRevealed ? null : fc.reveal(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(minHeight: 200),
        decoration: _cardDecoration(theme),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Instruction
            Text(
              'من أي سورة هذه الآية؟',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
            const SizedBox(height: 16),

            // Verse text
            _verseWithMarker(
              theme,
              verseText,
              verseNum is int ? verseNum : 0,
              theme.primaryText,
            ),
            const SizedBox(height: 20),

            // Answer or reveal
            if (!fc.isRevealed)
              _revealPrompt(theme)
            else
              Column(
                children: [
                  Container(width: 60, height: 1, color: theme.dividerColor),
                  const SizedBox(height: 16),
                  Text(
                    'سورة $surahName',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$surahNameEn · Verse $verseNum (Surah $surahNum)',
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Mutashabihat Card ──

  Widget _buildMutashabihatCard(
    ThemeProvider theme,
    FlashcardProvider fc,
    Flashcard card,
  ) {
    final sourceText = card.questionData['sourceText'] as String? ?? '';
    final similarText = card.questionData['similarText'] as String? ?? '';
    final sourceKey = card.questionData['sourceVerseKey'] as String? ?? '';
    final similarKey = card.questionData['similarVerseKey'] as String? ?? '';

    return GestureDetector(
      onTap: () => fc.isRevealed ? null : fc.reveal(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(minHeight: 200),
        decoration: _cardDecoration(theme),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'أي الآيتين من السورة الصحيحة؟',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
            const SizedBox(height: 16),

            // Source verse
            _verseBubble(
              theme,
              sourceText,
              sourceKey,
              fc.isRevealed ? Colors.green.shade50 : null,
              fc.isRevealed ? Colors.green.shade700 : null,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.actionVs,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.mutedText,
              ),
            ),
            const SizedBox(height: 12),

            // Similar verse
            _verseBubble(
              theme,
              similarText,
              similarKey,
              fc.isRevealed ? Colors.red.shade50 : null,
              fc.isRevealed ? Colors.red.shade700 : null,
            ),

            if (!fc.isRevealed) ...[
              const SizedBox(height: 16),
              _revealPrompt(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _verseBubble(
    ThemeProvider theme,
    String text,
    String key,
    Color? bgColor,
    Color? textColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor ?? theme.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor?.withValues(alpha: 0.3) ?? theme.dividerColor,
        ),
      ),
      child: Column(
        children: [
          _verseWithMarker(
            theme,
            text,
            _extractVerseNum(key),
            textColor ?? theme.primaryText,
            fontSize: 18,
          ),
          const SizedBox(height: 6),
          Text(
            key,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 10,
              color: theme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Verse Completion Card ──

  Widget _buildVerseCompletionCard(
    ThemeProvider theme,
    FlashcardProvider fc,
    Flashcard card,
  ) {
    final blankedText = card.questionData['blankedText'] as String? ?? '';
    final surahName = card.questionData['surahName'] as String? ?? '';
    final surah = card.questionData['surah'];
    final verse = card.questionData['verse'];
    final page = card.questionData['page'];
    final fullVerse = card.answerData['verseText'] as String? ?? '';

    return GestureDetector(
      onTap: () => fc.isRevealed ? null : fc.reveal(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(minHeight: 200),
        decoration: _cardDecoration(theme),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _referenceBadge(theme, '$surahName  ($surah:$verse) · p.$page'),
            const SizedBox(height: 16),

            // Instruction
            Text(
              '\u0623\u0643\u0645\u0644 \u0627\u0644\u0622\u064a\u0629',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
            const SizedBox(height: 16),

            // Blanked verse text
            ExcludeSemantics(
              child: Text(
                blankedText,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: AppLocalizations.of(context)!.pracHafsScript,
                  fontSize: 22,
                  height: 2.0,
                  color: theme.primaryText,
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (!fc.isRevealed)
              _revealPrompt(theme)
            else
              Column(
                children: [
                  Container(width: 60, height: 1, color: theme.dividerColor),
                  const SizedBox(height: 16),
                  _verseWithMarker(
                    theme,
                    fullVerse,
                    verse is int ? verse : 0,
                    Colors.green.shade700,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Previous Verse Card ──

  Widget _buildPreviousVerseCard(
    ThemeProvider theme,
    FlashcardProvider fc,
    Flashcard card,
  ) {
    final questionVerse = card.questionData['verseText'] as String? ?? '';
    final surahName = card.questionData['surahName'] as String? ?? '';
    final surah = card.questionData['surah'];
    final verse = card.questionData['verse'];
    final page = card.questionData['page'];
    final answerVerse = card.answerData['verseText'] as String? ?? '';
    final answerVNum = card.answerData['verse'];

    return GestureDetector(
      onTap: () => fc.isRevealed ? null : fc.reveal(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(minHeight: 200),
        decoration: _cardDecoration(theme),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _referenceBadge(theme, '$surahName  ($surah:$verse) · p.$page'),
            const SizedBox(height: 16),

            // Question verse
            _verseWithMarker(
              theme,
              questionVerse,
              verse is int ? verse : 0,
              theme.primaryText,
            ),
            const SizedBox(height: 16),

            // Instruction
            Text(
              '\u0645\u0627 \u0627\u0644\u0622\u064a\u0629 \u0627\u0644\u0633\u0627\u0628\u0642\u0629\u061f',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
            const SizedBox(height: 16),

            if (!fc.isRevealed)
              _revealPrompt(theme)
            else
              Column(
                children: [
                  Container(width: 60, height: 1, color: theme.dividerColor),
                  const SizedBox(height: 16),
                  _referenceBadge(theme, '$surahName  ($surah:$answerVNum)'),
                  const SizedBox(height: 12),
                  _verseWithMarker(
                    theme,
                    answerVerse,
                    answerVNum is int ? answerVNum : 0,
                    Colors.green.shade700,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Shared card elements ──

  BoxDecoration _cardDecoration(ThemeProvider theme) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: theme.shadowCardFull,
    );
  }

  /// Renders Arabic verse text followed by an inline decorative verse number marker.
  Widget _verseWithMarker(
    ThemeProvider theme,
    String verseText,
    int verseNum,
    Color textColor, {
    double fontSize = 22,
  }) {
    return ExcludeSemantics(
      child: RichText(
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        text: TextSpan(
          children: [
            TextSpan(
              text: verseText,
              style: TextStyle(
                fontFamily: AppLocalizations.of(context)!.pracHafsScript,
                fontSize: fontSize,
                height: 2.0,
                color: textColor,
              ),
            ),
            const TextSpan(text: ' '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _verseEndMarker(verseNum, textColor, fontSize * 0.75),
            ),
          ],
        ),
      ),
    );
  }

  /// Draws a decorative circular ornament with the verse number inside.
  Widget _verseEndMarker(int verseNumber, Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Center(
        child: Text(
          '$verseNumber',
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1,
          ),
        ),
      ),
    );
  }

  /// Extract verse number from a verse key like '81:22'
  int _extractVerseNum(String key) {
    final parts = key.split(':');
    if (parts.length == 2) return int.tryParse(parts[1]) ?? 0;
    return 0;
  }

  Widget _referenceBadge(ThemeProvider theme, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: GeistTypography.primaryFontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: theme.accentColor,
        ),
      ),
    );
  }

  Widget _revealPrompt(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Tap to reveal',
        style: TextStyle(
          fontFamily: GeistTypography.primaryFontFamily,
          fontSize: 13,
          color: theme.accentColor,
        ),
      ),
    );
  }

  Widget _ratingButton(
    ThemeProvider theme,
    FlashcardProvider fc,
    IconData icon,
    String label,
    FlashcardRating rating,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => fc.rate(rating),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Center(child: Icon(icon, size: 24, color: color)),
          ),
          const SizedBox(height: 4),
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
    );
  }

  // ════════════════════════════════
  // SESSION SUMMARY
  // ════════════════════════════════

  Widget _buildSummary(ThemeProvider theme, FlashcardProvider fc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.target, size: 56, color: theme.accentColor),
          const SizedBox(height: 16),
          Text(
            'Review Complete!',
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                _statRow(
                  theme,
                  LucideIcons.pencil,
                  'Cards reviewed',
                  '${fc.reviewedCount}',
                ),
                if (fc.strongCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _statRow(
                      theme,
                      LucideIcons.dumbbell,
                      'Strong',
                      '${fc.strongCount}',
                    ),
                  ),
                if (fc.okCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _statRow(
                      theme,
                      LucideIcons.helpCircle,
                      'OK',
                      '${fc.okCount}',
                    ),
                  ),
                if (fc.weakCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _statRow(
                      theme,
                      LucideIcons.alertCircle,
                      'Weak',
                      '${fc.weakCount}',
                    ),
                  ),
                if (fc.forgotCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _statRow(
                      theme,
                      LucideIcons.xCircle,
                      'Forgot',
                      '${fc.forgotCount}',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: GeistButton(
              onPressed: () => Navigator.of(context).pop(),
              label: 'Done',
              type: GeistButtonType.primary,
              size: GeistButtonSize.large,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(
    ThemeProvider theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.accentColor),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
      ],
    );
  }

  // ════════════════════════════════
  // NO CARDS VIEW
  // ════════════════════════════════

  Widget _buildNoCards(ThemeProvider theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.sparkles, size: 56, color: theme.accentColor),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No cards due right now.\nKeep memorizing and cards will appear!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 14,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 32),
            GeistButton(
              onPressed: () => Navigator.of(context).pop(),
              label: 'Back',
              type: GeistButtonType.primary,
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _buildCardTypeBadge(ThemeProvider theme, FlashcardType type) {
    IconData icon;
    String label;
    Color color;

    switch (type) {
      case FlashcardType.nextVerse:
        icon = LucideIcons.skipForward;
        label = 'Next Verse';
        color = SemanticColors.practiceBlue.fg(theme.isDark);
        break;
      case FlashcardType.surahDetective:
        icon = LucideIcons.search;
        label = 'Surah Detective';
        color = SemanticColors.practicePurple.fg(theme.isDark);
        break;
      case FlashcardType.mutashabihatDuel:
        icon = LucideIcons.swords;
        label = 'Mutashabihat Duel';
        color = SemanticColors.practiceRed.fg(theme.isDark);
        break;
      case FlashcardType.verseCompletion:
        icon = LucideIcons.pencil;
        label = 'Verse Completion';
        color = SemanticColors.practiceEmerald.fg(theme.isDark);
        break;
      case FlashcardType.previousVerse:
        icon = LucideIcons.skipBack;
        label = 'Previous Verse';
        color = SemanticColors.practiceCyan.fg(theme.isDark);
        break;
      case FlashcardType.connectSequence:
        icon = LucideIcons.link;
        label = 'Connect Sequence';
        color = SemanticColors.practiceAmber.fg(theme.isDark);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tap-to-order card for Connect Sequence flashcard type.
class _ConnectSequenceCard extends StatefulWidget {
  final ThemeProvider theme;
  final FlashcardProvider fc;
  final Flashcard card;
  final Widget Function(ThemeProvider, String, int, Color, {double fontSize})
  verseWithMarker;
  final Widget Function(ThemeProvider, String) referenceBadge;
  final BoxDecoration Function(ThemeProvider) cardDecoration;

  const _ConnectSequenceCard({
    required this.theme,
    required this.fc,
    required this.card,
    required this.verseWithMarker,
    required this.referenceBadge,
    required this.cardDecoration,
  });

  @override
  State<_ConnectSequenceCard> createState() => _ConnectSequenceCardState();
}

class _ConnectSequenceCardState extends State<_ConnectSequenceCard> {
  final List<int> _selectedOrder = []; // indices the user has tapped
  int? _wrongTap; // flash red momentarily

  @override
  void didUpdateWidget(covariant _ConnectSequenceCard old) {
    super.didUpdateWidget(old);
    if (old.card.id != widget.card.id) {
      _selectedOrder.clear();
      _wrongTap = null;
    }
  }

  void _onTapVerse(int shuffledIdx) {
    if (widget.fc.isRevealed) return;
    // The correct next original index to pick
    final verses = widget.card.questionData['verses'] as List<dynamic>;
    final shuffledIndices =
        (widget.card.questionData['shuffledIndices'] as List<dynamic>)
            .map((e) => (e as num).toInt())
            .toList();
    final displayIdx = shuffledIdx; // position in the displayed list
    final originalIdx = shuffledIndices[displayIdx];

    // Already selected?
    if (_selectedOrder.contains(displayIdx)) return;

    // Check if this is the correct next verse
    final expectedOriginalIdx = _selectedOrder.length; // 0, 1, 2
    if (originalIdx == expectedOriginalIdx) {
      setState(() {
        _selectedOrder.add(displayIdx);
        _wrongTap = null;
      });
      // If all selected, auto-reveal
      if (_selectedOrder.length == verses.length) {
        widget.fc.reveal();
      }
    } else {
      setState(() => _wrongTap = displayIdx);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _wrongTap = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final card = widget.card;
    final verses = card.questionData['verses'] as List<dynamic>;
    final shuffledIndices =
        (card.questionData['shuffledIndices'] as List<dynamic>)
            .map((e) => (e as num).toInt())
            .toList();
    final surahName = card.questionData['surahName'] as String? ?? '';
    final page = card.questionData['page'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      constraints: const BoxConstraints(minHeight: 200),
      decoration: widget.cardDecoration(theme),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.referenceBadge(theme, '$surahName · p.$page'),
          const SizedBox(height: 12),
          Text(
            '\u0631\u062a\u0628 \u0627\u0644\u0622\u064a\u0627\u062a',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.accentColor,
            ),
          ),
          const SizedBox(height: 12),
          // Render each verse in shuffled order
          for (int i = 0; i < shuffledIndices.length; i++) ...[
            _buildVerseTile(theme, i, shuffledIndices, verses),
            if (i < shuffledIndices.length - 1) const SizedBox(height: 8),
          ],
          if (widget.fc.isRevealed) ...[
            const SizedBox(height: 12),
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
            const SizedBox(height: 4),
            Text(
              'Correct order!',
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerseTile(
    ThemeProvider theme,
    int displayIdx,
    List<int> shuffledIndices,
    List<dynamic> verses,
  ) {
    final originalIdx = shuffledIndices[displayIdx];
    final verse = verses[originalIdx] as Map<String, dynamic>;
    final text = verse['text'] as String? ?? '';
    final isSelected = _selectedOrder.contains(displayIdx);
    final isWrong = _wrongTap == displayIdx;
    final orderNum = isSelected ? _selectedOrder.indexOf(displayIdx) + 1 : null;

    Color borderColor = theme.dividerColor;
    Color bgColor = Colors.transparent;
    if (isSelected) {
      borderColor = Colors.green.shade400;
      bgColor = Colors.green.withValues(alpha: 0.05);
    } else if (isWrong) {
      borderColor = Colors.red.shade400;
      bgColor = Colors.red.withValues(alpha: 0.05);
    }

    return GestureDetector(
      onTap: () => _onTapVerse(displayIdx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected || isWrong ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Order number or empty circle
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.green.shade400
                    : theme.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isSelected
                    ? Text(
                        '$orderNum',
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '?',
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.mutedText,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  text,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: AppLocalizations.of(context)!.pracHafsScript,
                    fontSize: 16,
                    height: 1.8,
                    color: isSelected
                        ? Colors.green.shade700
                        : theme.primaryText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
