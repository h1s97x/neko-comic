/// Database initialization for NekoComic
/// Reference: Venera foundation/database

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../utils/isolate.dart';

/// Database manager for NekoComic
class NekoDatabase {
  static NekoDatabase? _instance;
  static NekoDatabase get instance => _instance ??= NekoDatabase._();

  NekoDatabase._();

  /// Initialize database (static method for easy access)
  static Future<void> init() => instance.initialize();

  late Database _db;
  bool _isInitialized = false;

  /// Database path
  String? _dbPath;

  /// Initialize database
  Future<void> initialize() async {
    if (_isInitialized) return;

    final appDir = await getApplicationDocumentsDirectory();
    _dbPath = p.join(appDir.path, 'neko_comic', 'data.db');

    _db = sqlite3.open(_dbPath!);

    await _createTables();
    _isInitialized = true;
  }

  /// Create all tables
  Future<void> _createTables() async {
    // Favorites table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        id TEXT NOT NULL,
        source_key TEXT NOT NULL,
        name TEXT NOT NULL,
        author TEXT NOT NULL,
        cover_path TEXT NOT NULL,
        tags TEXT NOT NULL,
        time TEXT NOT NULL,
        PRIMARY KEY (id, source_key)
      );
    ''');

    // History table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS history (
        id TEXT NOT NULL,
        source_key TEXT NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL,
        cover TEXT NOT NULL,
        ep INTEGER NOT NULL DEFAULT 0,
        page INTEGER NOT NULL DEFAULT 0,
        chapter_group INTEGER,
        read_episode TEXT NOT NULL DEFAULT '',
        max_page INTEGER,
        time INTEGER NOT NULL,
        PRIMARY KEY (id, source_key)
      );
    ''');

    // Settings table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT NOT NULL PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    // Comic sources table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS comic_sources (
        key TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        config TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        update_time TEXT
      );
    ''');

    // Downloads table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS downloads (
        id TEXT NOT NULL PRIMARY KEY,
        comic_id TEXT NOT NULL,
        chapter_id TEXT NOT NULL,
        source_key TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        progress REAL NOT NULL DEFAULT 0,
        path TEXT,
        time INTEGER NOT NULL
      );
    ''');
  }

  /// Get database instance
  Database get db => _db;

  /// Close database
  void close() {
    if (_isInitialized) {
      _db.dispose();
      _isInitialized = false;
      _instance = null;
    }
  }

  /// Execute a query
  ResultSet execute(String sql, [List<Object?>? parameters]) {
    return _db.execute(sql, parameters);
  }

  /// Select query
  ResultSet select(String sql, [List<Object?>? parameters]) {
    return _db.select(sql, parameters);
  }
}

/// Database result set extension
extension ResultSetExtension on ResultSet {
  /// Get first row or null
  Row? firstOrNull() {
    return isEmpty ? null : first;
  }

  /// Convert to list of maps
  List<Map<String, Object?>> toListOfMaps() {
    return map((row) {
      final map = <String, Object?>{};
      for (var i = 0; i < row.length; i++) {
        map[columns[i]] = row[i];
      }
      return map;
    }).toList();
  }
}

/// Isolate helper for database operations
class DatabaseIsolate {
  /// Run database operation in isolate
  static Future<R> run<R>(Future<R> Function(Database) operation) async {
    return await compute<_DbOperation<R>, R>(
      _dbOperation,
      _DbOperation(operation),
    );
  }
}

class _DbOperation<R> {
  final Future<R> Function(Database) operation;

  _DbOperation(this.operation);
}

Future<R> _dbOperation<R>(_DbOperation<R> op) async {
  final db = sqlite3.openInMemory();
  try {
    return await op.operation(db);
  } finally {
    db.dispose();
  }
}
