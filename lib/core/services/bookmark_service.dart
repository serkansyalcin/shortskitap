import '../api/api_client.dart';
import '../models/bookmark_model.dart';

class BookmarkService {
  final ApiClient _client = ApiClient.instance;

  Future<List<BookmarkModel>> getBookmarks() async {
    final res = await _client.get('/bookmarks');
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => BookmarkModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
