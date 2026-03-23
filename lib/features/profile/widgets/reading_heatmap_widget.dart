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
      
      final Map<String, int> mapped = {};
      rawData.forEach((key, value) {
        mapped[key] = int.tryParse(value.toString()) ?? 0;
      });
      
      if (mounted) {
        setState(() {
          _heatmapData = mapped;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getColorForCount(int count) {
    if (count == 0) return Colors.white.withOpacity(0.05);
    if (count < 10) return AppColors.primary.withOpacity(0.3);
    if (count < 30) return AppColors.primary.withOpacity(0.6);
    if (count < 60) return AppColors.primary.withOpacity(0.8);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final today = DateTime.now();
    final firstDay = today.subtract(const Duration(days: 364));
    
    // We want a horizontal grid that scrolls right.
    // 53 columns * 7 rows.
    
    // Generate the grid arrays
    final List<List<DateTime>> columns = [];
    DateTime currentDate = firstDay;
    
    // Adjust start date to be Sunday of that week for standard alignment
    while (currentDate.weekday != DateTime.sunday) {
      currentDate = currentDate.subtract(const Duration(days: 1));
    }
    
    while (currentDate.isBefore(today) || currentDate.isAtSameMomentAs(today)) {
      List<DateTime> week = [];
      for (int i = 0; i < 7; i++) {
        week.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }
      columns.add(week);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Okuma Haritası',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              reverse: true, // Scroll to end (now)
              itemCount: columns.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, colIndex) {
                // Because reverse is true, we render backwards
                final reversedIndex = columns.length - 1 - colIndex;
                final week = columns[reversedIndex];
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: week.map((date) {
                    if (date.isAfter(today)) {
                      return const SizedBox(width: 12, height: 12);
                    }
                    
                    final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                    final count = _heatmapData[dateString] ?? 0;
                    
                    return Tooltip(
                      message: '$dateString: $count paragraf',
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getColorForCount(count),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Az', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(width: 4),
              Container(width: 10, height: 10, decoration: BoxDecoration(color: _getColorForCount(0), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 2),
              Container(width: 10, height: 10, decoration: BoxDecoration(color: _getColorForCount(5), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 2),
              Container(width: 10, height: 10, decoration: BoxDecoration(color: _getColorForCount(20), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 2),
              Container(width: 10, height: 10, decoration: BoxDecoration(color: _getColorForCount(40), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 2),
              Container(width: 10, height: 10, decoration: BoxDecoration(color: _getColorForCount(100), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 4),
              Text('Çok', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          )
        ],
      ),
    );
  }
}
