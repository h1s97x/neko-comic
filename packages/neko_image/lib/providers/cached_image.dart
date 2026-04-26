part of 'neko_image.dart';

/// Image provider for cached thumbnails and covers.
/// 
/// Features:
/// - Automatic disk caching
/// - Progress tracking for loading
/// - Fallback to local file support
/// - Concurrent loading limit
class NekoCachedImageProvider
    extends NekoBaseImageProvider<NekoCachedImageProvider> {
  /// Create a cached image provider
  /// 
  /// [url] - Image URL or file path
  /// [headers] - Optional HTTP headers
  /// [cacheKey] - Custom cache key
  const NekoCachedImageProvider(
    this.url, {
    this.headers,
    this.cacheKey,
    this.enableResize = false,
  });

  final String url;
  final Map<String, String>? headers;
  final String? cacheKey;
  
  @override
  final bool enableResize;

  static int _loadingCount = 0;
  static const _maxLoadingCount = 8;

  @override
  Future<Uint8List> load(
    StreamController<ImageChunkEvent> chunkEvents,
    void Function() checkStop,
  ) async {
    while (_loadingCount > _maxLoadingCount) {
      await Future.delayed(const Duration(milliseconds: 100));
      checkStop();
    }
    _loadingCount++;
    
    try {
      // Check cache first
      final cache = NekoCacheManager.instance;
      final key = cacheKey ?? url;
      final cachedFile = await cache.find(key);
      if (cachedFile != null) {
        return await cachedFile.readAsBytes();
      }
      
      // Load from network or file
      Uint8List? data;
      if (url.startsWith('file://')) {
        final file = File(url.substring(7));
        if (await file.exists()) {
          data = await file.readAsBytes();
        }
      } else {
        data = await _loadFromNetwork(chunkEvents, checkStop);
      }
      
      if (data == null || data.isEmpty) {
        throw Exception('Failed to load image: $url');
      }
      
      // Save to cache
      await cache.write(key, data);
      
      return data;
    } finally {
      _loadingCount--;
    }
  }

  Future<Uint8List?> _loadFromNetwork(
    StreamController<ImageChunkEvent> chunkEvents,
    void Function() checkStop,
  ) async {
    try {
      final dio = Dio(BaseOptions(
        headers: headers ?? {'user-agent': webUA},
        responseType: ResponseType.stream,
      ));
      
      var requestUrl = url;
      if (requestUrl.startsWith('//')) {
        requestUrl = 'https:$requestUrl';
      }
      
      final response = await dio.request<ResponseBody>(
        requestUrl,
        options: Options(responseType: ResponseType.stream),
      );
      
      final stream = response.data?.stream;
      if (stream == null) return null;
      
      final expectedBytes = response.data?.contentLength;
      final buffer = <int>[];
      
      await for (final chunk in stream) {
        buffer.addAll(chunk);
        checkStop();
        chunkEvents.add(ImageChunkEvent(
          cumulativeBytesLoaded: buffer.length,
          expectedTotalBytes: expectedBytes ?? -1,
        ));
      }
      
      return Uint8List.fromList(buffer);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<NekoCachedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  String get key => cacheKey ?? url;
}

/// User agent for web requests
const webUA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
