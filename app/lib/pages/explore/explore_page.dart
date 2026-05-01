import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neko_source_js/neko_source_js.dart';
import 'package:neko_ui/neko_ui.dart';

/// Explore page showing content from comic sources
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _explorePages = [];

  @override
  void initState() {
    super.initState();
    _loadExplorePages();
  }

  void _loadExplorePages() {
    final sources = NekoComicSourceManager().all();
    for (final source in sources) {
      for (final page in source.explorePages) {
        _explorePages.add(page.title);
      }
    }
    _tabController = TabController(
      length: _explorePages.length,
      vsync: this,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_explorePages.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Explore'),
        ),
        body: const NekoEmptyWidget(
          message: 'No explore pages available',
          icon: Icons.explore_off,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _explorePages.map((title) => Tab(text: title)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _explorePages.map((title) {
          return _ExplorePageContent(
            sourceKey: _getSourceKeyForPage(title),
            pageTitle: title,
          );
        }).toList(),
      ),
    );
  }

  String? _getSourceKeyForPage(String title) {
    final sources = NekoComicSourceManager().all();
    for (final source in sources) {
      for (final page in source.explorePages) {
        if (page.title == title) {
          return source.key;
        }
      }
    }
    return null;
  }
}

class _ExplorePageContent extends StatefulWidget {
  final String? sourceKey;
  final String pageTitle;

  const _ExplorePageContent({
    required this.sourceKey,
    required this.pageTitle,
  });

  @override
  State<_ExplorePageContent> createState() => _ExplorePageContentState();
}

class _ExplorePageContentState extends State<_ExplorePageContent> {
  NekoExplorePageData? _pageData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    if (widget.sourceKey == null) {
      setState(() {
        _isLoading = false;
        _error = 'Source not found';
      });
      return;
    }

    final source = NekoComicSourceManager().find(widget.sourceKey!);
    if (source == null) {
      setState(() {
        _isLoading = false;
        _error = 'Source not found';
      });
      return;
    }

    try {
      final result = await source.getExplorePage(widget.pageTitle);
      setState(() {
        _pageData = result;
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return NekoErrorWidget(
        message: _error!,
        onRetry: _loadPage,
      );
    }

    if (_pageData == null) {
      return const NekoEmptyWidget(
        message: 'No data available',
        icon: Icons.inbox,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPage,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pageData!.items.length,
        itemBuilder: (context, index) {
          final item = _pageData!.items[index];
          return _buildItem(context, item);
        },
      ),
    );
  }

  Widget _buildItem(BuildContext context, NekoExploreItem item) {
    switch (item.type) {
      case NekoExploreItemType.comics:
        return _buildComicSection(item);
      case NekoExploreItemType.section:
        return _buildSectionHeader(item);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSectionHeader(NekoExploreItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        item.title ?? '',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildComicSection(NekoExploreItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.title != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              item.title!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: item.comics?.length ?? 0,
            itemBuilder: (context, index) {
              final comic = item.comics![index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 140,
                  child: NekoComicCard(
                    comic: comic,
                    onTap: () {
                      context.push(
                        '/comic/${comic.sourceKey}/${comic.id}',
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
