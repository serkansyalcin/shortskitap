import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/friend_activity_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/friend_activity_model.dart';
import '../../../core/widgets/reader_profile_avatar.dart';

class FriendActivitySection extends ConsumerWidget {
  const FriendActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(friendActivityProvider);
    final scheme = Theme.of(context).colorScheme;

    return activityAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (activities) {
        if (activities.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arkadaşların okuyor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Takip ettiğin kişilerin güncel okumaları.',
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: activities.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (ctx, i) => _ActivityCard(activity: activities[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});
  final FriendActivityModel activity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final book = activity.book;
    final user = activity.user;
    final pct = activity.completionPct.clamp(0, 100).toDouble();

    return GestureDetector(
      onTap: book.slug != null
          ? () => context.push('/books/${book.slug}')
          : null,
      child: SizedBox(
        width: 150,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                child: SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: book.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: book.coverUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => _coverPlaceholder(scheme),
                        )
                      : _coverPlaceholder(scheme),
                ),
              ),
              // Progress bar
              ClipRRect(
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 3,
                  backgroundColor: scheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    activity.isCompleted
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ReaderProfileAvatar(
                          name: user.name,
                          avatarRef: user.avatarUrl,
                          size: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.isCompleted
                          ? 'Tamamladı ✓'
                          : '%${pct.toStringAsFixed(0)} okudu',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: activity.isCompleted
                            ? AppColors.primary
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder(ColorScheme scheme) => Container(
        color: scheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.auto_stories_rounded, size: 32, color: AppColors.primary),
        ),
      );
}
