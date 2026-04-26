import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui show Codec;
import 'dart:async';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

part 'cache/cache_manager.dart';
part 'providers/base_provider.dart';
part 'providers/cached_image.dart';
part 'providers/reader_image.dart';

/// Application configuration for neko_image
class NekoAppConfig {
  static String? _cachePath;
  static String? _dataPath;
  
  static String get cachePath => _cachePath ?? (throw StateError('NekoImage not initialized'));
  static String get dataPath => _dataPath ?? (throw StateError('NekoImage not initialized'));
  
  /// Initialize neko_image with paths
  static Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    _dataPath = dir.path;
    _cachePath = p.join(dir.path, 'cache');
  }
}

/// Core image package for NekoComic.
/// 
/// This package provides:
/// - Image caching with SQLite-based cache manager
/// - Custom ImageProvider implementations for comic reading
/// - Image loading with progress tracking
/// - Automatic cache cleanup and management
library neko_image;

export 'cache/cache_manager.dart';
export 'providers/base_provider.dart';
export 'providers/cached_image.dart';
export 'providers/reader_image.dart';
