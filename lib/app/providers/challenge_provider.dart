import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/challenge_model.dart';
import '../../core/services/challenge_service.dart';
import 'auth_provider.dart';

final challengeServiceProvider = Provider<ChallengeService>((_) => ChallengeService());

final challengesProvider =
    AsyncNotifierProvider<ChallengesNotifier, List<ChallengeModel>>(
  ChallengesNotifier.new,
);

class ChallengesNotifier extends AsyncNotifier<List<ChallengeModel>> {
  ChallengeService get _svc => ref.read(challengeServiceProvider);

  @override
  Future<List<ChallengeModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) return [];
    try {
      return await _svc.getChallenges();
    } catch (_) {
      return [];
    }
  }

  Future<void> claim(int challengeId) async {
    await _svc.claimReward(challengeId);
    state = AsyncData(
      (state.valueOrNull ?? [])
          .map((c) => c.id == challengeId ? c.copyWith(isClaimed: true) : c)
          .toList(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_svc.getChallenges);
  }
}
