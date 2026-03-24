import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/public_profile_model.dart';
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
