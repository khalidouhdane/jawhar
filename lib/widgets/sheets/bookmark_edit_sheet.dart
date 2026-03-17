import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/models/bookmark_model.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

/// A bottom sheet for editing a single bookmark (color, note, collection, delete).
class BookmarkEditSheet extends StatefulWidget {
  final String bookmarkId;
  final VoidCallback onClose;

  const BookmarkEditSheet({
    super.key,
    required this.bookmarkId,
    required this.onClose,
  });

  @override
  State<BookmarkEditSheet> createState() => _BookmarkEditSheetState();
}

class _BookmarkEditSheetState extends State<BookmarkEditSheet> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final bp = context.read<BookmarkProvider>();
    final bm = bp.getById(widget.bookmarkId);
    _noteController = TextEditingController(text: bm?.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final bp = context.watch<BookmarkProvider>();
    final l = AppLocalizations.of(context);
    final bm = bp.getById(widget.bookmarkId);

    if (bm == null) {
      // Bookmark was deleted externally
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onClose());
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(LucideIcons.pencil, size: 18, color: theme.accentColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.t('bm_edit_title'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.primaryText,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onClose,
                  child: Icon(
                    LucideIcons.x,
                    size: 20,
                    color: theme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Bookmark Info ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  bm.type == BookmarkType.verse
                      ? LucideIcons.bookOpen
                      : LucideIcons.fileText,
                  size: 14,
                  color: theme.mutedText,
                ),
                const SizedBox(width: 6),
                Text(
                  bm.type == BookmarkType.verse
                      ? '${bm.verseKey} · ${bm.surahName}'
                      : '${l.t('nav_page')} ${bm.pageNumber} · ${bm.surahName}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: theme.mutedText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Color Picker ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.t('bm_color'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.mutedText,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // "None" option
                    _colorCircle(theme, null, bm.colorIndex == null && bm.customColor == null, bp),
                    // Preset palette
                    ...List.generate(BookmarkColors.palette.length, (i) {
                      return _colorCircle(
                        theme, i, bm.colorIndex == i && bm.customColor == null, bp,
                      );
                    }),
                    // Custom color circle
                    _customColorCircle(theme, bm, bp),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Note Field ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.t('bm_note'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.mutedText,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: theme.primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: l.t('bm_note_hint'),
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: theme.mutedText.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: theme.accentColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                  onChanged: (text) {
                    bp.updateNote(widget.bookmarkId, text);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Move to Collection ──
          if (bp.collections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.t('bm_collection'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _collectionChip(
                        theme,
                        l.t('bm_uncategorized'),
                        null,
                        bm.collectionId == null,
                        bp,
                      ),
                      ...bp.collections.map((col) => _collectionChip(
                            theme,
                            col.name,
                            col.id,
                            bm.collectionId == col.id,
                            bp,
                          )),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // ── Delete ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  bp.removeBookmark(widget.bookmarkId);
                  widget.onClose();
                },
                icon: const Icon(LucideIcons.trash2, size: 16),
                label: Text(l.t('bm_delete')),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF5350),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: const Color(0xFFEF5350).withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }

  Widget _colorCircle(
    ThemeProvider theme,
    int? colorIndex,
    bool isActive,
    BookmarkProvider bp,
  ) {
    final color = colorIndex == null
        ? theme.mutedText.withValues(alpha: 0.2)
        : Color(BookmarkColors.palette[colorIndex]);

    return GestureDetector(
      onTap: () => bp.updateColor(widget.bookmarkId, colorIndex),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isActive
              ? Border.all(color: theme.primaryText, width: 2.5)
              : null,
        ),
        child: colorIndex == null && isActive
            ? Icon(LucideIcons.x, size: 14, color: theme.mutedText)
            : null,
      ),
    );
  }

  Widget _customColorCircle(
    ThemeProvider theme,
    Bookmark bm,
    BookmarkProvider bp,
  ) {
    final hasCustom = bm.customColor != null;
    final color = hasCustom ? Color(bm.customColor!) : theme.accentColor;

    return GestureDetector(
      onTap: () => _showHexColorDialog(theme, bm, bp),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: hasCustom ? theme.primaryText : theme.dividerColor,
            width: hasCustom ? 2.5 : 1.5,
          ),
          color: hasCustom ? color : Colors.transparent,
        ),
        child: hasCustom
            ? null
            : Icon(LucideIcons.pipette, size: 14, color: theme.mutedText),
      ),
    );
  }

  void _showHexColorDialog(
    ThemeProvider theme,
    Bookmark bm,
    BookmarkProvider bp,
  ) {
    final hexController = TextEditingController(
      text: bm.customColor != null
          ? bm.customColor!.toRadixString(16).substring(2).toUpperCase()
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        Color preview = bm.customColor != null
            ? Color(bm.customColor!)
            : theme.accentColor;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.scaffoldBackground,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Custom Color',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryText,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Preview circle
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: preview,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme.dividerColor, width: 2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Hex input
                  TextField(
                    controller: hexController,
                    maxLength: 6,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      prefixText: '#',
                      prefixStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.mutedText,
                      ),
                      hintText: 'FF5733',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        color: theme.mutedText.withValues(alpha: 0.3),
                      ),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: theme.accentColor),
                      ),
                    ),
                    onChanged: (val) {
                      if (val.length == 6) {
                        final parsed = int.tryParse('FF$val', radix: 16);
                        if (parsed != null) {
                          setDialogState(
                              () => preview = Color(parsed));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Quick palette row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      0xFFFF5733, 0xFF33FF57, 0xFF3357FF,
                      0xFFFF33A8, 0xFF33FFF5, 0xFFFFC300,
                      0xFF8E44AD, 0xFF1ABC9C,
                    ].map((c) {
                      return GestureDetector(
                        onTap: () {
                          setDialogState(() => preview = Color(c));
                          hexController.text =
                              c.toRadixString(16).substring(2).toUpperCase();
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(c),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (bm.customColor != null) {
                      bp.updateCustomColor(widget.bookmarkId, null);
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text('Clear',
                      style: TextStyle(color: theme.mutedText)),
                ),
                TextButton(
                  onPressed: () {
                    final hex = hexController.text.trim();
                    if (hex.length == 6) {
                      final parsed =
                          int.tryParse('FF$hex', radix: 16);
                      if (parsed != null) {
                        bp.updateCustomColor(
                            widget.bookmarkId, parsed);
                      }
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text('Apply',
                      style: TextStyle(color: theme.accentColor)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _collectionChip(
    ThemeProvider theme,
    String label,
    String? collectionId,
    bool isActive,
    BookmarkProvider bp,
  ) {
    return GestureDetector(
      onTap: () => bp.moveToCollection(widget.bookmarkId, collectionId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? theme.accentColor.withValues(alpha: 0.12)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? theme.accentColor : theme.dividerColor,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? theme.accentColor : theme.primaryText,
          ),
        ),
      ),
    );
  }
}
