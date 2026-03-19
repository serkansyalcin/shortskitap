import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/achievement_model.dart';

class AchievementBadgeGrid extends StatelessWidget {
  final List<AchievementModel> achievements;
  final int earnedCount;

  const AchievementBadgeGrid({
    super.key,
    required this.achievements,
    required this.earnedCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD35C).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🏆', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rozetler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '$earnedCount / ${achievements.length} kazanıldı',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (achievements.isNotEmpty)
                _EarnedProgressPill(
                  earned: earnedCount,
                  total: achievements.length,
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _BadgeTile(
                achievement: achievement,
                isDark: isDark,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EarnedProgressPill extends StatelessWidget {
  final int earned;
  final int total;

  const _EarnedProgressPill({required this.earned, required this.total});

  @override
  Widget build(BuildContext context) {
    final percent = total > 0 ? (earned / total * 100).round() : 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$percent%',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final AchievementModel achievement;
  final bool isDark;

  const _BadgeTile({required this.achievement, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final earned = achievement.isEarned;
    final isNew = achievement.isNew;
    final rarityColor = _rarityColor(achievement.rarity);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: earned
            ? rarityColor.withValues(alpha: isDark ? 0.18 : 0.12)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: earned
              ? rarityColor.withValues(alpha: 0.40)
              : colorScheme.outline.withValues(alpha: 0.3),
          width: earned ? 1.5 : 1,
        ),
        boxShadow: earned && isNew
            ? [
                BoxShadow(
                  color: rarityColor.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: earned ? 1.0 : 0.3,
                  child: Text(
                    achievement.icon ?? '🎖️',
                    style: TextStyle(fontSize: earned ? 28 : 22),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  achievement.title ?? achievement.key,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: earned
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (earned && achievement.xpReward > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+${achievement.xpReward} XP',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: rarityColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (earned)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: rarityColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 9,
                  color: Colors.white,
                ),
              ),
            ),
          if (isNew)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'YENİ',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
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
