import 'package:flutter/material.dart';

/// Comic reader component
class NekoReader extends StatelessWidget {
  final List<String> images;
  final int initialIndex;
  final ReaderLayout layout;
  final void Function(int index)? onPageChanged;
  final void Function()? onTap;

  const NekoReader({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.layout = ReaderLayout.rightToLeft,
    this.onPageChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Implement reader
    return const Center(
      child: Text('Reader not implemented yet'),
    );
  }
}

/// Reader layout options
enum ReaderLayout {
  leftToRight,
  rightToLeft,
  vertical,
  webtoon,
}
