/// Network API for JavaScript comic sources.
///
/// This file provides the HTTP request functionality that can be
/// called from JavaScript code running in comic sources.

import 'dart:typed_data';

/// Standard user agent used for web requests.
const String webUA = 
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

/// HTTP response wrapper for JavaScript API.
class NekoHttpResponse {
  /// HTTP status code.
  final int? status;
  
  /// Response headers.
  final Map<String, String> headers;
  
  /// Response body.
  final dynamic body;
  
  /// Error message if the request failed.
  final String? error;

  NekoHttpResponse({
    this.status,
    this.headers = const {},
    this.body,
    this.error,
  });

  /// Convert to a map for JavaScript interop.
  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'headers': headers,
      'body': body,
      'error': error,
    };
  }
}

/// HTTP methods supported by the API.
enum NekoHttpMethod {
  get,
  post,
  put,
  delete,
  patch,
  head,
  options,
}

/// Build an HTTP request for JavaScript.
///
/// This is a helper function that creates a request map
/// that can be passed to the JS engine.
Map<String, dynamic> buildHttpRequest({
  required String url,
  NekoHttpMethod method = NekoHttpMethod.get,
  Map<String, String>? headers,
  dynamic data,
  bool bytes = false,
  Map<String, dynamic>? extra,
}) {
  return {
    'url': url,
    'http_method': method.name.toUpperCase(),
    'headers': headers ?? {},
    'data': data,
    'bytes': bytes,
    'extra': extra ?? {},
  };
}

/// Parse HTTP response for JavaScript.
Map<String, dynamic> parseHttpResponse(dynamic body) {
  if (body is Uint8List) {
    return {'bytes': body};
  } else if (body is String) {
    return {'text': body};
  } else if (body is Map) {
    return Map<String, dynamic>.from(body);
  }
  return {'text': body.toString()};
}
