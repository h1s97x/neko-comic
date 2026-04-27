import 'package:flutter/material.dart';

/// Comic description widget for displaying comic information
class NekoComicDescription extends StatelessWidget {
  const NekoComicDescription({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.badge,
    this.tags,
    this.maxLines = 2,
    this.enableTranslate = true,
    this.rating = 0,
    this.titleStyle,
    this.subtitleStyle,
    this.descriptionStyle,
  });

  /// Main title
  final String title;

  /// Subtitle (e.g., author)
  final String? subtitle;

  /// Description text
  final String? description;

  /// Badge text (e.g., language)
  final String? badge;

  /// Tags list
  final List<String>? tags;

  /// Maximum lines for description
  final int maxLines;

  /// Enable tag translation
  final bool enableTranslate;

  /// Star rating (0-10, displayed as 0-5 stars)
  final int rating;

  /// Custom title style
  final TextStyle? titleStyle;

  /// Custom subtitle style
  final TextStyle? subtitleStyle;

  /// Custom description style
  final TextStyle? descriptionStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Badge and rating row
        if (badge != null && badge!.isNotEmpty || rating > 0)
          Row(
            children: [
              if (badge != null && badge!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              if (rating > 0) _buildRating(theme),
            ],
          ),

        const SizedBox(height: 4),

        // Title
        Text(
          title,
          style: titleStyle ??
              theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),

        // Subtitle
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: subtitleStyle ??
                theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Description
        if (description != null && description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _formatDescription(description!),
            style: descriptionStyle ??
                theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Tags
        if (tags != null && tags!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: tags!.take(5).map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  enableTranslate ? tag : tag,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildRating(ThemeData theme) {
    final stars = rating ~/ 2;
    final hasHalfStar = (rating % 2) == 1;
    final displayStars = hasHalfStar ? stars + 1 : stars;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: 14,
          color: Colors.amber,
        ),
        const SizedBox(width: 2),
        Text(
          '${displayStars / 2}',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  String _formatDescription(String desc) {
    // Replace common separators with newlines or spaces
    return desc.replaceAll('|', ' ').replaceAll('\\n', ' ');
  }
}

/// Compact comic description (title only with optional badge)
class NekoCompactDescription extends StatelessWidget {
  const NekoCompactDescription({
    super.key,
    required this.title,
    this.badge,
    this.rating,
  });

  final String title;
  final String? badge;
  final int? rating;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge
        if (badge != null && badge!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badge!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontSize: 10,
              ),
            ),
          ),

        // Title
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        // Rating
        if (rating != null && rating! > 0) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 2),
              Text(
                '${rating! / 2}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
