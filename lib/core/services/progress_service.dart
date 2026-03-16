import '../api/api_client.dart';
import '../models/progress_model.dart';

class ProgressService {
  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> syncProgress(
    int bookId,
    int lastParagraphOrder,
    int sessionSeconds,
  ) async {
    final res = await _client.post('/progress', data: {
      'book_id': bookId,
      'last_paragraph_order': lastParagraphOrder,
      'session_seconds': sessionSeconds,
    });
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
