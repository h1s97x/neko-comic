part of 'neko_image.dart';

/// Image provider for comic reader images.
/// 
/// Features:
/// - Automatic caching
/// - Progress tracking
/// - Support for custom image processing
/// - Local file support
class NekoReaderImageProvider
    extends NekoBaseImageProvider<NekoReaderImageProvider> {
  /// Create a reader image provider
  /// 
  /// [imageKey] - Image URL or file path
  /// [sourceKey] - Comic source identifier
  /// [cid] - Comic ID
  /// [eid] - Episode/Chapter ID
  /// [page] - Page number
  const NekoReaderImageProvider({
    required this.imageKey,
    this.sourceKey,
    this.cid,
    this.eid,
    this.page = 0,
    this.enableResize = false,
  });

  final String imageKey;
  final String? sourceKey;
  final String? cid;
  final String? eid;
  final int page;
  
  @override
  final bool enableResize;

  @override
  Future<Uint8List> load(
    StreamController<ImageChunkEvent> chunkEvents,
    void Function() checkStop,
  ) async {
    Uint8List? imageBytes;
    
    // Load from local file
    if (imageKey.startsWith('file://')) {
      final file = File(imageKey);
      if (await file.exists()) {
        imageBytes = await file.readAsBytes();
      } else {
        throw Exception('File not found: $imageKey');
      }
    } else {
      // Check cache first
      final cache = NekoCacheManager.instance;
      final cacheKey = '$imageKey@$sourceKey@$cid@$eid';
      final cachedFile = await cache.find(cacheKey);
      if (cachedFile != null) {
        return await cachedFile.readAsBytes();
      }
      
      // Load from network
      imageBytes = await _loadFromNetwork(cacheKey, chunkEvents, checkStop);
      
      // Save to cache
      if (imageBytes != null) {
        await cache.write(cacheKey, imageBytes);
      }
    }
    
    if (imageBytes == null || imageBytes.isEmpty) {
      throw Exception('Failed to load image: $imageKey');
    }
    
    return imageBytes;
  }

  Future<Uint8List?> _loadFromNetwork(
    String cacheKey,
    StreamController<ImageChunkEvent> chunkEvents,
    void Function() checkStop,
  ) async {
    try {
      final dio = Dio(BaseOptions(
        headers: {'user-agent': webUA},
        responseType: ResponseType.stream,
      ));
      
      var requestUrl = imageKey;
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
  Future<NekoReaderImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  String get key => '$imageKey@$sourceKey@$cid@$eid@$enableResize';
}

/// Image download progress
class ImageDownloadProgress {
  const ImageDownloadProgress({
    required this.currentBytes,
    this.totalBytes,
    this.imageBytes,
  });

  final int currentBytes;
  final int? totalBytes;
  final Uint8List? imageBytes;
  
  double get progress => totalBytes != null && totalBytes! > 0
      ? currentBytes / totalBytes!
      : 0.0;
}
