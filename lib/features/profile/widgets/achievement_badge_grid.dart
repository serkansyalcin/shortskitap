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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              size: 24,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '$earnedCount / ${achievements.length} kazan\u0131ld\u0131',
                    style: TextStyle(
                      fontSize: 13,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          alignment: WrapAlignment.start,
          children: [
            for (final achievement in achievements)
              SizedBox(
                width: 110,
                child: _BadgeTile(achievement: achievement),
              ),
          ],
        ),
      ],
    );
  }

  int _percent() => achievements.isEmpty
      ? 0
      : ((earnedCount / achievements.length) * 100).round();
}

class _BadgeTile extends StatelessWidget {
  final AchievementModel achievement;

  const _BadgeTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final earned = achievement.isEarned;
    final isNew = achievement.isNew;
    final rarityColor = _rarityColor(achievement.rarity);
    final title = achievement.title ?? achievement.key;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 12,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isNew)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'YEN\u0130',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (isNew && earned) const SizedBox(width: 4),
              if (earned)
                Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: rarityColor,
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Opacity(
          opacity: earned ? 1 : 0.4,
          child: _BadgeIcon(
            icon: achievement.icon,
            color: earned ? rarityColor : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 110,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: earned
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.55),
              height: 1.15,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (earned && achievement.xpReward > 0) ...[
          const SizedBox(height: 2),
          Text(
            '+${achievement.xpReward} XP',
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: rarityColor,
            ),
          ),
        ],
      ],
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
  final String? icon;
  final Color color;

  const _BadgeIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final value = icon?.trim();
    if (value == null || value.isEmpty) {
      return Icon(
        Icons.military_tech_rounded,
        size: 30,
        color: color,
      );
    }

    return Text(
      value,
      style: const TextStyle(fontSize: 30),
      textAlign: TextAlign.center,
    );
  }
}
