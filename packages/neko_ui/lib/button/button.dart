import 'package:flutter/material.dart';

/// Button type enum
enum NekoButtonType {
  filled,
  outlined,
  text,
  normal,
}

/// Custom button widget
class NekoButton extends StatefulWidget {
  const NekoButton({
    super.key,
    required this.type,
    required this.child,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
    this.color,
    this.icon,
  });

  const NekoButton.filled({
    super.key,
    required this.child,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
    this.color,
    this.icon,
  }) : type = NekoButtonType.filled;

  const NekoButton.outlined({
    super.key,
    required this.child,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
    this.color,
    this.icon,
  }) : type = NekoButtonType.outlined;

  const NekoButton.text({
    super.key,
    required this.child,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
    this.color,
    this.icon,
  }) : type = NekoButtonType.text;

  const NekoButton.normal({
    super.key,
    required this.child,
    required this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.padding,
    this.color,
    this.icon,
  }) : type = NekoButtonType.normal;

  final NekoButtonType type;
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final Color? color;
  final IconData? icon;

  @override
  State<NekoButton> createState() => _NekoButtonState();
}

class _NekoButtonState extends State<NekoButton> {
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18),
          const SizedBox(width: 8),
        ],
        widget.child,
        if (widget.isLoading) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.type == NekoButtonType.filled
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
          ),
        ],
      ],
    );

    Widget button;
    final effectivePadding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    switch (widget.type) {
      case NekoButtonType.filled:
        button = FilledButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: FilledButton.styleFrom(
            padding: effectivePadding,
            minimumSize: Size(widget.width ?? 0, widget.height ?? 0),
            backgroundColor: widget.color,
          ),
          child: buttonChild,
        );
        break;

      case NekoButtonType.outlined:
        button = OutlinedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: OutlinedButton.styleFrom(
            padding: effectivePadding,
            minimumSize: Size(widget.width ?? 0, widget.height ?? 0),
            foregroundColor: widget.color,
          ),
          child: buttonChild,
        );
        break;

      case NekoButtonType.text:
        button = TextButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: TextButton.styleFrom(
            padding: effectivePadding,
            minimumSize: Size(widget.width ?? 0, widget.height ?? 0),
            foregroundColor: widget.color,
          ),
          child: buttonChild,
        );
        break;

      case NekoButtonType.normal:
        button = ElevatedButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            padding: effectivePadding,
            minimumSize: Size(widget.width ?? 0, widget.height ?? 0),
            backgroundColor: widget.color,
          ),
          child: buttonChild,
        );
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: button,
      ),
    );
  }
}
