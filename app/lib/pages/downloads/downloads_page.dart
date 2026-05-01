import 'dart:async';
import 'package:flutter/material.dart';
import 'package:neko_core/neko_core.dart';

/// Downloads management page
class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  List<NekoDownload> _downloads = [];
  bool _isLoading = true;
  StreamSubscription<NekoDownload>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
    _subscription = NekoDownloadManager.instance.progressStream.listen((download) {
      _updateDownload(download);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _loadDownloads() async {
    setState(() => _isLoading = true);
    try {
      final downloads = await NekoDownloadManager.instance.getAll();
      setState(() {
        _downloads = downloads;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _updateDownload(NekoDownload download) {
    setState(() {
      final index = _downloads.indexWhere((d) => d.id == download.id);
      if (index >= 0) {
        _downloads[index] = download;
      } else {
        _downloads.insert(0, download);
      }
    });
  }

  Future<void> _pauseDownload(NekoDownload download) async {
    await NekoDownloadManager.instance.pauseDownload(download.id);
  }

  Future<void> _resumeDownload(NekoDownload download) async {
    await NekoDownloadManager.instance.resumeDownload(download.id);
  }

  Future<void> _removeDownload(NekoDownload download) async {
    await NekoDownloadManager.instance.removeDownload(download.id);
    setState(() {
      _downloads.removeWhere((d) => d.id == download.id);
    });
  }

  Future<void> _retryDownload(NekoDownload download) async {
    await NekoDownloadManager.instance.resumeDownload(download.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDownloads,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _downloads.isEmpty
              ? _buildEmptyState()
              : _buildDownloadList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No downloads',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Download chapters to read offline',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadList() {
    // Group by status
    final active = _downloads.where((d) =>
        d.status == NekoDownloadStatus.downloading ||
        d.status == NekoDownloadStatus.pending).toList();
    final completed = _downloads.where((d) =>
        d.status == NekoDownloadStatus.completed).toList();
    final failed = _downloads.where((d) =>
        d.status == NekoDownloadStatus.failed ||
        d.status == NekoDownloadStatus.paused).toList();

    return RefreshIndicator(
      onRefresh: _loadDownloads,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (active.isNotEmpty) ...[
            _buildSectionHeader('Active'),
            ...active.map((d) => _DownloadItem(
                  download: d,
                  onPause: () => _pauseDownload(d),
                  onResume: () => _resumeDownload(d),
                  onRemove: () => _removeDownload(d),
                )),
            const SizedBox(height: 24),
          ],
          if (completed.isNotEmpty) ...[
            _buildSectionHeader('Completed'),
            ...completed.map((d) => _DownloadItem(
                  download: d,
                  onPause: () => _pauseDownload(d),
                  onResume: () => _resumeDownload(d),
                  onRemove: () => _removeDownload(d),
                )),
            const SizedBox(height: 24),
          ],
          if (failed.isNotEmpty) ...[
            _buildSectionHeader('Failed'),
            ...failed.map((d) => _DownloadItem(
                  download: d,
                  onPause: () => _pauseDownload(d),
                  onResume: () => _retryDownload(d),
                  onRemove: () => _removeDownload(d),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _DownloadItem extends StatelessWidget {
  final NekoDownload download;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onRemove;

  const _DownloadItem({
    required this.download,
    required this.onPause,
    required this.onResume,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        download.comicId,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chapter: ${download.chapterId}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _buildStatusIcon(context),
              ],
            ),
            if (download.status == NekoDownloadStatus.downloading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: download.progress,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(
                '${(download.progress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (download.status == NekoDownloadStatus.downloading)
                  IconButton(
                    icon: const Icon(Icons.pause),
                    onPressed: onPause,
                    tooltip: 'Pause',
                  )
                else if (download.status == NekoDownloadStatus.pending)
                  IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: onRemove,
                    tooltip: 'Cancel',
                  )
                else if (download.status == NekoDownloadStatus.paused ||
                    download.status == NekoDownloadStatus.failed)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onResume,
                    tooltip: 'Retry',
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                  tooltip: 'Remove',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(BuildContext context) {
    switch (download.status) {
      case NekoDownloadStatus.pending:
        return Icon(
          Icons.hourglass_empty,
          color: Theme.of(context).colorScheme.outline,
        );
      case NekoDownloadStatus.downloading:
        return Icon(
          Icons.downloading,
          color: Theme.of(context).colorScheme.primary,
        );
      case NekoDownloadStatus.paused:
        return Icon(
          Icons.pause_circle,
          color: Theme.of(context).colorScheme.secondary,
        );
      case NekoDownloadStatus.completed:
        return Icon(
          Icons.check_circle,
          color: Colors.green,
        );
      case NekoDownloadStatus.failed:
        return Icon(
          Icons.error,
          color: Colors.red,
        );
    }
  }
}
