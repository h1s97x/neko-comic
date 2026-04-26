/// History management for NekoComic
/// Reference: Venera foundation/history.dart

import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

import '../comic/models.dart';
import 'database.dart';

/// Reading history
class NekoHistory {
  final String id;
  final String sourceKey;
  final String title;
  final String subtitle;
  final String cover;
  final int ep; // Chapter index, 1-based
  final int page; // Page index, 1-based
  final int? chapterGroup;
  final Set<String> readEpisodes;
  final int? maxPage;
  final DateTime time;

  const NekoHistory({
    required this.id,
    required this.sourceKey,
    required this.title,
    required this.subtitle,
    required this.cover,
    this.ep = 0,
    this.page = 0,
    this.chapterGroup,
    this.readEpisodes = const {},
    this.maxPage,
    required this.time,
  });

  factory NekoHistory.fromComicDetails(NekoComicDetails details, {
    int ep = 0,
    int page = 0,
    int? chapterGroup,
    Set<String>? readEpisodes,
  }) {
    return NekoHistory(
      id: details.comicId,
      sourceKey: details.sourceKey,
      title: details.title,
      subtitle: details.subTitle ?? '',
      cover: details.cover,
      ep: ep,
      page: page,
      chapterGroup: chapterGroup,
      readEpisodes: readEpisodes ?? {},
      maxPage: details.maxPage,
      time: DateTime.now(),
    );
  }

  factory NekoHistory.fromRow(Row row) {
    final readEpStr = row['read_episode'] as String;
    return NekoHistory(
      id: row['id'] as String,
      sourceKey: row['source_key'] as String,
      title: row['title'] as String,
      subtitle: row['subtitle'] as String,
      cover: row['cover'] as String,
      ep: row['ep'] as int,
      page: row['page'] as int,
      chapterGroup: row['chapter_group'] as int?,
      readEpisodes: readEpStr.isEmpty
          ? {}
          : readEpStr.split(',').toSet(),
      maxPage: row['max_page'] as int?,
      time: DateTime.fromMillisecondsSinceEpoch(row['time'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_key': sourceKey,
      'title': title,
      'subtitle': subtitle,
      'cover': cover,
      'ep': ep,
      'page': page,
      'chapter_group': chapterGroup,
      'read_episode': readEpisodes.join(','),
      'max_page': maxPage,
      'time': time.millisecondsSinceEpoch,
    };
  }

  /// Convert to Comic model
  NekoComic toComic() {
    return NekoComic(
      id: id,
      title: title,
      cover: cover,
      sourceKey: sourceKey,
      subtitle: subtitle,
    );
  }

  /// Get description
  String get description {
    final parts = <String>[];
    if (chapterGroup != null) {
      parts.add('Group $chapterGroup');
    }
    if (ep >= 1) {
      parts.add('Chapter $ep');
    }
    if (page >= 1) {
      if (ep >= 1) {
        parts.add('-');
      }
      parts.add('Page $page');
    }
    return parts.join(' ');
  }

  String get hashKey => '$id:$sourceKey';
}

/// History manager
class NekoHistoryManager with ChangeNotifier {
  static NekoHistoryManager? _instance;
  static NekoHistoryManager get instance =>
      _instance ??= NekoHistoryManager._();

  NekoHistoryManager._();

  bool _isInitialized = false;

  /// Get all history
  List<NekoHistory> getAll() {
    _ensureInitialized();
    final result = NekoDatabase.instance.select(
      'SELECT * FROM history ORDER BY time DESC',
    );
    return result.map((row) => NekoHistory.fromRow(row)).toList();
  }

  /// Get history by id
  NekoHistory? get(String id, String sourceKey) {
    _ensureInitialized();
    final result = NekoDatabase.instance.select(
      'SELECT * FROM history WHERE id = ? AND source_key = ?',
      [id, sourceKey],
    );
    if (result.isEmpty) return null;
    return NekoHistory.fromRow(result.first);
  }

  /// Check if history exists
  bool hasHistory(String id, String sourceKey) {
    _ensureInitialized();
    final result = NekoDatabase.instance.select(
      'SELECT 1 FROM history WHERE id = ? AND source_key = ?',
      [id, sourceKey],
    );
    return result.isNotEmpty;
  }

  /// Add or update history
  Future<void> add(NekoHistory history) async {
    _ensureInitialized();
    NekoDatabase.instance.execute(
      '''INSERT OR REPLACE INTO history 
         (id, source_key, title, subtitle, cover, ep, page, chapter_group, 
          read_episode, max_page, time)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      [
        history.id,
        history.sourceKey,
        history.title,
        history.subtitle,
        history.cover,
        history.ep,
        history.page,
        history.chapterGroup,
        history.readEpisodes.join(','),
        history.maxPage,
        history.time.millisecondsSinceEpoch,
      ],
    );
    notifyListeners();
  }

  /// Update reading progress
  Future<void> updateProgress(String id, String sourceKey, {
    int? ep,
    int? page,
    int? chapterGroup,
  }) async {
    _ensureInitialized();
    final current = get(id, sourceKey);
    if (current == null) return;

    final updated = NekoHistory(
      id: current.id,
      sourceKey: current.sourceKey,
      title: current.title,
      subtitle: current.subtitle,
      cover: current.cover,
      ep: ep ?? current.ep,
      page: page ?? current.page,
      chapterGroup: chapterGroup ?? current.chapterGroup,
      readEpisodes: current.readEpisodes,
      maxPage: current.maxPage,
      time: DateTime.now(),
    );

    await add(updated);
  }

  /// Add read episode
  Future<void> addReadEpisode(String id, String sourceKey, String episode) async {
    _ensureInitialized();
    final current = get(id, sourceKey);
    if (current == null) return;

    final newEpisodes = Set<String>.from(current.readEpisodes)..add(episode);
    final updated = NekoHistory(
      id: current.id,
      sourceKey: current.sourceKey,
      title: current.title,
      subtitle: current.subtitle,
      cover: current.cover,
      ep: current.ep,
      page: current.page,
      chapterGroup: current.chapterGroup,
      readEpisodes: newEpisodes,
      maxPage: current.maxPage,
      time: current.time,
    );

    await add(updated);
  }

  /// Remove history
  Future<void> remove(String id, String sourceKey) async {
    _ensureInitialized();
    NekoDatabase.instance.execute(
      'DELETE FROM history WHERE id = ? AND source_key = ?',
      [id, sourceKey],
    );
    notifyListeners();
  }

  /// Clear all history
  Future<void> clear() async {
    _ensureInitialized();
    NekoDatabase.instance.execute('DELETE FROM history');
    notifyListeners();
  }

  /// Get history count
  int get count {
    _ensureInitialized();
    final result = NekoDatabase.instance.select(
      'SELECT COUNT(*) FROM history',
    );
    return result.first[0] as int;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('NekoHistoryManager not initialized');
    }
  }

  /// Initialize
  void initialize() {
    _isInitialized = true;
  }
}
