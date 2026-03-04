import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

class BottomDock extends StatefulWidget {
  final int activePage;
  final List<int> paginationArray;
  final ValueChanged<int> onPageSelected;
  final VoidCallback onNavMenuTapped;
  final String surahName;
  final String juzName;

  const BottomDock({
    super.key,
    required this.activePage,
    required this.paginationArray,
    required this.onPageSelected,
    required this.onNavMenuTapped,
    required this.surahName,
    required this.juzName,
  });

  @override
  State<BottomDock> createState() => _BottomDockState();
}

class _BottomDockState extends State<BottomDock> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final totalPages = widget.paginationArray.isNotEmpty
        ? widget.paginationArray.length
        : 604;

    return Container(
      decoration: BoxDecoration(
        color: theme.dockBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Surah name + Juz label
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.surahName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryText,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  widget.juzName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryText,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Nav icon + pagination + bookmark
            Row(
              children: [
                GestureDetector(
                  onTap: widget.onNavMenuTapped,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.pillBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.list,
                      size: 20,
                      color: theme.accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: PaginationSlider(
                      activePage: widget.activePage,
                      paginationArray: widget.paginationArray,
                      onPageSelected: widget.onPageSelected,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.02),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.bookmark,
                    size: 18,
                    color: theme.accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Full-width smooth slider
            SizedBox(
              height: 20,
              // Negative horizontal margin to pull the slider track exactly to the container edges
              // (which are padded by 16px). Or instead use a custom track shape.
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  activeTrackColor: theme.sliderActive,
                  inactiveTrackColor: theme.sliderInactive,
                  thumbColor: Colors.transparent,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  trackShape: const _FullWidthTrackShape(),
                ),
                child: ExcludeSemantics(
                  child: Slider(
                    value: _dragValue ?? widget.activePage.toDouble(),
                    min: 1,
                    max: totalPages.toDouble(),
                    onChanged: (val) {
                      setState(() {
                        _dragValue = val;
                      });
                      widget.onPageSelected(val.round());
                    },
                    onChangeEnd: (val) {
                      setState(() {
                        _dragValue = null;
                      });
                      widget.onPageSelected(val.round());
                    },
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

class _FullWidthTrackShape extends RoundedRectSliderTrackShape {
  const _FullWidthTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

/// A horizontally scrolling pagination strip where the active page is always
/// centered. Scrolling/swiping snaps to the nearest item and fires
/// [onPageSelected] so the center item drives the reading view.
class PaginationSlider extends StatefulWidget {
  final int activePage;
  final List<int> paginationArray;
  final ValueChanged<int> onPageSelected;

  const PaginationSlider({
    super.key,
    required this.activePage,
    required this.paginationArray,
    required this.onPageSelected,
  });

  @override
  State<PaginationSlider> createState() => _PaginationSliderState();
}

class _PaginationSliderState extends State<PaginationSlider> {
  late ScrollController _scrollController;
  static const double _itemWidth = 36.0;

  // The index currently closest to center (updated on scroll).
  int _centerIndex = 0;

  // True only when the user physically drags the pagination strip.
  // Programmatic scrolls (jumpTo, animateTo) leave this false.
  bool _userDragging = false;

  @override
  void initState() {
    super.initState();
    _centerIndex = _activeIndex;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToIndex(_centerIndex);
    });
  }

  int get _activeIndex {
    final idx = widget.paginationArray.indexOf(widget.activePage);
    return idx == -1 ? 0 : idx;
  }

  @override
  void didUpdateWidget(PaginationSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activePage != widget.activePage) {
      final newIndex = _activeIndex;
      if (newIndex != _centerIndex) {
        _centerIndex = newIndex;
        _animateToIndex(newIndex);
      }
    }
  }

  // ------------------------------------------------------------------
  // Scroll helpers
  // ------------------------------------------------------------------

  /// The scroll offset that places [index] exactly at the viewport center.
  double _offsetForIndex(int index) {
    if (!_scrollController.hasClients) return 0;
    final viewportW = _scrollController.position.viewportDimension;
    final desired = (index * _itemWidth) - (viewportW / 2) + (_itemWidth / 2);
    return desired.clamp(0.0, _scrollController.position.maxScrollExtent);
  }

  void _jumpToIndex(int index) {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_offsetForIndex(index));
  }

  void _animateToIndex(int index) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _offsetForIndex(index),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  /// Called on every scroll tick. Only updates the visual center index.
  void _onScroll() {
    if (!_userDragging || !_scrollController.hasClients) return;

    final viewportW = _scrollController.position.viewportDimension;
    final scrollOffset = _scrollController.offset;
    final centerPixel = scrollOffset + viewportW / 2;

    int closestIndex = (centerPixel / _itemWidth).round().clamp(
      0,
      widget.paginationArray.length - 1,
    );

    if (closestIndex != _centerIndex) {
      setState(() {
        _centerIndex = closestIndex;
      });
    }
  }

  /// Only fire onPageSelected for user-initiated scrolls.
  /// Programmatic scrolls (from didUpdateWidget) have null dragDetails.
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _userDragging = notification.dragDetails != null;
    }
    if (notification is ScrollEndNotification && _userDragging) {
      _userDragging = false;
      _animateToIndex(_centerIndex);
      widget.onPageSelected(widget.paginationArray[_centerIndex]);
    }
    return false;
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.paginationArray.length,
        itemBuilder: (context, index) {
          final pageNum = widget.paginationArray[index];
          final isActive = index == _centerIndex;
          final distance = (index - _centerIndex).abs();

          // Opacity gradient radiates from the center item.
          double targetOpacity;
          if (isActive) {
            targetOpacity = 1.0;
          } else if (distance == 1) {
            targetOpacity = 0.6;
          } else if (distance == 2) {
            targetOpacity = 0.45;
          } else if (distance == 3) {
            targetOpacity = 0.30;
          } else if (distance == 4) {
            targetOpacity = 0.20;
          } else {
            targetOpacity = 0.12;
          }

          return GestureDetector(
            onTap: () {
              _centerIndex = index;
              widget.onPageSelected(pageNum);
              _animateToIndex(index);
            },
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: targetOpacity,
              child: Container(
                width: _itemWidth - 8,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? theme.accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isActive
                      ? null
                      : Border.all(color: theme.accentColor),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: theme.accentColor.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _line(isActive, theme),
                    _line(isActive, theme),
                    Container(
                      width: 14,
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white.withValues(alpha: 0.7)
                            : theme.accentColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      pageNum.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0,
                        color: isActive ? Colors.white : theme.accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _line(bool isActive, ThemeProvider theme) {
    return Container(
      width: 14,
      height: 2,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.7)
            : theme.accentColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
