part of 'comic_source.dart';

/// Compare two semantic versions.
/// Returns true if ver1 > ver2.
bool compareSemVer(String ver1, String ver2) {
  ver1 = ver1.replaceFirst("-", ".");
  ver2 = ver2.replaceFirst("-", ".");
  List<String> v1 = ver1.split('.');
  List<String> v2 = ver2.split('.');

  for (int i = 0; i < 3; i++) {
    int num1 = int.parse(v1[i]);
    int num2 = int.parse(v2[i]);

    if (num1 > num2) {
      return true;
    } else if (num1 < num2) {
      return false;
    }
  }

  var v14 = v1.length > 3 ? v1[3] : null;
  var v24 = v2.length > 3 ? v2[3] : null;

  if (v14 != v24) {
    if (v14 == null && v24 != "hotfix") {
      return true;
    } else if (v14 == null) {
      return false;
    }
    if (v24 == null) {
      if (v14 == "hotfix") {
        return true;
      }
      return false;
    }
    return v14.compareTo(v24) > 0;
  }

  return false;
}

/// Exception thrown when comic source parsing fails.
class NekoComicSourceParseException implements Exception {
  final String message;

  NekoComicSourceParseException(this.message);

  @override
  String toString() => message;
}

/// Parser for JavaScript comic sources.
class NekoComicSourceParser {
  String? _key;
  String? _name;

  /// Create and parse a comic source from JavaScript code.
  Future<NekoComicSource> createAndParse(String js, String fileName) async {
    if (!fileName.endsWith("js")) {
      fileName = "$fileName.js";
    }
    // File writing is handled by the host app
    try {
      return await parse(js, fileName);
    } catch (e) {
      rethrow;
    }
  }

  /// Parse a comic source from JavaScript code.
  Future<NekoComicSource> parse(String js, String filePath) async {
    js = js.replaceAll("\r\n", "\n");
    
    // Check for valid ComicSource class
    var line1 = js.split('\n').firstWhereOrNull(
      (e) => e.trim().startsWith("class ") && e.contains("extends ComicSource"),
    );
    if (line1 == null) {
      throw NekoComicSourceParseException("Invalid Content: No ComicSource class found");
    }
    
    var className = line1.split("class")[1].split("extends ComicSource").first.trim();
    _name = _getJsValue(js, className, "name");
    _key = _getJsValue(js, className, "key");
    var version = _getJsValue(js, className, "version") ?? "1.0.0";
    
    if (_name == null) {
      throw NekoComicSourceParseException('name is required');
    }
    if (_key == null) {
      throw NekoComicSourceParseException('key is required');
    }
    
    // Check key validation (only alphanumeric and underscore)
    if (!_key!.contains(RegExp(r"^[a-zA-Z0-9_]+$"))) {
      throw NekoComicSourceParseException("key $_key is invalid");
    }
    
    // Check for duplicate key
    for (var source in NekoComicSource.all()) {
      if (source.key == _key) {
        throw NekoComicSourceParseException("key($_key) already exists");
      }
    }
    
    // Parse source properties
    final source = NekoComicSource(
      _name!,
      _key!,
      filePath: filePath,
      url: _getJsValue(js, className, "url") ?? "",
      version: version,
      // Additional properties will be parsed from JS
    );
    
    NekoComicSourceManager().add(source);
    await source.loadData();
    
    return source;
  }

  String? _getJsValue(String js, String className, String property) {
    // Simple regex-based extraction for basic properties
    // Full implementation would use the JS engine
    var pattern = RegExp('$property\\s*[:=]\\s*[\'"]([^\'"]*)[\'"]');
    var match = pattern.firstMatch(js);
    return match?.group(1);
  }
}

extension on List<String> {
  String? elementAtOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
