/// NekoSourceJS - JavaScript-based comic source system
/// 
/// This package provides a JavaScript runtime for executing comic source plugins.
/// Comic sources are written in JavaScript and define how to fetch comics from various websites.
/// 
/// ## Features
/// - JavaScript runtime (QuickJS via flutter_qjs)
/// - JS API for network requests, HTML parsing, and encryption
/// - Comic source plugin system
/// - Category, search, and explore page support
/// 
/// ## Usage
/// 
/// ```dart
/// import 'package:neko_source_js/neko_source_js.dart';
/// 
/// // Initialize the JS engine
/// await NekoJsEngine().ensureInit();
/// 
/// // Load a comic source
/// final source = await NekoComicSourceParser().parse(sourceCode, filePath);
/// 
/// // Search for comics
/// final result = await source.search('keyword');
/// 
/// // Get comic details
/// final details = await source.getComic(comicId);
/// ```

library;

export 'js_engine.dart';
export 'js_pool.dart';
export 'comic_source/comic_source.dart';
export 'api/network.dart';
export 'api/html.dart';
export 'api/convert.dart';
