import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neko_core/neko_core.dart';
import 'package:neko_source_js/neko_source_js.dart';
import 'package:neko_ui/neko_ui.dart';

/// Aggregate search page - searches multiple sources simultaneously
class AggregateSearchPage extends StatefulWidget {
  final String? initialQuery;

  const AggregateSearchPage({
    super.key,
    this.initialQuery,
  });

  @override
  State<AggregateSearchPage> createState() => _AggregateSearchPageState();
}

class _AggregateSearchPageState extends State<AggregateSearchPage> {
  final _searchController = TextEditingController();
  final Set<String> _selectedSources = {};
  List<NekoComic> _results = [];
  final Map<String, SearchPageData?> _sourceResults = {};
  bool _isSearching = false;
  bool _selectingSources = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _selectingSources = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.trim().isEmpty) return;
    if (_selectedSources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one source')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
      _results = [];
      _sourceResults.clear();
    });

    final query = _searchController.text.trim();
    final manager = NekoComicSourceManager();

    // Search all selected sources in parallel
    await Future.wait(_selectedSources.map((sourceKey) async {
      final source = manager.find(sourceKey);
      if (source == null) return;

      try {
        final data = await source.search(query);
        if (mounted) {
          setState(() {
            _sourceResults[sourceKey] = data;
            if (data.comics != null) {
              _results.addAll(data.comics!);
            }
          });
        }
      } catch (e) {
        debugPrint('Search failed for $sourceKey: $e');
      }
    }));

    if (mounted) {
      setState(() {
        _isSearching = false;
        _selectingSources = false;
      });
    }
  }

  void _showSourceSelector() {
    final sources = NekoComicSourceManager().sources;
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Sources',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Select all
                        setModalState(() {
                          _selectedSources.clear();
                          _selectedSources.addAll(sources.map((s) => s.key));
                        });
                      },
                      child: const Text('Select All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sources.length,
                    itemBuilder: (context, index) {
                      final source = sources[index];
                      final isSelected = _selectedSources.contains(source.key);
                      return CheckboxListTile(
                        title: Text(source.name),
                        subtitle: Text(source.lang ?? 'Unknown'),
                        value: isSelected,
                        onChanged: (value) {
                          setModalState(() {
                            if (value == true) {
                              _selectedSources.add(source.key);
                            } else {
                              _selectedSources.remove(source.key);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: NekoButton(
                    label: 'Search (${_selectedSources.length} sources)',
                    onPressed: () {
                      Navigator.pop(context);
                      _performSearch();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search comics across all sources...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onSubmitted: (_) => _performSearch(),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showSourceSelector,
            tooltip: 'Select Sources',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _performSearch,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching multiple sources...'),
          ],
        ),
      );
    }

    if (_selectingSources) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Search ${_selectedSources.isEmpty ? "all" : _selectedSources.length} sources',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a query and tap search',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            NekoButton(
              label: 'Select Sources',
              onPressed: _showSourceSelector,
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text('No results found'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${_results.length} results',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Text(
                'from ${_sourceResults.length} sources',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Change Sources'),
                onPressed: () {
                  setState(() {
                    _selectingSources = true;
                    _results = [];
                    _sourceResults.clear();
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: NekoComicGrid(
            comics: _results,
            onComicTap: (comic) {
              context.push('/comic/${comic.sourceKey}/${comic.id}');
            },
          ),
        ),
      ],
    );
  }
}
