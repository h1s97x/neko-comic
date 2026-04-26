/// Reader layout modes
enum ReaderLayout {
  /// Gallery mode: left to right
  leftToRight('leftToRight'),

  /// Gallery mode: right to left (common in manga)
  rightToLeft('rightToLeft'),

  /// Gallery mode: top to bottom
  topToBottom('topToBottom'),

  /// Continuous scroll: top to bottom
  vertical('vertical'),

  /// Webtoon mode: continuous vertical scroll
  webtoon('webtoon');

  final String key;

  const ReaderLayout(this.key);

  /// Whether this is a gallery (page-by-page) mode
  bool get isGallery =>
      this == ReaderLayout.leftToRight ||
      this == ReaderLayout.rightToLeft ||
      this == ReaderLayout.topToBottom;

  /// Whether this is a continuous scroll mode
  bool get isContinuous => this == ReaderLayout.vertical || this == ReaderLayout.webtoon;

  /// Whether pages are displayed right-to-left (common in manga)
  bool get isRtl => this == ReaderLayout.rightToLeft;

  /// Whether pages are displayed left-to-right
  bool get isLtr => this == ReaderLayout.leftToRight;

  /// Whether this is vertical scroll mode
  bool get isVertical => this == ReaderLayout.vertical || this == ReaderLayout.webtoon;

  /// Create layout from key string
  static ReaderLayout fromKey(String key) {
    for (var mode in values) {
      if (mode.key == key) {
        return mode;
      }
    }
    return rightToLeft;
  }
}

/// Reader settings
class NekoReaderSettings {
  /// Enable page animation
  bool enablePageAnimation;

  /// Animation duration
  Duration pageAnimationDuration;

  /// Enable double tap to zoom
  bool enableDoubleTapToZoom;

  /// Show system status bar
  bool showSystemStatusBar;

  /// Enable volume key page turning
  bool enableVolumeKeyTurnPage;

  /// Images per page (for adaptive display)
  int imagesPerPage;

  /// Show single image on first page
  bool showSingleImageOnFirstPage;

  /// Preload image count
  int preloadCount;

  /// Quick collect image gesture
  String quickCollectImage;

  NekoReaderSettings({
    this.enablePageAnimation = true,
    this.pageAnimationDuration = const Duration(milliseconds: 300),
    this.enableDoubleTapToZoom = true,
    this.showSystemStatusBar = false,
    this.enableVolumeKeyTurnPage = false,
    this.imagesPerPage = 1,
    this.showSingleImageOnFirstPage = false,
    this.preloadCount = 3,
    this.quickCollectImage = 'None',
  });

  void copyFrom(NekoReaderSettings other) {
    enablePageAnimation = other.enablePageAnimation;
    pageAnimationDuration = other.pageAnimationDuration;
    enableDoubleTapToZoom = other.enableDoubleTapToZoom;
    showSystemStatusBar = other.showSystemStatusBar;
    enableVolumeKeyTurnPage = other.enableVolumeKeyTurnPage;
    imagesPerPage = other.imagesPerPage;
    showSingleImageOnFirstPage = other.showSingleImageOnFirstPage;
    preloadCount = other.preloadCount;
    quickCollectImage = other.quickCollectImage;
  }
}

/// Image loading state
enum ImageLoadingState {
  idle,
  loading,
  loaded,
  error,
}

/// Image data with metadata
class NekoImageData {
  final String url;
  final String? cacheKey;
  final Map<String, String>? headers;
  final int? width;
  final int? height;
  ImageLoadingState state;

  NekoImageData({
    required this.url,
    this.cacheKey,
    this.headers,
    this.width,
    this.height,
    this.state = ImageLoadingState.idle,
  });
}

/// Page data for reader
class NekoPageData {
  final int index;
  final List<NekoImageData> images;
  final bool isComments;

  const NekoPageData({
    required this.index,
    required this.images,
    this.isComments = false,
  });
}
