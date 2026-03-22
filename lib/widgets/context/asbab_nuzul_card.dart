import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/context_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';

/// An expandable card that shows asbab al-nuzul (reason/occasion of revelation)
/// for a verse.
///
/// Only renders content if the verse has asbab al-nuzul data.
/// Collapsed: shows an icon + label. Expanded: shows the narrative text.
///
/// Usage:
/// ```dart
/// AsbabNuzulCard(verseKey: '2:89')
/// ```
class AsbabNuzulCard extends StatefulWidget {
  final String verseKey;

  /// Optional: provide the occasions text directly instead of loading
  /// from the provider.
  final List<String>? occasions;

  /// Whether to display in expanded state by default.
  final bool initiallyExpanded;

  const AsbabNuzulCard({
    super.key,
    required this.verseKey,
    this.occasions,
    this.initiallyExpanded = false,
  });

  @override
  State<AsbabNuzulCard> createState() => _AsbabNuzulCardState();
}

class _AsbabNuzulCardState extends State<AsbabNuzulCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (_isExpanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    // Get occasions from props or provider
    List<String>? occasions = widget.occasions;
    if (occasions == null) {
      final ctx = context.watch<ContextProvider>();
      if (ctx.activeVerseKey == widget.verseKey) {
        occasions = ctx.activeAsbabNuzul;
      } else if (ctx.verseHasAsbabNuzul(widget.verseKey)) {
        // Trigger load
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ctx.loadAsbabNuzul(widget.verseKey);
        });
        return const SizedBox.shrink();
      }
    }

    // Don't render if no data
    if (occasions == null || occasions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (always visible)
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.accentLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📜',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Occasion of Revelation',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryText,
                          ),
                        ),
                        Text(
                          'Verse ${widget.verseKey}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: theme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: _rotationAnimation,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 22,
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: theme.dividerColor,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int i = 0; i < occasions.length; i++) ...[
                        if (i > 0) ...[
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: theme.dividerColor,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (occasions.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              'Narration ${i + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.accentColor,
                              ),
                            ),
                          ),
                        // Occasion text — ExcludeSemantics for Windows safety
                        ExcludeSemantics(
                          child: Text(
                            occasions[i],
                            style: GoogleFonts.amiri(
                              fontSize: 16,
                              height: 2.0,
                              color: theme.primaryText,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Source attribution
                      Text(
                        'Source: صحيح أسباب النزول — إبراهيم محمد العلي',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: theme.mutedText,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
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
