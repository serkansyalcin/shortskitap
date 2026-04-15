import 'package:flutter/material.dart';

class LeagueHistoryScreen extends StatelessWidget {
  const LeagueHistoryScreen({
    super.key,
    required this.history,
    this.title = 'Lig Geçmişi',
  });

  final List<Map<String, dynamic>> history;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: history.isEmpty
            ? ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: const [
                  _LeagueHistoryInfoCard(
                    title: 'Lig Geçmişi',
                    subtitle: 'Tamamlanan sezonlar burada görünecek.',
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Text(
                    '${history.length} tamamlanan sezon listeleniyor.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final maxExtent = constraints.maxWidth >= 720
                          ? 220.0
                          : constraints.maxWidth >= 420
                          ? 240.0
                          : 320.0;
                      final ratio = constraints.maxWidth >= 420 ? 1.7 : 1.55;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: history.length,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: maxExtent,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: ratio,
                        ),
                        itemBuilder: (context, index) {
                          final entry = history[index];
                          return _LeagueHistoryEntryCard(
                            season: entry['season'] as String? ?? 'Sezon',
                            tierLabel: entry['tier_label'] as String? ?? 'Lig',
                            resultLabel: _resultLabel(
                              entry['result'] as String?,
                            ),
                            rank: '#${entry['rank'] ?? '-'}',
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }

  static String _resultLabel(String? result) {
    return switch (result) {
      'promoted' => 'Terfi etti',
      'demoted' => 'Lig düştü',
      'stayed' => 'Yerini korudu',
      _ => 'Sonuç yok',
    };
  }
}

class _LeagueHistoryEntryCard extends StatelessWidget {
  const _LeagueHistoryEntryCard({
    required this.season,
    required this.tierLabel,
    required this.resultLabel,
    required this.rank,
  });

  final String season;
  final String tierLabel;
  final String resultLabel;
  final String rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _LeagueHistoryInfoCard(
      title: season,
      subtitle: tierLabel,
      trailingLabel: rank,
      footerText: resultLabel,
      theme: theme,
    );
  }
}

class _LeagueHistoryInfoCard extends StatelessWidget {
  const _LeagueHistoryInfoCard({
    required this.title,
    required this.subtitle,
    this.trailingLabel,
    this.footerText,
    this.theme,
  });

  final String title;
  final String subtitle;
  final String? trailingLabel;
  final String? footerText;
  final ThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final resolvedTheme = theme ?? Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: resolvedTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: resolvedTheme.colorScheme.outline.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: resolvedTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: resolvedTheme.colorScheme.onSurface,
                  ),
                ),
              ),
              if ((trailingLabel ?? '').isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: resolvedTheme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trailingLabel!,
                    style: resolvedTheme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: resolvedTheme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: resolvedTheme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: resolvedTheme.colorScheme.onSurface,
            ),
          ),
          if ((footerText ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              footerText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: resolvedTheme.textTheme.bodySmall?.copyWith(
                color: resolvedTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
