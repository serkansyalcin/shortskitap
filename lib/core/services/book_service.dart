import '../api/api_client.dart';
import '../models/book_model.dart';
import '../models/category_model.dart';
import '../models/paragraph_model.dart';

class BookService {
  final ApiClient _client = ApiClient.instance;

  Future<List<BookModel>> getBooks({
    String? category,
    String? sort,
    int page = 1,
    bool isKids = false,
  }) async {
    final res = await _client.get(
      '/books',
      params: {
        if (category != null) 'category': category,
        if (sort != null) 'sort': sort,
        'is_kids': isKids ? 1 : 0,
        'page': page,
        'per_page': 20,
      },
    );
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookModel>> getFeatured({bool isKids = false}) async {
    final res = await _client.get(
      '/books/featured',
      params: {'is_kids': isKids ? 1 : 0},
    );
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookModel> getBook(String slug) async {
    final res = await _client.get('/books/$slug');
    return BookModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<CategoryModel>> getCategories({bool isKids = false}) async {
    final res = await _client.get(
      '/categories',
      params: {'isKids': isKids ? 1 : 0},
    );
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookModel>> search(String query) async {
    final res = await _client.get('/search', params: {'q': query});
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ParagraphModel>> getParagraphs(
    int bookId, {
    int fromOrder = 0,
    int limit = 50,
  }) async {
    final res = await _client.get(
      '/books/$bookId/paragraphs',
      params: {'from_order': fromOrder, 'limit': limit},
    );
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => ParagraphModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ParagraphModel>> getAllParagraphs(
    int bookId, {
    int batchSize = 200,
  }) async {
    final paragraphs = <ParagraphModel>[];
    var fromOrder = 0;

    while (true) {
      final batch = await getParagraphs(
        bookId,
        fromOrder: fromOrder,
        limit: batchSize,
      );
      if (batch.isEmpty) break;

      paragraphs.addAll(batch);
      if (batch.length < batchSize) break;

      fromOrder = batch.last.sortOrder + 1;
    }

    return paragraphs;
  }
}
