import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neko_source_js/neko_source_js.dart';
import 'package:neko_ui/neko_ui.dart';

/// Categories page for browsing comics by category
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  String? _selectedSourceKey;
  List<NekoCategoryData> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  void _loadSources() {
    final sources = NekoComicSourceManager().all();
    if (sources.isNotEmpty) {
      _selectedSourceKey = sources.first.key;
      _loadCategories();
    } else {
      setState(() {
        _isLoading = false;
        _error = 'No sources available';
      });
    }
  }

  Future<void> _loadCategories() async {
    if (_selectedSourceKey == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final source = NekoComicSourceManager().find(_selectedSourceKey!);
    if (source == null) {
      setState(() {
        _isLoading = false;
        _error = 'Source not found';
      });
      return;
    }

    try {
      final result = await source.getCategories();
      setState(() {
        _categories = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = NekoComicSourceManager().all();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          if (sources.length > 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.source),
              onSelected: (key) {
                setState(() {
                  _selectedSourceKey = key;
                });
                _loadCategories();
              },
              itemBuilder: (context) {
                return sources.map((source) {
                  return PopupMenuItem<String>(
                    value: source.key,
                    child: Row(
                      children: [
                        if (source.key == _selectedSourceKey)
                          const Icon(Icons.check, size: 18),
                        if (source.key != _selectedSourceKey)
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Text(source.name),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return NekoErrorWidget(
        message: _error!,
        onRetry: _loadCategories,
      );
    }

    if (_categories.isEmpty) {
      return const NekoEmptyWidget(
        message: 'No categories available',
        icon: Icons.category_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          return _CategoryTile(
            category: category,
            sourceKey: _selectedSourceKey!,
            onTap: () {
              context.push(
                '/search?source=$_selectedSourceKey&category=${Uri.encodeComponent(category.name)}',
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final NekoCategoryData category;
  final String sourceKey;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.sourceKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: category.icon != null
            ? Icon(_getIconData(category.icon!))
            : const Icon(Icons.category),
        title: Text(category.name),
        subtitle: category.count != null
            ? Text('${category.count} comics')
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  IconData _getIconData(String iconName) {
    // Map common icon names to IconData
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'trending':
        return Icons.trending_up;
      case 'new':
        return Icons.new_releases;
      case 'hot':
        return Icons.local_fire_department;
      case 'random':
        return Icons.shuffle;
      default:
        return Icons.category;
    }
  }
}
