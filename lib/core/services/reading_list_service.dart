import '../api/api_client.dart';
import '../models/reading_list_model.dart';

class ReadingListService {
  final ApiClient _client = ApiClient.instance;

  Future<List<ReadingListModel>> getLists() async {
    final res = await _client.get('/me/reading-lists');
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => ReadingListModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReadingListModel> createList({
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    final res = await _client.post('/me/reading-lists', data: {
      'name': name,
      if (description?.trim().isNotEmpty == true) 'description': description!.trim(),
      'is_public': isPublic,
    });
    return ReadingListModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ReadingListModel> updateList(
    int listId, {
    String? name,
    String? description,
    bool? isPublic,
  }) async {
    final res = await _client.patch('/me/reading-lists/$listId', data: {
      'name': name,
      'description': description,
      'is_public': isPublic,
    });
    return ReadingListModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteList(int listId) =>
      _client.delete('/me/reading-lists/$listId');

  Future<ReadingListModel> addBook(int listId, int bookId) async {
    final res = await _client.post(
      '/me/reading-lists/$listId/books',
      data: {'book_id': bookId},
    );
    return ReadingListModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ReadingListModel> removeBook(int listId, int bookId) async {
    final res = await _client.delete('/me/reading-lists/$listId/books/$bookId');
    return ReadingListModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<ReadingListBookItem>> getListBooks(int listId) async {
    final res = await _client.get('/me/reading-lists/$listId/books');
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => ReadingListBookItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns all lists + which lists already contain [bookId].
  Future<({List<ReadingListModel> lists, List<int> inLists})> checkBook(
      int bookId) async {
    final res = await _client.get('/me/reading-lists/check/$bookId');
    final lists = (res.data['data'] as List<dynamic>)
        .map((e) => ReadingListModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final inLists = (res.data['in_lists'] as List<dynamic>)
        .map((e) => e as int)
        .toList();
    return (lists: lists, inLists: inLists);
  }
}
