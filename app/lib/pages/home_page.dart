import 'package:flutter/material.dart';
import 'package:neko_ui/neko_ui.dart';

/// Home page
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo data
    final comics = List.generate(
      10,
      (i) => ComicItem(
        id: 'comic_$i',
        title: 'Comic ${i + 1}',
        coverUrl: 'https://picsum.photos/200/300?random=$i',
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('NekoComic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
        ],
      ),
      body: ComicGrid(
        comics: comics,
        columns: 3,
        onLoadMore: () {
          // TODO: Load more comics
        },
      ),
    );
  }
}
