library;

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'comic_source/models.dart';
import 'comic_source/types.dart';
import 'comic_source/category.dart';
import 'comic_source/parser.dart';
import 'js_engine.dart';

part 'models.dart';
part 'favorites.dart';

/// Manager for all comic sources.
///
/// This class is responsible for loading, managing, and accessing
/// comic sources that are written in JavaScript.
class NekoComicSourceManager with ChangeNotifier {
  final List<NekoComicSource> _sources = [];

  static NekoComicSourceManager? _instance;

  NekoComicSourceManager._create();

  factory NekoComicSourceManager() => _instance ??= NekoComicSourceManager._create();

  /// Initialize the manager (static method for easy access)
  static Future<void> init() => NekoComicSourceManager().init();

  /// Get all registered comic sources.
  List<NekoComicSource> all() => List.from(_sources);

  /// Find a comic source by its key.
  NekoComicSource? find(String key) =>
      _sources.firstWhereOrNull((element) => element.key == key);

  /// Find a comic source by its integer hash key.
  NekoComicSource? fromIntKey(int key) =>
      _sources.firstWhereOrNull((element) => element.key.hashCode == key);

  /// Initialize and load all comic sources from the data directory.
  Future<void> init() async {
    await NekoJsEngine().ensureInit();
    // Comic sources will be loaded from the app's data directory
    // This is typically done by the host app
  }

  /// Reload all comic sources.
  Future<void> reload() async {
    _sources.clear();
    NekoJsEngine().runCode("ComicSource.sources = {};");
    await init();
    notifyListeners();
  }

  /// Add a comic source to the manager.
  void add(NekoComicSource source) {
    _sources.add(source);
    notifyListeners();
  }

  /// Remove a comic source by its key.
  void remove(String key) {
    _sources.removeWhere((element) => element.key == key);
    notifyListeners();
  }

  /// Check if there are any comic sources.
  bool get isEmpty => _sources.isEmpty;

  /// Available updates for comic sources.
  /// Key is the source key, value is the version.
  final Map<String, String> _availableUpdates = {};

  void updateAvailableUpdates(Map<String, String> updates) {
    _availableUpdates.addAll(updates);
    notifyListeners();
  }

  Map<String, String> get availableUpdates => Map.from(_availableUpdates);

  /// Notify listeners of state change.
  void notifyStateChange() {
    notifyListeners();
  }
}

/// A comic source that defines how to fetch comics from a website.
///
/// Comic sources are written in JavaScript and define methods for:
/// - Loading comic details
/// - Loading chapters/pages
/// - Searching comics
/// - Category browsing
class NekoComicSource {
  /// Get all registered comic sources.
  static List<NekoComicSource> all() => NekoComicSourceManager().all();

  /// Find a comic source by its key.
  static NekoComicSource? find(String key) => NekoComicSourceManager().find(key);

  /// Find a comic source by its integer hash key.
  static NekoComicSource? fromIntKey(int key) => NekoComicSourceManager().fromIntKey(key);

  /// Check if there are any comic sources.
  static bool get isEmpty => NekoComicSourceManager().isEmpty;

  /// Name of this source.
  final String name;

  /// Unique identifier for this source.
  final String key;

  int get intKey => key.hashCode;

  /// Account configuration for logged-in features.
  final NekoAccountConfig? account;

  /// Category data for building category pages.
  final NekoCategoryData? categoryData;

  /// Category comics data for browsing comics by category.
  final NekoCategoryComicsData? categoryComicsData;

  /// Favorite data for user's favorites.
  final NekoFavoriteData? favoriteData;

  /// Explore pages for discovery.
  final List<NekoExplorePageData> explorePages;

  /// Search page configuration.
  final NekoSearchPageData? searchPageData;

  /// Function to load comic details.
  final NekoLoadComicFunc? loadComicInfo;

  /// Function to load comic thumbnails.
  final NekoComicThumbnailLoader? loadComicThumbnail;

  /// Function to load comic chapters/pages.
  final NekoLoadComicPagesFunc? loadComicPages;

  /// Function to get image loading configuration.
  final NekoGetImageLoadingConfigFunc? getImageLoadingConfig;

  /// Function to get thumbnail loading configuration.
  final NekoGetThumbnailLoadingConfigFunc? getThumbnailLoadingConfig;

  /// Custom data storage.
  var data = <String, dynamic>{};

  /// Check if user is logged in.
  bool get isLogged => data["account"] != null;

  /// Path to the source file.
  final String filePath;

  /// Base URL of the source website.
  final String url;

  /// Version of the comic source.
  final String version;

  /// Comments loader function.
  final NekoCommentsLoader? commentsLoader;

  /// Send comment function.
  final NekoSendCommentFunc? sendCommentFunc;

  /// Chapter comments loader.
  final NekoChapterCommentsLoader? chapterCommentsLoader;

  /// Send chapter comment function.
  final NekoSendChapterCommentFunc? sendChapterCommentFunc;

  /// Regular expression to match comic IDs from URLs.
  final RegExp? idMatcher;

  /// Like/unlike comic function.
  final NekoLikeOrUnlikeComicFunc? likeOrUnlikeComic;

  /// Vote comment function.
  final NekoVoteCommentFunc? voteCommentFunc;

  /// Like comment function.
  final NekoLikeCommentFunc? likeCommentFunc;

  /// Source settings.
  final Map<String, Map<String, dynamic>>? settings;

  /// Tag translations.
  final Map<String, Map<String, String>>? translations;

  /// Tag click handler.
  final NekoHandleClickTagEvent? handleClickTagEvent;

  /// Tag suggestion selection handler.
  final NekoTagSuggestionSelectFunc? onTagSuggestionSelected;

  /// Link handler.
  final NekoLinkHandler? linkHandler;

  /// Whether tag suggestions are enabled.
  final bool enableTagsSuggestions;

  /// Whether tag translation is enabled.
  final bool enableTagsTranslate;

  const NekoComicSource(
    this.name,
    this.key, {
    this.account,
    this.categoryData,
    this.categoryComicsData,
    this.favoriteData,
    this.explorePages = const [],
    this.searchPageData,
    this.settings,
    this.loadComicInfo,
    this.loadComicThumbnail,
    this.loadComicPages,
    this.getImageLoadingConfig,
    this.getThumbnailLoadingConfig,
    required this.filePath,
    required this.url,
    required this.version,
    this.commentsLoader,
    this.sendCommentFunc,
    this.chapterCommentsLoader,
    this.sendChapterCommentFunc,
    this.idMatcher,
    this.likeOrUnlikeComic,
    this.voteCommentFunc,
    this.likeCommentFunc,
    this.translations,
    this.handleClickTagEvent,
    this.onTagSuggestionSelected,
    this.linkHandler,
    this.enableTagsSuggestions = false,
    this.enableTagsTranslate = false,
  });

  /// Load persisted data for this source.
  Future<void> loadData() async {
    // Implementation depends on host app's data storage
  }

  /// Save data for this source.
  Future<void> saveData() async {
    // Implementation depends on host app's data storage
  }

  /// Search for comics.
  Future<NekoResult<List<NekoComic>>> search(String keyword, {int page = 1}) async {
    if (searchPageData == null) {
      return NekoResult.error("Search not supported");
    }
    // Delegate to JavaScript implementation
    return NekoResult.error("Not implemented");
  }

  /// Get comic details.
  Future<NekoResult<NekoComicDetails>> getComic(String id) async {
    if (loadComicInfo == null) {
      return NekoResult.error("Loading comic info not supported");
    }
    return loadComicInfo!(id);
  }

  /// Get comic pages/chapters.
  Future<NekoResult<List<String>>> getPages(String id, String? ep) async {
    if (loadComicPages == null) {
      return NekoResult.error("Loading pages not supported");
    }
    return loadComicPages!(id, ep);
  }

  /// Get comic thumbnail.
  Future<NekoResult<List<String>>> getThumbnails(String comicId, {String? next}) async {
    if (loadComicThumbnail == null) {
      return NekoResult.error("Loading thumbnails not supported");
    }
    return loadComicThumbnail!(comicId, next);
  }
}

/// Extension methods for lists.
extension _ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
