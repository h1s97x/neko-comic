import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neko_core/neko_core.dart';
import 'package:neko_ui/neko_ui.dart';
import 'package:provider/provider.dart';

import '../../stores/app_store.dart';

/// Search page for finding comics
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  
  String? _selectedSourceId;
  List<NekoComic> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchFocus.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final appStore = context.read<AppStore>();
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      List<NekoComic> results = [];
      
      if (_selectedSourceId != null) {
        final source = appStore.sources.firstWhere(
          (s) => s.id == _selectedSourceId,
        );
        results = await source.search(query);
      } else {
        // Search all sources
        for (final source in appStore.sources) {
          try {
            final sourceResults = await source.search(query);
            results.addAll(sourceResults);
          } catch (e) {
            // Skip sources that fail
          }
        }
      }

      setState(() {
        _results = results;
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
    final appStore = context.watch<AppStore>();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          decoration: InputDecoration(
            hintText: 'Search comics...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _results = [];
                      });
                    },
                  )
                : null,
          ),
          onSubmitted: (_) => _search(),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _search,
          ),
        ],
      ),
      body: Column(
        children: [
          // Source filter
          if (appStore.sources.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedSourceId == null,
                    onSelected: (_) {
                      setState(() {
                        _selectedSourceId = null;
                      });
                      if (_searchController.text.isNotEmpty) {
                        _search();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ...appStore.sources.map((source) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(source.name),
                      selected: _selectedSourceId == source.id,
                      onSelected: (_) {
                        setState(() {
                          _selectedSourceId = source.id;
                        });
                        if (_searchController.text.isNotEmpty) {
                          _search();
                        }
                      },
                    ),
                  )),
                ],
              ),
            ),
          const Divider(height: 1),
          // Results
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return NekoErrorWidget(
        message: _error!,
        onRetry: _search,
      );
    }

    if (_results.isEmpty && _searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Search for comics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return NekoComicGrid(
      comics: _results,
      onComicTap: (comic) {
        context.push('/comic/${comic.sourceId}/${comic.id}');
      },
    );
  }
}
