/// NekoComic Core - Core data models, storage, and network layer
library neko_core;

// Comic models
export 'comic/models.dart';

// Storage
export 'storage/database.dart';
export 'storage/favorites.dart';
export 'storage/history.dart';

// Network
export 'network/client.dart';
export 'network/cloudflare.dart';
export 'network/cookie_jar.dart';

// Sync
export 'sync/sync_manager.dart';

// Download
export 'download/download_manager.dart';

// Local comics
export 'local/local_comics.dart';

// Utils
export 'utils/utils.dart';
