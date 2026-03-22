import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/flashcard_models.dart';
import 'package:quran_app/providers/flashcard_provider.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<HifzProfileProvider>();
      if (profile.hasActiveProfile) {
        final fc = context.read<FlashcardProvider>();
        if (widget.filterType != null) {
          fc.loadDueCardsByType(
              profile.activeProfile!.id, widget.filterType);
        } else {
          fc.loadDueCards(profile.activeProfile!.id, generate: false);
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
            ? Center(
                child: CircularProgressIndicator(color: theme.accentColor))
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
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child:
                      Icon(LucideIcons.x, size: 18, color: theme.primaryText),
                ),
              ),
              const Spacer(),
              Text(
                '${fc.currentIndex + 1} / ${fc.dueCards.length}',
                style: TextStyle(
                  fontFamily: 'Inter',
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _cardTypeLabel(card.type),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
          ),
          const Spacer(),

          // Card content — switches based on card type
          _buildCardContent(theme, fc, card),

          const Spacer(),

          // Rating buttons (visible only when revealed)
          if (fc.isRevealed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ratingButton(theme, fc, '❌', 'Forgot',
                    FlashcardRating.forgot, Colors.red.shade400),
                _ratingButton(theme, fc, '😬', 'Weak',
                    FlashcardRating.weak, Colors.orange.shade400),
                _ratingButton(theme, fc, '🤔', 'OK', FlashcardRating.ok,
                    Colors.blue.shade400),
                _ratingButton(theme, fc, '💪', 'Strong',
                    FlashcardRating.strong, Colors.green.shade400),
              ],
            )
          else
            GestureDetector(
              onTap: () => fc.skip(),
              child: Text('Skip →',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: theme.mutedText)),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCardContent(
      ThemeProvider theme, FlashcardProvider fc, Flashcard card) {
    switch (card.type) {
      case FlashcardType.nextVerse:
        return _buildNextVerseCard(theme, fc, card);
      case FlashcardType.surahDetective:
        return _buildSurahDetectiveCard(theme, fc, card);
      case FlashcardType.mutashabihatDuel:
        return _buildMutashabihatCard(theme, fc, card);
      default:
        return _buildGenericCard(theme, fc, card);
    }
  }

  // ── Next Verse Card ──

  Widget _buildNextVerseCard(
      ThemeProvider theme, FlashcardProvider fc, Flashcard card) {
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
            _verseWithMarker(theme, questionVerse, verse is int ? verse : 0, theme.primaryText),
            const SizedBox(height: 16),

            // Instruction
            Text(
              'ما الآية التالية؟',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Inter',
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
                  Container(
                      width: 60,
                      height: 1,
                      color: theme.dividerColor),
                  const SizedBox(height: 16),
                  _referenceBadge(
                      theme, '$surahName  ($surah:$answerVNum)'),
                  const SizedBox(height: 12),
                  _verseWithMarker(theme, answerVerse, answerVNum is int ? answerVNum : 0, Colors.green.shade700),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ── Surah Detective Card ──

  Widget _buildSurahDetectiveCard(
      ThemeProvider theme, FlashcardProvider fc, Flashcard card) {
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
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
            const SizedBox(height: 16),

            // Verse text
            _verseWithMarker(theme, verseText, verseNum is int ? verseNum : 0, theme.primaryText),
            const SizedBox(height: 20),

            // Answer or reveal
            if (!fc.isRevealed)
              _revealPrompt(theme)
            else
              Column(
                children: [
                  Container(
                      width: 60,
                      height: 1,
                      color: theme.dividerColor),
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
                      fontFamily: 'Inter',
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
      ThemeProvider theme, FlashcardProvider fc, Flashcard card) {
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
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.accentColor,
              ),
            ),
            const SizedBox(height: 16),

            // Source verse
            _verseBubble(theme, sourceText, sourceKey,
                fc.isRevealed ? Colors.green.shade50 : null,
                fc.isRevealed ? Colors.green.shade700 : null),
            const SizedBox(height: 12),
            Text('VS',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.mutedText)),
            const SizedBox(height: 12),

            // Similar verse
            _verseBubble(theme, similarText, similarKey,
                fc.isRevealed ? Colors.red.shade50 : null,
                fc.isRevealed ? Colors.red.shade700 : null),

            if (!fc.isRevealed) ...[
              const SizedBox(height: 16),
              _revealPrompt(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _verseBubble(ThemeProvider theme, String text, String key,
      Color? bgColor, Color? textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor ?? theme.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: textColor?.withValues(alpha: 0.3) ?? theme.dividerColor),
      ),
      child: Column(
        children: [
          _verseWithMarker(theme, text, _extractVerseNum(key), textColor ?? theme.primaryText, fontSize: 18),
          const SizedBox(height: 6),
          Text(
            key,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: theme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  // ── Generic fallback ──

  Widget _buildGenericCard(
      ThemeProvider theme, FlashcardProvider fc, Flashcard card) {
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
            Text(
              card.questionData['instruction'] ?? 'Review',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Inter', fontSize: 14, color: theme.mutedText),
            ),
            const SizedBox(height: 16),
            Text(
              card.verseKey,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            if (!fc.isRevealed) _revealPrompt(theme),
            if (fc.isRevealed)
              Icon(LucideIcons.check, color: theme.accentColor, size: 28),
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
      border: Border.all(color: theme.dividerColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Renders Arabic verse text followed by an inline decorative verse number marker.
  Widget _verseWithMarker(ThemeProvider theme, String verseText, int verseNum, Color textColor, {double fontSize = 22}) {
    return ExcludeSemantics(
      child: RichText(
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        text: TextSpan(
          children: [
            TextSpan(
              text: verseText,
              style: TextStyle(
                fontFamily: 'KFGQPC Uthmanic Script HAFS',
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
            fontFamily: 'Inter',
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
          fontFamily: 'Inter',
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
            fontFamily: 'Inter', fontSize: 13, color: theme.accentColor),
      ),
    );
  }

  Widget _ratingButton(ThemeProvider theme, FlashcardProvider fc, String emoji,
      String label, FlashcardRating rating, Color color) {
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
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(height: 4),
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
          const Text('🎯', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'Review Complete!',
            style: TextStyle(
              fontFamily: 'Inter',
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
                    theme, '📝', 'Cards reviewed', '${fc.reviewedCount}'),
                if (fc.strongCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child:
                        _statRow(theme, '💪', 'Strong', '${fc.strongCount}'),
                  ),
                if (fc.okCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _statRow(theme, '🤔', 'OK', '${fc.okCount}'),
                  ),
                if (fc.weakCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _statRow(theme, '😬', 'Weak', '${fc.weakCount}'),
                  ),
                if (fc.forgotCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child:
                        _statRow(theme, '❌', 'Forgot', '${fc.forgotCount}'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: theme.accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Done',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(
      ThemeProvider theme, String emoji, String label, String value) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: theme.secondaryText,
              )),
        ),
        Text(value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.primaryText,
            )),
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
            const Text('✨', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: TextStyle(
                fontFamily: 'Inter',
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
                fontFamily: 'Inter',
                fontSize: 14,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  String _cardTypeLabel(FlashcardType type) {
    switch (type) {
      case FlashcardType.nextVerse:
        return '⏭️ Next Verse';
      case FlashcardType.surahDetective:
        return '🔍 Surah Detective';
      case FlashcardType.mutashabihatDuel:
        return '⚔️ Mutashabihat Duel';
      case FlashcardType.verseCompletion:
        return '📝 Verse Completion';
      case FlashcardType.previousVerse:
        return '⏮️ Previous Verse';
      case FlashcardType.connectSequence:
        return '🔗 Connect Sequence';
    }
  }
}
