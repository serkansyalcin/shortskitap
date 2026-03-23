import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/api/api_client.dart';

class ReadingHeatmapWidget extends StatefulWidget {
  const ReadingHeatmapWidget({super.key});

  @override
  State<ReadingHeatmapWidget> createState() => _ReadingHeatmapWidgetState();
}

class _ReadingHeatmapWidgetState extends State<ReadingHeatmapWidget> {
  final ApiClient _client = ApiClient.instance;

  bool _isLoading = true;
  Map<String, int> _heatmapData = {};

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
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.6)),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final today = DateTime.now();
    final start = _startOfWeek(today.subtract(const Duration(days: 364)));
    final weeks = <List<DateTime>>[];

    for (
      var cursor = start;
      !cursor.isAfter(today);
      cursor = cursor.add(const Duration(days: 7))
    ) {
      weeks.add(
        List.generate(
          7,
          (index) => cursor.add(Duration(days: index)),
          growable: false,
        ),
      );
    }

    final activeDays = _heatmapData.values.where((value) => value > 0).length;
    final totalParagraphs =
        _heatmapData.values.fold<int>(0, (sum, value) => sum + value);
    final maxDailyCount = _heatmapData.values.fold<int>(
      0,
      (max, value) => value > max ? value : max,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.65)),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: weeks.map((week) {
                return Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Column(
                    children: week.map((date) {
                      final isFuture = date.isAfter(today);
                      final count =
                          isFuture ? 0 : (_heatmapData[_dateKey(date)] ?? 0);

                      return Container(
                        width: 11,
                        height: 11,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: isFuture
                              ? theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.28)
                              : _colorForCount(count, theme, maxDailyCount),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                );
              }).toList(growable: false),
            ),
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
