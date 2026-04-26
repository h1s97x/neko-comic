import 'package:dio/dio.dart';

/// HTTP client for NekoComic
class NekoClient {
  static final NekoClient _instance = NekoClient._();
  static NekoClient get instance => _instance;

  late final Dio _dio;

  NekoClient._() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  /// GET request
  Future<Response<String>> get(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(
      url,
      options: Options(headers: headers),
      queryParameters: queryParameters,
    );
  }

  /// POST request
  Future<Response<String>> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? headers,
  }) async {
    return _dio.post(
      url,
      data: data,
      options: Options(headers: headers),
    );
  }

  /// Download bytes
  Future<Response<List<int>>> downloadBytes(
    String url, {
    Map<String, dynamic>? headers,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    return _dio.get<List<int>>(
      url,
      options: Options(
        headers: headers,
        responseType: ResponseType.bytes,
      ),
      onReceiveProgress: onReceiveProgress,
    );
  }
}
