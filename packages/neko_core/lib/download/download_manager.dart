import 'dart:async';
import 'package:neko_core/neko_core.dart';
import 'package:neko_source_js/neko_source_js.dart';

/// Download status enum
enum NekoDownloadStatus {
  pending(0),
  downloading(1),
  paused(2),
  completed(3),
  failed(4);

  final int value;
  const NekoDownloadStatus(this.value);

  static NekoDownloadStatus fromValue(int value) {
    return NekoDownloadStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => NekoDownloadStatus.pending,
    );
  }
}

/// Download item model
class NekoDownload {
  final String id;
  final String comicId;
  final String chapterId;
  final String sourceKey;
  final NekoDownloadStatus status;
  final double progress;
  final String? path;
  final DateTime time;

  NekoDownload({
    required this.id,
    required this.comicId,
    required this.chapterId,
    required this.sourceKey,
    required this.status,
    required this.progress,
    this.path,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'comicId': comicId,
        'chapterId': chapterId,
        'sourceKey': sourceKey,
        'status': status.value,
        'progress': progress,
        'path': path,
        'time': time.millisecondsSinceEpoch,
      };

  factory NekoDownload.fromJson(Map<String, dynamic> json) => NekoDownload(
        id: json['id'],
        comicId: json['comicId'],
        chapterId: json['chapterId'],
        sourceKey: json['sourceKey'],
        status: NekoDownloadStatus.fromValue(json['status']),
        progress: (json['progress'] as num).toDouble(),
        path: json['path'],
        time: DateTime.fromMillisecondsSinceEpoch(json['time']),
      );
}

/// Download manager
class NekoDownloadManager {
  static NekoDownloadManager? _instance;
  static NekoDownloadManager get instance =>
      _instance ??= NekoDownloadManager._();

  NekoDownloadManager._();

  final _downloads = <String, NekoDownload>{};
  final _downloadTasks = <String, Completer<void>>{};
  final _progressController = StreamController<NekoDownload>.broadcast();

  Stream<NekoDownload> get progressStream => _progressController.stream;

  Future<List<NekoDownload>> getAll() async {
    try {
      final db = await NekoDatabase.instance;
      final rows = await db.query('downloads', orderBy: 'time DESC');
      return rows.map((row) => _rowToDownload(row)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addDownload({
    required String comicId,
    required String chapterId,
    required String sourceKey,
  }) async {
    final id = '${comicId}_$chapterId';
    
    if (_downloads.containsKey(id)) return;

    final download = NekoDownload(
      id: id,
      comicId: comicId,
      chapterId: chapterId,
      sourceKey: sourceKey,
      status: NekoDownloadStatus.pending,
      progress: 0,
      time: DateTime.now(),
    );

    _downloads[id] = download;
    await _saveDownload(download);
    _startDownload(download);
  }

  Future<void> pauseDownload(String id) async {
    _downloadTasks[id]?.complete();
    final download = _downloads[id];
    if (download != null) {
      final paused = NekoDownload(
        id: download.id,
        comicId: download.comicId,
        chapterId: download.chapterId,
        sourceKey: download.sourceKey,
        status: NekoDownloadStatus.paused,
        progress: download.progress,
        path: download.path,
        time: download.time,
      );
      _downloads[id] = paused;
      await _saveDownload(paused);
    }
  }

  Future<void> resumeDownload(String id) async {
    final download = _downloads[id];
    if (download != null && download.status == NekoDownloadStatus.paused) {
      final resumed = NekoDownload(
        id: download.id,
        comicId: download.comicId,
        chapterId: download.chapterId,
        sourceKey: download.sourceKey,
        status: NekoDownloadStatus.downloading,
        progress: download.progress,
        path: download.path,
        time: DateTime.now(),
      );
      _downloads[id] = resumed;
      await _saveDownload(resumed);
      _startDownload(resumed);
    }
  }

  Future<void> removeDownload(String id) async {
    _downloadTasks[id]?.complete();
    _downloads.remove(id);
    final db = await NekoDatabase.instance;
    await db.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }

  void _startDownload(NekoDownload download) async {
    _downloadTasks[download.id] = Completer<void>();

    try {
      // Get source
      final source = NekoComicSourceManager().get(download.sourceKey);
      if (source == null) {
        await _failDownload(download.id, 'Source not found');
        return;
      }

      // Update status to downloading
      final downloading = NekoDownload(
        id: download.id,
        comicId: download.comicId,
        chapterId: download.chapterId,
        sourceKey: download.sourceKey,
        status: NekoDownloadStatus.downloading,
        progress: 0,
        time: DateTime.now(),
      );
      _downloads[download.id] = downloading;
      _progressController.add(downloading);

      // Get chapter pages
      final pages = await source.getPages(download.chapterId);

      // Download images
      for (var i = 0; i < pages.length; i++) {
        if (_downloadTasks[download.id]?.isCompleted == true) {
          return; // Paused or cancelled
        }

        // In a real implementation, we would download the image here
        // For now, we just update progress
        final progress = (i + 1) / pages.length;
        final updated = NekoDownload(
          id: download.id,
          comicId: download.comicId,
          chapterId: download.chapterId,
          sourceKey: download.sourceKey,
          status: NekoDownloadStatus.downloading,
          progress: progress,
          time: DateTime.now(),
        );
        _downloads[download.id] = updated;
        _progressController.add(updated);
        await _saveDownload(updated);
      }

      // Completed
      final completed = NekoDownload(
        id: download.id,
        comicId: download.comicId,
        chapterId: download.chapterId,
        sourceKey: download.sourceKey,
        status: NekoDownloadStatus.completed,
        progress: 1.0,
        path: '/path/to/downloaded/chapter', // Would be actual path
        time: DateTime.now(),
      );
      _downloads[download.id] = completed;
      _progressController.add(completed);
      await _saveDownload(completed);
    } catch (e) {
      await _failDownload(download.id, e.toString());
    }
  }

  Future<void> _failDownload(String id, String error) async {
    final download = _downloads[id];
    if (download != null) {
      final failed = NekoDownload(
        id: download.id,
        comicId: download.comicId,
        chapterId: download.chapterId,
        sourceKey: download.sourceKey,
        status: NekoDownloadStatus.failed,
        progress: download.progress,
        path: null,
        time: DateTime.now(),
      );
      _downloads[id] = failed;
      _progressController.add(failed);
      await _saveDownload(failed);
    }
  }

  Future<void> _saveDownload(NekoDownload download) async {
    final db = await NekoDatabase.instance;
    await db.insert('downloads', {
      'id': download.id,
      'comicId': download.comicId,
      'chapterId': download.chapterId,
      'sourceKey': download.sourceKey,
      'status': download.status.value,
      'progress': download.progress,
      'path': download.path,
      'time': download.time.millisecondsSinceEpoch,
    });
  }

  NekoDownload _rowToDownload(Map<String, Object?> row) {
    return NekoDownload(
      id: row['id'] as String,
      comicId: row['comic_id'] as String,
      chapterId: row['chapter_id'] as String,
      sourceKey: row['source_key'] as String,
      status: NekoDownloadStatus.fromValue(row['status'] as int),
      progress: (row['progress'] as num).toDouble(),
      path: row['path'] as String?,
      time: DateTime.fromMillisecondsSinceEpoch(row['time'] as int),
    );
  }
}
