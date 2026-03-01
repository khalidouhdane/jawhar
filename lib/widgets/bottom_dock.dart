import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

class BottomDock extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final totalPages = paginationArray.isNotEmpty
        ? paginationArray.length
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
                  surahName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryText,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  juzName,
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
                  onTap: onNavMenuTapped,
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
                      activePage: activePage,
                      paginationArray: paginationArray,
                      onPageSelected: onPageSelected,
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
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: ExcludeSemantics(
                  child: Slider(
                    value: activePage.toDouble(),
                    min: 1,
                    max: totalPages.toDouble(),
                    onChanged: (val) {
                      onPageSelected(val.round());
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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActive());
  }

  @override
  void didUpdateWidget(PaginationSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activePage != widget.activePage) {
      _scrollToActive();
    }
  }

  void _scrollToActive() {
    final index = widget.paginationArray.indexOf(widget.activePage);
    if (index == -1 || !_scrollController.hasClients) return;

    final viewportWidth = _scrollController.position.viewportDimension;
    final targetOffset =
        (index * _itemWidth) - (viewportWidth / 2) + (_itemWidth / 2);
    final clampedOffset = targetOffset.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: widget.paginationArray.length,
      itemBuilder: (context, index) {
        final pageNum = widget.paginationArray[index];
        final isActive = pageNum == widget.activePage;
        final activeIndex = widget.paginationArray.indexOf(widget.activePage);
        final distance = (index - activeIndex).abs();

        double targetOpacity = 1.0;
        if (!isActive) {
          if (distance == 1) {
            targetOpacity = 0.5;
          } else if (distance == 2) {
            targetOpacity = 0.35;
          } else if (distance == 3) {
            targetOpacity = 0.2;
          } else if (distance == 4) {
            targetOpacity = 0.1;
          } else {
            targetOpacity = 0.05;
          }
        }

        return GestureDetector(
          onTap: () => widget.onPageSelected(pageNum),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: targetOpacity,
            child: Container(
              width: _itemWidth - 8,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? theme.accentColor : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: isActive ? null : Border.all(color: theme.accentColor),
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
                  Container(
                    width: 14,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.7)
                          : theme.accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withValues(alpha: 0.7)
                          : theme.accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
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
    );
  }
}
