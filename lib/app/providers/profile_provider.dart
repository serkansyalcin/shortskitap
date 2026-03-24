import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/public_profile_model.dart';
import '../../core/models/user_search_result_model.dart';
import '../../core/services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService(ApiClient.instance);
});

final publicProfileProvider =
    FutureProvider.autoDispose.family<PublicProfileModel, String>((
      ref,
      username,
    ) {
      return ref.read(profileServiceProvider).getProfile(username);
    });

final userSearchProvider =
    FutureProvider.autoDispose.family<List<UserSearchResultModel>, String>((
      ref,
      query,
    ) {
      final normalized = query.trim();
      if (normalized.length < 2) {
        return Future.value(const <UserSearchResultModel>[]);
      }

      return ref.read(profileServiceProvider).searchUsers(normalized);
    });
