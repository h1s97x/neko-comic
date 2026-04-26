# neko_image

Image loading and caching package for NekoComic.

## Features

- **NekoCacheManager**: SQLite-based cache management with automatic cleanup
- **NekoCachedImageProvider**: ImageProvider for thumbnails and covers with caching
- **NekoReaderImageProvider**: ImageProvider for comic reader with progress tracking
- **NekoBaseImageProvider**: Abstract base class for custom providers

## Installation

```yaml
dependencies:
  neko_image:
    path: packages/neko_image
```

## Usage

### Initialize

```dart
import 'package:neko_image/neko_image.dart';

void main() async {
  await NekoAppConfig.init();
  runApp(MyApp());
}
```

### Load Cached Image

```dart
Image(
  image: NekoCachedImageProvider(
    'https://example.com/image.jpg',
    headers: {'Referer': 'https://example.com'},
  ),
)
```

### Load Reader Image

```dart
Image(
  image: NekoReaderImageProvider(
    imageKey: 'https://example.com/comic/1/page1.jpg',
    sourceKey: 'exhentai',
    cid: 'abc123',
    eid: 'chapter1',
    page: 0,
  ),
)
```

### Cache Management

```dart
// Get cache stats
final stats = NekoCacheManager.instance.stats;

// Set cache limit (in MB)
NekoCacheManager.instance.setLimitSizeMB(1024); // 1GB

// Clear all cache
await NekoCacheManager.instance.clear();

// Delete specific cache
await NekoCacheManager.instance.delete('cache-key');
```

## API Reference

### NekoCacheManager

- `instance` - Singleton instance
- `write(key, data)` - Write data to cache
- `find(key)` - Find cached file by key
- `delete(key)` - Delete cache by key
- `clear()` - Clear all cache
- `stats` - Get cache statistics

### NekoCachedImageProvider

- `url` - Image URL or file path
- `headers` - Optional HTTP headers
- `cacheKey` - Custom cache key
- `enableResize` - Enable image resize

### NekoReaderImageProvider

- `imageKey` - Image URL or file path
- `sourceKey` - Comic source identifier
- `cid` - Comic ID
- `eid` - Episode/Chapter ID
- `page` - Page number
- `enableResize` - Enable image resize

## TODO

- [ ] Add image prefetching support
- [ ] Add image compression
- [ ] Add WebP/AVIF support
- [ ] Add memory cache layer
- [ ] Add progress callback
- [ ] Add error retry logic

## Migrated from Venera

This package was migrated from [Venera](https://github.com/venera-app/venera) foundation/image_provider/ system.
