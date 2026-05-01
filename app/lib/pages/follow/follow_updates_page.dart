import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neko_ui/neko_ui.dart';
import '../../stores/app_store.dart';
import '../../router.dart';

class FollowUpdatesPage extends StatefulWidget {
  const FollowUpdatesPage({super.key});

  @override
  State<FollowUpdatesPage> createState() => _FollowUpdatesPageState();
}

class _FollowUpdatesPageState extends State<FollowUpdatesPage> {
  String? _folder;
  List<Map<String, dynamic>> _updatedComics = [];
  List<Map<String, dynamic>> _allComics = [];
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final store = context.read<NekoAppStore>();
    _folder = store.settings['followUpdatesFolder'];
    if (_folder != null) {
      _allComics = store.getFollowComics(_folder!);
      _updatedComics = _allComics.where((c) => c['hasNewUpdate'] == true).toList();
    }
  }

  Future<void> _checkUpdates() async {
    if (_folder == null || _isChecking) return;
    setState(() => _isChecking = true);
    
    // Simulate checking updates
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() {
      _isChecking = false;
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow Updates'),
        actions: [
          if (_folder != null)
            IconButton(
              icon: _isChecking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isChecking ? null : _checkUpdates,
            ),
        ],
      ),
      body: _folder == null ? _buildNotConfigured() : _buildContent(),
    );
  }

  Widget _buildNotConfigured() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Not Configured',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a favorites folder and set it as the follow folder in settings.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
            label: const Text('Go to Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        if (_updatedComics.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Updates (${_updatedComics.length})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final comic = _updatedComics[index];
                return _buildComicTile(comic);
              },
              childCount: _updatedComics.length,
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 32)),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'All (${_allComics.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final comic = _allComics[index];
              return _buildComicTile(comic);
            },
            childCount: _allComics.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildComicTile(Map<String, dynamic> comic) {
    return NekoComicTile(
      comic: comic,
      showUpdateBadge: comic['hasNewUpdate'] == true,
      onTap: () => context.push('/comic/${comic['id']}?source=${comic['source']}'),
    );
  }
}
