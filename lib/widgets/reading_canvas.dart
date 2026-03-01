import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/providers/audio_provider.dart';

class ReadingCanvas extends StatefulWidget {
  final List<Verse> verses;
  final int? selectedVerseId;
  final ValueChanged<int?> onVerseSelected;
  final VoidCallback onCanvasTapped;

  const ReadingCanvas({
    super.key,
    required this.verses,
    required this.selectedVerseId,
    required this.onVerseSelected,
    required this.onCanvasTapped,
  });

  @override
  State<ReadingCanvas> createState() => _ReadingCanvasState();
}

class _ReadingCanvasState extends State<ReadingCanvas> {
  final Map<int, GlobalKey> _verseKeys = {};
  OverlayEntry? _menuOverlay;

  @override
  void dispose() {
    _removeOverlay();
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
                onDismiss: () {
                  widget.onVerseSelected(null);
                },
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_menuOverlay!);
  }

  GlobalKey _getKeyForVerse(int verseId) {
    return _verseKeys.putIfAbsent(verseId, () => GlobalKey());
  }

  @override
  Widget build(BuildContext context) {
    final totalWords = widget.verses
        .expand((v) => v.words)
        .where((w) => w.charTypeName == 'word')
        .length;
    final isShortPage = totalWords < 40;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (widget.selectedVerseId != null) {
          widget.onVerseSelected(null);
        } else {
          widget.onCanvasTapped();
        }
      },
      child: Container(
        color: Colors.transparent,
        width: double.infinity,
        height: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(
            top: 0,
            bottom: 90,
            left: 12,
            right: 12,
          ),
          child: Consumer<AudioProvider>(
            builder: (context, audioProvider, child) {
              // Build RichText with TextSpan and WidgetSpan for continuous verse highlight
              final spans = <InlineSpan>[];

              for (final verse in widget.verses) {
                final isSelected = widget.selectedVerseId == verse.id;
                final isPlaying = audioProvider.activeVerseId == verse.id;
                final isHighlighted = isSelected || isPlaying;

                for (int wi = 0; wi < verse.words.length; wi++) {
                  final word = verse.words[wi];

                  if (word.charTypeName == 'end') {
                    // Verse marker as WidgetSpan
                    Widget marker = _VerseMarker(
                      verseNumber: verse.verseNumber,
                      isHighlighted: isHighlighted,
                    );
                    // Attach key on first marker for menu positioning
                    if (isSelected) {
                      marker = KeyedSubtree(
                        key: _getKeyForVerse(verse.id),
                        child: marker,
                      );
                    }
                    spans.add(
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: GestureDetector(
                            onLongPress: () {
                              widget.onVerseSelected(
                                isSelected ? null : verse.id,
                              );
                            },
                            child: marker,
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Add space between words (except first word)
                    final text = wi == 0
                        ? word.textUthmani
                        : ' ${word.textUthmani}';

                    final recognizer = LongPressGestureRecognizer()
                      ..onLongPress = () {
                        widget.onVerseSelected(isSelected ? null : verse.id);
                      };

                    spans.add(
                      TextSpan(
                        text: text,
                        style: GoogleFonts.amiriQuran(
                          fontSize: 22,
                          height: 2.2,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF1A454E),
                          backgroundColor: isHighlighted
                              ? const Color(0xFFE0F2F1)
                              : null,
                        ),
                        recognizer: recognizer,
                      ),
                    );
                  }
                }

                // Add a small space between verses
                spans.add(const TextSpan(text: ' '));
              }

              final richText = RichText(
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                text: TextSpan(children: spans),
              );

              if (isShortPage) {
                return Center(child: richText);
              } else {
                return Align(alignment: Alignment.topCenter, child: richText);
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Styled verse number marker with Latin numerals
class _VerseMarker extends StatelessWidget {
  final int verseNumber;
  final bool isHighlighted;

  const _VerseMarker({required this.verseNumber, required this.isHighlighted});

  @override
  Widget build(BuildContext context) {
    const size = 22.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isHighlighted
            ? const Color(0xFF4DB6AC)
            : const Color(0xFFB2DFDB),
        border: Border.all(
          color: isHighlighted ? Colors.teal.shade600 : const Color(0xFF80CBC4),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          '$verseNumber',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A454E),
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _ContextualMenu extends StatelessWidget {
  final Verse verse;
  final List<Verse> verses;
  final VoidCallback onDismiss;

  const _ContextualMenu({
    required this.verse,
    required this.verses,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A454E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A454E).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            _ActionIcon(icon: LucideIcons.copy, onTap: () {}),
            const SizedBox(width: 16),
            _ActionIcon(icon: LucideIcons.bookmark, onTap: () {}),
            const SizedBox(width: 16),
            _ActionIcon(icon: LucideIcons.share, onTap: () {}),
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 16,
              color: Colors.white.withOpacity(0.2),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Tafsir',
                style: TextStyle(
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
