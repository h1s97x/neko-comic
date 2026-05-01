import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neko_core/neko_core.dart';
import 'package:neko_source_js/neko_source_js.dart';

/// Profile page showing user stats and quick actions
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _favoritesCount = 0;
  int _historyCount = 0;
  int _sourcesCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      await NekoDatabase.init();
      
      final favoritesManager = NekoFavoritesManager();
      final favorites = await favoritesManager.getAll();

      final historyManager = NekoHistoryManager();
      final history = await historyManager.getAll();

      final sources = NekoComicSourceManager().all();

      setState(() {
        _favoritesCount = favorites.length;
        _historyCount = history.length;
        _sourcesCount = sources.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildStatsCard(),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 16),
                  _buildAppInfo(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.favorite,
                  label: 'Favorites',
                  value: _favoritesCount.toString(),
                ),
                _buildStatItem(
                  icon: Icons.history,
                  label: 'History',
                  value: _historyCount.toString(),
                ),
                _buildStatItem(
                  icon: Icons.source,
                  label: 'Sources',
                  value: _sourcesCount.toString(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorPrimary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Favorites'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/favorites'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Reading History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/history'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Downloads'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to downloads
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloads page coming soon')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Sync'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to sync settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sync page coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NekoComic',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'A modern comic reader with modular architecture',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Version 0.1.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
