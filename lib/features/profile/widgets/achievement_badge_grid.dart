import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/achievement_model.dart';

class AchievementBadgeGrid extends StatelessWidget {
  const AchievementBadgeGrid({
    super.key,
    required this.achievements,
    required this.earnedCount,
    this.limit = 4,
    this.compact = false,
  });

  final List<AchievementModel> achievements;
  final int earnedCount;
  final int? limit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleAchievements = limit != null
        ? achievements.take(limit!).toList()
        : achievements;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 540;
        final crossAxisCount = isNarrow ? 2 : 3;
        final spacing = compact ? 10.0 : (isNarrow ? 12.0 : 14.0);
        final cardHeight = compact ? 182.0 : (isNarrow ? 232.0 : 238.0);
        final compactCardWidth = isNarrow ? 168.0 : 180.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 22,
                  color: Color(0xFFB7791F),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rozetler',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '$earnedCount / ${achievements.length} rozet kazanıldı',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (achievements.isNotEmpty)
                  Text(
                    '${_percent()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                if (limit != null && achievements.length > limit!) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      context.push(
                        '/home/badges',
                        extra: {
                          'achievements': achievements,
                          'earnedCount': earnedCount,
                        },
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Tümünü Gör',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (compact)
              SizedBox(
                height: cardHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visibleAchievements.length,
                  separatorBuilder: (_, index) => SizedBox(width: spacing),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: compactCardWidth,
                      child: _BadgeTile(
                        achievement: visibleAchievements[index],
                        compact: true,
                      ),
                    );
                  },
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleAchievements.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  mainAxisExtent: cardHeight,
                ),
                itemBuilder: (context, index) {
                  return _BadgeTile(achievement: visibleAchievements[index]);
                },
              ),
          ],
        );
      },
    );
  }

  int _percent() => achievements.isEmpty
      ? 0
      : ((earnedCount / achievements.length) * 100).round();
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.achievement, this.compact = false});

  static const _titleHeight = 32.0;
  static const _descriptionHeight = 38.0;
  static const _progressBlockHeight = 28.0;

  final AchievementModel achievement;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final earned = achievement.isEarned;
    final rarityColor = _rarityColor(achievement.rarity);
    final title = achievement.title ?? achievement.key;
    final supportingText = earned
        ? achievement.description
        : achievement.hint ?? achievement.description;

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 10 : 11,
        compact ? 7 : 8,
        compact ? 10 : 11,
        compact ? 8 : 8,
      ),
      decoration: BoxDecoration(
        color: earned ? rarityColor.withValues(alpha: 0.08) : theme.cardColor,
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(
          color: earned
              ? rarityColor.withValues(alpha: 0.4)
              : colorScheme.outline.withValues(alpha: 0.28),
          width: earned ? 1.5 : 1,
        ),
        boxShadow: earned
            ? [
                BoxShadow(
                  color: rarityColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: compact ? 20 : 24,
            child: Stack(
              children: [
                if (achievement.isNew)
                  const Positioned(top: 0, right: 0, child: _NewBadgePill()),
                if (earned)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: rarityColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: compact ? 9 : 10,
                            color: rarityColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Kazanıldı',
                            style: TextStyle(
                              fontSize: compact ? 7 : 8,
                              fontWeight: FontWeight.w800,
                              color: rarityColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: compact ? 4 : 4),
          Align(
            alignment: Alignment.center,
            child: _BadgeIcon(
              icon: achievement.icon ?? achievement.key,
              color: earned ? rarityColor : colorScheme.onSurfaceVariant,
              isEarned: earned,
              compact: compact,
            ),
          ),
          SizedBox(height: compact ? 5 : 8),
          SizedBox(
            height: compact ? 26 : _titleHeight,
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: compact ? 10.5 : 12,
                  fontWeight: FontWeight.w800,
                  color: earned
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.5),
                  height: 1.15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(height: compact ? 3 : 6),
          SizedBox(
            height: compact ? 34 : _descriptionHeight,
            child: Text(
              supportingText ?? '',
              style: TextStyle(
                fontSize: compact ? 8.5 : 10,
                height: compact ? 1.2 : 1.3,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          if (!earned && achievement.hasProgress) ...[
            SizedBox(
              height: compact ? 22 : _progressBlockHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: compact ? 3 : 5,
                      value: achievement.progressRatio,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 5),
                  Text(
                    '${achievement.progressCurrent}/${achievement.progressTarget} tamamlandı',
                    style: TextStyle(
                      fontSize: compact ? 7.5 : 9,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(height: compact ? 3 : 6),
          ],
          SizedBox(
            height: compact ? 11 : 14,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    achievement.rarity.label,
                    style: TextStyle(
                      fontSize: compact ? 7.5 : 9,
                      fontWeight: FontWeight.w800,
                      color: rarityColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (achievement.xpReward > 0)
                  Text(
                    '+${achievement.xpReward} XP',
                    style: TextStyle(
                      fontSize: compact ? 7.5 : 9,
                      fontWeight: FontWeight.w800,
                      color: earned ? rarityColor : AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _rarityColor(AchievementRarity rarity) => switch (rarity) {
    AchievementRarity.common => const Color(0xFF6B7280),
    AchievementRarity.uncommon => const Color(0xFF10B981),
    AchievementRarity.rare => const Color(0xFF3B82F6),
    AchievementRarity.epic => const Color(0xFF8B5CF6),
    AchievementRarity.legendary => const Color(0xFFFFD35C),
  };
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({
    required this.icon,
    required this.color,
    required this.isEarned,
    this.compact = false,
  });

  final String? icon;
  final Color color;
  final bool isEarned;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final emoji = _iconFor(icon);

    return Container(
      width: compact ? 34 : 44,
      height: compact ? 34 : 44,
      decoration: BoxDecoration(
        color: isEarned
            ? color.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: BoxShape.circle,
        border: isEarned
            ? Border.all(color: color.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(
            fontSize: compact ? 18 : 22,
            color: isEarned ? null : Colors.grey.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }

  String _iconFor(String? key) => switch (key) {
    'first_book' || 'ğŸ‰' => 'ğŸ‰',
    '100_paragraphs' || '📖' => '📖',
    '3_books' || '📚' => '📚',
    'night_owl' || '🌙' => '🌙',
    'weekend_warrior' || 'ğŸ—“ï¸' => 'ğŸ—“ï¸',
    '10_favorites' || '❤️' => '❤️',
    '30_day_streak' || '🔥' => '🔥',
    '1000_paragraphs' || '✍️' => '✍️',
    _ => (key?.length ?? 0) > 2 ? '🏆' : (key ?? '🏆'),
  };
}

class _NewBadgePill extends StatelessWidget {
  const _NewBadgePill();

  @override
  Widget build(BuildContext context) {
    return const _StatusPill(
      label: 'Yeni',
      backgroundColor: Color(0xFFEF4444),
      foregroundColor: Colors.white,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: foregroundColor,
        ),
      ),
    );
  }
}
