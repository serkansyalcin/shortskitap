import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/models/achievement_model.dart';

final earnedAchievementsProvider =
    FutureProvider<List<AchievementModel>>((ref) async {
  final res = await ApiClient.instance.get('/achievements');
  final data = res.data['data'] as List<dynamic>;
  return data
      .map((e) => AchievementModel.fromJson(e as Map<String, dynamic>))
      .toList();
});
