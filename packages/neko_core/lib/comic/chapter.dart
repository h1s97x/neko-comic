/// Chapter data model
class Chapter {
  final String id;
  final String title;
  final int index;
  final String comicId;
  final DateTime? uploadDate;
  final String? sourceId;

  const Chapter({
    required this.id,
    required this.title,
    required this.index,
    required this.comicId,
    this.uploadDate,
    this.sourceId,
  });
}
