/// Sync manager for NekoComic
/// Reference: Venera utils/data_sync.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:webdav_client/webdav_client.dart';

import '../storage/database.dart';
import '../storage/favorites.dart';
import '../storage/history.dart';

/// Sync configuration
class NekoSyncConfig {
  final String serverUrl;
  final String username;
  final String password;
  final bool enabled;

  const NekoSyncConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.enabled = true,
  });

  bool get isValid =>
      serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'serverUrl': serverUrl,
        'username': username,
        'password': password,
        'enabled': enabled,
      };

  factory NekoSyncConfig.fromJson(Map<String, dynamic> json) {
    return NekoSyncConfig(
      serverUrl: json['serverUrl'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      enabled: json['enabled'] ?? true,
    );
  }
}

/// Sync status
enum NekoSyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Sync manager for WebDAV synchronization
class NekoSyncManager with ChangeNotifier {
  static NekoSyncManager? _instance;
  static NekoSyncManager get instance => _instance ??= NekoSyncManager._();

  NekoSyncManager._();

  NekoSyncConfig? _config;
  NekoSyncStatus _status = NekoSyncStatus.idle;
  String? _lastError;
  DateTime? _lastSyncTime;

  /// Current sync status
  NekoSyncStatus get status => _status;

  /// Last error message
  String? get lastError => _lastError;

  /// Last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Is syncing
  bool get isSyncing => _status == NekoSyncStatus.syncing;

  /// Check if sync is configured
  bool get isConfigured => _config?.isValid ?? false;

  /// Configure sync
  void configure(NekoSyncConfig config) {
    _config = config;
    notifyListeners();
  }

  /// Clear configuration
  void clearConfig() {
    _config = null;
    _status = NekoSyncStatus.idle;
    _lastError = null;
    notifyListeners();
  }

  /// Sync data to remote
  Future<void> sync() async {
    if (_status == NekoSyncStatus.syncing) return;
    if (_config == null || !_config!.isValid) {
      _lastError = 'Sync not configured';
      _status = NekoSyncStatus.error;
      notifyListeners();
      return;
    }

    _status = NekoSyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final client = WebDavClient(
        _config!.serverUrl,
        user: _config!.username,
        password: _config!.password,
      );

      // Prepare local data
      final data = _prepareSyncData();

      // Upload to remote
      final jsonStr = jsonEncode(data);
      final bytes = utf8.encode(jsonStr);

      await client.write(
        '/neko_comic/sync.json',
        Stream.fromIterable([bytes]),
        length: bytes.length,
      );

      _lastSyncTime = DateTime.now();
      _status = NekoSyncStatus.success;
    } catch (e) {
      _lastError = e.toString();
      _status = NekoSyncStatus.error;
    }

    notifyListeners();
  }

  /// Download data from remote
  Future<void> download() async {
    if (_status == NekoSyncStatus.syncing) return;
    if (_config == null || !_config!.isValid) {
      _lastError = 'Sync not configured';
      _status = NekoSyncStatus.error;
      notifyListeners();
      return;
    }

    _status = NekoSyncStatus.syncing;
    _lastError = null;
    notifyListeners();

    try {
      final client = WebDavClient(
        _config!.serverUrl,
        user: _config!.username,
        password: _config!.password,
      );

      // Download from remote
      final data = await client.read('/neko_comic/sync.json');
      final jsonStr = utf8.decode(data);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Apply downloaded data
      _applySyncData(json);

      _lastSyncTime = DateTime.now();
      _status = NekoSyncStatus.success;
    } catch (e) {
      _lastError = e.toString();
      _status = NekoSyncStatus.error;
    }

    notifyListeners();
  }

  /// Full sync (upload then download)
  Future<void> fullSync() async {
    await sync();
    if (_status == NekoSyncStatus.success) {
      await download();
    }
  }

  Map<String, dynamic> _prepareSyncData() {
    // Get favorites
    final favorites = NekoFavoritesManager.instance.getAll();

    // Get history
    final history = NekoHistoryManager.instance.getAll();

    return {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'favorites': favorites.map((f) => f.toJson()).toList(),
      'history': history.map((h) => h.toJson()).toList(),
    };
  }

  void _applySyncData(Map<String, dynamic> data) {
    // Apply favorites
    final favorites = data['favorites'] as List<dynamic>?;
    if (favorites != null) {
      for (final item in favorites) {
        final favorite = NekoFavoriteItem(
          id: item['id'],
          sourceKey: item['source_key'],
          name: item['name'],
          author: item['author'],
          coverPath: item['cover_path'],
          tags: (item['tags'] as String).split(','),
          time: DateTime.parse(item['time']),
        );
        NekoFavoritesManager.instance.add(favorite);
      }
    }

    // Apply history
    final history = data['history'] as List<dynamic>?;
    if (history != null) {
      for (final item in history) {
        final h = NekoHistory(
          id: item['id'],
          sourceKey: item['source_key'],
          title: item['title'],
          subtitle: item['subtitle'],
          cover: item['cover'],
          ep: item['ep'] ?? 0,
          page: item['page'] ?? 0,
          chapterGroup: item['chapter_group'],
          readEpisodes: (item['read_episode'] as String).split(',').toSet(),
          maxPage: item['max_page'],
          time: DateTime.fromMillisecondsSinceEpoch(item['time']),
        );
        NekoHistoryManager.instance.add(h);
      }
    }
  }
}
