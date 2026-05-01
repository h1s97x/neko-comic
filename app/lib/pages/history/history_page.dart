import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:neko_core/neko_core.dart';
import 'package:neko_ui/neko_ui.dart';

/// History page showing reading history
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<NekoHistoryItem> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await NekoDatabase.init();
      final historyManager = NekoHistoryManager();
      final history = await historyManager.getAll();
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'Are you sure you want to clear all reading history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await NekoDatabase.init();
        final historyManager = NekoHistoryManager();
        await historyManager.clear();
        setState(() {
          _history = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('History cleared')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear history: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteItem(NekoHistoryItem item) async {
    try {
      await NekoDatabase.init();
      final historyManager = NekoHistoryManager();
      await historyManager.delete(item.comicId);
      setState(() {
        _history.removeWhere((h) => h.comicId == item.comicId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return NekoErrorWidget(
        message: _error!,
        onRetry: _loadHistory,
      );
    }

    if (_history.isEmpty) {
      return const NekoEmptyWidget(
        message: 'No reading history',
        icon: Icons.history,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          return _HistoryTile(
            item: item,
            onTap: () {
              context.push(
                '/comic/${item.sourceKey}/${item.comicId}',
              );
            },
            onDelete: () => _deleteItem(item),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final NekoHistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.comicId),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: item.thumbnail != null
                ? Image.network(
                    item.thumbnail!,
                    width: 50,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 50,
                      height: 70,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 70,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image),
                  ),
          ),
          title: Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.chapterTitle != null)
                Text(
                  'Chapter ${item.chapterIndex}: ${item.chapterTitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (item.lastRead != null)
                Text(
                  _formatDate(item.lastRead!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          trailing: Text(
            '${item.pageIndex + 1}/${item.totalPages}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes} min ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
