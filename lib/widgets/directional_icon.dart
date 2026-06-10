import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An Icon wrapper that automatically flips/mirrors the icon horizontally
/// when the text direction is Right-to-Left (RTL).
class DirectionalIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;
  final TextDirection? textDirection;

  const DirectionalIcon({
    super.key,
    required this.icon,
    this.size,
    this.color,
    this.semanticLabel,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    final direction = textDirection ?? Directionality.of(context);
    if (direction == TextDirection.rtl) {
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: Icon(
          icon,
          size: size,
          color: color,
          semanticLabel: semanticLabel,
        ),
      );
    }
    return Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
  }
}
