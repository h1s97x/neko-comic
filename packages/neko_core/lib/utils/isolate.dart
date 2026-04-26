/// Isolate utilities for NekoComic
library;

/// Compute function wrapper
R compute<R>(R Function() computation) {
  return computation();
}

/// Isolate helper
class IsolateHelper {
  /// Run computation in isolate
  static Future<R> run<R>(R Function() computation) async {
    return compute(computation);
  }
}
