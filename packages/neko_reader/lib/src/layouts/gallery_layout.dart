import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../reader_mode.dart';

/// Gallery layout for page-by-page reading
class NekoGalleryLayout extends StatefulWidget {
  /// Image URLs
  final List<String> images;

  /// Page controller
  final PageController controller;

  /// Initial page index
  final int initialIndex;

  /// Layout mode
  final ReaderLayout layout;

  /// Image builder function
  final ImageProvider Function(String url)? imageBuilder;

  /// Callback when page changes
  final void Function(int index)? onPageChanged;

  /// Callback when image is loaded
  final VoidCallback? onImageLoaded;

  /// Callback when page loading starts
  final VoidCallback? onPageLoading;

  const NekoGalleryLayout({
    super.key,
    required this.images,
    required this.controller,
    this.initialIndex = 0,
    required this.layout,
    this.imageBuilder,
    this.onPageChanged,
    this.onPageLoading,
    this.onImageLoaded,
  });

  @override
  State<NekoGalleryLayout> createState() => _NekoGalleryLayoutState();
}

class _NekoGalleryLayoutState extends State<NekoGalleryLayout> {
  late int _currentIndex;
  bool _isLoading = true;

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

    return PhotoViewGallery.builder(
      scrollPhysics: const BouncingScrollPhysics(),
      builder: (context, index) {
        final imageUrl = widget.images[index];
        final imageProvider = imageBuilder(imageUrl);

        return PhotoViewGalleryPageOptions(
          imageProvider: imageProvider,
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          heroAttributes: PhotoViewHeroAttributes(tag: 'image_$index'),
          onScaleEnd: (context, details, controllerValue) {
            // Handle scale end
          },
          onMainImageChanged: (image) {
            if (_currentIndex != index) {
              setState(() {
                _currentIndex = index;
                _isLoading = false;
              });
              widget.onPageChanged?.call(index);
            }
            if (_isLoading) {
              setState(() {
                _isLoading = false;
              });
              widget.onImageLoaded?.call();
            }
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        );
      },
      itemCount: widget.images.length,
      loadingBuilder: (context, event) {
        return Center(
          child: CircularProgressIndicator(
            value: event == null
                ? null
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
            color: Colors.white,
          ),
        );
      },
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      pageController: widget.controller,
      reverse: widget.layout.isRtl,
      scrollDirection:
          widget.layout == ReaderLayout.topToBottom ? Axis.vertical : Axis.horizontal,
      onPageChanged: (index) {
        if (_currentIndex != index) {
          setState(() {
            _currentIndex = index;
            _isLoading = true;
          });
          widget.onPageChanged?.call(index);
          widget.onPageLoading?.call();
        }
      },
    );
  }
}

/// Gallery page item for advanced customization
class NekoGalleryPage extends StatelessWidget {
  final String imageUrl;
  final ImageProvider Function(String url)? imageBuilder;
  final bool enableZoom;
  final double? minScale;
  final double? maxScale;
  final BoxFit? fit;

  const NekoGalleryPage({
    super.key,
    required this.imageUrl,
    this.imageBuilder,
    this.enableZoom = true,
    this.minScale,
    this.maxScale,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider provider;
    if (imageBuilder != null) {
      provider = imageBuilder!(imageUrl);
    } else if (imageUrl.startsWith('http')) {
      provider = NetworkImage(imageUrl);
    } else {
      provider = AssetImage(imageUrl);
    }

    final options = PhotoViewPageOptions(
      imageProvider: provider,
      initialScale: PhotoViewComputedScale.contained,
      minScale: minScale ?? PhotoViewComputedScale.contained,
      maxScale: maxScale ?? PhotoViewComputedScale.covered * 3,
      fit: fit,
    );

    if (!enableZoom) {
      return Image(
        image: provider,
        fit: fit ?? BoxFit.contain,
        errorBuilder: (context, error, stack) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 64),
          );
        },
      );
    }

    return PhotoView(
      imageProvider: provider,
      initialScale: PhotoViewComputedScale.contained,
      minScale: minScale ?? PhotoViewComputedScale.contained,
      maxScale: maxScale ?? PhotoViewComputedScale.covered * 3,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
    );
  }
}
