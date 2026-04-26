import 'package:flutter/material.dart';
import 'comic_card.dart';

/// Comic grid widget
class ComicGrid extends StatelessWidget {
  final List<ComicItem> comics;
  final int columns;
  final void Function(ComicItem comic)? onLoadMore;
  final bool isLoading;

  const ComicGrid({
    super.key,
    required this.comics,
    this.columns = 3,
    this.onLoadMore,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: comics.length,
      itemBuilder: (context, index) {
        final comic = comics[index];
        return ComicCard(
          title: comic.title,
          coverUrl: comic.coverUrl,
          onTap: comic.onTap,
        );
      },
    );
  }
}

/// Comic item for grid
class ComicItem {
  final String id;
  final String title;
  final String? coverUrl;
  final VoidCallback? onTap;

  const ComicItem({
    required this.id,
    required this.title,
    this.coverUrl,
    this.onTap,
  });
}
