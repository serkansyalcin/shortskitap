import '../api/api_client.dart';
import '../models/public_profile_model.dart';
import '../models/user_search_result_model.dart';

class ProfileService {
  final ApiClient _client;

  ProfileService(this._client);

  Future<PublicProfileModel> getProfile(String username) async {
    final response = await _client.get(
      '/profiles/${Uri.encodeComponent(username)}',
    );
    return PublicProfileModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<PublicProfileModel> follow(String username) async {
    final response = await _client.post(
      '/profiles/${Uri.encodeComponent(username)}/follow',
    );
    return PublicProfileModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<PublicProfileModel> unfollow(String username) async {
    final response = await _client.delete(
      '/profiles/${Uri.encodeComponent(username)}/follow',
    );
    return PublicProfileModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<ProfileFollowPageModel> getFollowers(
    String username, {
    int limit = 20,
  }) async {
    final response = await _client.get(
      '/profiles/${Uri.encodeComponent(username)}/followers',
      params: {'limit': limit},
    );
    return ProfileFollowPageModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<ProfileFollowPageModel> getFollowing(
    String username, {
    int limit = 20,
  }) async {
    final response = await _client.get(
      '/profiles/${Uri.encodeComponent(username)}/following',
      params: {'limit': limit},
    );
    return ProfileFollowPageModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<UserSearchResultModel>> searchUsers(
    String query, {
    int limit = 6,
  }) async {
    final response = await _client.get(
      '/search/users',
      params: {'q': query, 'limit': limit},
    );

    final data = response.data['data'] as List<dynamic>? ?? const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(UserSearchResultModel.fromJson)
        .toList(growable: false);
  }
}
