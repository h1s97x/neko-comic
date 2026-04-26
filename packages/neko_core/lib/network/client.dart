/// HTTP client for NekoComic
/// Reference: Venera network/app_dio.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:rhttp/rhttp.dart' as rhttp;

/// HTTP client configuration
class NekoHttpClient {
  static NekoHttpClient? _instance;
  static NekoHttpClient get instance => _instance ??= NekoHttpClient._();

  NekoHttpClient._();

  late Dio _dio;
  bool _isInitialized = false;

  /// Initialize client
  void initialize({
    String? proxy,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    if (_isInitialized) return;

    _dio = Dio(BaseOptions(
      connectTimeout: connectTimeout ?? const Duration(seconds: 15),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 15),
      sendTimeout: sendTimeout ?? const Duration(seconds: 15),
    ));

    // Use RHttp adapter for better performance
    _dio.httpClientAdapter = RHttpAdapter();

    _isInitialized = true;
  }

  /// Get Dio instance
  Dio get dio {
    if (!_isInitialized) {
      initialize();
    }
    return _dio;
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return dio.get<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Download file
  Future<Response<dynamic>> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String? template郎,
    Map<String, dynamic>? queryParameters,
    Options? options,
    data,
  }) {
    return dio.download(
      urlPath,
      savePath,
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
      deleteOnError: deleteOnError,
      lengthHeader: template郎,
      queryParameters: queryParameters,
      options: options,
      data: data,
    );
  }

  /// Download as bytes
  Future<List<int>> downloadBytes(
    String url, {
    Map<String, dynamic>? headers,
    void Function(int received, int total)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    final response = await dio.get<List<int>>(
      url,
      options: Options(
        headers: headers,
        responseType: ResponseType.bytes,
      ),
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
    return response.data ?? [];
  }

  /// Fetch string content
  Future<String> fetchString(
    String url, {
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    final response = await dio.get<String>(
      url,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    );
    return response.data ?? '';
  }

  /// Fetch JSON
  Future<Map<String, dynamic>> fetchJson(
    String url, {
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    final response = await dio.get<dynamic>(
      url,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    throw FormatException('Response is not JSON: ${response.data}');
  }

  /// Close client
  void close() {
    dio.close();
    _isInitialized = false;
    _instance = null;
  }
}

/// RHttp adapter for Dio
class RHttpAdapter implements HttpClientAdapter {
  final rhttp.RHttpClient _client = rhttp.RHttpClient();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    ResponseCancelToken? cancelToken,
  ) async {
    final rhttp.Response response;

    try {
      response = await _client.request(
        options.uri.toString(),
        method: options.method,
        headers: options.headers,
        body: requestStream != null
            ? await requestStream.toList()
            : options.data,
        cancelToken: cancelToken,
      );
    } catch (e) {
      throw DioException(
        requestOptions: options,
        error: e,
        type: DioExceptionType.unknown,
      );
    }

    return ResponseBody.fromStream(
      Stream.value(Uint8List.fromList(response.bodyBytes)),
      response.statusCode ?? 0,
      headers: response.headers.map.map((key, value) => MapEntry(key, value)),
    );
  }

  @override
  void close({bool force = false}) {
    _client.close();
  }
}

/// Request options helper
extension RequestOptionsExtension on RequestOptions {
  /// Add common headers
  RequestOptions withCommonHeaders({
    String? userAgent,
    String? referer,
    String? accept,
  }) {
    final headers = Map<String, dynamic>.from(this.headers);
    if (userAgent != null) headers['User-Agent'] = userAgent;
    if (referer != null) headers['Referer'] = referer;
    if (accept != null) headers['Accept'] = accept;
    return copyWithHeaders(headers);
  }
}
