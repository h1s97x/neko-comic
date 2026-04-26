/// Comic data models for NekoComic
/// Reference: Venera comic_source/models.dart

/// Comment model
class NekoComment {
  final String userName;
  final String? avatar;
  final String content;
  final String? time;
  final int? replyCount;
  final String? id;
  int? score;
  final bool? isLiked;
  int? voteStatus; // 1: upvote, -1: downvote, 0: none

  NekoComment({
    required this.userName,
    this.avatar,
    required this.content,
    this.time,
    this.replyCount,
    this.id,
    this.score,
    this.isLiked,
    this.voteStatus,
  });

  static String? parseTime(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      if (value < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000)
            .toString()
            .substring(0, 19);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(value)
            .toString()
            .substring(0, 19);
      }
    }
    return value.toString();
  }

  factory NekoComment.fromJson(Map<String, dynamic> json) {
    return NekoComment(
      userName: json["userName"],
      avatar: json["avatar"],
      content: json["content"],
      time: parseTime(json["time"]),
      replyCount: json["replyCount"],
      id: json["id"]?.toString(),
      score: json["score"],
      isLiked: json["isLiked"],
      voteStatus: json["voteStatus"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "userName": userName,
      "avatar": avatar,
      "content": content,
      "time": time,
      "replyCount": replyCount,
      "id": id,
      "score": score,
      "isLiked": isLiked,
      "voteStatus": voteStatus,
    };
  }
}

/// Comic model (basic info)
class NekoComic {
  final String title;
  final String cover;
  final String id;
  final String? subtitle;
  final List<String>? tags;
  final String description;
  final String sourceKey;
  final int? maxPage;
  final String? language;
  final String? favoriteId;
  final double? stars;

  const NekoComic({
    required this.title,
    required this.cover,
    required this.id,
    this.subtitle,
    this.tags,
    this.description = "",
    required this.sourceKey,
    this.maxPage,
    this.language,
    this.favoriteId,
    this.stars,
  });

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "cover": cover,
      "id": id,
      "subtitle": subtitle,
      "tags": tags,
      "description": description,
      "sourceKey": sourceKey,
      "maxPage": maxPage,
      "language": language,
      "favoriteId": favoriteId,
      "stars": stars,
    };
  }

  factory NekoComic.fromJson(Map<String, dynamic> json, String sourceKey) {
    return NekoComic(
      title: json["title"],
      cover: json["cover"],
      id: json["id"],
      subtitle: json["subtitle"] ?? json["subTitle"] ?? "",
      tags: List<String>.from(json["tags"] ?? []),
      description: json["description"] ?? "",
      sourceKey: sourceKey,
      maxPage: json["maxPage"],
      language: json["language"],
      favoriteId: json["favoriteId"],
      stars: (json["stars"] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! NekoComic) return false;
    return other.id == id && other.sourceKey == sourceKey;
  }

  @override
  int get hashCode => id.hashCode ^ sourceKey.hashCode;

  @override
  String toString() => "$sourceKey@$id";
}

/// Comic ID with type
class NekoComicID {
  final NekoComicType type;
  final String id;

  const NekoComicID(this.type, this.id);

  @override
  bool operator ==(Object other) {
    if (other is! NekoComicID) return false;
    return other.type == type && other.id == id;
  }

  @override
  int get hashCode => type.hashCode ^ id.hashCode;

  @override
  String toString() => "$type@$id";
}

/// Comic type enum
enum NekoComicType {
  local,
  network,
  favorite,
  history,
  downloaded;

  int get hashCode => index;
}

/// Comic chapters
class NekoComicChapters {
  final Map<String, String>? _chapters;
  final Map<String, Map<String, String>>? _groupedChapters;

  /// Create with flat map
  const NekoComicChapters(Map<String, String> this._chapters)
      : _groupedChapters = null;

  /// Create with grouped map
  const NekoComicChapters.grouped(Map<String, Map<String, String>> this._groupedChapters)
      : _chapters = null;

  factory NekoComicChapters.fromJson(dynamic json) {
    if (json is! Map) throw ArgumentError("Invalid json type");

    // Check if it's grouped format
    if (json.values.isNotEmpty) {
      final firstValue = json.values.first;
      if (firstValue is Map) {
        // Grouped format
        var grouped = <String, Map<String, String>>{};
        json.forEach((key, value) {
          if (value is Map) {
            grouped[key] = Map<String, String>.from(value);
          }
        });
        return NekoComicChapters.grouped(grouped);
      }
    }

    // Flat format
    return NekoComicChapters(Map<String, String>.from(json));
  }

  /// Get flat list of chapters
  List<MapEntry<String, String>> get entries {
    if (_chapters != null) {
      return _chapters!.entries.toList();
    }
    var result = <MapEntry<String, String>>[];
    _groupedChapters?.forEach((_, chapters) {
      result.addAll(chapters.entries);
    });
    return result;
  }

  /// Get flat map
  Map<String, String> toFlatMap() {
    if (_chapters != null) return Map.from(_chapters!);
    var result = <String, String>{};
    _groupedChapters?.forEach((_, chapters) {
      result.addAll(chapters);
    });
    return result;
  }

  /// Get grouped map
  Map<String, Map<String, String>>? get grouped =>
      _groupedChapters;

  /// Get chapter title by id
  String? getChapterTitle(String id) {
    return toFlatMap()[id];
  }

  /// Get all chapter ids
  List<String> get ids => toFlatMap().keys.toList();

  /// Get all chapter titles
  List<String> get titles => toFlatMap().values.toList();

  /// Get total count
  int get length => toFlatMap().length;

  bool get isEmpty => length == 0;
  bool get isNotEmpty => !isEmpty;

  Map<String, dynamic> toJson() {
    if (_chapters != null) return Map.from(_chapters!);
    return {"grouped": _groupedChapters};
  }
}

/// Comic details (full info)
class NekoComicDetails {
  final String title;
  final String? subTitle;
  final String cover;
  final String? description;
  final Map<String, List<String>> tags;
  final NekoComicChapters? chapters;
  final List<String>? thumbnails;
  final List<NekoComic>? recommend;
  final String sourceKey;
  final String comicId;
  final bool? isFavorite;
  final String? subId;
  final bool? isLiked;
  final int? likesCount;
  final int? commentCount;
  final String? uploader;
  final String? uploadTime;
  final String? updateTime;
  final String? url;
  final double? stars;
  final int? maxPage;
  final List<NekoComment>? comments;

  const NekoComicDetails({
    required this.title,
    this.subTitle,
    required this.cover,
    this.description,
    this.tags = const {},
    this.chapters,
    this.thumbnails,
    this.recommend,
    required this.sourceKey,
    required this.comicId,
    this.isFavorite,
    this.subId,
    this.isLiked,
    this.likesCount,
    this.commentCount,
    this.uploader,
    this.uploadTime,
    this.updateTime,
    this.url,
    this.stars,
    this.maxPage,
    this.comments,
  });

  static Map<String, List<String>> _generateMap(Map<dynamic, dynamic> map) {
    var res = <String, List<String>>{};
    map.forEach((key, value) {
      if (value is List) {
        res[key] = List<String>.from(value);
      }
    });
    return res;
  }

  factory NekoComicDetails.fromJson(Map<String, dynamic> json) {
    return NekoComicDetails(
      title: json["title"],
      subTitle: json["subtitle"],
      cover: json["cover"],
      description: json["description"],
      tags: _generateMap(json["tags"] ?? {}),
      chapters: json["chapters"] != null
          ? NekoComicChapters.fromJson(json["chapters"])
          : null,
      thumbnails: json["thumbnails"] != null
          ? List<String>.from(json["thumbnails"])
          : null,
      recommend: (json["recommend"] as List?)
          ?.map((e) => NekoComic.fromJson(e, json["sourceKey"]))
          .toList(),
      sourceKey: json["sourceKey"],
      comicId: json["comicId"],
      isFavorite: json["isFavorite"],
      subId: json["subId"],
      likesCount: json["likesCount"],
      isLiked: json["isLiked"],
      commentCount: json["commentCount"],
      uploader: json["uploader"],
      uploadTime: json["uploadTime"],
      updateTime: json["updateTime"],
      url: json["url"],
      stars: (json["stars"] as num?)?.toDouble(),
      maxPage: json["maxPage"],
      comments: (json["comments"] as List?)
          ?.map((e) => NekoComment.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "subTitle": subTitle,
      "cover": cover,
      "description": description,
      "tags": tags,
      "chapters": chapters?.toJson(),
      "thumbnails": thumbnails,
      "recommend": null,
      "sourceKey": sourceKey,
      "comicId": comicId,
      "isFavorite": isFavorite,
      "subId": subId,
      "isLiked": isLiked,
      "likesCount": likesCount,
      "commentCount": commentCount,
      "uploader": uploader,
      "uploadTime": uploadTime,
      "updateTime": updateTime,
      "url": url,
      "stars": stars,
      "maxPage": maxPage,
    };
  }

  /// Convert tags map to plain list
  List<String> get plainTags {
    var res = <String>[];
    tags.forEach((key, value) {
      res.addAll(value.map((e) => "$key:$e"));
    });
    return res;
  }

  /// Find author tag
  String? findAuthor() {
    var authorNamespaces = [
      "author", "authors", "artist", "artists",
      "作者", "画师"
    ];
    for (var entry in tags.entries) {
      if (authorNamespaces.contains(entry.key.toLowerCase()) &&
          entry.value.isNotEmpty) {
        return entry.value.first;
      }
    }
    return null;
  }

  /// Find update time
  String? findUpdateTime() {
    if (updateTime != null) {
      return _validateUpdateTime(updateTime!);
    }
    const acceptedNamespaces = [
      "更新", "最後更新", "最后更新", "update", "last update",
    ];
    for (var entry in tags.entries) {
      if (acceptedNamespaces.contains(entry.key.toLowerCase()) &&
          entry.value.isNotEmpty) {
        return _validateUpdateTime(entry.value.first);
      }
    }
    return null;
  }

  String? _validateUpdateTime(String time) {
    time = time.split(" ").first;
    var segments = time.split("-");
    if (segments.length != 3) return null;
    var year = int.tryParse(segments[0]);
    var month = int.tryParse(segments[1]);
    var day = int.tryParse(segments[2]);
    if (year == null || month == null || day == null) return null;
    if (year < 2000 || year > 3000) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    return "$year-$month-$day";
  }

  /// Convert to basic Comic model
  NekoComic toComic() {
    return NekoComic(
      title: title,
      cover: cover,
      id: comicId,
      subtitle: subTitle,
      tags: plainTags,
      description: description ?? "",
      sourceKey: sourceKey,
      maxPage: maxPage,
      isFavorite: isFavorite,
      stars: stars,
    );
  }
}

/// Chapter model
class NekoChapter {
  final String id;
  final String title;
  final int index;
  final String comicId;
  final DateTime? uploadDate;
  final String? sourceId;

  const NekoChapter({
    required this.id,
    required this.title,
    required this.index,
    required this.comicId,
    this.uploadDate,
    this.sourceId,
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "index": index,
      "comicId": comicId,
      "uploadDate": uploadDate?.toIso8601String(),
      "sourceId": sourceId,
    };
  }

  factory NekoChapter.fromJson(Map<String, dynamic> json) {
    return NekoChapter(
      id: json["id"],
      title: json["title"],
      index: json["index"],
      comicId: json["comicId"],
      uploadDate: json["uploadDate"] != null
          ? DateTime.parse(json["uploadDate"])
          : null,
      sourceId: json["sourceId"],
    );
  }
}

/// Image info model
class NekoImageInfo {
  final String url;
  final int index;
  final int? width;
  final int? height;

  const NekoImageInfo({
    required this.url,
    required this.index,
    this.width,
    this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      "url": url,
      "index": index,
      "width": width,
      "height": height,
    };
  }

  factory NekoImageInfo.fromJson(Map<String, dynamic> json) {
    return NekoImageInfo(
      url: json["url"],
      index: json["index"],
      width: json["width"],
      height: json["height"],
    );
  }
}

/// Archive info model
class NekoArchiveInfo {
  final String title;
  final String description;
  final String id;

  const NekoArchiveInfo({
    required this.title,
    required this.description,
    required this.id,
  });

  factory NekoArchiveInfo.fromJson(Map<String, dynamic> json) {
    return NekoArchiveInfo(
      title: json["title"],
      description: json["description"],
      id: json["id"],
    );
  }
}
