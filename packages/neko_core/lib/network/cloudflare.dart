/// Cloudflare bypass for NekoComic
/// Reference: Venera network/cloudflare.dart

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Cloudflare exception
class NekoCloudflareException implements DioException {
  final String url;

  NekoCloudflareException(this.url);

  @override
  String toString() => 'CloudflareException: $url';

  static NekoCloudflareException? fromString(String message) {
    final match = RegExp(r'CloudflareException: (.+)').firstMatch(message);
    if (match == null) return null;
    return NekoCloudflareException(match.group(1)!);
  }

  @override
  DioException copyWith({
    RequestOptions? requestOptions,
    Response<dynamic>? response,
    DioExceptionType? type,
    Object? error,
    StackTrace? stackTrace,
    String? message,
  }) {
    return this;
  }

  @override
  Object? get error => this;

  @override
  String? get message => toString();

  @override
  RequestOptions get requestOptions => RequestOptions();

  @override
  Response? get response => null;

  @override
  StackTrace get stackTrace => StackTrace.empty;

  @override
  DioExceptionType get type => DioExceptionType.badResponse;
}

/// Cloudflare bypass utility
class NekoCloudflareBypass {
  static NekoCloudflareBypass? _instance;
  static NekoCloudflareBypass get instance =>
      _instance ??= NekoCloudflareBypass._();

  NekoCloudflareBypass._();

  /// Check if response is Cloudflare challenge
  bool isCloudflareChallenge(Response response) {
    // Check header
    if (response.headers['cf-mitigated']?.firstOrNull == 'challenge') {
      return true;
    }

    // Check status code
    if (response.statusCode == 403) {
      return true;
    }

    return false;
  }

  /// Check if HTML contains Cloudflare challenge
  bool isCloudflareChallengeHtml(String html) {
    final challengeIndicators = [
      'cloudflare',
      'challenge',
      'Checking your browser',
      'cf-challenge-platform',
      '_cf_chl_opt',
      'challenge-platform',
    ];

    final lowerHtml = html.toLowerCase();
    for (final indicator in challengeIndicators) {
      if (lowerHtml.contains(indicator.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  /// Extract clearance cookie from response headers
  String? extractClearanceCookie(Map<String, List<String>> headers) {
    final cookies = headers['set-cookie'];
    if (cookies == null) return null;

    for (final cookie in cookies) {
      if (cookie.startsWith('cf_clearance=')) {
        final parts = cookie.split(';');
        if (parts.isNotEmpty) {
          return parts[0];
        }
      }
    }

    return null;
  }

  /// Check if URL is protected by Cloudflare
  Future<bool> isProtected(String url) async {
    try {
      final response = await Dio().head(url);
      return isCloudflareChallenge(response);
    } catch (e) {
      return false;
    }
  }
}

/// Cloudflare interceptor for Dio
class NekoCloudflareInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 403) {
      // Check if it's Cloudflare challenge
      final cfHeader = err.response?.headers['cf-mitigated']?.firstOrNull;
      if (cfHeader == 'challenge' || cfHeader == 'captcha') {
        final url = err.requestOptions.uri.toString();
        handler.next(NekoCloudflareException(url));
        return;
      }
    }
    handler.next(err);
  }
}

/// User agent strings
class NekoUserAgent {
  static const desktop = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.0.0 Safari/537.36';

  static const mobile = 'Mozilla/5.0 (Linux; Android 13) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/120.0.0.0 Mobile Safari/537.36';

  static const ios = 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) '
      'Version/17.0 Mobile/15E148 Safari/604.1';

  /// Get default user agent
  static String get defaultAgent => desktop;

  /// Check if user agent is mobile
  static bool isMobile(String ua) {
    return ua.contains('Mobile') || ua.contains('Android') || ua.contains('iPhone');
  }
}
