import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

class SessionSpotlightMask extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final VoidCallback? onTap;

  const SessionSpotlightMask({
    super.key,
    required this.child,
    required this.isActive,
    this.onTap,
  });

  @override
  State<SessionSpotlightMask> createState() => _SessionSpotlightMaskState();
}

class _SessionSpotlightMaskState extends State<SessionSpotlightMask>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  Offset? _touchOffset;
  double _pressure = 0.5;
  int? _activePointerId;
  Duration? _downTime;
  Offset? _downPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // Grow speed
      reverseDuration: const Duration(
        milliseconds: 350,
      ), // Slow smooth fade out
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _animation.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        setState(() {
          _touchOffset = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.isActive) return;
    if (_activePointerId != null) return; // Lock to first pointer

    _activePointerId = event.pointer;
    _downTime = event.timeStamp;
    _downPosition = event.localPosition;
    _updatePointer(event);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!widget.isActive) return;
    if (event.pointer != _activePointerId) return; // Ignore secondary touches

    _updatePointer(event);
  }

  void _updatePointer(PointerEvent event) {
    // Calculate scaled pressure
    double rawPressure = event.pressure;
    if (event.kind == PointerDeviceKind.touch) {
      // Fallback for touch interface without hardware pressure sensitivity
      // If event.size is 0.0 (unsupported), fallback to 0.5 default
      rawPressure = event.size > 0.0 ? event.size.clamp(0.1, 1.0) : 0.5;
    } else if (event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus) {
      // Stylus devices support high-precision analog pressure up to 1.0
      rawPressure = rawPressure.clamp(0.1, 1.0);
    } else if (rawPressure <= 0.0 || rawPressure == 1.0) {
      // Fallback when hardware reports binary pressure (e.g., mouse clicks)
      rawPressure = 0.5;
    }

    setState(() {
      _touchOffset = event.localPosition;
      _pressure = rawPressure;
    });

    // Check status != forward to allow interrupting reverse animations cleanly
    if (_controller.status != AnimationStatus.forward &&
        _controller.value < 1.0) {
      _controller.forward();
    }
  }

  void _onPointerUpOrCancel(PointerEvent event) {
    if (!widget.isActive) return;
    if (event.pointer != _activePointerId) return;

    if (_downTime != null && _downPosition != null) {
      final duration = event.timeStamp - _downTime!;
      final distance = (event.localPosition - _downPosition!).distance;
      if (duration.inMilliseconds < 500 && distance < 25.0) {
        widget.onTap?.call();
      }
    }

    _activePointerId = null;
    _downTime = null;
    _downPosition = null;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }

    final theme = context.watch<ThemeProvider>();
    final maskColor = theme.scaffoldBackground;

    return Stack(
      children: [
        // Disable interaction with the underlying text canvas when masked.
        // Wrap child in a RepaintBoundary to isolate repaint and avoid heavy CPU text paints.
        IgnorePointer(child: RepaintBoundary(child: widget.child)),

        // Intercept all touches on top of the mask
        Positioned.fill(
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerMove: _onPointerMove,
            onPointerUp: _onPointerUpOrCancel,
            onPointerCancel: _onPointerUpOrCancel,
            behavior: HitTestBehavior.opaque,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  return CustomPaint(
                    painter: MaskPainter(
                      pointerOffset: _touchOffset,
                      revealFactor: _animation.value,
                      pressure: _pressure,
                      maskColor: maskColor,
                      minRadius: theme.spotlightMinRadius,
                      midRadius: theme.spotlightMidRadius,
                      curveType: theme.spotlightCurveType,
                      maskOpacity: theme.spotlightMaskOpacity,
                      feathering: theme.spotlightFeathering,
                      sensitivity: theme.spotlightSensitivity,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MaskPainter extends CustomPainter {
  final Offset? pointerOffset;
  final double revealFactor;
  final double pressure;
  final Color maskColor;
  final double minRadius;
  final double midRadius;
  final SpotlightCurveType curveType;
  final double maskOpacity;
  final double feathering;
  final double sensitivity;

  MaskPainter({
    required this.pointerOffset,
    required this.revealFactor,
    required this.pressure,
    required this.maskColor,
    required this.minRadius,
    required this.midRadius,
    required this.curveType,
    required this.maskOpacity,
    required this.feathering,
    required this.sensitivity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Save canvas layer to support alpha blend modes
    canvas.saveLayer(rect, Paint());

    // 1. Draw solid background color matching the canvas theme background with custom opacity
    final maskPaint = Paint()..color = maskColor.withValues(alpha: maskOpacity);
    canvas.drawRect(rect, maskPaint);

    // 2. Erase spotlight circle with radial transparency gradient
    if (pointerOffset != null && revealFactor > 0.0) {
      final double maxDimension = size.longestSide;
      // Circle needs to be at least 1.5x the longest side to guarantee full screen clearance
      final double maxRadius = maxDimension * 1.5;

      // Normalize pressure from [0.1, 1.0] range to [0.0, 1.0]
      final double normalizedPressure = ((pressure - 0.1) / 0.9).clamp(
        0.0,
        1.0,
      );

      // Apply sensitivity scaling
      final double p = (normalizedPressure * sensitivity).clamp(0.0, 1.0);

      // Compute scaling factor based on the selected curve type
      double targetRadius;
      switch (curveType) {
        case SpotlightCurveType.linear:
          targetRadius = minRadius + p * (maxRadius - minRadius);
          break;
        case SpotlightCurveType.quadratic:
          targetRadius = minRadius + (p * p) * (maxRadius - minRadius);
          break;
        case SpotlightCurveType.quartic:
          targetRadius = minRadius + (p * p * p * p) * (maxRadius - minRadius);
          break;
        case SpotlightCurveType.dualZone:
          if (p <= 0.5) {
            final double t = p / 0.5;
            targetRadius = minRadius + t * (midRadius - minRadius);
          } else {
            final double t = (p - 0.5) / 0.5;
            targetRadius = midRadius + (t * t) * (maxRadius - midRadius);
          }
          break;
      }

      final double radius = targetRadius * revealFactor;

      // Compute feathering stops to create soft fading transition
      final double stopStart = (1.0 - feathering).clamp(0.0, 0.999);
      final gradientPaint = Paint()
        ..shader = RadialGradient(
          colors: const [Colors.black, Colors.transparent],
          stops: [stopStart, 1.0],
        ).createShader(Rect.fromCircle(center: pointerOffset!, radius: radius))
        ..blendMode = BlendMode.dstOut;

      canvas.drawCircle(pointerOffset!, radius, gradientPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MaskPainter oldDelegate) {
    return oldDelegate.pointerOffset != pointerOffset ||
        oldDelegate.revealFactor != revealFactor ||
        oldDelegate.pressure != pressure ||
        oldDelegate.maskColor != maskColor ||
        oldDelegate.minRadius != minRadius ||
        oldDelegate.midRadius != midRadius ||
        oldDelegate.curveType != curveType ||
        oldDelegate.maskOpacity != maskOpacity ||
        oldDelegate.feathering != feathering ||
        oldDelegate.sensitivity != sensitivity;
  }
}
