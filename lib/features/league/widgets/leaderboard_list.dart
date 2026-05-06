import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitaplig/app/providers/duel_provider.dart';
import 'package:kitaplig/app/providers/league_provider.dart';
import 'package:kitaplig/app/theme/app_colors.dart';
import 'package:kitaplig/core/models/league_model.dart';

import '../../subscription/widgets/premium_badge.dart';
import 'league_empty_state.dart';

class LeaderboardList extends ConsumerWidget {
  const LeaderboardList({
    super.key,
    required this.membership,
    this.isKidsMode = false,
  });

  final LeagueMembershipModel membership;
  final bool isKidsMode;

  static const _dangerColor = Color(0xFFD95C5C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final boardState = ref.watch(leaderboardProvider);

    if (boardState.isLoading && boardState.entries.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (boardState.error != null && boardState.entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 42,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                'Liderlik tablosu yüklenemedi',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(leaderboardProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }

    final entries = boardState.entries;
    if (entries.isEmpty) {
      return const LeagueEmptyState(
        icon: Icons.groups_rounded,
        title: 'Henüz grup oluşmadı',
        subtitle:
            'Katılımcılar yerleştiğinde liderlik tablosu burada görünecek.',
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._buildRows(entries),
        if (boardState.hasMore || boardState.isLoadingMore)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Center(
              child: boardState.isLoadingMore
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(leaderboardProvider.notifier).loadMore(),
                      icon: const Icon(Icons.expand_more_rounded),
                      label: const Text('Daha fazla göster'),
                    ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildRows(List<LeaderboardEntry> entries) {
    final rows = <Widget>[];

    for (final entry in entries) {
      if (entry.rank == membership.promotionZone + 1) {
        rows.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: _ZoneDivider(
              label: 'Terfi çizgisi',
              color: AppColors.primary,
            ),
          ),
        );
      }

      if (entry.rank == membership.demotionZone) {
        rows.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: _ZoneDivider(label: 'Düşme çizgisi', color: _dangerColor),
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
            isKidsMode: isKidsMode,
          ),
        ),
      );
    }

    return rows;
  }
}


class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.entry,
    required this.isPromotionZone,
    required this.isDemotionZone,
    this.isKidsMode = false,
  });

  final LeaderboardEntry entry;
  final bool isPromotionZone;
  final bool isDemotionZone;
  final bool isKidsMode;

  static const _dangerColor = Color(0xFFD95C5C);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final background = entry.isMe
        ? (isDark ? AppColors.primary.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.06))
        : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: entry.isMe 
          ? Border.all(color: AppColors.primary.withValues(alpha: 0.2)) 
          : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _RankBadge(rank: entry.rank),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: entry.username.isEmpty || (isKidsMode && !entry.isMe)
                      ? null
                      : () => context.push('/profil/${entry.username}'),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                                  color: theme.colorScheme.onSurface,
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
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Sen',
                                  style: TextStyle(
                                    color: Colors.white,
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
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.weeklyLp}',
                    style: TextStyle(
                      color: isPromotionZone ? AppColors.primary : (isDemotionZone ? _dangerColor : theme.colorScheme.onSurface),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    isKidsMode ? 'Puan' : 'LP',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!entry.isMe) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                ref.watch(duelStateProvider);
                final duelNotifier = ref.read(duelStateProvider.notifier);
                final existingDuel = duelNotifier.findOpenDuelWithUser(
                  entry.userId,
                  otherReaderProfileId: entry.readerProfileId,
                );
                final hasIncomingPending =
                    existingDuel != null &&
                    existingDuel.isPending &&
                    (entry.readerProfileId != null
                        ? existingDuel.challengerReaderProfileId ==
                              entry.readerProfileId
                        : existingDuel.challengerId == entry.userId);
                final actionLabel = existingDuel == null
                    ? 'Düello et'
                    : existingDuel.isActive
                    ? 'Düelloya git'
                    : hasIncomingPending
                    ? 'Teklifi gör'
                    : 'Gönderildi';
                final promptLabel = existingDuel == null
                    ? 'Rekabet etmek ister misin?'
                    : existingDuel.isActive
                    ? 'Bu kullanıcıyla aktif bir düellon var.'
                    : hasIncomingPending
                    ? 'Bu kullanıcıdan gelen teklif seni bekliyor.'
                    : 'Teklif gönderildi, cevap bekleniyor.';

                Future<void> handlePressed() async {
                  if (existingDuel != null) {
                    context.push('/duels/${existingDuel.id}');
                    return;
                  }

                  final result = await duelNotifier.challenge(
                    entry.userId,
                    opponentReaderProfileId: entry.readerProfileId,
                  );
                  if (!context.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(result.message)));
                }

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        promptLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 32,
                      child: OutlinedButton.icon(
                        onPressed: handlePressed,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.bolt_rounded, size: 14),
                        label: Text(
                          actionLabel,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String _resultLabel(String result) {
    return switch (result) {
      'promoted' => isKidsMode ? 'Ödül bölgesinde' : 'Terfi hattında',
      'demoted' => isKidsMode ? 'Dikkat bölgesinde' : 'Düşme hattında',
      _ => isKidsMode ? 'Orta sırada' : 'Sabit bölgede',
    };
  }

  Color _resultColor(String result) {
    return switch (result) {
      'promoted' => AppColors.primary,
      'demoted' => _dangerColor,
      _ => AppColors.lpDGreen300,
    };
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (rank == 1) {
      return const Icon(
        Icons.workspace_premium,
        color: Color(0xFFB5892E),
        size: 30,
      );
    }
    if (rank == 2) {
      return const Icon(
        Icons.workspace_premium,
        color: Color(0xFF94A3B8),
        size: 30,
      );
    }
    if (rank == 3) {
      return const Icon(
        Icons.workspace_premium,
        color: Color(0xFF8F6135),
        size: 30,
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceMuted
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ZoneDivider extends StatelessWidget {
  const _ZoneDivider({required this.label, required this.color});

  final String label;
  final Color color;

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
