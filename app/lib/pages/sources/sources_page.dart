import 'package:flutter/material.dart';
import 'package:neko_source_js/neko_source_js.dart';

/// Source management page for adding/removing/enabling/disabling comic sources
class SourcesPage extends StatefulWidget {
  const SourcesPage({super.key});

  @override
  State<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends State<SourcesPage> {
  List<NekoComicSource> _sources = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  void _loadSources() {
    setState(() {
      _sources = NekoComicSourceManager().all();
      _isLoading = false;
    });
  }

  Future<void> _refreshSources() async {
    await NekoComicSourceManager().refresh();
    _loadSources();
  }

  Future<void> _addSource() async {
    final urlController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comic Source'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Source URL',
            hintText: 'Enter JavaScript source URL',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(urlController.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await NekoComicSourceManager().addSource(result);
        _loadSources();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Source added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add source: $e')),
          );
        }
      }
    }
  }

  Future<void> _removeSource(NekoComicSource source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Source'),
        content: Text('Are you sure you want to remove "${source.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await NekoComicSourceManager().remove(source.key);
        _loadSources();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Source removed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove source: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comic Sources'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSources,
            tooltip: 'Refresh Sources',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sources.isEmpty
              ? _buildEmptyState()
              : _buildSourceList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSource,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.source_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No comic sources',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a source to start reading comics',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addSource,
            icon: const Icon(Icons.add),
            label: const Text('Add Source'),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceList() {
    return RefreshIndicator(
      onRefresh: _refreshSources,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _sources.length,
        itemBuilder: (context, index) {
          final source = _sources[index];
          return _SourceCard(
            source: source,
            onRemove: () => _removeSource(source),
          );
        },
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  final NekoComicSource source;
  final VoidCallback onRemove;

  const _SourceCard({
    required this.source,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (source.icon != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      source.icon!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 40,
                        height: 40,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.source),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.source),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (source.version != null)
                        Text(
                          'v${source.version}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'remove') {
                      onRemove();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'remove',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Remove', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (source.description != null) ...[
              const SizedBox(height: 12),
              Text(
                source.description!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (source.supportSearch)
                  _buildFeatureChip(Icons.search, 'Search'),
                if (source.supportCategory)
                  _buildFeatureChip(Icons.category, 'Category'),
                if (source.supportExplore)
                  _buildFeatureChip(Icons.explore, 'Explore'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
