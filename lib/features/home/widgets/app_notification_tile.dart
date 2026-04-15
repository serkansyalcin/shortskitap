import 'package:flutter/material.dart';
import 'package:kitaplig/app/theme/app_colors.dart';
import 'package:kitaplig/core/models/app_notification_model.dart';

class AppNotificationTile extends StatelessWidget {
  const AppNotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.compact = false,
    this.showChevron = true,
  });

  final AppNotificationModel notification;
  final VoidCallback? onTap;
  final bool compact;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(compact ? 16 : 20),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? theme.cardColor
              : AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(compact ? 16 : 20),
          border: Border.all(
            color: notification.isRead
                ? theme.colorScheme.outline.withValues(alpha: 0.4)
                : AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 40 : 46,
              height: compact ? 40 : 46,
              decoration: BoxDecoration(
                color: _iconColor(notification.type).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconForType(notification.type),
                color: _iconColor(notification.type),
                size: compact ? 20 : 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 14 : 15,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatNotificationTime(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      height: 1.35,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                if (!notification.isRead)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(width: 10, height: 10),
                const SizedBox(height: 6),
                if (showChevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForType(String type) {
  switch (type) {
    case 'duel_challenge':
      return Icons.flash_on_rounded;
    case 'duel_accepted':
      return Icons.sports_kabaddi_rounded;
    case 'duel_declined':
      return Icons.close_rounded;
    case 'duel_completed':
      return Icons.emoji_events_rounded;
    case 'lp_earned':
      return Icons.trending_up_rounded;
    case 'lp_lost':
      return Icons.trending_down_rounded;
    case 'league_result':
      return Icons.workspace_premium_rounded;
    case 'rank_changed':
      return Icons.leaderboard_rounded;
    case 'followed_you':
      return Icons.person_add_alt_1_rounded;
    case 'ai_story_ready':
      return Icons.auto_stories_rounded;
    default:
      return Icons.notifications_none_rounded;
  }
}

Color _iconColor(String type) {
  switch (type) {
    case 'duel_challenge':
      return const Color(0xFFF59E0B);
    case 'duel_accepted':
      return const Color(0xFF10B981);
    case 'duel_declined':
      return const Color(0xFFEF4444);
    case 'duel_completed':
      return const Color(0xFF2563EB);
    case 'lp_earned':
      return const Color(0xFF16A34A);
    case 'lp_lost':
      return const Color(0xFFDC2626);
    case 'league_result':
      return const Color(0xFF7C3AED);
    case 'rank_changed':
      return const Color(0xFF0891B2);
    case 'followed_you':
      return const Color(0xFF16A34A);
    case 'ai_story_ready':
      return const Color(0xFF0F766E);
    default:
      return AppColors.primary;
  }
}

String formatNotificationTime(DateTime createdAt) {
  final now = DateTime.now();
  final diff = now.difference(createdAt);

  if (diff.inMinutes <= 0) {
    return 'Şimdi';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} dk';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} sa';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} g';
  }

  final day = createdAt.day.toString().padLeft(2, '0');
  final month = createdAt.month.toString().padLeft(2, '0');
  return '$day.$month';
}
