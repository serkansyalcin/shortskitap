import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/friend_activity_model.dart';
import 'auth_provider.dart';

final friendActivityProvider =
    FutureProvider.autoDispose<List<FriendActivityModel>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return [];

  final res = await ApiClient.instance.get('/me/friends-activity');
  final data = res.data['data'] as List<dynamic>;
  return data
      .map((e) => FriendActivityModel.fromJson(e as Map<String, dynamic>))
      .toList();
});
