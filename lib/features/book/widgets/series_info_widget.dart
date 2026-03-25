import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/series_model.dart';

class SeriesInfoWidget extends StatelessWidget {
  final SeriesModel series;
  final int? currentBookOrder;
  final Color accentColor;

  const SeriesInfoWidget({
    super.key,
    required this.series,
    this.currentBookOrder,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bookCount = series.booksCount ?? series.books.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withValues(alpha: 0.14),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('📚', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Seri',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                    if (currentBookOrder != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '$currentBookOrder / $bookCount',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  series.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (series.description != null &&
                    series.description!.isNotEmpty)
                  Text(
                    series.description!,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.push('/series/${series.id}'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Seriyi Gör',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SeriesBookListWidget extends StatelessWidget {
  final SeriesModel series;
  final int? currentBookId;
  final Color accentColor;

  const SeriesBookListWidget({
    super.key,
    required this.series,
    this.currentBookId,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final books = series.books;

    if (books.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seri Kitapları',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final book = books[index];
              final isCurrent = book.id == currentBookId;

              return GestureDetector(
                onTap: isCurrent
                    ? null
                    : () => context.push('/books/${book.slug}'),
                child: Container(
                  width: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: isCurrent
                        ? Border.all(color: accentColor, width: 2)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(isCurrent ? 12 : 14),
                          child: book.coverImageUrl != null
                              ? Image.network(
                                  book.coverImageUrl!,
                                  fit: BoxFit.cover,
                                  width: 76,
                                  errorBuilder: (_, __, ___) =>
                                      _FallbackMini(accentColor: accentColor),
                                )
                              : _FallbackMini(accentColor: accentColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.title,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isCurrent
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isCurrent
                              ? accentColor
                              : colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FallbackMini extends StatelessWidget {
  final Color accentColor;
  const _FallbackMini({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: accentColor.withValues(alpha: 0.15),
      child: const Center(child: Text('📖', style: TextStyle(fontSize: 22))),
    );
  }
}
