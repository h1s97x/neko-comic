import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_qjs/flutter_qjs.dart';

import 'js_engine.dart';

/// Pool of JavaScript engines running in isolates.
///
/// This class manages multiple isolated JavaScript engines to allow
/// parallel execution of comic source scripts.
class NekoJsPool {
  static const int _maxInstances = 4;
  final List<NekoIsolateJsEngine> _instances = [];
  bool _isInitializing = false;

  static final NekoJsPool _singleton = NekoJsPool._internal();
  
  factory NekoJsPool() => _singleton;
  
  NekoJsPool._internal();

  /// Initialize the engine pool.
  Future<void> init() async {
    if (_isInitializing) return;
    _isInitializing = true;
    
    var jsInitBuffer = await rootBundle.load("assets/init.js");
    var jsInit = jsInitBuffer.buffer.asUint8List();
    
    for (int i = 0; i < _maxInstances; i++) {
      _instances.add(NekoIsolateJsEngine(jsInit));
    }
    _isInitializing = false;
  }

  /// Execute a JavaScript function with the given arguments.
  Future<dynamic> execute(String jsFunction, List<dynamic> args) async {
    await init();
    
    var selectedInstance = _instances[0];
    for (var instance in _instances) {
      if (instance.pendingTasks < selectedInstance.pendingTasks) {
        selectedInstance = instance;
      }
    }
    return selectedInstance.execute(jsFunction, args);
  }

  /// Close all engines in the pool.
  void closeAll() {
    for (var instance in _instances) {
      instance.close();
    }
    _instances.clear();
  }
}

/// Parameters passed to the isolate for initialization.
class _NekoIsolateJsEngineInitParam {
  final SendPort sendPort;
  final Uint8List jsInit;

  _NekoIsolateJsEngineInitParam(this.sendPort, this.jsInit);
}

/// Task message sent to the isolate.
class NekoJsTask {
  final int id;
  final String jsFunction;
  final List<dynamic> args;

  NekoJsTask(this.id, this.jsFunction, this.args);
}

/// Result message sent back from the isolate.
class NekoJsTaskResult {
  final int id;
  final dynamic result;
  final String? error;

  NekoJsTaskResult(this.id, this.result, this.error);
}

/// A JavaScript engine running in an isolate.
class NekoIsolateJsEngine {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  int _counter = 0;
  final Map<int, Completer<dynamic>> _tasks = {};
  bool _isClosed = false;

  /// Number of pending tasks.
  int get pendingTasks => _tasks.length;

  NekoIsolateJsEngine(Uint8List jsInit) {
    _receivePort = ReceivePort();
    _receivePort!.listen(_onMessage);
    Isolate.spawn(_run, _NekoIsolateJsEngineInitParam(_receivePort!.sendPort, jsInit));
  }

  void _onMessage(dynamic message) {
    if (message is SendPort) {
      _sendPort = message;
    } else if (message is NekoJsTaskResult) {
      final completer = _tasks.remove(message.id);
      if (completer != null) {
        if (message.error != null) {
          completer.completeError(Exception(message.error));
        } else {
          completer.complete(message.result);
        }
      }
    } else if (message is Exception) {
      if (kDebugMode) {
        print("NekoIsolateJsEngine error: $message");
      }
      for (var completer in _tasks.values) {
        completer.completeError(message);
      }
      _tasks.clear();
      close();
    }
  }

  static void _run(_NekoIsolateJsEngineInitParam params) async {
    var sendPort = params.sendPort;
    final port = ReceivePort();
    sendPort.send(port.sendPort);
    
    final engine = NekoJsEngine();
    try {
      NekoJsEngine.cacheJsInit(params.jsInit);
      await engine.ensureInit();
    } catch (e, s) {
      sendPort.send(Exception("Failed to initialize JS engine: $e\n$s"));
      return;
    }
    
    await for (final message in port) {
      if (message is NekoJsTask) {
        try {
          final jsFunc = engine.runCode(message.jsFunction);
          if (jsFunc is! JSInvokable) {
            throw Exception("The provided code does not evaluate to a function.");
          }
          final result = jsFunc.invoke(message.args);
          jsFunc.free();
          sendPort.send(NekoJsTaskResult(message.id, result, null));
        } catch (e) {
          sendPort.send(NekoJsTaskResult(message.id, null, e.toString()));
        }
      }
    }
  }

  /// Execute a JavaScript function with the given arguments.
  Future<dynamic> execute(String jsFunction, List<dynamic> args) async {
    if (_isClosed) {
      throw Exception("NekoIsolateJsEngine is closed.");
    }
    while (_sendPort == null) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    final completer = Completer<dynamic>();
    final taskId = _counter++;
    _tasks[taskId] = completer;
    final task = NekoJsTask(taskId, jsFunction, args);
    _sendPort?.send(task);
    return completer.future;
  }

  /// Close this engine and release resources.
  void close() async {
    if (!_isClosed) {
      _isClosed = true;
      while (_tasks.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      _receivePort?.close();
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
    }
  }
}
