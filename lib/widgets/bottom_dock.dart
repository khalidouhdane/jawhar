import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

class BottomDock extends StatefulWidget {
  final int activePage;
  final List<int> paginationArray;
  final ValueChanged<int> onPageSelected;
  final String surahName;
  final String hizbName;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Decoration? decoration;

  const BottomDock({
    super.key,
    required this.activePage,
    required this.paginationArray,
    required this.onPageSelected,
    required this.surahName,
    required this.hizbName,
    this.margin,
    this.padding,
    this.decoration,
  });
  @override
  State<BottomDock> createState() => _BottomDockState();
}

class _BottomDockState extends State<BottomDock> {
  double? _dragValue;

  int _clampPage(int page, int totalPages) => page.clamp(1, totalPages).toInt();

  @override
  void didUpdateWidget(covariant BottomDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final dragValue = _dragValue;
    if (dragValue != null && widget.activePage == dragValue.round()) {
      _dragValue = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final totalPages = widget.paginationArray.isNotEmpty
        ? widget.paginationArray.length
        : 604;
    final previewPage = _clampPage(
      (_dragValue ?? widget.activePage.toDouble()).round(),
      totalPages,
    );
    final isPreviewingPage = _dragValue != null;

    return Container(
      margin: widget.margin,
      decoration:
          widget.decoration ??
          BoxDecoration(
            color: theme.dockBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: theme.shadowRing,
          ),
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Surah name + Hizb label
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
                  widget.hizbName,
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
            // Pagination strip (full width)
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.05, 0.92, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: SizedBox(
                height: 48,
                child: PaginationSlider(
                  activePage: previewPage,
                  isPreviewing: isPreviewingPage,
                  paginationArray: widget.paginationArray,
                  onPageSelected: widget.onPageSelected,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Full-width page slider
            SizedBox(
              key: const ValueKey('page_slider'),
              height: 28,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  activeTrackColor: theme.sliderActive,
                  inactiveTrackColor: theme.sliderInactive,
                  thumbColor: theme.sliderActive,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 18,
                  ),
                  overlayColor: theme.sliderActive.withValues(alpha: 0.12),
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
                    },
                    onChangeEnd: (val) {
                      final page = _clampPage(val.round(), totalPages);
                      setState(() {
                        _dragValue = page.toDouble();
                      });
                      widget.onPageSelected(page);
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
  final bool isPreviewing;
  final List<int> paginationArray;
  final ValueChanged<int> onPageSelected;

  const PaginationSlider({
    super.key,
    required this.activePage,
    this.isPreviewing = false,
    required this.paginationArray,
    required this.onPageSelected,
  });

  @override
  State<PaginationSlider> createState() => _PaginationSliderState();
}

class _PaginationSliderState extends State<PaginationSlider> {
  late ScrollController _scrollController;
  static const double _itemWidth = 36.0;
  static const int _anchorCycle = 50;

  // The virtual index currently closest to center (updated on scroll).
  int _centerVirtualIndex = 0;

  // True only when the user physically drags the pagination strip.
  // Programmatic scrolls (jumpTo, animateTo) leave this false.
  bool _userDragging = false;

  @override
  void initState() {
    super.initState();
    _centerVirtualIndex = _initialVirtualIndex;
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToVirtualIndex(_centerVirtualIndex);
    });
  }

  int get _activeIndex {
    final idx = widget.paginationArray.indexOf(widget.activePage);
    return idx == -1 ? 0 : idx;
  }

  int get _pageCount => widget.paginationArray.length;

  int get _initialVirtualIndex => (_anchorCycle * _pageCount) + _activeIndex;

  int _floorMod(int value, int divisor) {
    final remainder = value % divisor;
    return remainder < 0 ? remainder + divisor : remainder;
  }

  int _pageForVirtualIndex(int virtualIndex) {
    if (_pageCount == 0) return widget.activePage;
    return widget.paginationArray[_floorMod(virtualIndex, _pageCount)];
  }

  @override
  void didUpdateWidget(PaginationSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activePage != widget.activePage) {
      final newIndex = _nearestVirtualIndexForPage(widget.activePage);
      if (newIndex != _centerVirtualIndex) {
        _centerVirtualIndex = newIndex;
        if (widget.isPreviewing) {
          _jumpToVirtualIndex(newIndex);
        } else {
          _animateToVirtualIndex(newIndex);
        }
      }
    }
  }

  // ------------------------------------------------------------------
  // Scroll helpers
  // ------------------------------------------------------------------

  /// The scroll offset that places [virtualIndex] exactly at the viewport center.
  double _offsetForVirtualIndex(int virtualIndex) {
    if (!_scrollController.hasClients) return 0;
    final viewportW = _scrollController.position.viewportDimension;
    return (virtualIndex * _itemWidth) - (viewportW / 2) + (_itemWidth / 2);
  }

  int _nearestVirtualIndexForPage(int page) {
    final pageIndex = widget.paginationArray.indexOf(page);
    if (pageIndex == -1 || _pageCount == 0) return _centerVirtualIndex;

    final currentCycleStart =
        _centerVirtualIndex - _floorMod(_centerVirtualIndex, _pageCount);
    final candidates = [
      currentCycleStart - _pageCount + pageIndex,
      currentCycleStart + pageIndex,
      currentCycleStart + _pageCount + pageIndex,
    ];

    candidates.sort(
      (a, b) => (a - _centerVirtualIndex).abs().compareTo(
        (b - _centerVirtualIndex).abs(),
      ),
    );
    return candidates.first;
  }

  void _jumpToVirtualIndex(int index) {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_offsetForVirtualIndex(index));
  }

  void _animateToVirtualIndex(int index) {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _offsetForVirtualIndex(index),
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

    final closestIndex = (centerPixel / _itemWidth).round();

    if (closestIndex != _centerVirtualIndex) {
      setState(() {
        _centerVirtualIndex = closestIndex;
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
      _animateToVirtualIndex(_centerVirtualIndex);
      widget.onPageSelected(_pageForVirtualIndex(_centerVirtualIndex));
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
    if (_pageCount == 0) return const SizedBox.shrink();

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemExtent: _itemWidth,
        itemBuilder: (context, index) {
          final pageNum = _pageForVirtualIndex(index);
          final isActive = index == _centerVirtualIndex;
          final distance = (index - _centerVirtualIndex).abs();

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
              _centerVirtualIndex = index;
              widget.onPageSelected(pageNum);
              _animateToVirtualIndex(index);
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
                  boxShadow: isActive ? theme.shadowCard : null,
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
                            ? theme.scaffoldBackground.withValues(alpha: 0.7)
                            : theme.mutedText,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      pageNum.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0,
                        color: isActive
                            ? theme.scaffoldBackground
                            : theme.secondaryText,
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
            ? theme.scaffoldBackground.withValues(alpha: 0.7)
            : theme.mutedText,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
