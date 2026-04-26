# NekoComic Core

Core data models, storage, and network layer for NekoComic.

## Features

- Comic data models (Comic, Chapter, Image, Comment)
- SQLite database storage
- HTTP client with Cloudflare bypass
- Cookie management with persistence
- WebDAV synchronization support

## Usage

```dart
import 'package:neko_core/neko_core.dart';

// Initialize database
await NekoDatabase.instance.initialize();

// Manage favorites
await NekoFavoritesManager.instance.add(favorite);
final favorites = NekoFavoritesManager.instance.getAll();

// Manage history
await NekoHistoryManager.instance.add(history);

// Sync data
await NekoSyncManager.instance.sync();
```

## Models

- `NekoComic` - Basic comic information
- `NekoComicDetails` - Full comic details with chapters
- `NekoChapter` - Chapter information
- `NekoImageInfo` - Image information
- `NekoComment` - Comment information
- `NekoHistory` - Reading history
- `NekoFavoriteItem` - Favorite item

## Status

- [x] Data models
- [x] Database initialization
- [x] Favorites management
- [x] History management
- [x] HTTP client
- [x] Cloudflare bypass
- [x] Cookie management
- [x] Sync manager
- [ ] Settings storage
- [ ] Comic source storage
