import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../storage/database.dart';
import '../comic/models.dart';

/// Represents a local comic file (CBZ, EPUB, PDF)
class NekoLocalComic {
  final String path;
  final String title;
  final String? coverPath;
  final List<NekoChapter> chapters;
  final DateTime addedAt;
  final int? totalPages;

  NekoLocalComic({
    required this.path,
    required this.title,
    this.coverPath,
    required this.chapters,
    required this.addedAt,
    this.totalPages,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'title': title,
        'coverPath': coverPath,
        'chapters': chapters.map((c) => c.toJson()).toList(),
        'addedAt': addedAt.toIso8601String(),
        'totalPages': totalPages,
      };

  factory NekoLocalComic.fromJson(Map<String, dynamic> json) => NekoLocalComic(
        path: json['path'],
        title: json['title'],
        coverPath: json['coverPath'],
        chapters: (json['chapters'] as List)
            .map((c) => NekoChapter.fromJson(c))
            .toList(),
        addedAt: DateTime.parse(json['addedAt']),
        totalPages: json['totalPages'],
      );
}

/// Manager for local comics
class NekoLocalComicManager {
  static NekoLocalComicManager? _instance;
  static NekoLocalComicManager get instance =>
      _instance ??= NekoLocalComicManager._();

  NekoLocalComicManager._();

  Future<String> get _localComicsDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final comicsDir = Directory('${appDir.path}/local_comics');
    if (!await comicsDir.exists()) {
      await comicsDir.create(recursive: true);
    }
    return comicsDir.path;
  }

  Future<List<NekoLocalComic>> getAll() async {
    try {
      final db = await NekoDatabase.instance;
      final rows = await db.query('local_comics', orderBy: 'added_at DESC');
      return rows.map((row) => _rowToComic(row)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<NekoLocalComic?> getByPath(String path) async {
    try {
      final db = await NekoDatabase.instance;
      final rows = await db.query(
        'local_comics',
        where: 'path = ?',
        whereArgs: [path],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return _rowToComic(rows.first);
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  Future<bool> importComic(String sourcePath) async {
    try {
      final file = File(sourcePath);
      if (!await file.exists()) return false;

      final ext = sourcePath.split('.').last.toLowerCase();
      if (!['cbz', 'zip', 'epub', 'pdf'].contains(ext)) {
        return false;
      }

      // Parse comic based on format
      final comic = await _parseComic(sourcePath, ext);
      if (comic == null) return false;

      // Save to database
      final db = await NekoDatabase.instance;
      await db.insert('local_comics', {
        'path': comic.path,
        'title': comic.title,
        'coverPath': comic.coverPath,
        'chapters': jsonEncode(comic.chapters.map((c) => c.toJson()).toList()),
        'addedAt': comic.addedAt.toIso8601String(),
        'totalPages': comic.totalPages,
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteComic(String path) async {
    final db = await NekoDatabase.instance;
    await db.delete('local_comics', where: 'path = ?', whereArgs: [path]);
  }

  Future<List<String>> getPages(String path, {int chapterIndex = 0}) async {
    try {
      final ext = path.split('.').last.toLowerCase();
      switch (ext) {
        case 'cbz':
        case 'zip':
          return _extractCbzPages(path);
        case 'epub':
          return _extractEpubPages(path);
        case 'pdf':
          return _extractPdfPages(path);
        default:
          return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<NekoLocalComic?> _parseComic(String path, String ext) async {
    switch (ext) {
      case 'cbz':
      case 'zip':
        return _parseCbz(path);
      case 'epub':
        return _parseEpub(path);
      case 'pdf':
        return _parsePdf(path);
      default:
        return null;
    }
  }

  Future<NekoLocalComic?> _parseCbz(String path) async {
    try {
      // Simple title extraction from filename
      final fileName = path.split('/').last;
      final title = fileName.replaceAll(RegExp(r'\.(cbz|zip)$'), '');

      // Create cover from first image
      String? coverPath;
      // In a real implementation, we would extract the first image

      return NekoLocalComic(
        path: path,
        title: title,
        coverPath: coverPath,
        chapters: [
          NekoChapter(
            id: 'local_${path.hashCode}',
            title: 'Chapter 1',
            index: 0,
            comicId: path,
            timestamp: DateTime.now(),
          ),
        ],
        addedAt: DateTime.now(),
        totalPages: 0,
      );
    } catch (e) {
      return null;
    }
  }

  Future<NekoLocalComic?> _parseEpub(String path) async {
    try {
      final fileName = path.split('/').last;
      final title = fileName.replaceAll(RegExp(r'\.epub$'), '');

      return NekoLocalComic(
        path: path,
        title: title,
        chapters: [
          NekoChapter(
            id: 'local_${path.hashCode}_1',
            title: 'Chapter 1',
            index: 0,
            comicId: path,
            timestamp: DateTime.now(),
          ),
        ],
        addedAt: DateTime.now(),
        totalPages: 0,
      );
    } catch (e) {
      return null;
    }
  }

  Future<NekoLocalComic?> _parsePdf(String path) async {
    try {
      final fileName = path.split('/').last;
      final title = fileName.replaceAll(RegExp(r'\.pdf$'), '');

      return NekoLocalComic(
        path: path,
        title: title,
        chapters: [
          NekoChapter(
            id: 'local_${path.hashCode}_1',
            title: 'Chapter 1',
            index: 0,
            comicId: path,
            timestamp: DateTime.now(),
          ),
        ],
        addedAt: DateTime.now(),
        totalPages: 0,
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> _extractCbzPages(String path) async {
    // In a real implementation, we would extract images from the CBZ/ZIP file
    return [];
  }

  Future<List<String>> _extractEpubPages(String path) async {
    // In a real implementation, we would extract images from the EPUB file
    return [];
  }

  Future<List<String>> _extractPdfPages(String path) async {
    // In a real implementation, we would render PDF pages
    return [];
  }

  NekoLocalComic _rowToComic(Map<String, dynamic> row) {
    List<NekoChapter> chapters = [];
    if (row['chapters'] != null) {
      final chaptersJson = jsonDecode(row['chapters'] as String) as List;
      chapters = chaptersJson.map((c) => NekoChapter.fromJson(c)).toList();
    }

    return NekoLocalComic(
      path: row['path'] as String,
      title: row['title'] as String,
      coverPath: row['coverPath'] as String?,
      chapters: chapters,
      addedAt: DateTime.parse(row['addedAt'] as String),
      totalPages: row['totalPages'] as int?,
    );
  }
}
