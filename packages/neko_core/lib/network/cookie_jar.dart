/// Cookie management for NekoComic
/// Reference: Venera network/cookie_jar.dart

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Cookie item
class NekoCookie {
  final String name;
  final String value;
  String? domain;
  String? path;
  DateTime? expires;
  bool secure;
  bool httpOnly;

  NekoCookie({
    required this.name,
    required this.value,
    this.domain,
    this.path,
    this.expires,
    this.secure = false,
    this.httpOnly = false,
  });

  factory NekoCookie.fromSetCookieValue(String header) {
    final cookie = Cookie.fromSetCookieValue(header);
    return NekoCookie(
      name: cookie.name,
      value: cookie.value,
      domain: cookie.domain,
      path: cookie.path,
      expires: cookie.expires,
      secure: cookie.secure,
      httpOnly: cookie.httpOnly,
    );
  }

  Cookie toDartCookie() {
    final cookie = Cookie(name, value);
    cookie.domain = domain;
    cookie.path = path;
    cookie.expires = expires;
    cookie.secure = secure;
    cookie.httpOnly = httpOnly;
    return cookie;
  }

  @override
  String toString() {
    return 'NekoCookie($name=$value, domain=$domain, path=$path)';
  }
}

/// Cookie jar for managing cookies with SQLite persistence
class NekoCookieJar {
  static NekoCookieJar? _instance;
  static NekoCookieJar get instance => _instance ??= NekoCookieJar._();

  NekoCookieJar._();

  Database? _db;
  bool _isInitialized = false;

  /// Initialize cookie jar
  Future<void> initialize() async {
    if (_isInitialized) return;

    final appDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(appDir.path, 'neko_comic', 'cookies.db');

    _db = sqlite3.open(dbPath);

    _db!.execute('''
      CREATE TABLE IF NOT EXISTS cookies (
        name TEXT NOT NULL,
        value TEXT NOT NULL,
        domain TEXT NOT NULL,
        path TEXT,
        expires INTEGER,
        secure INTEGER,
        http_only INTEGER,
        PRIMARY KEY (name, domain, path)
      );
    ''');

    _isInitialized = true;
  }

  /// Save cookies from response
  void saveFromResponse(Uri uri, List<NekoCookie> cookies) {
    if (_db == null) return;

    for (final cookie in cookies) {
      final domain = cookie.domain ?? uri.host;
      final path = cookie.path ?? '/';

      _db!.execute('''
        INSERT OR REPLACE INTO cookies 
        (name, value, domain, path, expires, secure, http_only)
        VALUES (?, ?, ?, ?, ?, ?, ?);
      ''', [
        cookie.name,
        cookie.value,
        domain,
        path,
        cookie.expires?.millisecondsSinceEpoch,
        cookie.secure ? 1 : 0,
        cookie.httpOnly ? 1 : 0,
      ]);
    }
  }

  /// Save cookies from Dart Cookie
  void saveFromDartCookies(Uri uri, List<Cookie> cookies) {
    saveFromResponse(uri, cookies.map((c) => NekoCookie(
      name: c.name,
      value: c.value,
      domain: c.domain ?? uri.host,
      path: c.path,
      expires: c.expires,
      secure: c.secure,
      httpOnly: c.httpOnly,
    )).toList());
  }

  /// Get cookies for request
  List<NekoCookie> getCookies(Uri uri) {
    if (_db == null) return [];

    final acceptedDomains = _getAcceptedDomains(uri.host);
    final cookies = <NekoCookie>[];

    for (final domain in acceptedDomains) {
      final result = _db!.select('''
        SELECT name, value, domain, path, expires, secure, http_only
        FROM cookies
        WHERE domain = ?;
      ''', [domain]);

      for (final row in result) {
        final expires = row['expires'] as int?;
        if (expires != null && DateTime.fromMillisecondsSinceEpoch(expires).isBefore(DateTime.now())) {
          // Cookie expired, delete it
          _db!.execute('''
            DELETE FROM cookies WHERE name = ? AND domain = ? AND path = ?;
          ''', [row['name'], row['domain'], row['path']]);
          continue;
        }

        if (!_checkPathMatch(uri.path, row['path'] as String?)) {
          continue;
        }

        cookies.add(NekoCookie(
          name: row['name'] as String,
          value: row['value'] as String,
          domain: row['domain'] as String,
          path: row['path'] as String?,
          expires: expires != null
              ? DateTime.fromMillisecondsSinceEpoch(expires)
              : null,
          secure: row['secure'] == 1,
          httpOnly: row['http_only'] == 1,
        ));
      }
    }

    return cookies;
  }

  /// Get cookies as header string
  String getCookieHeader(Uri uri) {
    final cookies = getCookies(uri);
    final map = <String, NekoCookie>{};

    for (final cookie in cookies) {
      if (!map.containsKey(cookie.name) ||
          (cookie.domain != null && cookie.domain!.startsWith('.'))) {
        map[cookie.name] = cookie;
      }
    }

    return map.entries.map((e) => '${e.value.name}=${e.value.value}').join('; ');
  }

  List<String> _getAcceptedDomains(String host) {
    final domains = <String>[host];
    final parts = host.split('.');
    for (var i = 0; i < parts.length - 1; i++) {
      domains.add('.${parts.sublist(i).join('.')}');
    }
    return domains;
  }

  bool _checkPathMatch(String requestPath, String? cookiePath) {
    if (cookiePath == null || cookiePath == '/') return true;
    if (cookiePath == requestPath) return true;

    if (cookiePath.endsWith('/')) {
      return requestPath.startsWith(cookiePath);
    }

    return requestPath.startsWith(cookiePath);
  }

  /// Delete specific cookie
  void delete(Uri uri, String name) {
    if (_db == null) return;

    final domains = _getAcceptedDomains(uri.host);
    for (final domain in domains) {
      _db!.execute('''
        DELETE FROM cookies WHERE name = ? AND domain = ?;
      ''', [name, domain]);
    }
  }

  /// Delete all cookies for domain
  void deleteDomain(Uri uri) {
    if (_db == null) return;

    final domains = _getAcceptedDomains(uri.host);
    for (final domain in domains) {
      _db!.execute('DELETE FROM cookies WHERE domain = ?;', [domain]);
    }
  }

  /// Clear all cookies
  void clearAll() {
    _db?.execute('DELETE FROM cookies;');
  }

  /// Close cookie jar
  void close() {
    _db?.dispose();
    _db = null;
    _isInitialized = false;
    _instance = null;
  }
}
