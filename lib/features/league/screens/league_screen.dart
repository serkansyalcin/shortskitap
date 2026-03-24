import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kitaplig/app/providers/auth_provider.dart';
import 'package:kitaplig/app/providers/kids_provider.dart';
import 'package:kitaplig/app/providers/league_provider.dart';
import 'package:kitaplig/core/models/league_model.dart';
import 'package:kitaplig/core/widgets/animated_segmented_control.dart';

import '../widgets/leaderboard_list.dart';
import '../widgets/league_header.dart';
import '../widgets/league_history.dart';
import '../widgets/league_empty_state.dart';
import 'package:kitaplig/app/providers/duel_provider.dart';
import 'package:kitaplig/core/models/duel_model.dart';
import 'package:go_router/go_router.dart';

enum _LeagueTab { leaderboard, duels, history }

class LeagueScreen extends ConsumerStatefulWidget {
  final bool embedded;

  const LeagueScreen({super.key, this.embedded = false});

  @override
  ConsumerState<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends ConsumerState<LeagueScreen> {
  _LeagueTab _tab = _LeagueTab.leaderboard;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.status == AuthStatus.unknown) {
      return _wrap(
        Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    final leagueAsync = ref.watch(myLeagueProvider);

    return _wrap(
      leagueAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        error: (_, __) => _LeagueErrorState(
          embedded: widget.embedded,
          onRetry: () => ref.refresh(myLeagueProvider),
        ),
        data: (status) => _LeagueContent(
          embedded: widget.embedded,
          tab: _tab,
          onTabChanged: (value) => setState(() => _tab = value),
          status: status,
          isKidsMode: ref.watch(kidsModeProvider),
        ),
      ),
    );
  }

  Widget _wrap(Widget child) {
    if (widget.embedded) {
      return child;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: child,
    );
  }
}

class _LeagueContent extends StatelessWidget {
  final bool embedded;
  final _LeagueTab tab;
  final ValueChanged<_LeagueTab> onTabChanged;
  final LeagueStatusModel status;
  final bool isKidsMode;

  const _LeagueContent({
    required this.embedded,
    required this.tab,
    required this.onTabChanged,
    required this.status,
    this.isKidsMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0E1712), Color(0xFF0A0A0A)]
              : const [Color(0xFFF7FAF5), Color(0xFFF0F5EF)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: LeagueHeader(
                status: status,
                showBackButton: !embedded,
                isKidsMode: isKidsMode,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: AnimatedSegmentedControl<_LeagueTab>(
                selected: tab,
                onChanged: onTabChanged,
                items: [
                  SegmentedItem(
                    value: _LeagueTab.leaderboard,
                    label: isKidsMode ? 'Sıralama' : 'Liderlik',
                    icon: Icons.emoji_events_rounded,
                  ),
                  const SegmentedItem(
                    value: _LeagueTab.duels,
                    label: 'Düellolar',
                    icon: Icons.bolt_rounded,
                  ),
                  const SegmentedItem(
                    value: _LeagueTab.history,
                    label: 'Geçmiş',
                    icon: Icons.history_rounded,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.75),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                        blurRadius: 26,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0.03, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: tab == _LeagueTab.leaderboard
                        ? KeyedSubtree(
                            key: const ValueKey('leaderboard'),
                            child: LeaderboardList(
                              membership: status.membership,
                              isKidsMode: isKidsMode,
                            ),
                          )
                        : tab == _LeagueTab.duels
                            ? const KeyedSubtree(
                                key: ValueKey('duels'),
                                child: _DuelTabContent(),
                              )
                            : const KeyedSubtree(
                                key: ValueKey('history'),
                                child: LeagueHistory(),
                              ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeagueErrorState extends StatelessWidget {
  final bool embedded;
  final VoidCallback onRetry;

  const _LeagueErrorState({required this.embedded, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [Color(0xFF0E1712), Color(0xFF0A0A0A)]
              : const [Color(0xFFF7FAF5), Color(0xFFF0F5EF)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.75),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: Color(0xFF22C55E),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Lig bilgisi şu an alınamadı',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    embedded
                        ? 'Sekmede kal, bağlantı toparlanınca tekrar deneyelim.'
                        : 'Bağlantını kontrol edip tekrar denersen lig ekranı yenilenecek.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DuelTabContent extends ConsumerWidget {
  const _DuelTabContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duelsAsync = ref.watch(duelStateProvider);

    return duelsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E))),
      error: (err, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 42, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text('Düellolar yüklenemedi: $err', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.read(duelStateProvider.notifier).loadDuels(),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      ),
      data: (duels) {
        if (duels.isEmpty) {
          return const LeagueEmptyState(
            icon: Icons.bolt_rounded,
            title: 'Aktif düellon yok',
            subtitle: 'Liderlik tablosundan rakiplerine meydan okuyarak kıyasıya rekabete başlayabilirsin!',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: duels.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final duel = duels[index];
            return _DuelListTile(duel: duel);
          },
        );
      },
    );
  }
}

class _DuelListTile extends StatelessWidget {
  final DuelModel duel;
  const _DuelListTile({required this.duel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => context.push('/duels/${duel.id}'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            _DuelStatusIcon(status: duel.status),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Text(
                        duel.challenger?.name ?? 'Ben',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('vs', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.redAccent)),
                      ),
                      Text(
                        duel.opponent?.name ?? 'Rakip',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    duel.status == 'pending' ? 'Onay bekliyor...' : 'Skor: ${duel.challengerScore} - ${duel.opponentScore}',
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DuelStatusIcon extends StatelessWidget {
  final String status;
  const _DuelStatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => Colors.orangeAccent,
      'pending' => Colors.blueAccent,
      'completed' => Colors.greenAccent,
      _ => Colors.grey,
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        status == 'pending' ? Icons.hourglass_top_rounded : Icons.bolt_rounded,
        color: color,
        size: 20,
      ),
    );
  }
}
