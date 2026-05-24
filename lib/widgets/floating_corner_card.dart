import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

/// A premium, glassmorphic floating corner card with diagonal slide-out animation.
///
/// Designed for tablet/desktop split layout overlays. Automatically mirrors
/// horizontal slide animation offsets for RTL layouts (e.g. Arabic locale).
class FloatingCornerCard extends StatelessWidget {
  final Widget child;
  final AlignmentGeometry alignment;
  final Offset slideOffset;
  final bool isFullScreen;
  final double maxWidth;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const FloatingCornerCard({
    super.key,
    required this.child,
    required this.alignment,
    required this.slideOffset,
    required this.isFullScreen,
    this.maxWidth = 360.0,
    this.height,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final xMultiplier = isRTL ? -1.0 : 1.0;

    // Flip horizontal direction of the slide-out vector for RTL layouts
    final actualSlideOffset = Offset(
      slideOffset.dx * xMultiplier,
      slideOffset.dy,
    );

    return Align(
      alignment: alignment,
      child: AnimatedSlide(
        offset: isFullScreen ? actualSlideOffset : Offset.zero,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          height: height,
          margin: margin ?? const EdgeInsets.all(24.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                padding: padding ?? const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  // Slightly transparent cardColor to support backdrop blur
                  color: theme.cardColor.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24.0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
