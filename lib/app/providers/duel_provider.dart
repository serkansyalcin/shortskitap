import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitaplig/app/providers/auth_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/models/duel_model.dart';
import '../../core/services/duel_service.dart';
import 'league_provider.dart';
import 'notification_provider.dart';

final duelServiceProvider = Provider<DuelService>((ref) {
  return DuelService(ApiClient.instance);
});

final myDuelsProvider = FutureProvider<List<DuelModel>>((ref) {
  final userId = ref.watch(authProvider.select((state) => state.user?.id));
  if (userId == null) {
    return const [];
  }
  return ref.read(duelServiceProvider).getMyDuels();
});

final duelDetailsProvider = FutureProvider.autoDispose.family<DuelModel, int>((
  ref,
  duelId,
) {
  ref.watch(authProvider.select((state) => state.user?.id));
  return ref.read(duelServiceProvider).getDuelDetails(duelId);
});

final duelStateProvider =
    StateNotifierProvider.autoDispose<
      DuelNotifier,
      AsyncValue<List<DuelModel>>
    >((ref) {
      final userId = ref.watch(authProvider.select((state) => state.user?.id));
      return DuelNotifier(ref, ref.read(duelServiceProvider), userId);
    });

class DuelNotifier extends StateNotifier<AsyncValue<List<DuelModel>>> {
  final Ref _ref;
  final DuelService _service;
  final int? _userId;

  DuelNotifier(this._ref, this._service, this._userId)
    : super(
        _userId == null
            ? const AsyncValue.data(<DuelModel>[])
            : const AsyncValue.loading(),
      ) {
    if (_userId != null) {
      loadDuels();
    }
  }

  Future<void> loadDuels() async {
    if (_userId == null) {
      state = const AsyncValue.data(<DuelModel>[]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final duels = await _service.getMyDuels();
      state = AsyncValue.data(duels);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  DuelModel? findOpenDuelWithUser(int otherUserId) {
    final currentUserId = _userId;
    if (currentUserId == null) {
      return null;
    }

    for (final duel in state.valueOrNull ?? const <DuelModel>[]) {
      if (duel.isOpen &&
          duel.involvesUser(currentUserId) &&
          duel.otherUserIdFor(currentUserId) == otherUserId) {
        return duel;
      }
    }

    return null;
  }

  Future<DuelActionResult> challenge(int userId) async {
    final result = await _service.challenge(userId);
    await _syncAfterMutation();
    return result;
  }

  Future<DuelActionResult> accept(int duelId) async {
    final result = await _service.accept(duelId);
    await _syncAfterMutation(extraInvalidations: [duelDetailsProvider(duelId)]);
    return result;
  }

  Future<DuelActionResult> decline(int duelId) async {
    final result = await _service.decline(duelId);
    await _syncAfterMutation(extraInvalidations: [duelDetailsProvider(duelId)]);
    return result;
  }

  Future<void> _syncAfterMutation({
    List<ProviderOrFamily>? extraInvalidations,
  }) async {
    await loadDuels();
    _ref.invalidate(myDuelsProvider);
    _ref.invalidate(myLeagueProvider);
    _ref.invalidate(leaderboardProvider);
    refreshNotificationProviders(_ref);

    if (extraInvalidations != null) {
      for (final provider in extraInvalidations) {
        _ref.invalidate(provider);
      }
    }
  }
}
