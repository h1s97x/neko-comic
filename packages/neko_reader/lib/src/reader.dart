import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'reader_mode.dart';
import 'reader_state.dart';
import 'layouts/gallery_layout.dart';
import 'layouts/continuous_layout.dart';
import 'controls/gesture_detector.dart';

export 'reader_mode.dart';

/// Main comic reader widget
class NekoReader extends StatefulWidget {
  /// Image URLs or paths
  final List<String> images;

  /// Initial page index (0-based)
  final int initialIndex;

  /// Reader layout mode
  final ReaderLayout layout;

  /// Callback when page changes
  final void Function(int index)? onPageChanged;

  /// Callback when tapped
  final VoidCallback? onTap;

  /// Callback when long pressed
  final void Function(int index)? onLongPress;

  /// Callback when double tapped
  final void Function(int index)? onDoubleTap;

  /// Whether to show UI controls
  final bool showControls;

  /// Image loading function
  final ImageProvider Function(String url)? imageBuilder;

  /// Preload count
  final int preloadCount;

  /// Current comic id (for settings)
  final String? comicId;

  /// Reader settings
  final NekoReaderSettings? settings;

  const NekoReader({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.layout = ReaderLayout.rightToLeft,
    this.onPageChanged,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.showControls = true,
    this.imageBuilder,
    this.preloadCount = 3,
    this.comicId,
    this.settings,
  });

  @override
  State<NekoReader> createState() => NekoReaderState();
}

class NekoReaderState extends State<NekoReader>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late PageController _pageController;
  late ItemScrollController _scrollController;
  late ItemPositionsListener _positionsListener;
  bool _isUiVisible = true;
  bool _isLoading = true;

  final _settings = NekoReaderSettings();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _scrollController = ItemScrollController();
    _positionsListener = ItemPositionsListener.create();

    // Apply custom settings
    if (widget.settings != null) {
      _settings.copyFrom(widget.settings!);
    }

    _setupSystemUi();
  }

  void _setupSystemUi() {
    if (!_settings.showSystemStatusBar) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  void toggleUi() {
    setState(() {
      _isUiVisible = !_isUiVisible;
    });
  }

  void goToPage(int index) {
    if (index < 0 || index >= widget.images.length) return;

    if (widget.layout.isGallery) {
      _pageController.animateToPage(
        index,
        duration: _settings.pageAnimationDuration,
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.scrollTo(
        index: index,
        duration: _settings.pageAnimationDuration,
        curve: Curves.easeInOut,
      );
    }

    setState(() {
      _currentIndex = index;
    });

    widget.onPageChanged?.call(index);
  }

  void nextPage() {
    if (_currentIndex < widget.images.length - 1) {
      goToPage(_currentIndex + 1);
    }
  }

  void previousPage() {
    if (_currentIndex > 0) {
      goToPage(_currentIndex - 1);
    }
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          NekoReaderGestureDetector(
            onTap: () {
              toggleUi();
              widget.onTap?.call();
            },
            onDoubleTap: widget.onDoubleTap != null
                ? (offset) => widget.onDoubleTap!(_currentIndex)
                : null,
            onLongPress: widget.onLongPress != null
                ? (offset) => widget.onLongPress!(_currentIndex)
                : null,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (velocity.abs() > 100) {
                if (widget.layout == ReaderLayout.rightToLeft) {
                  velocity > 0 ? previousPage() : nextPage();
                } else {
                  velocity > 0 ? nextPage() : previousPage();
                }
              }
            },
            onVerticalDragEnd: (details) {
              if (widget.layout == ReaderLayout.vertical ||
                  widget.layout == ReaderLayout.webtoon) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity.abs() > 100) {
                  velocity > 0 ? previousPage() : nextPage();
                }
              }
            },
            child: widget.layout.isGallery
                ? _buildGalleryMode(imageBuilder)
                : _buildContinuousMode(imageBuilder),
          ),

          // UI Controls
          if (widget.showControls && _isUiVisible)
            _buildControls(),

          // Loading indicator
          if (_isLoading)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryMode(ImageProvider Function(String) imageBuilder) {
    return NekoGalleryLayout(
      images: widget.images,
      controller: _pageController,
      initialIndex: widget.initialIndex,
      layout: widget.layout,
      imageBuilder: imageBuilder,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
          _isLoading = false;
        });
        widget.onPageChanged?.call(index);
      },
      onImageLoaded: () {
        if (_isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  Widget _buildContinuousMode(ImageProvider Function(String) imageBuilder) {
    return NekoContinuousLayout(
      images: widget.images,
      scrollController: _scrollController,
      positionsListener: _positionsListener,
      layout: widget.layout,
      imageBuilder: imageBuilder,
      initialIndex: widget.initialIndex,
      onIndexChanged: (index) {
        setState(() {
          _currentIndex = index;
          _isLoading = false;
        });
        widget.onPageChanged?.call(index);
      },
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        // Top bar
        _buildTopBar(),
        const Spacer(),
        // Bottom bar with slider
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha(179),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Text(
                  'Page ${_currentIndex + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withAlpha(179),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_currentIndex + 1}',
                style: const TextStyle(color: Colors.white),
              ),
              Expanded(
                child: Slider(
                  value: _currentIndex.toDouble(),
                  min: 0,
                  max: (widget.images.length - 1).toDouble(),
                  divisions: widget.images.length > 1 ? widget.images.length - 1 : 1,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white38,
                  onChanged: (value) {
                    goToPage(value.toInt());
                  },
                ),
              ),
              Text(
                '${widget.images.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
