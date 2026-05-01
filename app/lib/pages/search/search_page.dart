import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neko_source_js/neko_source_js.dart';
import 'package:neko_ui/neko_ui.dart';

/// Search page for finding comics
class SearchPage extends StatefulWidget {
  final String? initialQuery;
  final String? source;
  final String? category;

  const SearchPage({
    super.key,
    this.initialQuery,
    this.source,
    this.category,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  List<NekoComic> _results = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedSourceKey;
  bool _searchAllSources = true;
  final Map<String, List<NekoComic>> _multiSourceResults = {};
  final Set<String> _loadedSources = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _search(widget.initialQuery!);
    }
    if (widget.source != null) {
      _selectedSourceKey = widget.source;
      _searchAllSources = false;
    }
    if (widget.category != null) {
      _searchController.text = widget.category!;
      _searchByCategory(widget.category!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String keyword) async {
    if (keyword.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      if (_searchAllSources) {
        _multiSourceResults.clear();
        _loadedSources.clear();
      }
    });

    try {
      final sources = NekoComicSourceManager().all();
      if (sources.isEmpty) {
        setState(() {
          _error = 'No comic sources available';
          _isLoading = false;
        });
        return;
      }

      if (_searchAllSources) {
        // Search all sources in parallel
        final futures = sources.map((source) => _searchSource(source, keyword));
        await Future.wait(futures);
        _mergeResults();
      } else {
        // Search selected source
        final source = sources.firstWhere(
          (s) => s.key == _selectedSourceKey,
          orElse: () => sources.first,
        );
        final result = await source.search(keyword);
        if (result.isSuccess && result.data != null) {
          _results = result.data!;
        } else {
          _error = result.error ?? 'Search failed';
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchSource(NekoComicSource source, String keyword) async {
    try {
      final result = await source.search(keyword);
      if (result.isSuccess && result.data != null) {
        _multiSourceResults[source.key] = result.data!;
      }
      _loadedSources.add(source.key);
      if (mounted) setState(() {});
    } catch (e) {
      // Ignore errors for individual sources
    }
  }

  void _mergeResults() {
    _results = _multiSourceResults.values.expand((list) => list).toList();
  }

  Future<void> _searchByCategory(String category) async {
    if (category.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final source = _selectedSourceKey != null
          ? NekoComicSourceManager().find(_selectedSourceKey!)
          : NekoComicSourceManager().all().firstOrNull;

      if (source == null) {
        setState(() {
          _error = 'No source available';
          _isLoading = false;
        });
        return;
      }

      final result = await source.search(category);
      if (result.isSuccess && result.data != null) {
        setState(() {
          _results = result.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error ?? 'Search failed';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              if (value == 'all') {
                setState(() {
                  _selectedSourceKey = null;
                  _searchAllSources = true;
                });
              } else {
                setState(() {
                  _selectedSourceKey = value;
                  _searchAllSources = false;
                });
              }
            },
            itemBuilder: (context) {
              final sources = NekoComicSourceManager().all();
              return [
                PopupMenuItem<String>(
                  value: 'all',
                  child: Row(
                    children: [
                      if (_searchAllSources) const Icon(Icons.check, size: 18),
                      if (!_searchAllSources) const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      const Text('All Sources'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                ...sources.map((source) {
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
                }),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_searchAllSources && _multiSourceResults.isNotEmpty)
            _buildSourceTabs(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: widget.category != null
              ? 'Browsing: ${widget.category}'
              : 'Search comics...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _results = [];
                      _multiSourceResults.clear();
                    });
                  },
                ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () => _search(_searchController.text),
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onSubmitted: _search,
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildSourceTabs() {
    final sources = _multiSourceResults.keys.toList();
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sources.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('All (${_results.length})'),
                selected: true,
                onSelected: (_) {
                  _mergeResults();
                  setState(() {});
                },
              ),
            );
          }
          final sourceKey = sources[index - 1];
          final source = NekoComicSourceManager().find(sourceKey);
          final count = _multiSourceResults[sourceKey]?.length ?? 0;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${source?.name ?? sourceKey} ($count)'),
              selected: false,
              onSelected: (_) {
                setState(() {
                  _results = _multiSourceResults[sourceKey] ?? [];
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (_searchAllSources && _loadedSources.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Searching ${_loadedSources.length} sources...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      );
    }

    if (_error != null) {
      return NekoErrorWidget(
        message: _error!,
        onRetry: () => _search(_searchController.text),
      );
    }

    if (_results.isEmpty) {
      return const NekoEmptyWidget(
        message: 'No results found',
        icon: Icons.search_off,
      );
    }

    return NekoComicGrid(
      comics: _results,
      onComicTap: (comic) {
        context.push('/comic/${comic.sourceKey}/${comic.id}');
      },
    );
  }
}
