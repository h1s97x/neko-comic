/// Comic data models
class ComicModels {
  ComicModels._();
}

/// Comic information
class Comic {
  final String id;
  final String title;
  final String? coverUrl;
  final String? author;
  final String? description;
  final List<String> tags;
  final String sourceId;
  final DateTime? lastUpdate;
  final bool isFavorite;

  const Comic({
    required this.id,
    required this.title,
    this.coverUrl,
    this.author,
    this.description,
    this.tags = const [],
    required this.sourceId,
    this.lastUpdate,
    this.isFavorite = false,
  });

  Comic copyWith({
    String? id,
    String? title,
    String? coverUrl,
    String? author,
    String? description,
    List<String>? tags,
    String? sourceId,
    DateTime? lastUpdate,
    bool? isFavorite,
  }) {
    return Comic(
      id: id ?? this.id,
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      author: author ?? this.author,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      sourceId: sourceId ?? this.sourceId,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'coverUrl': coverUrl,
      'author': author,
      'description': description,
      'tags': tags,
      'sourceId': sourceId,
      'lastUpdate': lastUpdate?.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory Comic.fromJson(Map<String, dynamic> json) {
    return Comic(
      id: json['id'] as String,
      title: json['title'] as String,
      coverUrl: json['coverUrl'] as String?,
      author: json['author'] as String?,
      description: json['description'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      sourceId: json['sourceId'] as String,
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'] as String)
          : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comic && other.id == id && other.sourceId == sourceId;
  }

  @override
  int get hashCode => Object.hash(id, sourceId);
}

/// Chapter information
class Chapter {
  final String id;
  final String title;
  final int index;
  final String comicId;
  final DateTime? uploadDate;
  final String? sourceId;

  const Chapter({
    required this.id,
    required this.title,
    required this.index,
    required this.comicId,
    this.uploadDate,
    this.sourceId,
  });

  Chapter copyWith({
    String? id,
    String? title,
    int? index,
    String? comicId,
    DateTime? uploadDate,
    String? sourceId,
  }) {
    return Chapter(
      id: id ?? this.id,
      title: title ?? this.title,
      index: index ?? this.index,
      comicId: comicId ?? this.comicId,
      uploadDate: uploadDate ?? this.uploadDate,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'index': index,
      'comicId': comicId,
      'uploadDate': uploadDate?.toIso8601String(),
      'sourceId': sourceId,
    };
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'] as String,
      title: json['title'] as String,
      index: json['index'] as int,
      comicId: json['comicId'] as String,
      uploadDate: json['uploadDate'] != null
          ? DateTime.parse(json['uploadDate'] as String)
          : null,
      sourceId: json['sourceId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chapter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Image information
class ImageInfo {
  final String url;
  final int index;
  final int? width;
  final int? height;

  const ImageInfo({
    required this.url,
    required this.index,
    this.width,
    this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'index': index,
      'width': width,
      'height': height,
    };
  }

  factory ImageInfo.fromJson(Map<String, dynamic> json) {
    return ImageInfo(
      url: json['url'] as String,
      index: json['index'] as int,
      width: json['width'] as int?,
      height: json['height'] as int?,
    );
  }
}

/// Comment information
class Comment {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final DateTime time;
  final int upCount;
  final int downCount;
  final String? avatarUrl;

  const Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.time,
    this.upCount = 0,
    this.downCount = 0,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'content': content,
      'time': time.toIso8601String(),
      'upCount': upCount,
      'downCount': downCount,
      'avatarUrl': avatarUrl,
    };
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      content: json['content'] as String,
      time: DateTime.parse(json['time'] as String),
      upCount: json['upCount'] as int? ?? 0,
      downCount: json['downCount'] as int? ?? 0,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
