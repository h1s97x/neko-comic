import 'package:flutter/material.dart';
import 'package:neko_core/neko_core.dart';

/// Comic card widget for displaying comic information in a card format
class NekoComicCard extends StatelessWidget {
  const NekoComicCard({
    super.key,
    required this.comic,
    this.onTap,
    this.onLongPress,
    this.heroID,
    this.imageProvider,
    this.showRating = true,
    this.showTags = true,
  });

  final NekoComic comic;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final int? heroID;
  final ImageProvider? imageProvider;
  final bool showRating;
  final bool showTags;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget card = Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover image
            Expanded(
              flex: 3,
              child: _buildCover(theme),
            ),

            // Info section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Expanded(
                      child: Text(
                        comic.title.replaceAll('\n', ''),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Rating
                    if (showRating && (comic.stars ?? 0) > 0) ...[
                      const SizedBox(height: 4),
                      _buildRating(theme),
                    ],

                    // Tags
                    if (showTags && (comic.tags?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 4),
                      _buildTags(theme),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (heroID != null) {
      card = Hero(
        tag: "cover$heroID",
        child: card,
      );
    }

    return card;
  }

  Widget _buildCover(ThemeData theme) {
    if (imageProvider != null) {
      return Image(
        image: imageProvider!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(theme);
        },
      );
    }

    // Check if comic has cover URL
    if (comic.cover != null && comic.cover!.isNotEmpty) {
      // In a real implementation, this would use NekoCachedImageProvider
      return _buildPlaceholder(theme);
    }

    return _buildPlaceholder(theme);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.secondaryContainer,
      child: Center(
        child: Icon(
          Icons.menu_book_outlined,
          size: 48,
          color: theme.colorScheme.onSecondaryContainer.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildRating(ThemeData theme) {
    final stars = comic.stars ?? 0;
    final fullStars = stars ~/ 2;
    final hasHalfStar = (stars % 2) == 1;

    return Row(
      children: [
        ...List.generate(fullStars, (index) {
          return Icon(
            Icons.star,
            size: 14,
            color: Colors.amber,
          );
        }),
        if (hasHalfStar)
          Icon(
            Icons.star_half,
            size: 14,
            color: Colors.amber,
          ),
        ...List.generate(5 - fullStars - (hasHalfStar ? 1 : 0), (index) {
          return Icon(
            Icons.star_border,
            size: 14,
            color: Colors.amber.withOpacity(0.5),
          );
        }),
      ],
    );
  }

  Widget _buildTags(ThemeData theme) {
    final tags = comic.tags ?? [];
    if (tags.isEmpty) return const SizedBox.shrink();

    return Text(
      tags.take(2).join(', '),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.outline,
        fontSize: 10,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
