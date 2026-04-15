import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/book_model.dart';
import '../ai_story_strings.dart';

class AiStoryHomeEntryCard extends StatelessWidget {
  final BookModel? latestBook;

  const AiStoryHomeEntryCard({super.key, this.latestBook});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.88),
            AppColors.primary.withValues(alpha: 0.14),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AiStoryStrings.homeTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AiStoryStrings.homeSubtitle,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (latestBook != null) ...[
            const SizedBox(height: 14),
            Text(
              'Son hikâyen: ${latestBook!.title}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              latestBook!.visibility == 'public'
                  ? 'Keşfette yayınlanıyor'
                  : 'Şu anda sana özel',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => context.push('/home/ai-story-studio'),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text(AiStoryStrings.createCta),
                ),
              ),
              if (latestBook != null) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: OutlinedButton(
                    onPressed: () => context.push('/books/${latestBook!.slug}'),
                    child: const Text(
                      AiStoryStrings.openStory,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
