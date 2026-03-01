import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

class AnimatedSvgIcon extends StatefulWidget {
  final String svgPath;
  final double width;
  final double height;
  final Color color;
  final bool fill;
  final Duration duration;
  final bool isSelected;
  final Rect viewBounds;

  const AnimatedSvgIcon({
    super.key,
    required this.svgPath,
    required this.width,
    required this.height,
    required this.color,
    required this.isSelected,
    this.fill = true,
    required this.viewBounds,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<AnimatedSvgIcon> createState() => _AnimatedSvgIconState();
}

class _AnimatedSvgIconState extends State<AnimatedSvgIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Path _path;

  @override
  void initState() {
    super.initState();
    _path = parseSvgPathData(widget.svgPath);
    _controller = AnimationController(
        vsync: this,
        duration: widget.duration,
        value: widget.isSelected ? 1.0 : 0.0);
  }

  @override
  void didUpdateWidget(AnimatedSvgIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.svgPath != oldWidget.svgPath) {
      _path = parseSvgPathData(widget.svgPath);
    }
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reverse(from: 1.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _SvgPathPainter(
            path: _path,
            color: widget.color,
            progress: CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic).value,
            fill: widget.fill,
            viewBox: widget.viewBounds,
          ),
        );
      },
    );
  }
}

class _SvgPathPainter extends CustomPainter {
  final Path path;
  final Color color;
  final double progress;
  final bool fill;
  final Rect viewBox;

  _SvgPathPainter({
    required this.path,
    required this.color,
    required this.progress,
    required this.fill,
    required this.viewBox,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0) return;

    // Scale path correctly to fit within `size` considering original `viewBox`.
    final double scaleX = size.width / viewBox.width;
    final double scaleY = size.height / viewBox.height;
    
    // Scale and translate the path to fit inside the given canvas size perfectly.
    final Matrix4 matrix = Matrix4.identity()
      ..scale(scaleX, scaleY)
      ..translate(-viewBox.left, -viewBox.top);
      
    final Path scaledPath = path.transform(matrix.storage);

    final Paint outlinePaint = Paint()
      ..color = color.withValues(alpha: fill ? 1.0 : progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint fillPaint = Paint()
      ..color = color.withValues(alpha: fill ? progress : 0.0)
      ..style = PaintingStyle.fill;

    // We do a GSAP-like draw path effect
    if (progress < 1.0) {
      final Path drawPath = Path();
      for (ui.PathMetric metric in scaledPath.computeMetrics()) {
        final double length = metric.length;
        // Drawing an outline first as if someone is hand-drawing it
        drawPath.addPath(
          metric.extractPath(0.0, length * progress),
          Offset.zero,
        );
      }
      canvas.drawPath(drawPath, outlinePaint);
      
      if (fill && progress > 0.5) {
         final fillOpacity = (progress - 0.5) * 2;
         canvas.drawPath(scaledPath, fillPaint..color = color.withValues(alpha: fillOpacity));
      }
    } else {
      // fully drawn
      if (fill) {
        canvas.drawPath(scaledPath, fillPaint..color = color);
      } else {
        canvas.drawPath(scaledPath, outlinePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SvgPathPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.path != path;
  }
}
