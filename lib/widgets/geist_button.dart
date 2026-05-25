import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/geist_tokens.dart';

enum GeistButtonType { primary, secondary, tertiary, error, warning }

enum GeistButtonShape { rounded, square }

enum GeistButtonSize { large, medium, small, tiny }

class GeistButton extends StatefulWidget {
  final String? label;
  final Widget? icon; // Used when svgOnly is true, or generic icon usage
  final Widget? prefix;
  final Widget? suffix;
  final GeistButtonType type;
  final GeistButtonShape shape;
  final GeistButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final bool svgOnly;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;

  const GeistButton({
    super.key,
    required this.label,
    this.prefix,
    this.suffix,
    this.type = GeistButtonType.primary,
    this.shape = GeistButtonShape.rounded,
    this.size = GeistButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.onPressed,
    this.padding,
  }) : svgOnly = false,
       icon = null;

  const GeistButton.icon({
    super.key,
    required this.icon,
    this.type = GeistButtonType.primary,
    this.shape = GeistButtonShape.square, // Default to square for icons
    this.size = GeistButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.onPressed,
    this.padding,
  }) : svgOnly = true,
       label = null,
       prefix = null,
       suffix = null;

  @override
  State<GeistButton> createState() => _GeistButtonState();
}

class _GeistButtonState extends State<GeistButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final effectiveDisabled = widget.isDisabled || widget.isLoading;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: effectiveDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: effectiveDisabled
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: effectiveDisabled
            ? null
            : (_) => setState(() => _isPressed = false),
        onTapCancel: effectiveDisabled
            ? null
            : () => setState(() => _isPressed = false),
        onTap: effectiveDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _getBackgroundColor(theme),
            borderRadius: BorderRadius.circular(_getBorderRadius()),
            border: _getBorder(theme),
            boxShadow: _getBoxShadow(theme),
          ),
          padding: widget.padding ?? _getPadding(),
          child: _buildContent(theme),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeProvider theme) {
    if (widget.isLoading) {
      return SizedBox(
        width: _getIconSize(),
        height: _getIconSize(),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_getTextColor(theme)),
        ),
      );
    }

    if (widget.svgOnly && widget.icon != null) {
      return IconTheme(
        data: IconThemeData(color: _getTextColor(theme), size: _getIconSize()),
        child: widget.icon!,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.prefix != null) ...[
          IconTheme(
            data: IconThemeData(
              color: _getTextColor(theme),
              size: _getIconSize(),
            ),
            child: widget.prefix!,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label ?? '',
          style: theme.textButton.copyWith(
            color: _getTextColor(theme),
            fontSize: _getFontSize(),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (widget.suffix != null) ...[
          const SizedBox(width: 8),
          IconTheme(
            data: IconThemeData(
              color: _getTextColor(theme),
              size: _getIconSize(),
            ),
            child: widget.suffix!,
          ),
        ],
      ],
    );
  }

  Color _getBackgroundColor(ThemeProvider theme) {
    Color baseColor;
    switch (widget.type) {
      case GeistButtonType.primary:
        baseColor = theme.buttonDefaultBg;
        break;
      case GeistButtonType.secondary:
        baseColor = theme.buttonSecondaryBg;
        break;
      case GeistButtonType.tertiary:
        baseColor = Colors.transparent;
        break;
      case GeistButtonType.warning:
        baseColor = theme.buttonWarningBg;
        break;
      case GeistButtonType.error:
        baseColor = theme.buttonErrorBg;
        break;
    }

    if (widget.isDisabled) {
      if (widget.type == GeistButtonType.tertiary) {
        return Colors.transparent;
      }
      return baseColor.withValues(alpha: 0.5);
    }

    if (_isPressed) {
      if (widget.type == GeistButtonType.tertiary) {
        return theme.isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05);
      }
      return baseColor.withValues(alpha: 0.8);
    }

    if (_isHovered) {
      if (widget.type == GeistButtonType.tertiary) {
        return theme.isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03);
      }
      return baseColor.withValues(alpha: 0.9);
    }

    return baseColor;
  }

  Color _getTextColor(ThemeProvider theme) {
    Color baseColor;
    switch (widget.type) {
      case GeistButtonType.primary:
        baseColor = theme.buttonDefaultText;
        break;
      case GeistButtonType.secondary:
        baseColor = theme.buttonSecondaryText;
        break;
      case GeistButtonType.tertiary:
        baseColor = theme.buttonTertiaryText;
        break;
      case GeistButtonType.warning:
        baseColor = theme.buttonWarningText;
        break;
      case GeistButtonType.error:
        baseColor = theme.buttonErrorText;
        break;
    }

    if (widget.isDisabled) {
      return baseColor.withValues(alpha: 0.5);
    }

    return baseColor;
  }

  BoxBorder? _getBorder(ThemeProvider theme) {
    if (widget.type == GeistButtonType.secondary) {
      return Border.all(
        color: widget.isDisabled
            ? theme.buttonSecondaryBorder.withValues(alpha: 0.5)
            : theme.buttonSecondaryBorder,
        width: 1,
      );
    }
    return null;
  }

  List<BoxShadow>? _getBoxShadow(ThemeProvider theme) {
    if (widget.type == GeistButtonType.tertiary || widget.isDisabled) {
      return null;
    }
    return theme.shadowRing;
  }

  double _getBorderRadius() {
    switch (widget.shape) {
      case GeistButtonShape.rounded:
        return GeistTokens.radiusMd;
      case GeistButtonShape.square:
        return GeistTokens.radiusMd;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    if (widget.svgOnly) {
      switch (widget.size) {
        case GeistButtonSize.large:
          return const EdgeInsets.all(12);
        case GeistButtonSize.medium:
          return const EdgeInsets.all(10);
        case GeistButtonSize.small:
          return const EdgeInsets.all(8);
        case GeistButtonSize.tiny:
          return const EdgeInsets.all(6);
      }
    }

    switch (widget.size) {
      case GeistButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 14);
      case GeistButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
      case GeistButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case GeistButtonSize.tiny:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case GeistButtonSize.large:
        return 16.0;
      case GeistButtonSize.medium:
        return 14.0;
      case GeistButtonSize.small:
        return 13.0;
      case GeistButtonSize.tiny:
        return 12.0;
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case GeistButtonSize.large:
        return 20.0;
      case GeistButtonSize.medium:
        return 18.0;
      case GeistButtonSize.small:
        return 16.0;
      case GeistButtonSize.tiny:
        return 14.0;
    }
  }
}
