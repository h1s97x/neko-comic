import 'package:flutter/material.dart';

/// Custom icon button widget
class NekoIconButton extends StatefulWidget {
  const NekoIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 24,
    this.color,
    this.tooltip,
    this.isLoading = false,
    this.borderRadius = 8,
    this.backgroundColor,
  });

  /// Icon widget
  final Widget icon;

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Size of the icon
  final double size;

  /// Color of the icon
  final Color? color;

  /// Tooltip text
  final String? tooltip;

  /// Loading state
  final bool isLoading;

  /// Border radius
  final double borderRadius;

  /// Background color
  final Color? backgroundColor;

  @override
  State<NekoIconButton> createState() => _NekoIconButtonState();
}

class _NekoIconButtonState extends State<NekoIconButton> {
  bool _isHover = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = widget.color ?? theme.colorScheme.onSurface;

    Widget button = Material(
      color: _getBackgroundColor(theme),
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        onTap: widget.isLoading ? null : widget.onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: widget.size + 8,
            height: widget.size + 8,
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: effectiveColor,
                      ),
                    )
                  : IconTheme(
                      data: IconThemeData(
                        size: widget.size,
                        color: effectiveColor,
                      ),
                      child: widget.icon,
                    ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      child: button,
    );
  }

  Color? _getBackgroundColor(ThemeData theme) {
    if (widget.backgroundColor != null) {
      return widget.backgroundColor;
    }

    if (_isPressed) {
      return theme.colorScheme.surfaceContainerHighest;
    }

    if (_isHover) {
      return theme.colorScheme.surfaceContainerHigh;
    }

    return null;
  }
}

/// Icon button with dropdown menu
class NekoIconButtonWithMenu extends StatelessWidget {
  const NekoIconButtonWithMenu({
    super.key,
    required this.icon,
    required this.onSelected,
    this.items = const [],
    this.tooltip,
    this.size = 24,
    this.color,
  });

  final Widget icon;
  final void Function(String) onSelected;
  final List<PopupMenuEntry<String>> items;
  final String? tooltip;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    Widget button = PopupMenuButton<String>(
      icon: IconTheme(
        data: IconThemeData(size: size, color: color),
        child: icon,
      ),
      onSelected: onSelected,
      itemBuilder: (context) => items,
      tooltip: tooltip,
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
