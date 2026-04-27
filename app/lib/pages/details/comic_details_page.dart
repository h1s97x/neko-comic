import 'package:flutter/material.dart';
import 'package:neko_source_js/neko_source_js.dart';

/// Comic details page
class ComicDetailsPage extends StatefulWidget {
  final String comicId;
  final String sourceKey;
  final NekoComicSource source;

  const ComicDetailsPage({
    super.key,
    required this.comicId,
    required this.sourceKey,
    required this.source,
  });

  @override
  State<ComicDetailsPage> createState() => _ComicDetailsPageState();
}

class _ComicDetailsPageState extends State<ComicDetailsPage> {
  NekoComicDetails? _comic;
  bool _isLoading = true;
  String? _error;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadComic();
  }

  Future<void> _loadComic() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.source.getComic(widget.comicId);
      if (result.isSuccess) {
        setState(() {
          _comic = result.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error ?? 'Failed to load comic';
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
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadComic,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_comic == null) {
      return const Center(
        child: Text('Comic not found'),
      );
    }

    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        if (_comic!.description != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_comic!.description!),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Chapters (${_comic!.chapters.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        _buildChaptersList(),
        SliverPadding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 80,
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_comic?.cover != null)
              Image.network(
                _comic!.cover!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(179),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Text(
                _comic!.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : null,
          ),
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              _comic!.cover ?? '',
              width: 120,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 120,
                height: 180,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.image),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_comic!.author != null)
                  Text(
                    _comic!.author!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                const SizedBox(height: 8),
                if (_comic!.tags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _comic!.tags.take(5).map((tag) {
                      return Chip(
                        label: Text(tag),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChaptersList() {
    if (_comic!.chapters.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No chapters available'),
          ),
        ),
      );
    }

    final chapters = _comic!.chapters.reversed.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final chapter = chapters[index];
          return ListTile(
            title: Text(chapter.title),
            subtitle: Text(chapter.subId ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to reader
            },
          );
        },
        childCount: chapters.length,
      ),
    );
  }
}
