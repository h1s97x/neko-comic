/// Favorites management for NekoComic
/// Reference: Venera foundation/favorites.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

import '../comic/models.dart';
import 'database.dart';

/// Favorite item
class NekoFavoriteItem {
  final String id;
  final String sourceKey;
  final String name;
  final String author;
  final String coverPath;
  final List<String> tags;
  final DateTime time;

  const NekoFavoriteItem({
    required this.id,
    required this.sourceKey,
    required this.name,
    required this.author,
    required this.coverPath,
    required this.tags,
    required this.time,
  });

  factory NekoFavoriteItem.fromComic(NekoComic comic, String coverPath) {
    return NekoFavoriteItem(
      id: comic.id,
      sourceKey: comic.sourceKey,
      name: comic.title,
      author: comic.subtitle ?? '',
      coverPath: coverPath,
      tags: comic.tags ?? [],
      time: DateTime.now(),
    );
  }

  factory NekoFavoriteItem.fromRow(Row row) {
    final tagsStr = row['tags'] as String;
    return NekoFavoriteItem(
      id: row['id'] as String,
      sourceKey: row['source_key'] as String,
      name: row['name'] as String,
      author: row['author'] as String,
      coverPath: row['cover_path'] as String,
      tags: tagsStr.isEmpty ? [] : tagsStr.split(','),
      time: DateTime.parse(row['time'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_key': sourceKey,
      'name': name,
      'author': author,
      'cover_path': coverPath,
      'tags': tags.join(','),
      'time': time.toIso8601String(),
    };
  }

  /// Convert to Comic model
  NekoComic toComic() {
    return NekoComic(
      id: id,
      title: name,
      cover: coverPath,
      sourceKey: sourceKey,
      subtitle: author,
      tags: tags,
    );
  }

  String get cover => coverPath;
  String get title => name;
  String? get subtitle => author;
}

/// Favorites manager
class NekoFavoritesManager with ChangeNotifier {
  static NekoFavoritesManager? _instance;
  static NekoFavoritesManager get instance =>
      _instance ??= NekoFavoritesManager._();

  NekoFavoritesManager._();

  bool _isInitialized = false;

  /// Get all favorites
  List<NekoFavoriteItem> getAll() {
    _ensureInitialized();
    final result = NekoDatabase.instance.select(
      'SELECT * FROM favorites ORDER BY time DESC',
    );
    return result.map((row) => NekoFavoriteItem.fromRow(row)).toList();
  }

  /// Check if comic is favorite
  bool isFavorite(String id, String sourceKey) {
    _ensureInitialized();
    final result = NekoDatabase.instance.select(
      'SELECT 1 FROM favorites WHERE id = ? AND source_key = ?',
      [id, sourceKey],
    );
    return result.isNotEmpty;
  }

  /// Add to favorites
  Future<void> add(NekoFavoriteItem item) async {
    _ensureInitialized();
    NekoDatabase.instance.execute(
      '''INSERT OR REPLACE INTO favorites 
         (id, source_key, name, author, cover_path, tags, time)
         VALUES (?, ?, ?, ?, ?, ?, ?)''',
      [item.id, item.sourceKey, item.name, item.author, item.coverPath,
       item.tags.join(','), item.time.toIso8601String()],
    );
    notifyListeners();
  }

  /// Add from comic
  Future<void> addFromComic(NekoComic comic, String coverPath) async {
    await add(NekoFavoriteItem.fromComic(comic, coverPath));
  }

  /// Remove from favorites
  Future<void> remove(String id, String sourceKey) async {
    _ensureInitialized();
    NekoDatabase.instance.execute(
      'DELETE FROM favorites WHERE id = ? AND source_key = ?',
      [id, sourceKey],
    );
    notifyListeners();
  }

  /// Clear all favorites
  Future<void> clear() async {
    _ensureInitialized();
    NekoDatabase.instance.execute('DELETE FROM favorites');
    notifyListeners();
  }

  /// Get favorite by id
  NekoFavoriteItem? getFavorite(String id, String sourceKey) {
    _ensureInitialized();
    final result = NekoDatabase.instance.select(
      'SELECT * FROM favorites WHERE id = ? AND source_key = ?',
      [id, sourceKey],
    );
    if (result.isEmpty) return null;
    return NekoFavoriteItem.fromRow(result.first);
  }

  /// Get favorites count
  int get count {
    _ensureInitialized();
    final result = NekoDatabase.instance.select(
      'SELECT COUNT(*) FROM favorites',
    );
    return result.first[0] as int;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('NekoFavoritesManager not initialized');
    }
  }

  /// Initialize
  void initialize() {
    _isInitialized = true;
  }
}
