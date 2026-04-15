import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/book_model.dart';
import '../ai_story_strings.dart';

class AiStoryDiscoverSection extends StatelessWidget {
  final List<BookModel> books;
  final String title;
  final String emptyMessage;

  const AiStoryDiscoverSection({
    super.key,
    required this.books,
    this.title = AiStoryStrings.discoverTitle,
    this.emptyMessage = AiStoryStrings.emptyDiscover,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Kullanıcıların paylaştığı AI hikâyeleri keşfet.',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        if (books.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          SizedBox(
            height: 212,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              separatorBuilder: (_, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final book = books[index];
                return InkWell(
                  onTap: () => context.push('/books/${book.slug}'),
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 228,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.24,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            book.generationType?.toUpperCase() ?? 'AI',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          book.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.author?.name ??
                              book.creatorDisplayName ??
                              'Kitaplig kullanıcısı',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          book.description ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.45,
                            color: colorScheme.onSurfaceVariant,
                          ),
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
