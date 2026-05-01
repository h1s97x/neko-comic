import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:neko_core/neko_core.dart';
import 'package:neko_ui/neko_ui.dart';

/// 图片收藏项
class ImageFavoriteItem {
  final String id;
  final String comicId;
  final String comicTitle;
  final String? subTitle;
  final String sourceKey;
  final int ep;
  final String epName;
  final int page;
  final String? imageKey;
  final String? imageUrl;
  final DateTime time;
  final List<String> tags;

  ImageFavoriteItem({
    required this.id,
    required this.comicId,
    required this.comicTitle,
    this.subTitle,
    required this.sourceKey,
    required this.ep,
    required this.epName,
    required this.page,
    this.imageKey,
    this.imageUrl,
    required this.time,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'comicId': comicId,
        'comicTitle': comicTitle,
        'subTitle': subTitle,
        'sourceKey': sourceKey,
        'ep': ep,
        'epName': epName,
        'page': page,
        'imageKey': imageKey,
        'imageUrl': imageUrl,
        'time': time.toIso8601String(),
        'tags': tags,
      };

  factory ImageFavoriteItem.fromJson(Map<String, dynamic> json) =>
      ImageFavoriteItem(
        id: json['id'],
        comicId: json['comicId'],
        comicTitle: json['comicTitle'],
        subTitle: json['subTitle'],
        sourceKey: json['sourceKey'],
        ep: json['ep'],
        epName: json['epName'],
        page: json['page'],
        imageKey: json['imageKey'],
        imageUrl: json['imageUrl'],
        time: DateTime.parse(json['time']),
        tags: List<String>.from(json['tags'] ?? []),
      );
}

/// 图片收藏管理器
class ImageFavoritesManager {
  static ImageFavoritesManager? _instance;

  static ImageFavoritesManager get instance {
    _instance ??= ImageFavoritesManager._();
    return _instance!;
  }

  ImageFavoritesManager._();

  final List<ImageFavoriteItem> _favorites = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _loadFavorites();
    _initialized = true;
  }

  Future<void> _loadFavorites() async {
    final db = NekoDatabase.instance;
    final results = await db.rawQuery(
      "SELECT * FROM image_favorites ORDER BY time DESC;",
    );
    _favorites.clear();
    for (final row in results) {
      try {
        final item = ImageFavoriteItem(
          id: row['id'] as String,
          comicId: row['comic_id'] as String,
          comicTitle: row['comic_title'] as String,
          subTitle: row['sub_title'] as String?,
          sourceKey: row['source_key'] as String,
          ep: row['ep'] as int,
          epName: row['ep_name'] as String,
          page: row['page'] as int,
          imageKey: row['image_key'] as String?,
          imageUrl: row['image_url'] as String?,
          time: DateTime.parse(row['time'] as String),
          tags: (row['tags'] as String?)?.isNotEmpty == true
              ? (jsonDecode(row['tags'] as String) as List).cast<String>()
              : [],
        );
        _favorites.add(item);
      } catch (e) {
        debugPrint('Failed to load image favorite: $e');
      }
    }
  }

  List<ImageFavoriteItem> get favorites => List.unmodifiable(_favorites);

  Future<void> addFavorite(ImageFavoriteItem item) async {
    final db = NekoDatabase.instance;
    await db.insert('image_favorites', {
      'id': item.id,
      'comic_id': item.comicId,
      'comic_title': item.comicTitle,
      'sub_title': item.subTitle,
      'source_key': item.sourceKey,
      'ep': item.ep,
      'ep_name': item.epName,
      'page': item.page,
      'image_key': item.imageKey,
      'image_url': item.imageUrl,
      'time': item.time.toIso8601String(),
      'tags': jsonEncode(item.tags),
    });
    _favorites.insert(0, item);
  }

  Future<void> removeFavorite(String id) async {
    final db = NekoDatabase.instance;
    await db.delete('image_favorites', where: 'id = ?', whereArgs: [id]);
    _favorites.removeWhere((item) => item.id == id);
  }

  bool isFavorited(String comicId, int ep, int page, String sourceKey) {
    return _favorites.any((item) =>
        item.comicId == comicId &&
        item.ep == ep &&
        item.page == page &&
        item.sourceKey == sourceKey);
  }

  Future<void> clear() async {
    final db = NekoDatabase.instance;
    await db.delete('image_favorites');
    _favorites.clear();
  }
}

/// 图片收藏页面
class ImageFavoritesPage extends StatefulWidget {
  const ImageFavoritesPage({super.key});

  @override
  State<ImageFavoritesPage> createState() => _ImageFavoritesPageState();
}

class _ImageFavoritesPageState extends State<ImageFavoritesPage> {
  late Future<List<ImageFavoriteItem>> _loadFuture;
  List<ImageFavoriteItem> _items = [];
  Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadItems();
  }

  Future<List<ImageFavoriteItem>> _loadItems() async {
    await ImageFavoritesManager.instance.init();
    return ImageFavoritesManager.instance.favorites;
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  Future<void> _deleteSelected() async {
    for (final id in _selectedIds) {
      await ImageFavoritesManager.instance.removeFavorite(id);
    }
    setState(() {
      _items.removeWhere((item) => _selectedIds.contains(item.id));
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图片收藏'),
        actions: [
          if (_isSelectionMode) ...[
            Text('${_selectedIds.length}'),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _selectedIds.isNotEmpty ? _deleteSelected : null,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectedIds.clear();
                  _isSelectionMode = false;
                });
              },
            ),
          ] else if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                setState(() {
                  _isSelectionMode = true;
                  _selectedIds.addAll(_items.map((e) => e.id));
                });
              },
            ),
        ],
      ),
      body: FutureBuilder<List<ImageFavoriteItem>>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return NekoErrorWidget(
              error: snapshot.error.toString(),
              onRetry: () => setState(() {
                _loadFuture = _loadItems();
              }),
            );
          }
          _items = snapshot.data ?? [];
          if (_items.isEmpty) {
            return const NekoEmptyWidget(
              message: '还没有收藏的图片',
              icon: Icons.image_not_supported_outlined,
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.7,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              final isSelected = _selectedIds.contains(item.id);
              return GestureDetector(
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleSelection(item.id);
                  } else {
                    _openImage(item);
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedIds.add(item.id);
                    });
                  }
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.imageUrl != null
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.broken_image),
                              ),
                            )
                          : Container(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.image),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          'P${item.page}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    if (_isSelectionMode)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSelected ? Icons.check : null,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openImage(ImageFavoriteItem item) {
    // TODO: 打开图片查看器
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.comicTitle} - ${item.epName} P${item.page}')),
    );
  }
}
