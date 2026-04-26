/// Comic data model
class Comic {
  final String id;
  final String title;
  final String? coverUrl;
  final String? author;
  final String? description;
  final List<String> tags;
  final String sourceId;
  final DateTime? lastUpdate;
  final bool isFavorite;

  const Comic({
    required this.id,
    required this.title,
    this.coverUrl,
    this.author,
    this.description,
    this.tags = const [],
    required this.sourceId,
    this.lastUpdate,
    this.isFavorite = false,
  });
}
