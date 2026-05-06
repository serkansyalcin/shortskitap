import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/community_models.dart';

class CommunityService {
  CommunityService(this._client);

  final ApiClient _client;

  Future<CommunityPageModel<CommunityPostModel>> fetchFeed({
    int page = 1,
    int perPage = 15,
    String? filter,
  }) {
    return _fetchPostPage(
      '/community/feed',
      page: page,
      perPage: perPage,
      params: {'filter': ?filter},
    );
  }

  Future<CommunityPageModel<CommunityPostModel>> fetchMyPosts({
    int page = 1,
    int perPage = 15,
  }) {
    return _fetchPostPage('/community/me/posts', page: page, perPage: perPage);
  }

  Future<CommunityPageModel<CommunityPostModel>> fetchProfilePosts(
    String username, {
    int page = 1,
    int perPage = 15,
  }) {
    return _fetchPostPage(
      '/profiles/${Uri.encodeComponent(username)}/posts',
      page: page,
      perPage: perPage,
    );
  }

  Future<CommunityPostModel> fetchPost(int postId) async {
    final response = await _client.get('/community/posts/$postId');
    return CommunityPostModel.fromJson(
      response.data['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<CommunityPostModel> createPost(CommunityComposePayload payload) async {
    final formData = FormData();

    void addString(String key, String? value) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        formData.fields.add(MapEntry(key, normalized));
      }
    }

    addString('body', payload.body);
    addString('quote_text', payload.quoteText);
    addString('quote_source', payload.quoteSource);
    formData.fields.add(MapEntry('visibility', payload.visibility));
    if (payload.bookId != null) {
      formData.fields.add(MapEntry('book_id', '${payload.bookId}'));
    }
    if (payload.paragraphId != null) {
      formData.fields.add(MapEntry('paragraph_id', '${payload.paragraphId}'));
    }
    for (final image in payload.images.take(4)) {
      formData.files.add(
        MapEntry(
          'images[]',
          MultipartFile.fromBytes(image.bytes, filename: image.fileName),
        ),
      );
    }

    final response = await _client.post('/community/posts', data: formData);
    return CommunityPostModel.fromJson(
      response.data['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<void> like(int postId) =>
      _client.post('/community/posts/$postId/like');

  Future<void> unlike(int postId) =>
      _client.delete('/community/posts/$postId/like');

  Future<void> save(int postId) =>
      _client.post('/community/posts/$postId/save');

  Future<void> unsave(int postId) =>
      _client.delete('/community/posts/$postId/save');

  Future<void> deletePost(int postId) =>
      _client.delete('/community/posts/$postId');

  Future<void> reportPost(
    int postId, {
    required String reason,
    String? details,
  }) {
    return _client.post(
      '/community/posts/$postId/report',
      data: {
        'reason': reason,
        if (details?.trim().isNotEmpty == true) 'details': details!.trim(),
      },
    );
  }

  Future<CommunityPageModel<CommunityCommentModel>> fetchComments(
    int postId, {
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _client.get(
      '/community/posts/$postId/comments',
      params: {'page': page, 'per_page': perPage},
    );
    final data = response.data['data'] as List<dynamic>? ?? const [];
    final meta = response.data['meta'] as Map<String, dynamic>? ?? const {};
    return CommunityPageModel(
      items: data
          .whereType<Map<String, dynamic>>()
          .map(CommunityCommentModel.fromJson)
          .toList(growable: false),
      meta: CommunityPageMeta.fromJson(meta),
    );
  }

  Future<CommunityCommentModel> createComment(int postId, String body) async {
    final response = await _client.post(
      '/community/posts/$postId/comments',
      data: {'body': body.trim()},
    );
    return CommunityCommentModel.fromJson(
      response.data['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<void> deleteComment(int commentId) =>
      _client.delete('/community/comments/$commentId');

  Future<void> reportComment(
    int commentId, {
    required String reason,
    String? details,
  }) {
    return _client.post(
      '/community/comments/$commentId/report',
      data: {
        'reason': reason,
        if (details?.trim().isNotEmpty == true) 'details': details!.trim(),
      },
    );
  }

  Future<CommunityPageModel<CommunityPostModel>> _fetchPostPage(
    String path, {
    required int page,
    required int perPage,
    Map<String, dynamic>? params,
  }) async {
    final response = await _client.get(
      path,
      params: {
        'page': page,
        'per_page': perPage,
        if (params != null) ...params,
      },
    );
    final data = response.data['data'] as List<dynamic>? ?? const [];
    final meta = response.data['meta'] as Map<String, dynamic>? ?? const {};
    return CommunityPageModel(
      items: data
          .whereType<Map<String, dynamic>>()
          .map(CommunityPostModel.fromJson)
          .toList(growable: false),
      meta: CommunityPageMeta.fromJson(meta),
    );
  }
}
