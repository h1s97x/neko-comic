part of 'comic_source.dart';

/// Build comic list function type.
typedef NekoComicListBuilder = Future<NekoResult<List<NekoComic>>> Function(int page);

/// Build comic list with next param function type.
typedef NekoComicListBuilderWithNext = Future<NekoResult<List<NekoComic>>> Function(String? next);

/// Login function type.
typedef NekoLoginFunction = Future<NekoResult<bool>> Function(String username, String password);

/// Load comic details function type.
typedef NekoLoadComicFunc = Future<NekoResult<NekoComicDetails>> Function(String id);

/// Load comic pages function type.
typedef NekoLoadComicPagesFunc = Future<NekoResult<List<String>>> Function(String id, String? ep);

/// Comments loader function type.
typedef NekoCommentsLoader = Future<NekoResult<List<NekoComment>>> Function(
  String id,
  String? subId,
  int page,
  String? replyTo,
);

/// Chapter comments loader function type.
typedef NekoChapterCommentsLoader = Future<NekoResult<List<NekoComment>>> Function(
  String comicId,
  String epId,
  int page,
  String? replyTo,
);

/// Send comment function type.
typedef NekoSendCommentFunc = Future<NekoResult<bool>> Function(
  String id,
  String? subId,
  String content,
  String? replyTo,
);

/// Send chapter comment function type.
typedef NekoSendChapterCommentFunc = Future<NekoResult<bool>> Function(
  String comicId,
  String epId,
  String content,
  String? replyTo,
);

/// Get image loading config function type.
typedef NekoGetImageLoadingConfigFunc = Future<Map<String, dynamic>> Function(
  String imageKey,
  String comicId,
  String epId,
);

/// Get thumbnail loading config function type.
typedef NekoGetThumbnailLoadingConfigFunc = Map<String, dynamic> Function(String imageKey);

/// Comic thumbnail loader function type.
typedef NekoComicThumbnailLoader = Future<NekoResult<List<String>>> Function(
  String comicId,
  String? next,
);

/// Like or unlike comic function type.
typedef NekoLikeOrUnlikeComicFunc = Future<NekoResult<bool>> Function(
  String comicId,
  bool isLiking,
);

/// Like comment function type.
typedef NekoLikeCommentFunc = Future<NekoResult<int?>> Function(
  String comicId,
  String? subId,
  String commentId,
  bool isLiking,
);

/// Vote comment function type.
typedef NekoVoteCommentFunc = Future<NekoResult<int?>> Function(
  String comicId,
  String? subId,
  String commentId,
  bool isUp,
  bool isCancel,
);

/// Handle click tag event function type.
typedef NekoHandleClickTagEvent = NekoPageJumpTarget? Function(String namespace, String tag);

/// Tag suggestion select function type.
typedef NekoTagSuggestionSelectFunc = String Function(String namespace, String tag);

/// Star rating function type.
typedef NekoStarRatingFunc = Future<NekoResult<bool>> Function(String comicId, int rating);

/// Link handler function type.
typedef NekoLinkHandler = NekoPageJumpTarget? Function(String url);

/// Account configuration.
class NekoAccountConfig {
  final String type;
  final bool required;
  final Map<String, String> fields;
  final List<String>? supported;

  const NekoAccountConfig({
    required this.type,
    this.required = false,
    this.fields = const {},
    this.supported,
  });
}

/// Page jump target.
class NekoPageJumpTarget {
  final NekoPageJumpType type;
  final String? comicId;
  final String? epId;
  final String? keyword;
  final String? url;

  const NekoPageJumpTarget({
    required this.type,
    this.comicId,
    this.epId,
    this.keyword,
    this.url,
  });
}

enum NekoPageJumpType {
  comic,
  chapter,
  search,
  url,
}
