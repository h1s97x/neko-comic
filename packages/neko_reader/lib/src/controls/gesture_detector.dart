import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// Gesture detector for reader interactions
class NekoReaderGestureDetector extends StatefulWidget {
  final Widget child;

  /// Single tap callback
  final VoidCallback? onTap;

  /// Double tap callback with position
  final void Function(Offset position)? onDoubleTap;

  /// Long press callback with position
  final void Function(Offset position)? onLongPress;

  /// Horizontal drag end callback
  final void Function(DragEndDetails details)? onHorizontalDragEnd;

  /// Vertical drag end callback
  final void Function(DragEndDetails details)? onVerticalDragEnd;

  /// Mouse wheel scroll callback
  final void Function(bool forward)? onMouseWheel;

  /// Enable double tap to zoom
  final bool enableDoubleTap;

  /// Double tap max time in milliseconds
  final int doubleTapMaxTime;

  /// Tap to turn page threshold percentage
  final double tapToTurnPagePercent;

  const NekoReaderGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onHorizontalDragEnd,
    this.onVerticalDragEnd,
    this.onMouseWheel,
    this.enableDoubleTap = true,
    this.doubleTapMaxTime = 200,
    this.tapToTurnPagePercent = 0.3,
  });

  @override
  State<NekoReaderGestureDetector> createState() => _NekoReaderGestureDetectorState();
}

class _NekoReaderGestureDetectorState extends State<NekoReaderGestureDetector> {
  TapDownDetails? _previousTap;
  Offset? _lastTapPosition;
  int? _lastTapPointer;
  Offset? _lastTapMoveDistance;
  bool _isLongPress = false;
  bool _isDragging = false;

  static const _kDoubleTapMaxDistanceSquared = 20.0 * 20.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (event.position == Offset.zero) {
          _previousTap = null;
          return;
        }

        _lastTapPointer = event.pointer;
        _lastTapMoveDistance = Offset.zero;

        // Start long press detection
        Future.delayed(const Duration(milliseconds: 250), () {
          if (_lastTapPointer == event.pointer && !_isDragging) {
            if (_lastTapMoveDistance?.distanceSquared ?? double.infinity < 400) {
              _isLongPress = true;
              widget.onLongPress?.call(event.localPosition);
            }
          }
        });
      },
      onPointerMove: (event) {
        if (event.pointer == _lastTapPointer) {
          _lastTapMoveDistance = event.delta + _lastTapMoveDistance!;

          // If moved too much, it's a drag not a tap
          if ((_lastTapMoveDistance?.distanceSquared ?? 0) > 400) {
            _isDragging = true;
          }
        }
      },
      onPointerUp: (event) {
        _handleTapUp(event.localPosition);
        _lastTapPointer = null;
        _lastTapMoveDistance = null;
      },
      onPointerCancel: (event) {
        _lastTapPointer = null;
        _lastTapMoveDistance = null;
        _isLongPress = false;
        _isDragging = false;
      },
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          widget.onMouseWheel?.call(event.scrollDelta.dy > 0);
        }
      },
      child: widget.child,
    );
  }

  void _handleTapUp(Offset position) {
    if (_isLongPress) {
      _isLongPress = false;
      return;
    }

    if (!widget.enableDoubleTap) {
      widget.onTap?.call();
      return;
    }

    // Double tap detection
    final previousPosition = _previousTap?.globalPosition;
    if (previousPosition != null) {
      final distance = (position - previousPosition).distanceSquared;
      if (distance < _kDoubleTapMaxDistanceSquared) {
        widget.onDoubleTap?.call(position);
        _previousTap = null;
        return;
      }
    }

    // Single tap with delay
    _previousTap = TapDownDetails(globalPosition: position);
    Future.delayed(Duration(milliseconds: widget.doubleTapMaxTime), () {
      if (_previousTap?.globalPosition == position) {
        _handleSingleTap(position);
        _previousTap = null;
      }
    });
  }

  void _handleSingleTap(Offset position) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tapZone = position.dx / screenWidth;

    // Left zone (30%) - previous
    if (tapZone < widget.tapToTurnPagePercent) {
      widget.onHorizontalDragEnd?.call(
        DragEndDetails(primaryVelocity: 100),
      );
    }
    // Right zone (70%) - next
    else if (tapZone > (1 - widget.tapToTurnPagePercent)) {
      widget.onHorizontalDragEnd?.call(
        DragEndDetails(primaryVelocity: -100),
      );
    }
    // Center - toggle UI
    else {
      widget.onTap?.call();
    }
  }
}

/// Simple gesture detector without tap zone detection
class NekoSimpleGestureDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final void Function(Offset position)? onDoubleTap;
  final void Function(Offset position)? onLongPress;
  final void Function(bool forward)? onMouseWheel;

  const NekoSimpleGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onMouseWheel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTapDown: (details) => onDoubleTap?.call(details.globalPosition),
      onLongPressStart: (details) => onLongPress?.call(details.globalPosition),
      onVerticalDragEnd: (details) {
        // Handle vertical swipe for webtoon mode
      },
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent && onMouseWheel != null) {
            onMouseWheel!(event.scrollDelta.dy > 0);
          }
        },
        child: child,
      ),
    );
  }
}
