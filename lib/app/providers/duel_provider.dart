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
  final activeProfileId = ref.watch(
    authProvider.select((state) => state.activeProfile?.id),
  );
  if (userId == null || activeProfileId == null) {
    return const [];
  }
  return ref.read(duelServiceProvider).getMyDuels();
});

final duelDetailsProvider = FutureProvider.autoDispose.family<DuelModel, int>((
  ref,
  duelId,
) {
  final activeProfileId = ref.watch(
    authProvider.select((state) => state.activeProfile?.id),
  );
  ref.watch(authProvider.select((state) => state.user?.id));
  if (activeProfileId == null) {
    throw StateError('Aktif okuyucu profili bulunamadı.');
  }
  return ref.read(duelServiceProvider).getDuelDetails(duelId);
});

final duelStateProvider =
    StateNotifierProvider.autoDispose<
      DuelNotifier,
      AsyncValue<List<DuelModel>>
    >((ref) {
      final userId = ref.watch(authProvider.select((state) => state.user?.id));
      final activeProfileId = ref.watch(
        authProvider.select((state) => state.activeProfile?.id),
      );
      return DuelNotifier(
        ref,
        ref.read(duelServiceProvider),
        userId,
        activeProfileId: activeProfileId,
      );
    });

class DuelNotifier extends StateNotifier<AsyncValue<List<DuelModel>>> {
  final Ref _ref;
  final DuelService _service;
  final int? _userId;
  final int? _activeProfileId;
  bool _disposed = false;

  DuelNotifier(
    this._ref,
    this._service,
    this._userId, {
    required int? activeProfileId,
  }) : _activeProfileId = activeProfileId,
       super(
         _userId == null || activeProfileId == null
             ? const AsyncValue.data(<DuelModel>[])
             : const AsyncValue.loading(),
       ) {
    if (_userId != null && _activeProfileId != null) {
      loadDuels();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _setStateSafe(AsyncValue<List<DuelModel>> value) {
    if (_disposed) return;
    state = value;
  }

  Future<void> loadDuels() async {
    if (_userId == null || _activeProfileId == null) {
      _setStateSafe(const AsyncValue.data(<DuelModel>[]));
      return;
    }

    _setStateSafe(const AsyncValue.loading());
    try {
      final duels = await _service.getMyDuels();
      _setStateSafe(AsyncValue.data(duels));
    } catch (e, st) {
      _setStateSafe(AsyncValue.error(e, st));
    }
  }

  DuelModel? findOpenDuelWithUser(
    int otherUserId, {
    int? otherReaderProfileId,
  }) {
    final currentUserId = _userId;
    final activeProfileId = _activeProfileId;
    if (currentUserId == null || activeProfileId == null) {
      return null;
    }

    for (final duel in state.valueOrNull ?? const <DuelModel>[]) {
      if (!duel.isOpen) {
        continue;
      }

      if (duel.hasReaderProfileScope &&
          otherReaderProfileId != null &&
          duel.involvesReaderProfile(activeProfileId) &&
          duel.otherReaderProfileIdFor(activeProfileId) ==
              otherReaderProfileId) {
        return duel;
      }

      if (duel.hasReaderProfileScope) {
        continue;
      }

      if (duel.involvesUser(currentUserId) &&
          duel.otherUserIdFor(currentUserId) == otherUserId) {
        return duel;
      }
    }

    return null;
  }

  Future<DuelActionResult> challenge(
    int userId, {
    int? opponentReaderProfileId,
  }) async {
    if (_activeProfileId == null) {
      return const DuelActionResult(
        success: false,
        message: 'Aktif okuyucu profili bulunamadı.',
      );
    }
    final result = await _service.challenge(
      userId,
      opponentReaderProfileId: opponentReaderProfileId,
    );
    await _syncAfterMutation();
    return result;
  }

  Future<DuelActionResult> accept(int duelId) async {
    if (_activeProfileId == null) {
      return const DuelActionResult(
        success: false,
        message: 'Aktif okuyucu profili bulunamadı.',
      );
    }
    final result = await _service.accept(duelId);
    await _syncAfterMutation(extraInvalidations: [duelDetailsProvider(duelId)]);
    return result;
  }

  Future<DuelActionResult> decline(int duelId) async {
    if (_activeProfileId == null) {
      return const DuelActionResult(
        success: false,
        message: 'Aktif okuyucu profili bulunamadı.',
      );
    }
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
