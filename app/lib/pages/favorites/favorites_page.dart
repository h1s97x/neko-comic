import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neko_core/neko_core.dart';
import 'package:neko_ui/neko_ui.dart';

/// Favorites page showing saved comics with follow updates
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<NekoFavoriteItem> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _favorites = NekoFavoritesManager.instance.getAll();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Favorites'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFavoritesTab(),
                _buildFollowingTab(),
              ],
            ),
    );
  }

  Widget _buildFavoritesTab() {
    if (_favorites.isEmpty) {
      return const NekoEmptyWidget(
        icon: Icons.favorite_border,
        message: 'No favorites yet',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final fav = _favorites[index];
          final comic = fav.toComic();
          return NekoComicTile(
            comic: comic,
            onTap: () => _openComicDetails(comic),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _removeFavorite(fav),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFollowingTab() {
    final followManager = NekoFollowManager.instance;
    final followed = followManager.getFollowedComics();

    if (followed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const NekoEmptyWidget(
              icon: Icons.notifications_none,
              message: 'No followed comics',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/favorites'),
              child: const Text('Go to Favorites'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await followManager.checkUpdates();
        setState(() {});
      },
      child: ListView.builder(
        itemCount: followed.length,
        itemBuilder: (context, index) {
          final comic = followed[index];
          final updateInfo = followManager.getUpdateInfo(comic.id);
          return _FollowedComicTile(
            comic: comic,
            updateInfo: updateInfo,
            onTap: () => _openComicDetails(comic),
          );
        },
      ),
    );
  }

  void _openComicDetails(NekoComic comic) {
    context.push('/comic/${Uri.encodeComponent(comic.id)}?sourceId=${comic.sourceId}');
  }

  Future<void> _removeFavorite(NekoFavoriteItem fav) async {
    await NekoFavoritesManager.instance.remove(fav.id);
    _loadFavorites();
  }
}

/// Tile for followed comics showing update status
class _FollowedComicTile extends StatelessWidget {
  final NekoComic comic;
  final NekoFollowUpdateInfo? updateInfo;
  final VoidCallback onTap;

  const _FollowedComicTile({
    required this.comic,
    this.updateInfo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUpdate = updateInfo != null && updateInfo!.hasUpdate;
    final isNewChapters = updateInfo?.newChapters.isNotEmpty ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: comic.cover.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  comic.cover,
                  width: 50,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 70,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image),
                  ),
                ),
              )
            : Container(
                width: 50,
                height: 70,
                color: Colors.grey[300],
                child: const Icon(Icons.image),
              ),
        title: Text(
          comic.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasUpdate && isNewChapters)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${updateInfo!.newChapters.length} new chapters',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              )
            else
              Text(
                comic.authors.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: hasUpdate
            ? const Icon(Icons.notifications_active, color: Colors.green)
            : const Icon(Icons.notifications_none),
        onTap: onTap,
      ),
    );
  }
}
