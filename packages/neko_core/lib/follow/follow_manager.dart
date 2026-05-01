import 'dart:async';
import '../storage/favorites.dart';
import '../comic/models.dart';
import '../network/client.dart';

class ComicUpdateResult {
  final bool updated;
  final String? errorMessage;

  ComicUpdateResult(this.updated, this.errorMessage);
}

class UpdateProgress {
  final int total;
  final int current;
  final int errors;
  final int updated;
  final FavoriteItemWithUpdateInfo? comic;
  final String? errorMessage;

  UpdateProgress(
    this.total,
    this.current,
    this.errors,
    this.updated, [
    this.comic,
    this.errorMessage,
  ]);
}

class NekoFollowManager {
  static final NekoFollowManager _instance = NekoFollowManager._();
  static NekoFollowManager get instance => _instance;
  NekoFollowManager._();

  final _followController = StreamController<UpdateProgress>.broadcast();
  Stream<UpdateProgress> get followStream => _followController.stream;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  Future<ComicUpdateResult> checkComicUpdate(
    FavoriteItemWithUpdateInfo comic,
  ) async {
    int retries = 3;
    while (true) {
      try {
        var comicSource = comic.type.source;
        if (comicSource == null) {
          return ComicUpdateResult(false, 'Comic source not found');
        }

        var newInfo = await comicSource.getComic(comic.id);
        if (newInfo == null) {
          return ComicUpdateResult(false, 'Failed to load comic info');
        }

        var updated = false;
        var updateTime = newInfo.findUpdateTime();
        if (updateTime != null && updateTime != comic.updateTime) {
          updated = true;
        }

        return ComicUpdateResult(updated, null);
      } catch (e) {
        await Future.delayed(const Duration(seconds: 2));
        retries--;
        if (retries == 0) {
          return ComicUpdateResult(false, e.toString());
        }
      }
    }
  }

  Future<void> checkAllUpdates(String folder, {bool ignoreCheckTime = false}) async {
    if (_isRunning) return;
    _isRunning = true;

    var comics = NekoFavoritesManager().getComicsWithUpdatesInfo(folder);
    int total = comics.length;
    int current = 0;
    int errors = 0;
    int updated = 0;

    _followController.add(UpdateProgress(total, current, errors, updated));

    var comicsToUpdate = <FavoriteItemWithUpdateInfo>[];

    for (var comic in comics) {
      if (!ignoreCheckTime) {
        var lastCheckTime = comic.lastCheckTime;
        if (lastCheckTime != null &&
            DateTime.now().difference(lastCheckTime).inDays < 1) {
          current++;
          _followController.add(UpdateProgress(total, current, errors, updated));
          continue;
        }
      }
      comicsToUpdate.add(comic);
    }

    total = comicsToUpdate.length;
    current = 0;
    _followController.add(UpdateProgress(total, current, errors, updated));

    for (var comic in comicsToUpdate) {
      var result = await checkComicUpdate(comic);
      current++;
      if (result.updated) {
        updated++;
      } else if (result.errorMessage != null) {
        errors++;
        _followController.add(UpdateProgress(
          total,
          current,
          errors,
          updated,
          comic,
          result.errorMessage,
        ));
      }
      _followController.add(UpdateProgress(total, current, errors, updated));
    }

    _isRunning = false;
  }

  int countUpdates(String folder) {
    var comics = NekoFavoritesManager().getComicsWithUpdatesInfo(folder);
    return comics.where((c) => c.hasNewUpdate).length;
  }

  void dispose() {
    _followController.close();
  }
}

extension on NekoComicDetails {
  String? findUpdateTime() {
    return updateTime;
  }
}
