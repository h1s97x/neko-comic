import 'package:flutter/material.dart';
import 'package:neko_reader/neko_reader.dart';
import 'package:neko_source_js/neko_source_js.dart';

/// Reader page for viewing comic chapters
class ReaderPage extends StatefulWidget {
  final String comicId;
  final String chapterId;
  final NekoComicSource source;

  const ReaderPage({
    super.key,
    required this.comicId,
    required this.chapterId,
    required this.source,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  bool _isLoading = true;
  String? _error;
  List<String> _images = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadChapter();
  }

  Future<void> _loadChapter() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get chapter images from source
      final result = await widget.source.getPages(
        widget.comicId,
        widget.chapterId,
      );
      
      if (result.isSuccess && result.data != null) {
        setState(() {
          _images = result.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result.error ?? 'Failed to load chapter';
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Chapter ${widget.chapterId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadChapter();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_images.isEmpty) {
      return const Center(
        child: Text(
          'No images found',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return NekoReader(
      images: _images,
      initialIndex: _currentIndex,
      layout: ReaderLayout.rightToLeft,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Layout',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: ReaderLayout.values.map((layout) {
                return ChoiceChip(
                  label: Text(layout.name),
                  selected: false,
                  onSelected: (selected) {
                    Navigator.pop(context);
                    // TODO: Update reader layout
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
