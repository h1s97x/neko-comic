part of 'comic_source.dart';

/// Comic basic information.
class NekoComic {
  final String id;
  final String title;
  final String? author;
  final String? cover;
  final String? description;
  final List<String> tags;
  final String source;
  final String? url;
  final Map<String, dynamic>? extra;

  const NekoComic({
    required this.id,
    required this.title,
    this.author,
    this.cover,
    this.description,
    this.tags = const [],
    required this.source,
    this.url,
    this.extra,
  });

  factory NekoComic.fromJson(Map<String, dynamic> json, String source) {
    return NekoComic(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown',
      author: json['author'],
      cover: json['cover'],
      description: json['description'],
      tags: List<String>.from(json['tags'] ?? []),
      source: source,
      url: json['url'],
      extra: json['extra'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'cover': cover,
    'description': description,
    'tags': tags,
    'source': source,
    'url': url,
    'extra': extra,
  };
}

/// Comic detailed information.
class NekoComicDetails {
  final String id;
  final String title;
  final String? author;
  final String? cover;
  final String? description;
  final List<String> tags;
  final String source;
  final String? url;
  final List<NekoChapter> chapters;
  final Map<String, dynamic>? extra;

  const NekoComicDetails({
    required this.id,
    required this.title,
    this.author,
    this.cover,
    this.description,
    this.tags = const [],
    required this.source,
    this.url,
    this.chapters = const [],
    this.extra,
  });

  factory NekoComicDetails.fromComic(NekoComic comic, {List<NekoChapter>? chapters}) {
    return NekoComicDetails(
      id: comic.id,
      title: comic.title,
      author: comic.author,
      cover: comic.cover,
      description: comic.description,
      tags: comic.tags,
      source: comic.source,
      url: comic.url,
      chapters: chapters ?? [],
      extra: comic.extra,
    );
  }

  factory NekoComicDetails.fromJson(Map<String, dynamic> json, String source) {
    return NekoComicDetails(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown',
      author: json['author'],
      cover: json['cover'],
      description: json['description'],
      tags: List<String>.from(json['tags'] ?? []),
      source: source,
      url: json['url'],
      chapters: (json['chapters'] as List?)
          ?.map((c) => NekoChapter.fromJson(c))
          : [],
      extra: json['extra'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'author': author,
    'cover': cover,
    'description': description,
    'tags': tags,
    'source': source,
    'url': url,
    'chapters': chapters.map((c) => c.toJson()).toList(),
    'extra': extra,
  };
}

/// Comic chapter information.
class NekoChapter {
  final String id;
  final String title;
  final int index;
  final String? subId;

  const NekoChapter({
    required this.id,
    required this.title,
    this.index = 0,
    this.subId,
  });

  factory NekoChapter.fromJson(Map<String, dynamic> json) {
    return NekoChapter(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown',
      index: json['index'] ?? 0,
      subId: json['subId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'index': index,
    'subId': subId,
  };
}

/// Comment information.
class NekoComment {
  final String id;
  final String userId;
  final String userName;
  final String? avatar;
  final String content;
  final DateTime time;
  final int likes;
  final String? replyTo;
  final List<NekoComment> replies;
  final Map<String, dynamic>? extra;

  const NekoComment({
    required this.id,
    required this.userId,
    required this.userName,
    this.avatar,
    required this.content,
    required this.time,
    this.likes = 0,
    this.replyTo,
    this.replies = const [],
    this.extra,
  });

  factory NekoComment.fromJson(Map<String, dynamic> json) {
    return NekoComment(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Anonymous',
      avatar: json['avatar'],
      content: json['content'] ?? '',
      time: DateTime.tryParse(json['time'] ?? '') ?? DateTime.now(),
      likes: json['likes'] ?? 0,
      replyTo: json['replyTo'],
      replies: (json['replies'] as List?)
          ?.map((r) => NekoComment.fromJson(r))
          : [],
      extra: json['extra'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'avatar': avatar,
    'content': content,
    'time': time.toIso8601String(),
    'likes': likes,
    'replyTo': replyTo,
    'replies': replies.map((r) => r.toJson()).toList(),
    'extra': extra,
  };
}

/// Result wrapper for comic operations.
class NekoResult<T> {
  final T? data;
  final String? error;
  final dynamic extra;

  const NekoResult({
    this.data,
    this.error,
    this.extra,
  });

  factory NekoResult.success(T data, {dynamic extra}) {
    return NekoResult(data: data, extra: extra);
  }

  factory NekoResult.error(String error, {dynamic extra}) {
    return NekoResult(error: error, extra: extra);
  }

  bool get isSuccess => error == null;
  bool get isError => error != null;
}

/// Resource wrapper.
class NekoRes<T> {
  final T value;
  final dynamic subData;

  const NekoRes(this.value, {this.subData});
}
