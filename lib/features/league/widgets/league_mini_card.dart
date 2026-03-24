import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitaplig/app/providers/auth_provider.dart';
import 'package:kitaplig/app/providers/league_provider.dart';

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

    return leagueAsync.when(
      loading: () => const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) {
        final m = status.membership;
        final s = status.season;
        final tierColor = Color(
          int.parse(m.tierColor.replaceFirst('#', 'FF'), radix: 16),
        );

        return GestureDetector(
          onTap: () => context.go('/league'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [tierColor, tierColor.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: tierColor.withOpacity(0.35),
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
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      if (m.streakShields > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.shield_rounded, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              '${m.streakShields} Kalkan Aktif',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
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
                // Mini progress to promotion
                Column(
                  children: [
                    if (m.isInPromotionZone)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
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
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
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
