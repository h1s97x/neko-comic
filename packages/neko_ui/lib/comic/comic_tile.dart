import 'package:flutter/material.dart';
import 'package:neko_core/neko_core.dart';

/// Comic tile widget for displaying comic in list mode
class NekoComicTile extends StatelessWidget {
  const NekoComicTile({
    super.key,
    required this.comic,
    this.enableLongPressed = true,
    this.badge,
    this.onTap,
    this.onLongPressed,
    this.heroID,
    this.imageProvider,
  });

  /// Comic data
  final NekoComic comic;

  /// Enable long press context menu
  final bool enableLongPressed;

  /// Badge text (e.g., language)
  final String? badge;

  /// Tap callback
  final VoidCallback? onTap;

  /// Long press callback
  final VoidCallback? onLongPressed;

  /// Hero animation ID for cover image
  final int? heroID;

  /// Custom image provider (optional)
  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    var displayMode =
        NekoSettingsReader.displayMode ?? NekoComicDisplayMode.brief;
    var theme = Theme.of(context);

    return displayMode == NekoComicDisplayMode.detailed
        ? _buildDetailedMode(context, theme)
        : _buildBriefMode(context, theme);
  }

  Widget _buildDetailedMode(BuildContext context, ThemeData theme) {
    return LayoutBuilder(builder: (context, constraints) {
      final height = constraints.maxHeight - 16;

      Widget image = _buildImageContainer(
        context: context,
        width: height * 0.68,
        height: double.infinity,
        borderRadius: BorderRadius.circular(8),
        theme: theme,
      );

      if (heroID != null) {
        image = Hero(
          tag: "cover$heroID",
          child: image,
        );
      }

      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () {},
        onLongPress: enableLongPressed ? (onLongPressed ?? () {}) : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 24, 8),
          child: Row(
            children: [
              image,
              const SizedBox.fromSize(size: Size(16, 5)),
              Expanded(
                child: NekoComicDescription(
                  title: comic.maxPage == null
                      ? comic.title.replaceAll("\n", "")
                      : "[${comic.maxPage}P]${comic.title.replaceAll("\n", "")}",
                  subtitle: comic.subtitle ?? '',
                  description: comic.description ?? '',
                  badge: badge ?? comic.language ?? '',
                  tags: comic.tags ?? [],
                  maxLines: 2,
                  enableTranslate: true,
                  rating: comic.stars ?? 0,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBriefMode(BuildContext context, ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget image = _buildImageContainer(
          context: context,
          width: double.infinity,
          height: double.infinity,
          borderRadius: BorderRadius.circular(8),
          theme: theme,
        );

        if (heroID != null) {
          image = Hero(
            tag: "cover$heroID",
            child: image,
          );
        }

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap ?? () {},
          onLongPress: enableLongPressed ? (onLongPressed ?? () {}) : null,
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: image),
                    if (_getOverlayText() != null)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.black54,
                          ),
                          child: Text(
                            _getOverlayText()!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                child: Text(
                  comic.title.replaceAll('\n', ''),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ).padding(const EdgeInsets.symmetric(horizontal: 6, vertical: 8)),
        );
      },
    );
  }

  String? _getOverlayText() {
    final subtitle = comic.subtitle?.replaceAll('\n', '').trim();
    final description = comic.description ?? '';
    final text = description.isNotEmpty
        ? description.split('|').join('\n')
        : (subtitle?.isNotEmpty == true ? subtitle : null);
    return text;
  }

  Widget _buildImageContainer({
    required BuildContext context,
    required double width,
    required double height,
    required BorderRadius borderRadius,
    required ThemeData theme,
  }) {
    Widget image;

    if (imageProvider != null) {
      image = Image(
        image: imageProvider!,
        fit: BoxFit.cover,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: theme.colorScheme.secondaryContainer,
            child: Icon(
              Icons.broken_image_outlined,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          );
        },
      );
    } else {
      // Use cached image provider from neko_image
      image = Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: borderRadius,
        ),
        child: Center(
          child: Text(
            comic.title.substring(0, 1).toUpperCase(),
            style: TextStyle(
              fontSize: 24,
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }
}

/// Comic display mode settings
enum NekoComicDisplayMode {
  brief,
  detailed,
}

/// Settings reader for comic display preferences
class NekoSettingsReader {
  static NekoComicDisplayMode? displayMode;
}
