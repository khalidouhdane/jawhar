import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

class AnimatedSvgIcon extends ImplicitlyAnimatedWidget {
  final String svgPath;
  final double width;
  final double height;
  final Color color;
  final bool isSelected;
  final Rect viewBounds;

  const AnimatedSvgIcon({
    super.key,
    required this.svgPath,
    required this.width,
    required this.height,
    required this.color,
    required this.isSelected,
    required this.viewBounds,
    super.duration = const Duration(milliseconds: 300),
    super.curve = Curves.easeOutCubic,
  });

  @override
  AnimatedWidgetBaseState<AnimatedSvgIcon> createState() =>
      _AnimatedSvgIconState();
}

class _AnimatedSvgIconState extends AnimatedWidgetBaseState<AnimatedSvgIcon> {
  ColorTween? _colorTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _colorTween =
        visitor(
              _colorTween,
              widget.color,
              (dynamic value) => ColorTween(begin: value as Color),
            )
            as ColorTween?;
  }

  @override
  Widget build(BuildContext context) {
    final Path path = parseSvgPathData(widget.svgPath);
    return CustomPaint(
      size: Size(widget.width, widget.height),
      painter: _SvgFillPainter(
        path: path,
        color: _colorTween?.evaluate(animation) ?? widget.color,
        viewBox: widget.viewBounds,
      ),
    );
  }
}

class _SvgFillPainter extends CustomPainter {
  final Path path;
  final Color color;
  final Rect viewBox;

  _SvgFillPainter({
    required this.path,
    required this.color,
    required this.viewBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale path correctly to fit within `size` considering original `viewBox`.
    final double scaleX = size.width / viewBox.width;
    final double scaleY = size.height / viewBox.height;

    // Scale and translate the path to fit inside the given canvas size perfectly.
    final Matrix4 matrix = Matrix4.identity()
      ..scale(scaleX, scaleY)
      ..translate(-viewBox.left, -viewBox.top);

    final Path scaledPath = path.transform(matrix.storage);

    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(scaledPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SvgFillPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.path != path;
  }
}
