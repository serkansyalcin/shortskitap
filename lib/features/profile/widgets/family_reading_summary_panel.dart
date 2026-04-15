import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/family_reading_summary_model.dart';
import '../../../core/widgets/reader_profile_avatar.dart';

class FamilyReadingSummaryEntryCard extends StatelessWidget {
  const FamilyReadingSummaryEntryCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  final FamilyReadingSummaryModel summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topReader = summary.topReader;

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aile okuma özeti',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(topReader),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.72,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(FamilyReadingProfileStatModel? topReader) {
    final parts = <String>[
      summary.periodLabel,
      '${summary.totalParagraphs} paragraf',
    ];

    if (summary.activeProfiles > 0) {
      parts.add('${summary.activeProfiles} aktif profil');
    }

    if (topReader != null) {
      parts.add('En aktif ${topReader.profile.name}');
    }

    return parts.join(' • ');
  }
}

class FamilyReadingSummaryPanel extends StatelessWidget {
  const FamilyReadingSummaryPanel({
    super.key,
    required this.summary,
    this.maxVisibleProfiles = 999,
    this.parentAvatarUrl,
    this.showDescription = true,
    this.showHiddenProfilesHint = true,
  });

  final FamilyReadingSummaryModel summary;
  final int maxVisibleProfiles;
  final String? parentAvatarUrl;
  final bool showDescription;
  final bool showHiddenProfilesHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topReader = summary.topReader;
    final visibleProfiles = summary.profiles
        .take(maxVisibleProfiles)
        .toList(growable: false);
    final hiddenProfilesCount =
        summary.profiles.length - visibleProfiles.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aile özeti',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summary.periodLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (topReader != null)
                _SummaryPill(
                  label: 'En aktif ${topReader.profile.name}',
                  color: AppColors.primary,
                ),
            ],
          ),
          if (showDescription) ...[
            const SizedBox(height: 10),
            Text(
              'Aile hesabındaki profillerin son dönemdeki okuma yoğunluğunu ve tamamlanan kitaplarını burada görebilirsiniz.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                label: 'Paragraf',
                value: '${summary.totalParagraphs}',
              ),
              _MetricChip(
                label: 'Aktif profil',
                value: '${summary.activeProfiles}',
              ),
              _MetricChip(
                label: 'Tamamlanan',
                value: '${summary.completedBooks}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (summary.activeProfileStats.isEmpty)
            Text(
              'Bu dönemde aile profillerinde henüz okuma görünmüyor.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            )
          else
            Column(
              children: [
                ...visibleProfiles.map(
                  (profileSummary) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _FamilyProfileReadingTile(
                      summary: profileSummary,
                      periodEndDate: summary.endDate,
                      parentAvatarUrl: parentAvatarUrl,
                    ),
                  ),
                ),
                if (showHiddenProfilesHint && hiddenProfilesCount > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '+$hiddenProfilesCount profil daha var.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.14),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$value ',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            TextSpan(
              text: label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FamilyProfileReadingTile extends StatelessWidget {
  const _FamilyProfileReadingTile({
    required this.summary,
    required this.periodEndDate,
    this.parentAvatarUrl,
  });

  final FamilyReadingProfileStatModel summary;
  final DateTime? periodEndDate;
  final String? parentAvatarUrl;

  String? _avatarRef() {
    final avatarRef = summary.profile.avatarUrl?.trim();
    if (avatarRef != null && avatarRef.isNotEmpty) {
      return avatarRef;
    }
    if (summary.profile.isParent) {
      final parentAvatar = parentAvatarUrl?.trim();
      if (parentAvatar != null && parentAvatar.isNotEmpty) {
        return parentAvatar;
      }
      return null;
    }
    return ReaderProfileAvatarCatalog.suggestedTokenValue(
      index: summary.profile.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ReaderProfileAvatar(
                name: summary.profile.name,
                avatarRef: _avatarRef(),
                size: 40,
                borderRadius: BorderRadius.circular(14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          summary.profile.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (summary.profile.isParent)
                          _SummaryPill(
                            label: 'Ebeveyn',
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${summary.totalParagraphs}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'paragraf',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MiniActivityStrip(heatmap: summary.heatmap, endDate: periodEndDate),
        ],
      ),
    );
  }

  String _subtitle() {
    if (!summary.hasActivity) {
      return 'Bu dönemde henüz okuma görünmüyor.';
    }

    final parts = <String>['${summary.activeDays} aktif gün'];

    if (summary.completedBooks > 0) {
      parts.add('${summary.completedBooks} kitap tamamlandı');
    }

    if (summary.totalMinutes > 0) {
      parts.add('${summary.totalMinutes} dk');
    }

    return parts.join(' • ');
  }
}

class _MiniActivityStrip extends StatelessWidget {
  const _MiniActivityStrip({required this.heatmap, this.endDate});

  final Map<String, int> heatmap;
  final DateTime? endDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateUtils.dateOnly(endDate ?? DateTime.now());
    final dates = List<DateTime>.generate(
      14,
      (index) => today.subtract(Duration(days: 13 - index)),
      growable: false,
    );
    final maxCount = heatmap.values.fold<int>(
      0,
      (currentMax, value) => value > currentMax ? value : currentMax,
    );

    return Row(
      children: [
        Expanded(
          child: Row(
            children: dates
                .map(
                  (date) => Expanded(
                    child: Container(
                      height: 8,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: _colorForCount(
                          theme,
                          heatmap[_key(date)] ?? 0,
                          maxCount,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '14 gün',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _key(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Color _colorForCount(ThemeData theme, int count, int maxCount) {
    if (count <= 0) {
      return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.72);
    }

    final safeMax = maxCount <= 0 ? 1 : maxCount;
    final ratio = (count / safeMax).clamp(0.0, 1.0);

    if (ratio >= 0.8) {
      return AppColors.primary;
    }
    if (ratio >= 0.5) {
      return AppColors.primary.withValues(alpha: 0.8);
    }
    if (ratio >= 0.25) {
      return AppColors.primary.withValues(alpha: 0.55);
    }
    return AppColors.primary.withValues(alpha: 0.28);
  }
}
