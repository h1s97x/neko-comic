import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neko_core/neko_core.dart';
import 'package:neko_source_js/neko_source_js.dart';
import 'package:neko_ui/neko_ui.dart';
import 'package:provider/provider.dart';

import '../../stores/app_store.dart';

/// Comic details page
class ComicDetailsPage extends StatefulWidget {
  final String sourceId;
  final String comicId;

  const ComicDetailsPage({
    super.key,
    required this.sourceId,
    required this.comicId,
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
    _checkFavorite();
  }

  Future<void> _loadComic() async {
    final appStore = context.read<AppStore>();
    
    try {
      final source = appStore.sources.firstWhere(
        (s) => s.id == widget.sourceId,
      );
      
      final comic = await source.getComicDetails(widget.comicId);
      
      setState(() {
        _comic = comic;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkFavorite() async {
    final isFav = await NekoFavoritesManager().isFavorite(widget.comicId);
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_comic == null) return;
    
    try {
      if (_isFavorite) {
        await NekoFavoritesManager().remove(_comic!.id);
      } else {
        await NekoFavoritesManager().add(_comic!);
      }
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      // Handle error
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
      return NekoErrorWidget(
        message: _error!,
        onRetry: _loadComic,
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
        SliverToBoxAdapter(
          child: _buildDescription(),
        ),
        SliverToBoxAdapter(
          child: _buildChaptersHeader(),
        ),
        _buildChaptersList(),
        SliverPadding(
          padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 16),
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
            // Background image
            if (_comic?.cover != null)
              Image.network(
                _comic!.cover!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).colorScheme.surface,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_outline,
            color: _isFavorite ? Colors.red : null,
          ),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Share comic
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _comic!.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoChip(icon: Icons.category, label: _comic!.type.name),
              const SizedBox(width: 8),
              _InfoChip(
                icon: Icons.list,
                label: '${_comic!.chapters.length} chapters',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    if (_comic!.description == null || _comic!.description!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: NekoComicDescription(
        description: _comic!.description!,
        tags: _comic!.tags,
      ),
    );
  }

  Widget _buildChaptersHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Chapters',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildChaptersList() {
    final chapters = _comic!.chapters;
    
    if (chapters.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No chapters available'),
          ),
        ),
      );
    }

    // Show newest first
    final sortedChapters = chapters.reversed.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final chapter = sortedChapters[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(chapter.title),
            subtitle: Text(chapter.time ?? ''),
            onTap: () => _openReader(chapter),
          );
        },
        childCount: sortedChapters.length,
      ),
    );
  }

  Future<void> _openReader(NekoChapter chapter) async {
    if (_comic == null) return;

    try {
      final images = await _comic!.source.getImages(chapter.id);
      
      if (!mounted) return;

      context.push('/reader', extra: {
        'comicId': _comic!.id,
        'chapterId': chapter.id,
        'images': images.map((e) => e.url).toList(),
        'currentIndex': 0,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load chapter: $e')),
      );
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
