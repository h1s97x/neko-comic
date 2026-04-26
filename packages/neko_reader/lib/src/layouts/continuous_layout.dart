import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../reader_mode.dart';

/// Continuous scroll layout for webtoon style reading
class NekoContinuousLayout extends StatefulWidget {
  /// Image URLs
  final List<String> images;

  /// Scroll controller
  final ItemScrollController scrollController;

  /// Positions listener
  final ItemPositionsListener positionsListener;

  /// Layout mode
  final ReaderLayout layout;

  /// Image builder function
  final ImageProvider Function(String url)? imageBuilder;

  /// Initial index
  final int initialIndex;

  /// Callback when index changes
  final void Function(int index)? onIndexChanged;

  const NekoContinuousLayout({
    super.key,
    required this.images,
    required this.scrollController,
    required this.positionsListener,
    required this.layout,
    this.imageBuilder,
    this.initialIndex = 0,
    this.onIndexChanged,
  });

  @override
  State<NekoContinuousLayout> createState() => _NekoContinuousLayoutState();
}

class _NekoContinuousLayoutState extends State<NekoContinuousLayout> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  ImageProvider _defaultImageBuilder(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return NetworkImage(url);
    }
    return AssetImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final imageBuilder = widget.imageBuilder ?? _defaultImageBuilder;
    final isVertical = widget.layout == ReaderLayout.vertical ||
                        widget.layout == ReaderLayout.webtoon;

    return ScrollablePositionedList.builder(
      itemCount: widget.images.length,
      itemScrollController: widget.scrollController,
      itemPositionsListener: widget.positionsListener,
      initialScrollIndex: widget.initialIndex,
      scrollDirection: isVertical ? Axis.vertical : Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final imageUrl = widget.images[index];

        return _NekoContinuousImageItem(
          key: ValueKey('image_$index'),
          imageUrl: imageUrl,
          imageBuilder: imageBuilder,
          index: index,
          isVertical: isVertical,
          onVisible: () {
            if (_currentIndex != index) {
              setState(() {
                _currentIndex = index;
              });
              widget.onIndexChanged?.call(index);
            }
          },
        );
      },
    );
  }
}

class _NekoContinuousImageItem extends StatefulWidget {
  final String imageUrl;
  final ImageProvider Function(String url)? imageBuilder;
  final int index;
  final bool isVertical;
  final VoidCallback? onVisible;

  const _NekoContinuousImageItem({
    super.key,
    required this.imageUrl,
    this.imageBuilder,
    required this.index,
    required this.isVertical,
    this.onVisible,
  });

  @override
  State<_NekoContinuousImageItem> createState() => _NekoContinuousImageItemState();
}

class _NekoContinuousImageItemState extends State<_NekoContinuousImageItem> {
  bool _isVisible = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _isVisible = true;
    if (_isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onVisible?.call();
      });
    }
  }

  ImageProvider _getProvider() {
    if (widget.imageBuilder != null) {
      return widget.imageBuilder!(widget.imageUrl);
    }
    if (widget.imageUrl.startsWith('http')) {
      return NetworkImage(widget.imageUrl);
    }
    return AssetImage(widget.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isVertical ? double.infinity : null,
      constraints: widget.isVertical
          ? null
          : BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
      child: Image(
        image: _getProvider(),
        fit: widget.isVertical ? BoxFit.fitWidth : BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            _isLoaded = true;
            return child;
          }
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: frame != null
                ? child
                : Container(
                    color: Colors.grey[900],
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.grey[600],
                        strokeWidth: 2,
                      ),
                    ),
                  ),
          );
        },
        errorBuilder: (context, error, stack) {
          return Container(
            color: Colors.grey[900],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    color: Colors.grey[700],
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loadingBuilder: (context, event) {
          return Container(
            color: Colors.grey[900],
            child: Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? null
                    : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                color: Colors.grey[600],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Webtoon specific layout with optimized settings
class NekoWebtoonLayout extends StatelessWidget {
  final List<String> images;
  final ItemScrollController scrollController;
  final ItemPositionsListener positionsListener;
  final ImageProvider Function(String url)? imageBuilder;
  final int initialIndex;
  final void Function(int index)? onIndexChanged;

  const NekoWebtoonLayout({
    super.key,
    required this.images,
    required this.scrollController,
    required this.positionsListener,
    this.imageBuilder,
    this.initialIndex = 0,
    this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NekoContinuousLayout(
      images: images,
      scrollController: scrollController,
      positionsListener: positionsListener,
      layout: ReaderLayout.webtoon,
      imageBuilder: imageBuilder,
      initialIndex: initialIndex,
      onIndexChanged: onIndexChanged,
    );
  }
}
