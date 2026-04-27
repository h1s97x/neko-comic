import 'package:flutter/material.dart';

/// Shimmer loading effect widget
class NekoShimmer extends StatefulWidget {
  const NekoShimmer({
    super.key,
    required this.child,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 1500),
    this.color,
  });

  final Widget child;
  final bool enabled;
  final Duration duration;
  final Color? color;

  @override
  State<NekoShimmer> createState() => _NekoShimmerState();
}

class _NekoShimmerState extends State<NekoShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final baseColor = widget.color ?? theme.colorScheme.surfaceContainerHighest;
    final highlightColor = theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Chip widget for options/tags
class NekoOptionChip extends StatelessWidget {
  const NekoOptionChip({
    super.key,
    required this.text,
    this.isSelected = false,
    this.onTap,
    this.leading,
    this.trailing,
  });

  final String text;
  final bool isSelected;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 6),
              ],
              Text(
                text,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrap of option chips
class NekoChipWrap extends StatelessWidget {
  const NekoChipWrap({
    super.key,
    required this.options,
    required this.selected,
    this.onChanged,
    this.spacing = 8,
    this.runSpacing = 8,
  });

  final List<String> options;
  final Set<String> selected;
  final void Function(Set<String>)? onChanged;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return NekoOptionChip(
          text: option,
          isSelected: isSelected,
          onTap: () {
            final newSelected = Set<String>.from(selected);
            if (isSelected) {
              newSelected.remove(option);
            } else {
              newSelected.add(option);
            }
            onChanged?.call(newSelected);
          },
        );
      }).toList(),
    );
  }
}
