import 'package:flutter/material.dart';
import 'package:neko_core/neko_core.dart';
import 'comic_tile.dart';

/// Comic grid widget for displaying comics in a grid layout
class NekoComicGrid extends StatelessWidget {
  const NekoComicGrid({
    super.key,
    required this.comics,
    required this.onComicTap,
    this.onComicLongPress,
    this.headers,
    this.onLoadMore,
    this.isLoading = false,
    this.crossAxisCount,
    this.childAspectRatio,
    this.shrinkWrap = false,
    this.physics,
  });

  /// List of comics to display
  final List<NekoComic> comics;

  /// Callback when a comic is tapped
  final void Function(NekoComic comic) onComicTap;

  /// Callback when a comic is long pressed
  final void Function(NekoComic comic)? onComicLongPress;

  /// Optional header widgets
  final List<Widget>? headers;

  /// Callback when load more is needed (infinite scroll)
  final VoidCallback? onLoadMore;

  /// Whether more data is currently loading
  final bool isLoading;

  /// Number of columns in the grid
  final int? crossAxisCount;

  /// Aspect ratio of each grid item
  final double? childAspectRatio;

  /// Whether to shrink wrap the grid
  final bool shrinkWrap;

  /// Scroll physics for the grid
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveCrossAxisCount =
        crossAxisCount ?? _calculateCrossAxisCount(context);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            onLoadMore != null &&
            !isLoading) {
          onLoadMore!();
        }
        return false;
      },
      child: CustomScrollView(
        physics: physics,
        slivers: [
          // Headers
          if (headers != null && headers!.isNotEmpty) ...[
            for (final header in headers!)
              SliverToBoxAdapter(child: header),
          ],

          // Grid content
          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: effectiveCrossAxisCount,
                childAspectRatio: childAspectRatio ?? 0.65,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= comics.length) {
                    return null;
                  }
                  final comic = comics[index];
                  return NekoComicTile(
                    comic: comic,
                    heroID: index,
                    onTap: () => onComicTap(comic),
                    onLongPressed: onComicLongPress != null
                        ? () => onComicLongPress!(comic)
                        : null,
                  );
                },
                childCount: comics.length,
              ),
            ),
          ),

          // Loading indicator
          if (isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),

          // End of list
          if (!isLoading && comics.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No more comics',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 8;
    if (width > 900) return 6;
    if (width > 600) return 4;
    if (width > 400) return 3;
    return 2;
  }
}

/// Comic grid for sliver-based scrolling
class NekoComicSliverGrid extends StatelessWidget {
  const NekoComicSliverGrid({
    super.key,
    required this.comics,
    required this.onComicTap,
    this.onComicLongPress,
    this.crossAxisCount,
    this.childAspectRatio,
  });

  final List<NekoComic> comics;
  final void Function(NekoComic comic) onComicTap;
  final void Function(NekoComic comic)? onComicLongPress;
  final int? crossAxisCount;
  final double? childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final effectiveCrossAxisCount =
        crossAxisCount ?? _calculateCrossAxisCount(context);

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: effectiveCrossAxisCount,
        childAspectRatio: childAspectRatio ?? 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= comics.length) {
            return null;
          }
          final comic = comics[index];
          return NekoComicTile(
            comic: comic,
            heroID: index,
            onTap: () => onComicTap(comic),
            onLongPressed: onComicLongPress != null
                ? () => onComicLongPress!(comic)
                : null,
          );
        },
        childCount: comics.length,
      ),
    );
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 8;
    if (width > 900) return 6;
    if (width > 600) return 4;
    if (width > 400) return 3;
    return 2;
  }
}
