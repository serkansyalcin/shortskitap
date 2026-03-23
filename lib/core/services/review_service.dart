import '../api/api_client.dart';

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
        if (comment != null && comment.trim().isNotEmpty) 'comment': comment.trim(),
      },
    );
  }

  Future<dynamic> getReviews(int bookId) async {
    final res = await _client.get('/books/$bookId/reviews');
    return res.data;
  }
}
