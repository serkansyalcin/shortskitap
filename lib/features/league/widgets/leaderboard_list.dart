import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitaplig/app/providers/league_provider.dart';
import 'package:kitaplig/app/theme/app_colors.dart';
import 'package:kitaplig/core/models/league_model.dart';
import '../../subscription/widgets/premium_badge.dart';

class LeaderboardList extends ConsumerWidget {
  final LeagueMembershipModel membership;

  const LeaderboardList({super.key, required this.membership});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(leaderboardProvider);

    return boardAsync.when(
      loading: () => Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Liderboard yüklenemedi',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => ref.refresh(leaderboardProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
      data: (entries) => _buildList(entries),
    );
  }

  Widget _buildList(List<LeaderboardEntry> entries) {
    final promotionZone = membership.promotionZone;
    final demotionZone = membership.demotionZone;
    final groupSize = membership.groupSize;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: entries.length + 2, // +2 for zone dividers
      itemBuilder: (context, index) {
        // Calculate effective index accounting for zone headers
        if (index == promotionZone) {
          return _ZoneDivider(
            label: '— Terfi Bölgesi Sınırı —',
            color: Colors.green.shade400,
          );
        }
        if (index == groupSize - (groupSize - demotionZone + 1) + 1) {
          return _ZoneDivider(
            label: '— Düşme Bölgesi Sınırı —',
            color: Colors.red.shade400,
          );
        }

        final effectiveIndex = index > promotionZone ? index - 1 : index;
        if (effectiveIndex >= entries.length) return const SizedBox.shrink();
        final entry = entries[effectiveIndex];

        return _LeaderboardTile(
          entry: entry,
          isPromotionZone: entry.rank <= promotionZone,
          isDemotionZone: entry.rank >= demotionZone,
        );
      },
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isPromotionZone;
  final bool isDemotionZone;

  const _LeaderboardTile({
    required this.entry,
    required this.isPromotionZone,
    required this.isDemotionZone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;

    final bgColor = entry.isMe
        ? (isDark ? Colors.amber.shade900.withOpacity(0.3) : Colors.amber.shade50)
        : isPromotionZone
            ? (isDark ? Colors.green.shade900.withOpacity(0.2) : Colors.green.shade50)
            : isDemotionZone
                ? (isDark ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade50)
                : cardColor;

    final borderColor = entry.isMe
        ? Colors.amber.shade400
        : isPromotionZone
            ? Colors.green.shade400
            : isDemotionZone
                ? Colors.red.shade400
                : (isDark ? AppColors.outline : Colors.grey.shade200);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: entry.isMe
            ? [BoxShadow(color: Colors.amber.shade200, blurRadius: 6)]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _RankBadge(rank: entry.rank),
        title: Row(
          children: [
            Text(
              entry.name,
              style: TextStyle(
                fontWeight: entry.isMe ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (entry.isPremium) ...[
              const SizedBox(width: 5),
              const PremiumCrownIcon(size: 14),
            ],
            if (entry.isMe) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Sen',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('⚡',
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 2),
                Text(
                  '${entry.weeklyXp}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            _ResultPreviewBadge(result: entry.resultPreview),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank == 1) return const Text('🥇', style: TextStyle(fontSize: 28));
    if (rank == 2) return const Text('🥈', style: TextStyle(fontSize: 28));
    if (rank == 3) return const Text('🥉', style: TextStyle(fontSize: 28));

    final theme = Theme.of(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _ResultPreviewBadge extends StatelessWidget {
  final String result;
  const _ResultPreviewBadge({required this.result});

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (result) {
      'promoted' => ('↑ Terfi', Colors.green.shade600),
      'demoted'  => ('↓ Düşer', Colors.red.shade500),
      _          => ('→ Kalır', Colors.grey.shade500),
    };

    return Text(text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500));
  }
}

class _ZoneDivider extends StatelessWidget {
  final String label;
  final Color color;
  const _ZoneDivider({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Divider(color: color, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Divider(color: color, thickness: 1)),
        ],
      ),
    );
  }
}
