import '../api/api_client.dart';
import '../models/highlight_model.dart';

class HighlightService {
  final ApiClient _client = ApiClient.instance;

  Future<dynamic> getHighlights({int? bookId}) async {
    final res = await _client.get(
      '/highlights',
      params: bookId != null ? {'book_id': bookId} : null,
    );
    return res.data;
  }

  Future<List<HighlightModel>> getHighlightsList({int? bookId}) async {
    final data = await getHighlights(bookId: bookId);
    final items = (data['data'] as List<dynamic>? ?? const <dynamic>[]);
    return items
        .map((item) => HighlightModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<dynamic> createHighlight({
    required int bookId,
    int? paragraphId,
    required String text,
    String? note,
    String? color,
  }) async {
    final res = await _client.post(
      '/highlights',
      data: {
        'book_id': bookId,
        'paragraph_id': paragraphId,
        'text': text,
        'note': note,
        'color': color,
      },
    );
    return res.data;
  }

  Future<dynamic> updateHighlight({
    required int highlightId,
    String? note,
    String? color,
  }) async {
    final res = await _client.put(
      '/highlights/$highlightId',
      data: {
        'note': note,
        'color': color,
      },
    );
    return res.data;
  }

  Future<void> deleteHighlight(int highlightId) async {
    await _client.delete('/highlights/$highlightId');
  }
}
