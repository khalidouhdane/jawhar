import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/widgets/context/tafsir_sheet.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/utils/verse_ref_formatter.dart';

class ReadingCanvas extends StatefulWidget {
  final List<Verse> verses;
  final int pageNumber;
  final int? selectedVerseId;
  final ValueChanged<int?> onVerseSelected;
  final VoidCallback onCanvasTapped;
  final ValueChanged<String>? onTranslateVerse;

  const ReadingCanvas({
    super.key,
    required this.verses,
    required this.pageNumber,
    required this.selectedVerseId,
    required this.onVerseSelected,
    required this.onCanvasTapped,
    this.onTranslateVerse,
  });

  @override
  State<ReadingCanvas> createState() => ReadingCanvasState();
}

class ReadingCanvasState extends State<ReadingCanvas> {
  final Map<int, GlobalKey> _verseKeys = {};
  OverlayEntry? _menuOverlay;

  /// Tracks gesture recognizers so they can be disposed to prevent memory leaks.
  final List<GestureRecognizer> _recognizers = [];

  /// Returns the RenderBox of a verse marker, or null if not found.
  /// Used by ScrollableReadingCanvas for accurate verse-level center lock.
  RenderBox? getVerseRenderBox(int verseId) {
    final key = _verseKeys[verseId];
    if (key?.currentContext == null) return null;
    final renderBox = key!.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return null;
    return renderBox;
  }

  /// Dispose all tracked gesture recognizers to free native resources.
  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _removeOverlay();
    _disposeRecognizers();
    super.dispose();
  }

  @override
  void didUpdateWidget(ReadingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedVerseId != oldWidget.selectedVerseId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _removeOverlay();
        if (widget.selectedVerseId != null) {
          _showMenuOverlay();
        }
      });
    }
  }

  void _removeOverlay() {
    _menuOverlay?.remove();
    _menuOverlay?.dispose();
    _menuOverlay = null;
  }

  void _showMenuOverlay() {
    final verseId = widget.selectedVerseId;
    if (verseId == null) return;

    final key = _verseKeys[verseId];
    if (key == null || key.currentContext == null) return;

    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final verse = widget.verses.firstWhere((v) => v.id == verseId);

    _menuOverlay = OverlayEntry(
      builder: (context) {
        final menuTop = position.dy - 50;
        return Positioned(
          top: menuTop < 10 ? position.dy + size.height + 10 : menuTop,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: _ContextualMenu(
                verse: verse,
                verses: widget.verses,
                pageNumber: widget.pageNumber,
                onDismiss: () {
                  widget.onVerseSelected(null);
                },
                onTranslateVerse: widget.onTranslateVerse,
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    Overlay.of(context).insert(_menuOverlay!);
  }

  GlobalKey _getKeyForVerse(int verseId) {
    return _verseKeys.putIfAbsent(verseId, () => GlobalKey());
  }

  void _toggleVerseSelection(int verseId) {
    widget.onVerseSelected(widget.selectedVerseId == verseId ? null : verseId);
  }

  List<InlineSpan> _buildSpans(
    ThemeProvider theme,
    String? activeVerseKey,
    QuranReadingProvider readingProvider,
    double fontSize,
  ) {
    // Dispose previous recognizers before creating new ones to prevent leaks.
    _disposeRecognizers();
    final spans = <InlineSpan>[];
    final isWarsh = readingProvider.selectedRewaya == 2;

    for (final verse in widget.verses) {
      if (verse.verseNumber == 1) {
        final chapterNum = int.tryParse(verse.verseKey.split(':').first);
        if (chapterNum != null) {
          Chapter? chapter;
          try {
            chapter = readingProvider.chapters.firstWhere(
              (c) => c.id == chapterNum,
            );
          } catch (_) {}
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _SurahHeader(
                chapterNumber: chapterNum,
                nameArabic: chapter?.nameArabic ?? '',
                nameSimple: chapter?.nameSimple ?? 'Surah $chapterNum',
                versesCount: chapter?.versesCount ?? 0,
              ),
            ),
          );
        }
      }

      final isSelected = widget.selectedVerseId == verse.id;
      final isPlaying = activeVerseKey == verse.verseKey;
      final isFlashHighlight =
          context.watch<BookmarkProvider>().highlightVerseKey == verse.verseKey;
      final isHighlighted = isSelected || isPlaying || isFlashHighlight;

      // Try to get Warsh text for this verse
      String? warshText;
      if (isWarsh) {
        warshText = readingProvider.getWarshVerseText(verse.verseKey);
      }

      if (isWarsh && warshText != null) {
        // ── Warsh mode: render full verse text as a single TextSpan ──
        final recognizer = LongPressGestureRecognizer()
          ..onLongPress = () {
            _toggleVerseSelection(verse.id);
          };
        _recognizers.add(recognizer);

        spans.add(
          TextSpan(
            text: warshText,
            style: GoogleFonts.amiriQuran(
              fontSize: fontSize,
              height: theme.quranLineHeight,
              fontWeight: FontWeight.w400,
              color: theme.quranText,
              backgroundColor: isHighlighted ? theme.verseHighlight : null,
            ),
            recognizer: recognizer,
          ),
        );

        // Add verse end marker
        Widget marker = _VerseMarker(
          verseNumber: verse.verseNumber,
          isHighlighted: isHighlighted,
        );
        if (isSelected || isPlaying) {
          marker = KeyedSubtree(key: _getKeyForVerse(verse.id), child: marker);
        }
        // Word Joiner (U+2060) prevents the text engine from breaking the
        // line between the last word of the verse and its end marker. Without
        // this, RTL layout can wrap the marker to a new line where it visually
        // appears at the start of the next verse.
        spans.add(const TextSpan(text: '\u2060'));
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onLongPress: () {
                  _toggleVerseSelection(verse.id);
                },
                child: marker,
              ),
            ),
          ),
        );
      } else {
        // ── Hafs mode (or Warsh fallback): word-by-word rendering ──
        for (int wi = 0; wi < verse.words.length; wi++) {
          final word = verse.words[wi];

          if (word.charTypeName == 'end') {
            Widget marker = _VerseMarker(
              verseNumber: verse.verseNumber,
              isHighlighted: isHighlighted,
            );
            if (isSelected || isPlaying) {
              marker = KeyedSubtree(
                key: _getKeyForVerse(verse.id),
                child: marker,
              );
            }
            // Word Joiner (U+2060) prevents the text engine from breaking
            // the line between the last word and its end marker in RTL.
            spans.add(const TextSpan(text: '\u2060'));
            spans.add(
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onLongPress: () {
                      _toggleVerseSelection(verse.id);
                    },
                    child: marker,
                  ),
                ),
              ),
            );
          } else {
            final text = wi == 0 ? word.textUthmani : ' ${word.textUthmani}';
            final recognizer = LongPressGestureRecognizer()
              ..onLongPress = () {
                _toggleVerseSelection(verse.id);
              };
            _recognizers.add(recognizer);

            spans.add(
              TextSpan(
                text: text,
                style: GoogleFonts.amiriQuran(
                  fontSize: fontSize,
                  height: theme.quranLineHeight,
                  fontWeight: FontWeight.w400,
                  color: theme.quranText,
                  backgroundColor: isHighlighted ? theme.verseHighlight : null,
                ),
                recognizer: recognizer,
              ),
            );
          }
        }
      }
      // Restore regular space between verses — this IS where line breaks should
      // happen: between two different verses, not between a verse and its marker.
      spans.add(const TextSpan(text: ' '));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.verses.isEmpty) return const SizedBox.shrink();

    final theme = context.watch<ThemeProvider>();
    final isOddPage = widget.pageNumber.isOdd;

    // Determine where the effect should be placed
    final isCenterEffect =
        theme.pageIndicatorEffect == PageIndicatorEffect.center;
    // Center Spine: Odd (Right) pages have spine on Left. Even (Left) pages have spine on Right.
    // Outer Edge: Odd (Right) pages have edge on Right. Even (Left) pages have edge on Left.
    final isEffectOnRight = isCenterEffect ? !isOddPage : isOddPage;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (widget.selectedVerseId != null) {
          widget.onVerseSelected(null);
        } else {
          widget.onCanvasTapped();
        }
      },
      child: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            // Main page content
            Container(
              color: theme.canvasBackground,
              width: double.infinity,
              height: double.infinity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Selector<AudioProvider, String?>(
                    selector: (context, provider) => provider.activeVerseKey,
                    builder: (context, activeVerseKey, child) {
                      final readingProvider = context
                          .watch<QuranReadingProvider>();
                      final isActivePage =
                          readingProvider.activePage == widget.pageNumber;

                      final paddingLeft =
                          10.0 +
                          (theme.spineEffectEnabled && !isEffectOnRight
                              ? theme.spineEffectPadding
                              : 0);
                      final paddingRight =
                          10.0 +
                          (theme.spineEffectEnabled && isEffectOnRight
                              ? theme.spineEffectPadding
                              : 0);
                      final paddingTop = MediaQuery.paddingOf(context).top > 0
                          ? MediaQuery.paddingOf(context).top + 20
                          : 32.0;
                      final paddingBottom =
                          MediaQuery.paddingOf(context).bottom > 0
                          ? MediaQuery.paddingOf(context).bottom
                          : 32.0;

                      // Constrain calculations to 680px width to scale correctly on wider tablets/web layouts
                      final effectiveMaxWidth = constraints.maxWidth > 680.0
                          ? 680.0
                          : constraints.maxWidth;
                      final availableWidth =
                          effectiveMaxWidth - paddingLeft - paddingRight;
                      // Subtract a small safe zone margin (20px) to ensure text never touches the fade gradients
                      final availableHeight =
                          constraints.maxHeight -
                          paddingTop -
                          paddingBottom -
                          20.0;

                      double calculatedFontSize = theme.quranFontSize;

                      if (theme.fitScreenHeight &&
                          availableHeight > 0 &&
                          availableWidth > 0 &&
                          widget.verses.isNotEmpty) {
                        double minFS = 14.0;
                        double maxFS = 30.0; // Hard cap per User instruction

                        for (int i = 0; i < 6; i++) {
                          final midFS = (minFS + maxFS) / 2;

                          final testSpans = _buildSpans(
                            theme,
                            activeVerseKey,
                            readingProvider,
                            midFS,
                          );

                          List<PlaceholderDimensions> placeholderDimensions =
                              [];
                          for (final span in testSpans) {
                            if (span is WidgetSpan) {
                              if (span.child is _SurahHeader) {
                                placeholderDimensions.add(
                                  PlaceholderDimensions(
                                    size: Size(availableWidth, 110),
                                    alignment: PlaceholderAlignment.middle,
                                  ),
                                );
                              } else {
                                placeholderDimensions.add(
                                  const PlaceholderDimensions(
                                    size: Size(26, 22),
                                    alignment: PlaceholderAlignment.middle,
                                  ),
                                );
                              }
                            }
                          }

                          final textPainter = TextPainter(
                            text: TextSpan(children: testSpans),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                          );

                          textPainter.setPlaceholderDimensions(
                            placeholderDimensions,
                          );
                          textPainter.layout(maxWidth: availableWidth);

                          if (textPainter.size.height > availableHeight) {
                            maxFS = midFS;
                          } else {
                            minFS = midFS;
                            calculatedFontSize = midFS;
                          }
                        }

                        // Prevent endless fraction jitter and ensure it remains within manual slider limits
                        // by safely flooring the double to the nearest whole integer.
                        // Implements the hard cap of 30.0 to prevent short pages from exploding.
                        calculatedFontSize = calculatedFontSize
                            .clamp(14.0, 30.0)
                            .floorToDouble();

                        // Push to theme so the slider updates visually.
                        if (isActivePage &&
                            theme.quranFontSize != calculatedFontSize) {
                          Future.microtask(
                            () => theme.setQuranFontSize(calculatedFontSize),
                          );
                        }
                      }

                      final finalSpans = _buildSpans(
                        theme,
                        activeVerseKey,
                        readingProvider,
                        calculatedFontSize,
                      );

                      final textAlign =
                          theme.quranTextAlign == QuranTextAlign.right
                          ? TextAlign.right
                          : theme.quranTextAlign == QuranTextAlign.justify
                          ? TextAlign.justify
                          : TextAlign.center;

                      final richText = ExcludeSemantics(
                        child: RichText(
                          textAlign: textAlign,
                          textDirection: TextDirection.rtl,
                          text: TextSpan(children: finalSpans),
                        ),
                      );

                      final contentAlign =
                          theme.contentAlignment == QuranContentAlignment.bottom
                          ? Alignment.bottomCenter
                          : theme.contentAlignment ==
                                QuranContentAlignment.center
                          ? Alignment.center
                          : Alignment.topCenter;

                      Widget contentWidget = Align(
                        alignment: contentAlign,
                        child: richText,
                      );

                      if (theme.fitScreenHeight) {
                        return Padding(
                          padding: EdgeInsets.only(
                            left: paddingLeft,
                            right: paddingRight,
                            top: paddingTop,
                            bottom: paddingBottom,
                          ),
                          child: contentWidget,
                        );
                      } else {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.only(
                            left: paddingLeft,
                            right: paddingRight,
                            top: paddingTop,
                            bottom: paddingBottom,
                          ),
                          child: contentWidget,
                        );
                      }
                    },
                  );
                },
              ),
            ),
            // Page indicator effect (Center Spine or Outer Edge stack)
            if (theme.spineEffectEnabled)
              Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: isEffectOnRight
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: theme.spineEffectWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: isEffectOnRight
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          end: isEffectOnRight
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          colors: [
                            isCenterEffect
                                ? Colors.black.withValues(
                                    alpha: theme.spineEffectIntensity,
                                  )
                                : theme.accentColor.withValues(
                                    alpha: theme.spineEffectIntensity * 1.5,
                                  ),
                            isCenterEffect
                                ? Colors.black.withValues(alpha: 0.0)
                                : theme.accentColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
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

/// Diamond-shaped verse number marker with Latin numerals.
/// Uses the brand diamond shape (45° rotated square) for visual consistency
/// with the surah list tiles and other index markers throughout the app.
class _VerseMarker extends StatelessWidget {
  final int verseNumber;
  final bool isHighlighted;

  const _VerseMarker({required this.verseNumber, required this.isHighlighted});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    const outerSize = 22.0;
    const innerSize = 16.0;
    const fontSize = 8.5;

    Color borderColor;
    Color? fillColor;
    Color textColor;

    if (isHighlighted) {
      borderColor = theme.verseMarkerHighlightBorder;
      fillColor = theme.verseMarkerHighlight;
      textColor = theme.scaffoldBackground;
    } else {
      borderColor = theme.verseMarkerBorder;
      fillColor = theme.verseMarkerColor;
      textColor = theme.primaryText;
    }

    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.785398, // 45 degrees
            child: Container(
              width: innerSize,
              height: innerSize,
              decoration: BoxDecoration(
                color: fillColor,
                border: Border.all(color: borderColor, width: 1.0),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          Text(
            '$verseNumber',
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextualMenu extends StatelessWidget {
  final Verse verse;
  final List<Verse> verses;
  final int pageNumber;
  final VoidCallback onDismiss;
  final ValueChanged<String>? onTranslateVerse;

  const _ContextualMenu({
    required this.verse,
    required this.verses,
    required this.pageNumber,
    required this.onDismiss,
    this.onTranslateVerse,
  });

  String get _verseText {
    return verse.words
        .where((w) => w.charTypeName != 'end')
        .map((w) => w.textUthmani)
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.contextMenuBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: theme.shadowCardFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play
            _ActionIcon(
              icon: LucideIcons.play,
              onTap: () {
                final verseIdx = verses.indexWhere((v) => v.id == verse.id);
                context.read<AudioProvider>().playVerseList(
                  verses,
                  startIndex: verseIdx >= 0 ? verseIdx : 0,
                );
                onDismiss();
              },
            ),
            const SizedBox(width: 16),
            // Copy verse text to clipboard
            _ActionIcon(
              icon: LucideIcons.copy,
              onTap: () {
                final l = AppLocalizations.of(context);
                Clipboard.setData(
                  ClipboardData(
                    text:
                        '$_verseText\n[${VerseRefFormatter.format(verse.verseKey, locale: l?.localeName ?? 'en', tier: VerseRefFormat.full)}]',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l?.verseCopied(
                            VerseRefFormatter.format(
                              verse.verseKey,
                              locale: l.localeName,
                              tier: VerseRefFormat.standard,
                            ),
                          ) ??
                          'Verse ${verse.verseKey} copied',
                      style: TextStyle(fontFamily: 'Inter'),
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                onDismiss();
              },
            ),
            const SizedBox(width: 16),
            // Bookmark
            Builder(
              builder: (ctx) {
                final bookmarkProv = ctx.watch<BookmarkProvider>();
                final isBookmarked = bookmarkProv.isVerseBookmarked(
                  verse.verseKey,
                );
                final readingProv = ctx.read<QuranReadingProvider>();
                final chapterId =
                    int.tryParse(verse.verseKey.split(':').first) ?? 1;
                String surahName = 'Surah $chapterId';
                try {
                  surahName = readingProv.chapters
                      .firstWhere((c) => c.id == chapterId)
                      .nameSimple;
                } catch (_) {}
                return _ActionIcon(
                  icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  onTap: () {
                    bookmarkProv.toggleVerseBookmark(
                      verseKey: verse.verseKey,
                      pageNumber: pageNumber,
                      surahName: surahName,
                    );
                    onDismiss();
                  },
                );
              },
            ),
            const SizedBox(width: 16),
            // Share
            _ActionIcon(
              icon: LucideIcons.share,
              onTap: () {
                final l = AppLocalizations.of(context);
                Clipboard.setData(
                  ClipboardData(
                    text:
                        '$_verseText\n\n— ${VerseRefFormatter.format(verse.verseKey, locale: l?.localeName ?? 'en', tier: VerseRefFormat.full)}',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l?.verseCopiedForSharing ?? 'Verse copied for sharing',
                      style: TextStyle(fontFamily: 'Inter'),
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                onDismiss();
              },
            ),
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 16,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 12),
            // Translate — switches to translation view with this verse highlighted
            GestureDetector(
              onTap: () {
                onDismiss();
                if (onTranslateVerse != null) {
                  onTranslateVerse!(verse.verseKey);
                }
              },
              child: Text(
                AppLocalizations.of(context)?.contextTranslate ?? 'Translate',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 1,
              height: 16,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 12),
            // Tafsir — opens the tafsir bottom sheet
            GestureDetector(
              onTap: () {
                onDismiss();
                // Look up surah name
                final readingProv = context.read<QuranReadingProvider>();
                final chapterId =
                    int.tryParse(verse.verseKey.split(':').first) ?? 1;
                String? surahName;
                try {
                  surahName = readingProv.chapters
                      .firstWhere((c) => c.id == chapterId)
                      .nameSimple;
                } catch (_) {}
                showTafsirSheet(
                  context,
                  verseKey: verse.verseKey,
                  surahName: surahName,
                );
              },
              child: Text(
                AppLocalizations.of(context)?.contextTafsir ?? 'Tafsir',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}

/// Decorative surah introduction header
class _SurahHeader extends StatelessWidget {
  final int chapterNumber;
  final String nameArabic;
  final String nameSimple;
  final int versesCount;

  const _SurahHeader({
    required this.chapterNumber,
    required this.nameArabic,
    required this.nameSimple,
    required this.versesCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        children: [
          // Ornamental divider top
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        theme.accentColor.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  LucideIcons.sparkles,
                  size: 10,
                  color: theme.accentColor.withValues(alpha: 0.5),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.accentColor.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Arabic surah name
          Text(
            'سُورَةُ $nameArabic',
            style: GoogleFonts.amiri(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.accentColor,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 10),

          // Ornamental divider bottom
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        theme.accentColor.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  LucideIcons.sparkles,
                  size: 10,
                  color: theme.accentColor.withValues(alpha: 0.5),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.accentColor.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
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
}
