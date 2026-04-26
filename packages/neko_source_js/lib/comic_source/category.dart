part of 'comic_source.dart';

/// Category data for building category pages.
class NekoCategoryData {
  /// The title displayed in the tab bar.
  final String title;

  /// Category tags to display.
  final List<NekoBaseCategoryPart> categories;

  final bool enableRankingPage;

  final String key;

  final List<NekoCategoryButtonData> buttons;

  const NekoCategoryData({
    required this.title,
    required this.categories,
    this.enableRankingPage = false,
    required this.key,
    this.buttons = const [],
  });
}

/// Category button data.
class NekoCategoryButtonData {
  final String label;
  final void Function() onTap;

  const NekoCategoryButtonData({
    required this.label,
    required this.onTap,
  });
}

/// Category item.
class NekoCategoryItem {
  final String label;
  final NekoPageJumpTarget target;

  const NekoCategoryItem(this.label, this.target);
}

/// Base class for category parts.
abstract class NekoBaseCategoryPart {
  String get title;
  List<NekoCategoryItem> get categories;
  bool get enableRandom;

  const NekoBaseCategoryPart();
}

/// Fixed category part with static tags.
class NekoFixedCategoryPart extends NekoBaseCategoryPart {
  @override
  final List<NekoCategoryItem> categories;

  @override
  bool get enableRandom => false;

  @override
  final String title;

  const NekoFixedCategoryPart(this.title, this.categories);
}

/// Random category part that shows random subset of tags.
class NekoRandomCategoryPart extends NekoBaseCategoryPart {
  final List<NekoCategoryItem> all;
  final int randomNumber;

  @override
  final String title;

  @override
  bool get enableRandom => true;

  List<NekoCategoryItem> _categories() {
    if (randomNumber >= all.length) return all;
    // Simple random selection
    return all.take(randomNumber).toList();
  }

  @override
  List<NekoCategoryItem> get categories => _categories();

  const NekoRandomCategoryPart(this.title, this.all, this.randomNumber);
}

/// Dynamic category part that loads tags dynamically.
class NekoDynamicCategoryPart extends NekoBaseCategoryPart {
  @override
  final String title;

  @override
  bool get enableRandom => true;

  final Future<List<NekoCategoryItem>> Function() loader;

  List<NekoCategoryItem>? _cached;

  @override
  List<NekoCategoryItem> get categories {
    if (_cached == null) {
      loader().then((items) => _cached = items);
      return [];
    }
    return _cached!;
  }

  const NekoDynamicCategoryPart(this.title, this.loader);
}

/// Category comics data for browsing comics by category.
class NekoCategoryComicsData {
  final String key;
  final String title;
  final bool hasNext;
  final NekoComicListBuilder builder;
  final NekoComicListBuilderWithNext? builderWithNext;

  const NekoCategoryComicsData({
    required this.key,
    required this.title,
    this.hasNext = true,
    required this.builder,
    this.builderWithNext,
  });
}

/// Favorite data for user's favorites.
class NekoFavoriteData {
  final bool enabled;
  final bool withEp;
  final bool withMessage;
  final bool withComment;

  const NekoFavoriteData({
    this.enabled = true,
    this.withEp = true,
    this.withMessage = true,
    this.withComment = true,
  });
}

/// Explore page data.
class NekoExplorePageData {
  final String title;
  final List<String> tags;
  final bool compact;
  final bool showTitle;
  final NekoComicListBuilder builder;
  final NekoComicListBuilderWithNext? builderWithNext;

  const NekoExplorePageData({
    required this.title,
    this.tags = const [],
    this.compact = false,
    this.showTitle = true,
    required this.builder,
    this.builderWithNext,
  });
}

/// Search page data.
class NekoSearchPageData {
  final bool enableSuggestions;
  final bool suggestionsWithTranslate;
  final NekoComicListBuilder builder;
  final NekoComicListBuilderWithNext? builderWithNext;

  const NekoSearchPageData({
    this.enableSuggestions = false,
    this.suggestionsWithTranslate = false,
    required this.builder,
    this.builderWithNext,
  });
}
