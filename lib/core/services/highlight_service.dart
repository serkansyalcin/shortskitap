import '../api/api_client.dart';
import '../models/highlight_model.dart';

class HighlightsPageResult {
  const HighlightsPageResult({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  final List<HighlightModel> items;
  final int total;
  final int currentPage;
  final int lastPage;
}

class HighlightService {
  final ApiClient _client = ApiClient.instance;

  Future<dynamic> getHighlights({int? bookId}) async {
    final res = await _client.get(
      '/highlights',
      params: bookId != null ? {'book_id': bookId} : null,
    );
    return res.data;
  }

  /// Sunucu [meta] dönmezse (eski API) tek sayfa varsayılır.
  Future<HighlightsPageResult> fetchHighlightsPage({
    int? bookId,
    int page = 1,
    int perPage = 30,
    bool kidsOnly = false,
  }) async {
    final params = <String, dynamic>{'page': page, 'per_page': perPage};
    if (bookId != null) {
      params['book_id'] = bookId;
    }
    if (kidsOnly) {
      params['kids_only'] = 1;
    }
    final res = await _client.get('/highlights', params: params);
    final data = res.data as Map<String, dynamic>? ?? {};
    final rawList = data['data'] as List<dynamic>? ?? const <dynamic>[];
    final items = rawList
        .map((item) => HighlightModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    final meta = data['meta'];
    if (meta is Map<String, dynamic>) {
      return HighlightsPageResult(
        items: items,
        total: (meta['total'] as num?)?.toInt() ?? items.length,
        currentPage: (meta['current_page'] as num?)?.toInt() ?? page,
        lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      );
    }

    return HighlightsPageResult(
      items: items,
      total: items.length,
      currentPage: 1,
      lastPage: 1,
    );
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
      data: {'note': note, 'color': color},
    );
    return res.data;
  }

  Future<void> deleteHighlight(int highlightId) async {
    await _client.delete('/highlights/$highlightId');
  }
}
