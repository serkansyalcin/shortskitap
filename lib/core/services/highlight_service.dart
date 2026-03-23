import '../api/api_client.dart';

class HighlightService {
  final ApiClient _client = ApiClient.instance;

  Future<dynamic> getHighlights({int? bookId}) async {
    final res = await _client.get(
      '/highlights',
      queryParameters: bookId != null ? {'book_id': bookId} : null,
    );
    return res.data;
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
