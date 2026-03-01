import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, -10),
          )
        ],
      ),
      padding: EdgeInsets.only(
        top: 20, 
        bottom: MediaQuery.paddingOf(context).bottom > 0 
            ? MediaQuery.paddingOf(context).bottom + 12 
            : 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  surahName,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5),
                ),
                Text(
                  juzName,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: onNavMenuTapped,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.list, size: 20, color: Color(0xFF1A454E)),
                  ),
                ),
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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[100]!),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4),
                    ]
                  ),
                  child: const Icon(LucideIcons.bookmark, size: 18, color: Color(0xFF1A454E)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              height: 16,
              margin: const EdgeInsets.only(top: 8),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  activeTrackColor: const Color(0xFF1A454E),
                  inactiveTrackColor: Colors.grey[200],
                  thumbColor: Colors.transparent,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: ExcludeSemantics(
                  child: Slider(
                    value: activePage.toDouble(),
                    min: 1,
                    max: paginationArray.isNotEmpty ? paginationArray.length.toDouble() : 604,
                    onChanged: (val) {
                      onPageSelected(val.round());
                    },
                  ),
                ),
              ),
            ),
          )
        ],
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
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    int initialIndex = widget.paginationArray.indexOf(widget.activePage);
    if (initialIndex == -1) initialIndex = 0;
    _controller = PageController(viewportFraction: 0.15, initialPage: initialIndex);
  }

  @override
  void didUpdateWidget(PaginationSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activePage != widget.activePage) {
      int index = widget.paginationArray.indexOf(widget.activePage);
      if (_controller.hasClients && index != -1 && _controller.page?.round() != index) {
        _controller.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        widget.onPageSelected(widget.paginationArray[index]);
      },
      itemCount: widget.paginationArray.length,
      itemBuilder: (context, index) {
        final pageNum = widget.paginationArray[index];
        final isActive = pageNum == widget.activePage;
        final activeIndex = widget.paginationArray.indexOf(widget.activePage);
        final distance = (index - activeIndex).abs();
        
        double targetOpacity = 1.0;
        if (!isActive) {
          if (distance == 1) targetOpacity = 0.4;
          else if (distance == 2) targetOpacity = 0.3;
          else if (distance == 3) targetOpacity = 0.2;
          else if (distance == 4) targetOpacity = 0.1;
          else targetOpacity = 0.03;
        }

        return GestureDetector(
          onTap: () => widget.onPageSelected(pageNum),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: targetOpacity,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              width: isActive ? 28 : 26,
              decoration: BoxDecoration(
              color: isActive ? const Color(0xFF1A454E) : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isActive ? null : Border.all(color: const Color(0xFF1A454E)),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1A454E).withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
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
                    color: isActive ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1A454E),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 14,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1A454E),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  width: 14,
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF1A454E),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  pageNum.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0,
                    color: isActive ? Colors.white : const Color(0xFF1A454E),
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

