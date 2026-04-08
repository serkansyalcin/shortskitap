import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitaplig/app/providers/auth_provider.dart';
import 'package:kitaplig/app/providers/league_provider.dart';
import 'package:kitaplig/app/theme/app_colors.dart';

/// Compact league card shown on the home screen.
class LeagueMiniCard extends ConsumerWidget {
  const LeagueMiniCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState.status != AuthStatus.authenticated) {
      return const SizedBox.shrink();
    }

    final leagueAsync = ref.watch(myLeagueProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return leagueAsync.when(
      loading: () => const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (status) {
        final m = status.membership;
        final s = status.season;

        return GestureDetector(
          onTap: () => context.go('/league'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [AppColors.darkSurfaceHigh, AppColors.darkSurface]
                    : const [AppColors.primary, AppColors.lpGreen600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : AppColors.lpGreen700.withValues(alpha: 0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppColors.primary : AppColors.accent)
                      .withValues(alpha: isDark ? 0.16 : 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(m.tierIcon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.tierLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${m.rank} sıra  •  ${m.weeklyLp} LP  •  ${s.daysRemaining}g kaldı',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 12,
                        ),
                      ),
                      if (m.streakShields > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.shield_rounded,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${m.streakShields} Kalkan aktif',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  children: [
                    if (m.isInPromotionZone)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '↑ Terfi!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else if (m.lpToPromotion != null)
                      Column(
                        children: [
                          Text(
                            '+${m.lpToPromotion} LP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'terfiye',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
