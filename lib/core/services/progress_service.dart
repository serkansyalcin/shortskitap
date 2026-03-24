import '../api/api_client.dart';
import '../models/progress_model.dart';

class ProgressService {
  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> syncProgress(
    int bookId,
    int lastParagraphOrder,
    int sessionSeconds,
    DateTime readAt,
  ) async {
    final isWeekend =
        readAt.weekday == DateTime.saturday ||
        readAt.weekday == DateTime.sunday;
    final isNightOwl = readAt.hour >= 22 || readAt.hour < 4;

    final res = await _client.post(
      '/progress',
      data: {
        'book_id': bookId,
        'last_paragraph_order': lastParagraphOrder,
        'session_seconds': sessionSeconds,
        'read_at_local': readAt.toIso8601String(),
        'read_hour_local': readAt.hour,
        'read_weekday_local': readAt.weekday,
        'is_weekend_local': isWeekend,
        'timezone_name': readAt.timeZoneName,
        'timezone_offset_minutes': readAt.timeZoneOffset.inMinutes,
        'client_achievement_context': {
          'night_owl_candidate': isNightOwl,
          'weekend_warrior_candidate': isWeekend,
        },
      },
    );
    return res.data['data'] as Map<String, dynamic>;
  }

  Future<List<ProgressModel>> getProgress() async {
    final res = await _client.get('/progress');
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => ProgressModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProgressModel?> getBookProgress(int bookId) async {
    try {
      final res = await _client.get('/progress/$bookId');
      final data = res.data['data'];
      if (data == null) return null;
      return ProgressModel.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
