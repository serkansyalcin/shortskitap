import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/achievement_model.dart';
import '../../core/services/achievement_service.dart';
import 'auth_provider.dart';

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService();
});

final earnedAchievementsProvider = FutureProvider<List<AchievementModel>>((
  ref,
) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) {
    return const <AchievementModel>[];
  }

  return ref.read(achievementServiceProvider).getAchievements();
});
