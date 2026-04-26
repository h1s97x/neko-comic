part of 'neko_image.dart';

/// Cache manager for images using SQLite storage.
/// 
/// Features:
/// - SQLite-based cache index
/// - Automatic cache cleanup when size exceeds limit
/// - Cache expiration management
/// - Thread-safe operations
class NekoCacheManager {
  /// Get the cache directory path
  static String get cachePath => '${NekoAppConfig.cachePath}/cache';

  /// Singleton instance
  static NekoCacheManager? _instance;
  
  static NekoCacheManager get instance => _instance ??= NekoCacheManager._();

  late Database _db;
  
  int? _currentSize;
  
  /// Current cache size in bytes
  int get currentSize => _currentSize ?? 0;

  int _dir = 0;
  
  /// Cache size limit in bytes (default: 2GB)
  int _limitSize = 2 * 1024 * 1024 * 1024;

  NekoCacheManager._() {
    _init();
  }

  void _init() {
    Directory(cachePath).createSync(recursive: true);
    _db = sqlite3.open('${NekoAppConfig.dataPath}/cache.db');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS cache (
        key TEXT PRIMARY KEY NOT NULL,
        dir TEXT NOT NULL,
        name TEXT NOT NULL,
        expires INTEGER NOT NULL,
        type TEXT
      )
    ''');
    _scanAndCleanup();
  }

  /// Set cache size limit in MB
  void setLimitSizeMB(int sizeMB) {
    _limitSize = sizeMB * 1024 * 1024;
  }

  /// Write data to cache with key
  Future<void> write(String key, List<int> data, {int durationMs = 7 * 24 * 60 * 60 * 1000}) async {
    await delete(key);
    _dir++;
    _dir %= 100;
    var name = md5.convert(key.codeUnits).toString();
    var file = File('$cachePath/$_dir/$name');
    await file.create(recursive: true);
    await file.writeAsBytes(data);
    var expires = DateTime.now().millisecondsSinceEpoch + durationMs;
    _db.execute(
      'INSERT OR REPLACE INTO cache (key, dir, name, expires) VALUES (?, ?, ?, ?)',
      [_keyToDir(key), name, expires.toString()],
    );
    if (_currentSize != null) {
      _currentSize = _currentSize! + data.length;
    }
    _checkSizeIfRequired();
  }

  /// Find cache by key. Returns null if not found or expired.
  Future<File?> find(String key) async {
    var res = _db.select(
      'SELECT * FROM cache WHERE key = ?',
      [_keyToDir(key)],
    );
    if (res.isEmpty) return null;
    
    var row = res.first;
    var dir = row[1] as String;
    var name = row[2] as String;
    var expires = int.parse(row[3] as String);
    var file = File('$cachePath/$dir/$name');
    var now = DateTime.now().millisecondsSinceEpoch;
    
    if (expires < now) {
      _db.execute('DELETE FROM cache WHERE key = ?', [_keyToDir(key)]);
      if (await file.exists()) await file.delete();
      return null;
    }
    
    if (await file.exists()) {
      // Update expires time
      var newExpires = now + 7 * 24 * 60 * 60 * 1000;
      _db.execute('UPDATE cache SET expires = ? WHERE key = ?', [newExpires.toString(), _keyToDir(key)]);
      return file;
    }
    
    _db.execute('DELETE FROM cache WHERE key = ?', [_keyToDir(key)]);
    return null;
  }

  /// Delete cache by key
  Future<void> delete(String key) async {
    var res = _db.select(
      'SELECT * FROM cache WHERE key = ?',
      [_keyToDir(key)],
    );
    if (res.isEmpty) return;
    
    var row = res.first;
    var dir = row[1] as String;
    var name = row[2] as String;
    var file = File('$cachePath/$dir/$name');
    if (await file.exists()) {
      var size = await file.length();
      _currentSize = (_currentSize ?? 0) - size;
      await file.delete();
    }
    _db.execute('DELETE FROM cache WHERE key = ?', [_keyToDir(key)]);
  }

  /// Clear all cache
  Future<void> clear() async {
    await for (var entity in Directory(cachePath).list()) {
      if (entity is File) await entity.delete();
    }
    _db.execute('DELETE FROM cache');
    _currentSize = 0;
  }

  /// Get cache statistics
  Map<String, dynamic> get stats => {
    'currentSize': currentSize,
    'limitSize': _limitSize,
    'usagePercent': _limitSize > 0 ? (currentSize / _limitSize * 100).toStringAsFixed(1) : '0',
  };

  String _keyToDir(String key) => md5.convert(key.codeUnits).toString().substring(0, 2);

  bool _isChecking = false;

  void _checkSizeIfRequired() {
    if (_currentSize != null && _currentSize! > _limitSize) {
      _checkAndCleanup();
    }
  }

  Future<void> _checkAndCleanup() async {
    if (_isChecking) return;
    _isChecking = true;
    
    try {
      var now = DateTime.now().millisecondsSinceEpoch;
      var res = _db.select(
        'SELECT * FROM cache WHERE expires < ?',
        [now.toString()],
      );
      
      for (var row in res) {
        var dir = row[1] as String;
        var name = row[2] as String;
        var file = File('$cachePath/$dir/$name');
        if (await file.exists()) {
          var size = await file.length();
          _currentSize = (_currentSize ?? 0) - size;
          await file.delete();
        }
      }
      
      _db.execute('DELETE FROM cache WHERE expires < ?', [now.toString()]);
      
      // If still over limit, delete oldest
      while (_currentSize != null && _currentSize! > _limitSize) {
        var oldest = _db.select('SELECT * FROM cache ORDER BY expires ASC LIMIT 1');
        if (oldest.isEmpty) break;
        
        var row = oldest.first;
        var dir = row[1] as String;
        var name = row[2] as String;
        var file = File('$cachePath/$dir/$name');
        if (await file.exists()) {
          var size = await file.length();
          _currentSize = _currentSize! - size;
          await file.delete();
        }
        _db.execute(
          'DELETE FROM cache WHERE dir = ? AND name = ?',
          [dir, name],
        );
      }
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _scanAndCleanup() async {
    int totalSize = 0;
    List<String> unmanagedFiles = [];
    
    if (!await Directory(cachePath).exists()) {
      _currentSize = 0;
      return;
    }
    
    await for (var file in Directory(cachePath).list(recursive: true)) {
      if (file is File) {
        var size = await file.length();
        totalSize += size;
      }
    }
    
    _currentSize = totalSize;
    _checkSizeIfRequired();
  }
}
