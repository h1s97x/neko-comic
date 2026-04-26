import 'package:flutter/material.dart';

/// Image loader for NekoComic
class ImageLoader extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ImageLoader({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? const CircularProgressIndicator();
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error);
      },
    );
  }
}
