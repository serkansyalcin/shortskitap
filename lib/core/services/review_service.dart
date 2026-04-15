import '../api/api_client.dart';
import '../models/review_model.dart';

class ReviewPageResult {
  const ReviewPageResult({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.averageRating,
  });

  final List<ReviewModel> items;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final double? averageRating;

  bool get hasMore => currentPage < lastPage;
}

class ReviewService {
  final ApiClient _client = ApiClient.instance;

  Future<void> submitReview({
    required int bookId,
    required int rating,
    String? comment,
  }) async {
    await _client.post(
      '/books/$bookId/reviews',
      data: {
        'rating': rating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
  }

  Future<ReviewPageResult> fetchReviewsPage({
    required int bookId,
    int page = 1,
    int perPage = 15,
  }) async {
    final res = await _client.get(
      '/books/$bookId/reviews',
      params: {'page': page, 'per_page': perPage},
    );
    final body = res.data;
    if (body is! Map<String, dynamic>) {
      return const ReviewPageResult(
        items: [],
        currentPage: 1,
        lastPage: 1,
        perPage: 15,
        total: 0,
      );
    }

    final rawList = body['data'];
    List<dynamic> list;
    if (rawList is List<dynamic>) {
      list = rawList;
    } else if (rawList is Map<String, dynamic> &&
        rawList['data'] is List<dynamic>) {
      list = rawList['data'] as List<dynamic>;
    } else {
      list = const [];
    }

    final items = list
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    final meta = body['meta'];
    if (meta is Map<String, dynamic>) {
      return ReviewPageResult(
        items: items,
        currentPage: (meta['current_page'] as num?)?.toInt() ?? page,
        lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
        perPage: (meta['per_page'] as num?)?.toInt() ?? perPage,
        total: (meta['total'] as num?)?.toInt() ?? items.length,
        averageRating: (meta['average_rating'] as num?)?.toDouble(),
      );
    }

    return ReviewPageResult(
      items: items,
      currentPage: 1,
      lastPage: 1,
      perPage: perPage,
      total: items.length,
    );
  }
}
