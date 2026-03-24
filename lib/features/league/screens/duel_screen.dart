import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitaplig/app/providers/duel_provider.dart';
import 'package:kitaplig/core/models/duel_model.dart';
import 'package:kitaplig/app/theme/app_colors.dart';

class DuelScreen extends ConsumerWidget {
  final int duelId;

  const DuelScreen({super.key, required this.duelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duelAsync = ref.watch(duelDetailsProvider(duelId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Düello Detayı'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: duelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(child: Text('Hata: $err')),
        data: (duel) => _DuelContent(duel: duel),
      ),
    );
  }
}

class _DuelContent extends StatelessWidget {
  final DuelModel duel;

  const _DuelContent({required this.duel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1A1A1A), const Color(0xFF0A0A0A)]
              : [const Color(0xFFF0F4FF), Colors.white],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _VersusHeader(duel: duel),
            const SizedBox(height: 40),
            _ProgressComparison(duel: duel),
            const SizedBox(height: 40),
            _DuelStats(duel: duel),
            const Spacer(),
            if (duel.isPending) _PendingActions(duel: duel),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _VersusHeader extends StatelessWidget {
  final DuelModel duel;
  const _VersusHeader({required this.duel});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _UserAvatar(user: duel.challenger, score: duel.challengerScore, label: 'Meydan Okuyan'),
        const Text(
          'VS',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Colors.redAccent,
          ),
        ),
        _UserAvatar(user: duel.opponent, score: duel.opponentScore, label: 'Rakip'),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final DuelUserModel? user;
  final int score;
  final String label;

  const _UserAvatar({this.user, required this.score, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primary.withOpacity(0.2),
          backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
          child: user?.avatarUrl == null ? const Icon(Icons.person, size: 40) : null,
        ),
        const SizedBox(height: 12),
        Text(
          user?.name ?? 'Bilinmiyor',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ProgressComparison extends StatelessWidget {
  final DuelModel duel;
  const _ProgressComparison({required this.duel});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${duel.challengerScore} Paragraf', style: const TextStyle(fontWeight: FontWeight.w900)),
              Text('${duel.opponentScore} Paragraf', style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 24,
              child: LinearProgressIndicator(
                value: duel.progressRatio,
                backgroundColor: Colors.blueAccent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DuelStats extends StatelessWidget {
  final DuelModel duel;
  const _DuelStats({required this.duel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          _StatRow(label: 'Kalan Süre', value: _formatDuration(duel.timeRemaining)),
          const Divider(),
          _StatRow(label: 'Ödül', value: '${duel.pointsAtStake} LP'),
          const Divider(),
          _StatRow(label: 'Durum', value: _statusLabel(duel.status)),
        ],
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '$hours s $minutes dk';
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'Onay Bekliyor',
      'active' => 'Devam Ediyor',
      'completed' => 'Tamamlandı',
      _ => status,
    };
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.redAccent)),
        ],
      ),
    );
  }
}

class _PendingActions extends ConsumerWidget {
  final DuelModel duel;
  const _PendingActions({required this.duel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => ref.read(duelStateProvider.notifier).decline(duel.id),
              child: const Text('Reddet'),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: FilledButton(
              onPressed: () => ref.read(duelStateProvider.notifier).accept(duel.id),
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Kabul Et'),
            ),
          ),
        ],
      ),
    );
  }
}
