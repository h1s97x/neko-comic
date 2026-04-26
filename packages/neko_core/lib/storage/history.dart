/// History manager
class HistoryManager {
  static final HistoryManager _instance = HistoryManager._();
  static HistoryManager get instance => _instance;

  HistoryManager._();

  /// Add to history
  Future<void> add({
    required String comicId,
    required String chapterId,
    required int pageIndex,
  }) async {
    // TODO: Implement add to history
  }

  /// Get reading history
  Future<List<ReadingHistory>> getAll() async {
    // TODO: Implement get all history
    return [];
  }

  /// Clear history
  Future<void> clear() async {
    // TODO: Implement clear history
  }
}

/// Reading history entry
class ReadingHistory {
  final String comicId;
  final String chapterId;
  final int pageIndex;
  final DateTime lastRead;

  const ReadingHistory({
    required this.comicId,
    required this.chapterId,
    required this.pageIndex,
    required this.lastRead,
  });
}
