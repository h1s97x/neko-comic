import 'package:flutter/material.dart';
import 'package:neko_image/neko_image.dart';

/// Widget for displaying a single reader image
class NekoReaderImage extends StatelessWidget {
  final String url;
  final String comicId;
  final BoxFit fit;

  const NekoReaderImage({
    super.key,
    required this.url,
    required this.comicId,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return NekoCachedImage(
      url: url,
      comicId: comicId,
      fit: fit,
      showProgress: true,
    );
  }
}

/// Widget for displaying a gallery page with zoom support
class NekoReaderPage extends StatefulWidget {
  final String url;
  final String comicId;
  final bool showControls;

  const NekoReaderPage({
    super.key,
    required this.url,
    required this.comicId,
    this.showControls = false,
  });

  @override
  State<NekoReaderPage> createState() => _NekoReaderPageState();
}

class _NekoReaderPageState extends State<NekoReaderPage> {
  final TransformationController _transformController = TransformationController();
  double _scale = 1.0;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _resetZoom,
      onScaleUpdate: (details) {
        setState(() {
          _scale = (_scale * details.scale).clamp(1.0, 4.0);
          final matrix = Matrix4.identity()..scale(_scale);
          _transformController.value = matrix;
        });
      },
      child: InteractiveViewer(
        transformationController: _transformController,
        minScale: 1.0,
        maxScale: 4.0,
        child: NekoReaderImage(
          url: widget.url,
          comicId: widget.comicId,
        ),
      ),
    );
  }
}
