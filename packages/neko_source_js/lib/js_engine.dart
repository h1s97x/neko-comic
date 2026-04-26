import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:enough_convert/enough_convert.dart';
import 'package:flutter/foundation.dart' show protected;
import 'package:flutter/services.dart';
import 'package:flutter_qjs/flutter_qjs.dart';
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;
import 'package:pointycastle/api.dart';
import 'package:pointycastle/asn1/asn1_parser.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/asymmetric/pkcs1.dart';
import 'package:pointycastle/asymmetric/rsa.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/block/modes/cfb.dart';
import 'package:pointycastle/block/modes/ecb.dart';
import 'package:pointycastle/block/modes/ofb.dart';
import 'package:uuid/uuid.dart';

import 'comic_source/comic_source.dart';
import 'api/network.dart';
import 'api/html.dart';
import 'api/convert.dart';

/// Exception thrown when JavaScript runtime encounters an error.
class NekoJsRuntimeException implements Exception {
  final String message;

  NekoJsRuntimeException(this.message);

  @override
  String toString() => "NekoJsException: $message";
}

/// JavaScript engine for executing comic source scripts.
///
/// This class wraps QuickJS via flutter_qjs and provides
/// a secure sandbox for running untrusted JavaScript code.
class NekoJsEngine with NekoJsEngineApi, NekoHtmlApi, NekoConvertApi {
  factory NekoJsEngine() => _cache ?? (_cache = NekoJsEngine._create());

  static NekoJsEngine? _cache;

  NekoJsEngine._create();

  FlutterQjs? _engine;

  bool _closed = true;

  Dio? _dio;

  static void reset() {
    _cache?.dispose();
    _cache = null;
    NekoJsEngine().ensureInit();
  }

  void resetDio() {
    _dio = Dio(BaseOptions(
      responseType: ResponseType.plain,
      validateStatus: (status) => true,
    ));
  }

  static Uint8List? _jsInitCache;

  static void cacheJsInit(Uint8List jsInit) {
    _jsInitCache = jsInit;
  }

  @override
  @protected
  Future<void> doInit() async {
    if (!_closed) return;
    
    try {
      _dio ??= Dio(BaseOptions(
        responseType: ResponseType.plain,
        validateStatus: (status) => true,
      ));
      
      _closed = false;
      _engine = FlutterQjs();
      _engine!.dispatch();
      
      // Set up global functions
      var setGlobalFunc = _engine!.evaluate("(key, value) => { this[key] = value; }");
      (setGlobalFunc as JSInvokable)(["sendMessage", _messageReceiver]);
      setGlobalFunc(["appVersion", _appVersion]);
      setGlobalFunc.free();
      
      // Load initialization script
      Uint8List jsInit;
      if (_jsInitCache != null) {
        jsInit = _jsInitCache!;
      } else {
        var buffer = await rootBundle.load("assets/init.js");
        jsInit = buffer.buffer.asUint8List();
      }
      _engine!.evaluate(utf8.decode(jsInit), name: "<init>");
    } catch (e, s) {
      if (kDebugMode) {
        print('NekoJsEngine Init Error: $e\n$s');
      }
    }
  }

  /// App version, should be set by the host app
  static String _appVersion = '1.0.0';
  
  static void setAppVersion(String version) {
    _appVersion = version;
  }

  Object? _messageReceiver(dynamic message) {
    try {
      if (message is Map<dynamic, dynamic>) {
        if (message["method"] == null) return null;
        String method = message["method"] as String;
        switch (method) {
          case "log":
            _handleLog(message);
          case 'load_data':
            return _handleLoadData(message);
          case 'save_data':
            return _handleSaveData(message);
          case 'delete_data':
            return _handleDeleteData(message);
          case 'http':
            return _http(Map.from(message));
          case 'html':
            return handleHtmlCallback(Map.from(message));
          case 'convert':
            return _convert(Map.from(message));
          case "random":
            return _random(
              message["min"] ?? 0,
              message["max"] ?? 1,
              message["type"],
            );
          case "cookie":
            return handleCookieCallback(Map.from(message));
          case "uuid":
            return const Uuid().v1();
          case "load_setting":
            return _handleLoadSetting(message);
          case "isLogged":
            return NekoComicSource.find(message["key"])!.isLogged;
          case "delay":
            return Future.delayed(Duration(milliseconds: message["time"]));
          case "getLocale":
            return "en_US"; // Should be provided by host app
          case "getPlatform":
            return Platform.operatingSystem;
          case "setClipboard":
            return Clipboard.setData(ClipboardData(text: message["text"]));
          case "getClipboard":
            return Future.sync(() async {
              var res = await Clipboard.getData(Clipboard.kTextPlain);
              return res?.text;
            });
          case "compute":
            return _handleCompute(message);
        }
      }
      return null;
    } catch (e, s) {
      if (kDebugMode) {
        print("Failed to handle message: $message\n$e\n$s");
      }
      rethrow;
    }
  }

  void _handleLog(Map<String, dynamic> message) {
    String level = message["level"] ?? "info";
    String title = message["title"] ?? "";
    String content = message["content"]?.toString() ?? "";
    
    if (kDebugMode) {
      switch (level) {
        case "error":
          print('[ERROR] $title: $content');
        case "warning":
          print('[WARN] $title: $content');
        default:
          print('[INFO] $title: $content');
      }
    }
  }

  dynamic _handleLoadData(Map<String, dynamic> message) {
    String key = message["key"];
    String dataKey = message["data_key"];
    return NekoComicSource.find(key)?.data[dataKey];
  }

  void _handleSaveData(Map<String, dynamic> message) {
    String key = message["key"];
    String dataKey = message["data_key"];
    if (dataKey == 'setting') {
      throw NekoJsRuntimeException("setting is not allowed to be saved");
    }
    var data = message["data"];
    var source = NekoComicSource.find(key)!;
    source.data[dataKey] = data;
    source.saveData();
  }

  void _handleDeleteData(Map<String, dynamic> message) {
    String key = message["key"];
    String dataKey = message["data_key"];
    var source = NekoComicSource.find(key);
    source?.data.remove(dataKey);
    source?.saveData();
  }

  dynamic _handleLoadSetting(Map<String, dynamic> message) {
    String key = message["key"];
    String settingKey = message["setting_key"];
    var source = NekoComicSource.find(key)!;
    return source.data["settings"]?[settingKey] ??
           source.settings?[settingKey]?['default'];
  }

  Future<dynamic> _handleCompute(Map<String, dynamic> message) async {
    final func = message["function"];
    final args = message["args"];
    if (func is JSInvokable) {
      func.free();
      throw NekoJsRuntimeException("Function must be a string");
    }
    if (func is! String) {
      throw NekoJsRuntimeException("Function must be a string");
    }
    if (args != null && args is! List) {
      throw NekoJsRuntimeException("Args must be a list");
    }
    return NekoJsPool().execute(func, args ?? []);
  }

  Future<NekoHttpResponse> _http(Map<String, dynamic> req) async {
    Response? response;
    String? error;

    try {
      var headers = Map<String, dynamic>.from(req["headers"] ?? {});
      var extra = Map<String, dynamic>.from(req["extra"] ?? {});
      
      if (headers["user-agent"] == null && headers["User-Agent"] == null) {
        headers["User-Agent"] = webUA;
      }
      
      var dio = _dio;
      if (headers['http_client'] == "dart:io") {
        dio = Dio(BaseOptions(
          responseType: ResponseType.plain,
          validateStatus: (status) => true,
        ));
        // Proxy support can be added here
      }
      
      response = await dio!.request(
        req["url"],
        data: req["data"],
        options: Options(
          method: req['http_method'] ?? 'GET',
          responseType: req["bytes"] == true
              ? ResponseType.bytes
              : ResponseType.plain,
          headers: headers,
          extra: extra,
        ),
      );
    } catch (e) {
      error = e.toString();
    }

    Map<String, String> responseHeaders = {};
    response?.headers.forEach((name, values) => responseHeaders[name] = values.join(','));

    dynamic body = response?.data;
    if (body is! Uint8List && body is List<int>) {
      body = Uint8List.fromList(body);
    }

    return NekoHttpResponse(
      status: response?.statusCode,
      headers: responseHeaders,
      body: body,
      error: error,
    );
  }

  /// Execute JavaScript code and return the result.
  Object? runCode(String js, [String? name]) {
    return _engine!.evaluate(js, name: name);
  }

  /// Dispose the engine and release resources.
  void dispose() {
    _cache = null;
    _closed = true;
    _engine?.close();
    _engine?.port.close();
  }
}

/// Mixin providing JS engine API implementations.
mixin class NekoJsEngineApi {
  CookieJar? _cookieJar;

  /// Handle cookie-related callbacks from JavaScript.
  dynamic handleCookieCallback(Map<String, dynamic> data) {
    switch (data["function"]) {
      case "set":
        // Cookie setting implementation
        return null;
      case "get":
        // Cookie getting implementation
        return <Map<String, dynamic>>[];
      case "delete":
        // Cookie deletion implementation
        return null;
    }
    return null;
  }

  void clearCookies(List<String> domains) async {
    // Cookie clearing implementation
  }
}

/// Generate random values from JavaScript.
dynamic _random(dynamic min, dynamic max, String? type) {
  if (type == "int") {
    return min.toInt() + (max.toInt() - min.toInt()) * (DateTime.now().millisecondsSinceEpoch % 1000) ~/ 1000;
  }
  return min + (max - min) * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000;
}
