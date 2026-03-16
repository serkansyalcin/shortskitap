import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitaplig/app/providers/league_provider.dart';

class LeagueHistory extends ConsumerWidget {
  const LeagueHistory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(leagueHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (history) {
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📖', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  'Henüz geçmiş sezon yok',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'İlk sezonun bitmesini bekle!',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, i) => _HistoryCard(entry: history[i]),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final result = entry['result'] as String?;
    final (resultIcon, resultText, resultColor) = switch (result) {
      'promoted' => ('↑', 'Terfi Etti', Colors.green.shade600),
      'demoted'  => ('↓', 'Düştü', Colors.red.shade500),
      'stayed'   => ('→', 'Kaldı', Colors.grey.shade500),
      _          => ('—', 'Tamamlanmadı', Colors.grey.shade400),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            entry['tier_icon'] as String? ?? '🏅',
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['season'] as String? ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  entry['tier_label'] as String? ?? '',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 2),
                  Text(
                    '${entry['weekly_xp']} XP',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(resultIcon,
                      style: TextStyle(
                          color: resultColor, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 3),
                  Text(resultText,
                      style: TextStyle(
                          color: resultColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              if (entry['rank'] != null)
                Text(
                  '#${entry['rank']}. sıra',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
