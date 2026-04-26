part of 'neko_image.dart';

/// Abstract base class for image providers with caching support.
abstract class NekoBaseImageProvider<T extends NekoBaseImageProvider<T>>
    extends ImageProvider<T> {
  const NekoBaseImageProvider();

  static const int maxImagePixel = 2560 * 1440;

  /// Get target size for image, resize if too large
  static TargetImageSize _getTargetSize(int width, int height) {
    if (width <= 0 || height <= 0) {
      return TargetImageSize(width: width, height: height);
    }
    final ratio = width / height;
    if (ratio > 2 || ratio < 0.5) {
      return TargetImageSize(width: width, height: height);
    }
    if (width * height > maxImagePixel) {
      final scale = sqrt(maxImagePixel / (width * height));
      return TargetImageSize(
        width: (width * scale).round(),
        height: (height * scale).round(),
      );
    }
    return TargetImageSize(width: width, height: height);
  }

  @override
  ImageStreamCompleter loadImage(T key, ImageDecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadBufferAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: 1.0,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>(
          'ImageProvider: $this\nKey: $key',
          this,
          style: DiagnosticsTreeStyle.errorProperty,
        );
      },
    );
  }

  Future<ui.Codec> _loadBufferAsync(
    T key,
    StreamController<ImageChunkEvent> chunkEvents,
    ImageDecoderCallback decode,
  ) async {
    try {
      int retryTime = 1;
      bool stop = false;
      chunkEvents.onCancel = () => stop = true;

      Uint8List? data;
      while (data == null && !stop) {
        try {
          data = await load(chunkEvents, () {
            if (stop) throw const _StopException();
          });
        } on _StopException {
          rethrow;
        } catch (e) {
          if (e.toString().contains('404') || e.toString().contains('403')) {
            rethrow;
          }
          retryTime <<= 1;
          if (retryTime > 8 || stop) rethrow;
          await Future.delayed(Duration(seconds: retryTime));
        }
      }

      if (stop) throw const _StopException();
      if (data!.isEmpty) throw Exception('Empty image data');

      final buffer = await ImmutableBuffer.fromUint8List(data);
      return await decode(
        buffer,
        getTargetSize: enableResize ? _getTargetSize : null,
      );
    } on _StopException {
      rethrow;
    } catch (e, s) {
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    } finally {
      chunkEvents.close();
    }
  }

  /// Load image data, called by the framework
  Future<Uint8List> load(
    StreamController<ImageChunkEvent> chunkEvents,
    void Function() checkStop,
  );

  /// Unique key for this image
  String get key;

  /// Whether to enable image resize for large images
  bool get enableResize => false;

  @override
  bool operator ==(Object other) =>
      other is NekoBaseImageProvider<T> && key == other.key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => '$runtimeType($key)';
}

class _StopException implements Exception {
  const _StopException();
}
