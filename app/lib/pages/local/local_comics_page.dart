import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';
import 'package:neko_core/neko_core.dart';
import 'package:neko_ui/neko_ui.dart';

/// Local comics page for managing CBZ/EPUB/PDF files
class LocalComicsPage extends StatefulWidget {
  const LocalComicsPage({super.key});

  @override
  State<LocalComicsPage> createState() => _LocalComicsPageState();
}

class _LocalComicsPageState extends State<LocalComicsPage> {
  List<NekoLocalComic> _comics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComics();
  }

  Future<void> _loadComics() async {
    setState(() => _isLoading = true);
    try {
      final comics = await NekoLocalComicManager().getAll();
      setState(() {
        _comics = comics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importComic() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Comics',
        extensions: ['cbz', 'zip', 'epub', 'pdf'],
      );
      
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      
      if (file != null) {
        final success = await NekoLocalComicManager().importComic(file.path);
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Comic imported successfully')),
            );
            _loadComics();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to import comic')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteComic(NekoLocalComic comic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comic'),
        content: Text('Are you sure you want to delete "${comic.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NekoLocalComicManager().deleteComic(comic.path);
      _loadComics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Comics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _importComic,
            tooltip: 'Import Comic',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _comics.isEmpty
              ? _buildEmptyState()
              : _buildComicList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _importComic,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No local comics',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Import CBZ, EPUB, or PDF files to read offline',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _importComic,
            icon: const Icon(Icons.folder_open),
            label: const Text('Import Comic'),
          ),
        ],
      ),
    );
  }

  Widget _buildComicList() {
    return RefreshIndicator(
      onRefresh: _loadComics,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _comics.length,
        itemBuilder: (context, index) {
          final comic = _comics[index];
          return _LocalComicCard(
            comic: comic,
            onDelete: () => _deleteComic(comic),
          );
        },
      ),
    );
  }
}

class _LocalComicCard extends StatelessWidget {
  final NekoLocalComic comic;
  final VoidCallback onDelete;

  const _LocalComicCard({
    required this.comic,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to reader
        Navigator.of(context).pushNamed(
          '/reader',
          arguments: {
            'comic': comic,
            'chapter': comic.chapters.first,
          },
        );
      },
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.of(context).pop();
                    onDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: comic.coverPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(comic.coverPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(context),
                      ),
                    )
                  : _buildPlaceholder(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            comic.title,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        _getFileIcon(comic.path),
        size: 40,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  IconData _getFileIcon(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'cbz':
      case 'zip':
        return Icons.menu_book;
      case 'epub':
        return Icons.book;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.insert_drive_file;
    }
  }
}
