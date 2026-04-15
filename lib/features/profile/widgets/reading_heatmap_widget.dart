import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/api/api_client.dart';

enum _HeatmapRange {
  month('1A', 4, 'Son 1 ay'),
  quarter('3A', 12, 'Son 3 ay'),
  halfYear('6A', 24, 'Son 6 ay'),
  year('Yıl', 52, 'Son 1 yıl');

  const _HeatmapRange(this.label, this.weeks, this.description);

  final String label;
  final int weeks;
  final String description;
}

class ReadingHeatmapWidget extends StatefulWidget {
  const ReadingHeatmapWidget({super.key});

  @override
  State<ReadingHeatmapWidget> createState() => _ReadingHeatmapWidgetState();
}

class _ReadingHeatmapWidgetState extends State<ReadingHeatmapWidget> {
  final ApiClient _client = ApiClient.instance;

  bool _isLoading = true;
  Map<String, int> _heatmapData = {};
  _HeatmapRange _selectedRange = _HeatmapRange.quarter;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final res = await _client.get('/stats/heatmap');
      final rawData = res.data['data'] as Map<String, dynamic>? ?? {};
      final mapped = <String, int>{};

      rawData.forEach((key, value) {
        final normalizedKey = _normalizeDateKey(key);
        if (normalizedKey != null) {
          mapped[normalizedKey] = int.tryParse(value.toString()) ?? 0;
        }
      });

      if (!mounted) return;
      setState(() {
        _heatmapData = mapped;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 170,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.6),
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final today = DateTime.now();
    final weeks = _buildWeeks(today, _selectedRange);
    final visibleDates = weeks.expand((week) => week);
    final visibleCounts = visibleDates
        .where((date) => !date.isAfter(today))
        .map((date) => _heatmapData[_dateKey(date)] ?? 0)
        .toList(growable: false);

    final activeDays = visibleCounts.where((value) => value > 0).length;
    final totalParagraphs = visibleCounts.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    final maxDailyCount = visibleCounts.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
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
                      'Okuma Haritası',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$activeDays aktif gün, $totalParagraphs paragraf.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _HeatmapRange.values
                .map((range) {
                  final isSelected = range == _selectedRange;
                  return InkWell(
                    onTap: () => setState(() => _selectedRange = range),
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.14)
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.25)
                              : theme.colorScheme.outline.withValues(
                                  alpha: 0.18,
                                ),
                        ),
                      ),
                      child: Text(
                        range.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            _selectedRange.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const columnSpacing = 2.0;
              const rowSpacing = 3.0;
              final weekCount = weeks.length;
              final cellSize =
                  ((constraints.maxWidth - (columnSpacing * (weekCount - 1))) /
                          weekCount)
                      .clamp(4.0, 11.0)
                      .toDouble();

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(weeks.length, (weekIndex) {
                  final week = weeks[weekIndex];
                  final isLastWeek = weekIndex == weeks.length - 1;

                  return Padding(
                    padding: EdgeInsets.only(
                      right: isLastWeek ? 0 : columnSpacing,
                    ),
                    child: Column(
                      children: week
                          .map((date) {
                            final isFuture = date.isAfter(today);
                            final count = isFuture
                                ? 0
                                : (_heatmapData[_dateKey(date)] ?? 0);

                            return Container(
                              width: cellSize,
                              height: cellSize,
                              margin: const EdgeInsets.only(bottom: rowSpacing),
                              decoration: BoxDecoration(
                                color: isFuture
                                    ? theme.colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.28)
                                    : _colorForCount(
                                        count,
                                        theme,
                                        maxDailyCount,
                                      ),
                                borderRadius: BorderRadius.circular(
                                  cellSize <= 5 ? 2 : 3,
                                ),
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Açık tonlar daha az, koyu tonlar daha yoğun okumayı gösterir.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Az',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              ...[0, 5, 20, 40, 80].map(
                (count) => Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: _colorForCount(count, theme, 80),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Çok',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  List<List<DateTime>> _buildWeeks(DateTime today, _HeatmapRange range) {
    final start = _startOfWeek(
      today.subtract(Duration(days: (range.weeks - 1) * 7)),
    );

    return List.generate(
      range.weeks,
      (weekIndex) => List.generate(
        7,
        (dayIndex) => start.add(Duration(days: (weekIndex * 7) + dayIndex)),
        growable: false,
      ),
      growable: false,
    );
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String? _normalizeDateKey(Object? rawKey) {
    if (rawKey == null) return null;

    final raw = rawKey.toString().trim();
    if (raw.isEmpty) return null;
    if (raw.length >= 10) {
      final leadingDate = raw.substring(0, 10);
      final parsedLeading = DateTime.tryParse(leadingDate);
      if (parsedLeading != null) {
        return _dateKey(parsedLeading);
      }
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return _dateKey(parsed);
  }

  Color _colorForCount(int count, ThemeData theme, int maxCount) {
    if (count <= 0) {
      return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.75);
    }

    final safeMax = maxCount <= 0 ? 1 : maxCount;
    final ratio = count / safeMax;

    if (ratio <= 0.25) return const Color(0xFFB8ECC7);
    if (ratio <= 0.5) return const Color(0xFF86DFA0);
    if (ratio <= 0.75) return const Color(0xFF47C96A);
    return const Color(0xFF19913B);
  }
}
