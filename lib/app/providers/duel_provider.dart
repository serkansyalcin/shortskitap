import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/duel_model.dart';
import '../../core/services/duel_service.dart';

final duelServiceProvider = Provider<DuelService>((ref) {
  return DuelService(ApiClient.instance);
});

final myDuelsProvider = FutureProvider<List<DuelModel>>((ref) {
  return ref.read(duelServiceProvider).getMyDuels();
});

final duelDetailsProvider = FutureProvider.family<DuelModel, int>((ref, duelId) {
  return ref.read(duelServiceProvider).getDuelDetails(duelId);
});

final duelStateProvider = StateNotifierProvider<DuelNotifier, AsyncValue<List<DuelModel>>>((ref) {
  return DuelNotifier(ref.read(duelServiceProvider));
});

class DuelNotifier extends StateNotifier<AsyncValue<List<DuelModel>>> {
  final DuelService _service;
  DuelNotifier(this._service) : super(const AsyncValue.loading()) {
    loadDuels();
  }

  Future<void> loadDuels() async {
    state = const AsyncValue.loading();
    try {
      final duels = await _service.getMyDuels();
      state = AsyncValue.data(duels);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> challenge(int userId) async {
    try {
      await _service.challenge(userId);
      await loadDuels();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> accept(int duelId) async {
    try {
      final success = await _service.accept(duelId);
      if (success) await loadDuels();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> decline(int duelId) async {
    try {
      final success = await _service.decline(duelId);
      if (success) await loadDuels();
    } catch (e) {
      // Handle error
    }
  }
}
