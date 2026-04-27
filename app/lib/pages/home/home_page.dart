import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neko_source_js/neko_source_js.dart';
import 'package:neko_ui/neko_ui.dart';
import 'package:provider/provider.dart';

import '../../stores/app_store.dart';

/// Home page with comic sources and recent updates
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final appStore = context.read<AppStore>();
    
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: const Text('NekoComic'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => appStore.refreshSources(),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: _SearchBar(),
        ),
        if (!appStore.isInitialized && appStore.initError == null)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (appStore.initError != null)
          SliverFillRemaining(
            child: NekoErrorWidget(
              message: appStore.initError!,
              onRetry: () => appStore.init(),
            ),
          )
        else ...[
          const SliverToBoxAdapter(
            child: _SourcesSection(),
          ),
          const SliverToBoxAdapter(
            child: _HistorySection(),
          ),
          const SliverToBoxAdapter(
            child: _FavoritesSection(),
          ),
        ],
        SliverPadding(padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom)),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => context.go('/search'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  'Search comics...',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourcesSection extends StatelessWidget {
  const _SourcesSection();

  @override
  Widget build(BuildContext context) {
    final appStore = context.watch<AppStore>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Comic Sources',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        SizedBox(
          height: 120,
          child: appStore.sources.isEmpty
              ? const Center(child: Text('No sources loaded'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: appStore.sources.length,
                  itemBuilder: (context, index) {
                    final source = appStore.sources[index];
                    return _SourceCard(source: source);
                  },
                ),
        ),
      ],
    );
  }
}

class _SourceCard extends StatelessWidget {
  final NekoComicSource source;
  
  const _SourceCard({required this.source});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () {
          // Navigate to source page
        },
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 100,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.book,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                source.name,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  // Navigate to history page
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 160,
          child: Center(
            child: Text('No reading history'),
          ),
        ),
      ],
    );
  }
}

class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Favorites',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () => context.go('/favorites'),
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 200,
          child: Center(
            child: Text('No favorites yet'),
          ),
        ),
      ],
    );
  }
}
