import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitaplig/app/providers/league_provider.dart';
import 'package:kitaplig/core/models/league_model.dart';

import '../../subscription/widgets/premium_badge.dart';

class LeaderboardList extends ConsumerWidget {
  final LeagueMembershipModel membership;

  const LeaderboardList({super.key, required this.membership});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardAsync = ref.watch(leaderboardProvider);

    return boardAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF22C55E)),
      ),
      error: (_, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: Colors.white.withValues(alpha: 0.72),
              ),
              const SizedBox(height: 12),
              const Text(
                'Liderlik tablosu yüklenemedi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => ref.refresh(leaderboardProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const _LeagueEmptyState(
            icon: Icons.groups_rounded,
            title: 'Henüz grup oluşmadı',
            subtitle:
                'Katılımcılar yerleştiğinde liderlik tablosu burada görünecek.',
          );
        }

        final widgets = _buildRows(entries);

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          children: widgets,
        );
      },
    );
  }

  List<Widget> _buildRows(List<LeaderboardEntry> entries) {
    final rows = <Widget>[
      _LeagueSummaryCard(membership: membership),
      const SizedBox(height: 14),
    ];

    for (final entry in entries) {
      if (entry.rank == membership.promotionZone + 1) {
        rows.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: _ZoneDivider(
              label: 'Terfi çizgisi',
              color: Color(0xFF4ADE80),
            ),
          ),
        );
      }

      if (entry.rank == membership.demotionZone) {
        rows.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: _ZoneDivider(
              label: 'Düşme çizgisi',
              color: Color(0xFFF87171),
            ),
          ),
        );
      }

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _LeaderboardTile(
            entry: entry,
            isPromotionZone: entry.rank <= membership.promotionZone,
            isDemotionZone: entry.rank >= membership.demotionZone,
          ),
        ),
      );
    }

    return rows;
  }
}

class _LeagueSummaryCard extends StatelessWidget {
  final LeagueMembershipModel membership;

  const _LeagueSummaryCard({required this.membership});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.insights_rounded, color: Color(0xFF22C55E)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bu haftaki konumun',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '#${membership.rank} sıradasın · ${membership.weeklyXp} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    final borderColor = entry.isMe
        ? const Color(0xFFFBBF24)
        : isPromotionZone
        ? const Color(0xFF4ADE80)
        : isDemotionZone
        ? const Color(0xFFF87171)
        : const Color(0xFF262626);

    final background = entry.isMe
        ? const Color(0xFF201A08)
        : isPromotionZone
        ? const Color(0xFF102014)
        : isDemotionZone
        ? const Color(0xFF231212)
        : const Color(0xFF151515);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _RankBadge(rank: entry.rank),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: entry.isMe
                              ? FontWeight.w800
                              : FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    if (entry.isPremium) ...[
                      const SizedBox(width: 6),
                      const PremiumCrownIcon(size: 14),
                    ],
                    if (entry.isMe) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Sen',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _resultLabel(entry.resultPreview),
                  style: TextStyle(
                    color: _resultColor(entry.resultPreview),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Haftalık XP',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.weeklyXp}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _resultLabel(String result) {
    return switch (result) {
      'promoted' => 'Terfi hattında',
      'demoted' => 'Düşme hattında',
      _ => 'Sabit bölgede',
    };
  }

  Color _resultColor(String result) {
    return switch (result) {
      'promoted' => const Color(0xFF4ADE80),
      'demoted' => const Color(0xFFF87171),
      _ => Colors.white70,
    };
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank == 1)
      return const Icon(
        Icons.workspace_premium,
        color: Color(0xFFFBBF24),
        size: 30,
      );
    if (rank == 2)
      return const Icon(
        Icons.workspace_premium,
        color: Color(0xFFD1D5DB),
        size: 30,
      );
    if (rank == 3)
      return const Icon(
        Icons.workspace_premium,
        color: Color(0xFFB45309),
        size: 30,
      );

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ZoneDivider extends StatelessWidget {
  final String label;
  final Color color;

  const _ZoneDivider({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: color.withValues(alpha: 0.7))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(child: Divider(color: color.withValues(alpha: 0.7))),
      ],
    );
  }
}

class _LeagueEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _LeagueEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: const Color(0xFF22C55E)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
