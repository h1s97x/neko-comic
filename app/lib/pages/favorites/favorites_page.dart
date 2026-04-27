import 'package:flutter/material.dart';
import 'package:neko_core/neko_core.dart';
import 'package:neko_ui/neko_ui.dart';

/// Favorites page showing saved comics
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<NekoFavoriteItem> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
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
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_favorites.isEmpty) {
      return const NekoEmptyWidget(
        icon: Icons.favorite_border,
        message: 'No favorites yet',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadFavorites();
      },
      child: ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final fav = _favorites[index];
          final comic = fav.toComic();
          return NekoComicTile(
            comic: comic,
            onTap: () {
              // Navigate to comic details
            },
          );
        },
      ),
    );
  }
}
