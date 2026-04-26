import 'package:flutter/material.dart';

/// Comic card widget
class ComicCard extends StatelessWidget {
  final String title;
  final String? coverUrl;
  final VoidCallback? onTap;

  const ComicCard({
    super.key,
    required this.title,
    this.coverUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: coverUrl != null
                  ? Image.network(
                      coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image),
                    )
                  : const Icon(Icons.image, size: 48),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
