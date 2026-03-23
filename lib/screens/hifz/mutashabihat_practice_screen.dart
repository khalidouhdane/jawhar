import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/flashcard_models.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran/quran.dart' as quran;

/// Practice modes for mutashabihat (similar verses).
/// Three modes: Spot the Difference, Context Anchoring, Quick Quiz.
class MutashabihatPracticeScreen extends StatefulWidget {
  const MutashabihatPracticeScreen({super.key});

  @override
  State<MutashabihatPracticeScreen> createState() =>
      _MutashabihatPracticeScreenState();
}

enum _PracticeMode { spotDiff, context, quiz }

class _MutashabihatPracticeScreenState
    extends State<MutashabihatPracticeScreen> {
  _PracticeMode _mode = _PracticeMode.spotDiff;
  List<MutashabihatGroup> _groups = [];
  bool _isLoading = true;
  int _currentIdx = 0;
  bool _isRevealed = false;
  int _correctCount = 0;
  int _totalAttempted = 0;

  // Quick Quiz state
  int? _quizChoice; // 0 = src, 1 = mut
  bool? _quizCorrect;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    final db = context.read<HifzDatabaseService>();
    final all = await db.getAllMutashabihat();
    // Prioritize "needsPractice", then "notStudied" — skip mastered
    final filtered = all
        .where((g) =>
            g.userStatus != MutashabihatStatus.mastered &&
            g.similarVerses.isNotEmpty)
        .toList()
      ..shuffle();
    if (mounted) {
      setState(() {
        _groups = filtered;
        _isLoading = false;
        _currentIdx = 0;
        _isRevealed = false;
      });
    }
  }

  void _next() {
    if (_currentIdx < _groups.length - 1) {
      setState(() {
        _currentIdx++;
        _isRevealed = false;
        _quizChoice = null;
        _quizCorrect = null;
      });
    } else {
      // Show summary
      setState(() => _currentIdx = _groups.length);
    }
  }

  String _getVerseText(String verseKey) {
    final parts = verseKey.split(':');
    if (parts.length != 2) return '';
    final surah = int.tryParse(parts[0]);
    final verse = int.tryParse(parts[1]);
    if (surah == null || verse == null) return '';
    try {
      return quran.getVerse(surah, verse);
    } catch (_) {
      return '';
    }
  }

  String _getSurahName(String verseKey) {
    final surah = int.tryParse(verseKey.split(':').first);
    if (surah == null) return '';
    return quran.getSurahNameArabic(surah);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mutashabihat Practice',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: theme.accentColor),
            )
          : _groups.isEmpty
              ? _buildEmpty(theme)
              : Column(
                  children: [
                    // Mode selector
                    _buildModeSelector(theme),
                    const SizedBox(height: 8),
                    // Progress
                    if (_currentIdx < _groups.length)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Text(
                              '${_currentIdx + 1} / ${_groups.length}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: theme.mutedText,
                              ),
                            ),
                            const Spacer(),
                            if (_totalAttempted > 0)
                              Text(
                                '$_correctCount/$_totalAttempted correct',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Content
                    Expanded(
                      child: _currentIdx >= _groups.length
                          ? _buildSummary(theme)
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              child: _buildCurrentCard(theme),
                            ),
                    ),
                  ],
                ),
    );
  }

  // ═══════════════════════════════════
  // MODE SELECTOR
  // ═══════════════════════════════════

  Widget _buildModeSelector(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _modeChip(theme, _PracticeMode.spotDiff, '🔎', 'Spot Diff'),
          const SizedBox(width: 8),
          _modeChip(theme, _PracticeMode.context, '🔗', 'Context'),
          const SizedBox(width: 8),
          _modeChip(theme, _PracticeMode.quiz, '📋', 'Quiz'),
        ],
      ),
    );
  }

  Widget _modeChip(
      ThemeProvider theme, _PracticeMode mode, String emoji, String label) {
    final isActive = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _mode = mode;
            _currentIdx = 0;
            _isRevealed = false;
            _correctCount = 0;
            _totalAttempted = 0;
            _quizChoice = null;
            _quizCorrect = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? theme.accentColor
                : theme.accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '$emoji $label',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : theme.secondaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════
  // CARD ROUTER
  // ═══════════════════════════════════

  Widget _buildCurrentCard(ThemeProvider theme) {
    final group = _groups[_currentIdx];
    switch (_mode) {
      case _PracticeMode.spotDiff:
        return _buildSpotDiffCard(theme, group);
      case _PracticeMode.context:
        return _buildContextCard(theme, group);
      case _PracticeMode.quiz:
        return _buildQuizCard(theme, group);
    }
  }

  // ═══════════════════════════════════
  // SPOT THE DIFFERENCE
  // ═══════════════════════════════════

  Widget _buildSpotDiffCard(ThemeProvider theme, MutashabihatGroup group) {
    final srcText = group.sourceText.isNotEmpty
        ? group.sourceText
        : _getVerseText(group.sourceVerseKey);
    final mutVerse = group.similarVerses.first;
    final mutText =
        mutVerse.text.isNotEmpty ? mutVerse.text : _getVerseText(mutVerse.verseKey);
    final srcName = _getSurahName(group.sourceVerseKey);
    final mutName = _getSurahName(mutVerse.verseKey);
    final srcWords = group.uniqueWords['src'] ?? [];
    final mutWords = group.uniqueWords['mut'] ?? [];

    return Column(
      children: [
        // Source verse
        _verseBlock(
          theme,
          label: '$srcName (${group.sourceVerseKey})',
          text: srcText,
          highlightWords: srcWords,
          highlightColor: const Color(0xFF3B82F6),
          hidden: false,
        ),
        const SizedBox(height: 12),
        // Similar verse (hidden until revealed)
        _verseBlock(
          theme,
          label: '$mutName (${mutVerse.verseKey})',
          text: mutText,
          highlightWords: mutWords,
          highlightColor: const Color(0xFFF59E0B),
          hidden: !_isRevealed,
        ),
        const SizedBox(height: 16),
        if (!_isRevealed)
          _actionButton(theme, 'Tap to reveal similar verse', () {
            setState(() {
              _isRevealed = true;
              _totalAttempted++;
            });
          })
        else
          Column(
            children: [
              if (srcWords.isNotEmpty || mutWords.isNotEmpty)
                _diffSummary(theme, srcWords, mutWords, srcName, mutName),
              const SizedBox(height: 12),
              _nextButton(theme),
            ],
          ),
      ],
    );
  }

  Widget _diffSummary(ThemeProvider theme, List<String> srcWords,
      List<String> mutWords, String srcName, String mutName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'الفرق',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.accentColor,
            ),
          ),
          const SizedBox(height: 6),
          if (srcWords.isNotEmpty)
            Text(
              '$srcName: ${srcWords.join(' · ')}',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          if (mutWords.isNotEmpty)
            Text(
              '$mutName: ${mutWords.join(' · ')}',
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: const Color(0xFFF59E0B),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════
  // CONTEXT ANCHORING
  // ═══════════════════════════════════

  Widget _buildContextCard(ThemeProvider theme, MutashabihatGroup group) {
    final mutVerse = group.similarVerses.first;
    final mutParts = mutVerse.verseKey.split(':');
    final mutSurah = int.tryParse(mutParts.first) ?? 1;
    final mutAyah = int.tryParse(mutParts.last) ?? 1;
    final mutSurahName = quran.getSurahNameArabic(mutSurah);
    final totalVerses = quran.getVerseCount(mutSurah);

    // Get 2 before and 2 after
    final contextVerses = <MapEntry<int, String>>[];
    for (int v = (mutAyah - 2).clamp(1, totalVerses);
        v <= (mutAyah + 2).clamp(1, totalVerses);
        v++) {
      try {
        contextVerses.add(MapEntry(v, quran.getVerse(mutSurah, v)));
      } catch (_) {}
    }

    // Source verse for comparison
    final srcText = group.sourceText.isNotEmpty
        ? group.sourceText
        : _getVerseText(group.sourceVerseKey);
    final srcName = _getSurahName(group.sourceVerseKey);

    return Column(
      children: [
        // Title
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'اقرأ الآيات في سياقها',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.accentColor,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Context verses
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            children: [
              Text(
                '$mutSurahName',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.accentColor,
                ),
              ),
              const SizedBox(height: 12),
              for (final entry in contextVerses) ...[
                ExcludeSemantics(
                  child: Text(
                    entry.value,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'KFGQPC Uthmanic Script HAFS',
                      fontSize: 18,
                      height: 2.0,
                      color: entry.key == mutAyah
                          ? const Color(0xFFF59E0B)
                          : theme.primaryText,
                      fontWeight: entry.key == mutAyah
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Compare with source
        if (!_isRevealed)
          _actionButton(theme, 'Show original verse from $srcName', () {
            setState(() {
              _isRevealed = true;
              _totalAttempted++;
              _correctCount++;
            });
          })
        else
          Column(
            children: [
              _verseBlock(
                theme,
                label: '$srcName (${group.sourceVerseKey})',
                text: srcText,
                highlightWords: group.uniqueWords['src'] ?? [],
                highlightColor: const Color(0xFF3B82F6),
                hidden: false,
              ),
              const SizedBox(height: 12),
              _nextButton(theme),
            ],
          ),
      ],
    );
  }

  // ═══════════════════════════════════
  // QUICK QUIZ
  // ═══════════════════════════════════

  Widget _buildQuizCard(ThemeProvider theme, MutashabihatGroup group) {
    final srcWords = group.uniqueWords['src'] ?? [];
    final mutWords = group.uniqueWords['mut'] ?? [];
    final srcName = _getSurahName(group.sourceVerseKey);
    final mutVerse = group.similarVerses.first;
    final mutName = _getSurahName(mutVerse.verseKey);

    if (srcWords.isEmpty && mutWords.isEmpty) {
      // No unique words — skip
      return Column(
        children: [
          Text(
            'No distinguishing words available for this pair.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          _nextButton(theme),
        ],
      );
    }

    // Pick the first unique word from src as the quiz target
    final quizWord = srcWords.isNotEmpty ? srcWords.first : mutWords.first;
    final correctSurah = srcWords.isNotEmpty ? srcName : mutName;

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
          // Question
          Text(
            'في أي سورة الكلمة:',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          // The word
          ExcludeSemantics(
            child: Text(
              quizWord,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'KFGQPC Uthmanic Script HAFS',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: theme.accentColor,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Choices
          _quizOption(theme, 0, srcName, correctSurah == srcName),
          const SizedBox(height: 10),
          _quizOption(theme, 1, mutName, correctSurah == mutName),

          const SizedBox(height: 16),

          // Fill-in details after choice
          if (_quizChoice != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_quizCorrect == true
                        ? Colors.green
                        : Colors.red)
                    .withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _quizCorrect == true ? '✅ صحيح!' : '❌ خطأ',
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _quizCorrect == true
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (srcWords.isNotEmpty)
                    Text(
                      '$srcName: ${srcWords.join(' · ')}',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: theme.secondaryText,
                      ),
                    ),
                  if (mutWords.isNotEmpty)
                    Text(
                      '$mutName: ${mutWords.join(' · ')}',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: theme.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _nextButton(theme),
          ],
        ],
      ),
    );
  }

  Widget _quizOption(
      ThemeProvider theme, int idx, String surahName, bool isCorrect) {
    final isSelected = _quizChoice == idx;
    Color bgColor = theme.cardColor;
    Color borderColor = theme.dividerColor;
    if (isSelected && _quizCorrect == true) {
      bgColor = Colors.green.withValues(alpha: 0.1);
      borderColor = Colors.green.shade400;
    } else if (isSelected && _quizCorrect == false) {
      bgColor = Colors.red.withValues(alpha: 0.1);
      borderColor = Colors.red.shade400;
    } else if (_quizChoice != null && isCorrect) {
      // Highlight the correct answer after wrong choice
      bgColor = Colors.green.withValues(alpha: 0.05);
      borderColor = Colors.green.shade300;
    }

    return GestureDetector(
      onTap: _quizChoice != null
          ? null
          : () {
              setState(() {
                _quizChoice = idx;
                _quizCorrect = isCorrect;
                _totalAttempted++;
                if (isCorrect) _correctCount++;
              });
            },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          surahName,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════

  Widget _verseBlock(
    ThemeProvider theme, {
    required String label,
    required String text,
    required List<String> highlightWords,
    required Color highlightColor,
    required bool hidden,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hidden ? theme.dividerColor : highlightColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: highlightColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: highlightColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Verse text
          ExcludeSemantics(
            child: hidden
                ? Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '؟',
                        style: TextStyle(
                          fontSize: 24,
                          color: theme.mutedText,
                        ),
                      ),
                    ),
                  )
                : _buildHighlightedText(
                    theme, text, highlightWords, highlightColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(ThemeProvider theme, String text,
      List<String> highlightWords, Color color) {
    if (highlightWords.isEmpty) {
      return Text(
        text,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'KFGQPC Uthmanic Script HAFS',
          fontSize: 18,
          height: 2.0,
          color: theme.primaryText,
        ),
      );
    }

    // Build rich text with highlighted words
    final words = text.split(' ');
    final spans = <TextSpan>[];
    for (int i = 0; i < words.length; i++) {
      final w = words[i];
      final isHighlight =
          highlightWords.any((hw) => w.contains(hw) || hw.contains(w));
      spans.add(TextSpan(
        text: i > 0 ? ' $w' : w,
        style: TextStyle(
          fontFamily: 'KFGQPC Uthmanic Script HAFS',
          fontSize: 18,
          height: 2.0,
          color: isHighlight ? color : theme.primaryText,
          fontWeight: isHighlight ? FontWeight.w700 : FontWeight.normal,
          backgroundColor:
              isHighlight ? color.withValues(alpha: 0.1) : null,
        ),
      ));
    }

    return RichText(
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      text: TextSpan(children: spans),
    );
  }

  Widget _actionButton(ThemeProvider theme, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.accentColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.accentColor,
          ),
        ),
      ),
    );
  }

  Widget _nextButton(ThemeProvider theme) {
    return GestureDetector(
      onTap: _next,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.accentColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Next →',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Practice Complete!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_correctCount / $_totalAttempted correct',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                color: theme.accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Done',
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
    );
  }

  Widget _buildEmpty(ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📿', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'No mutashabihat loaded yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your connection and try again.',
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
