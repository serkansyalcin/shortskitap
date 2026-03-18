import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers/auth_provider.dart';
import '../../core/models/progress_model.dart';
import '../../core/services/progress_service.dart' as svc;

final progressServiceProvider =
    Provider<svc.ProgressService>((ref) => svc.ProgressService());

final allProgressProvider = FutureProvider<List<ProgressModel>>((ref) {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) {
    return Future.value(const <ProgressModel>[]);
  }
  return ref.read(progressServiceProvider).getProgress();
});

final bookProgressProvider =
    FutureProvider.family<ProgressModel?, int>((ref, bookId) {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) {
    return Future.value(null);
  }
  return ref.read(progressServiceProvider).getBookProgress(bookId);
});

class ProgressSyncState {
  final bool isSyncing;
  final Map<String, dynamic>? lastResult;

  const ProgressSyncState({this.isSyncing = false, this.lastResult});
}

class ProgressSyncNotifier extends StateNotifier<ProgressSyncState> {
  final svc.ProgressService _service;

  ProgressSyncNotifier(this._service) : super(const ProgressSyncState());

  Future<void> sync(int bookId, int paragraphOrder, int sessionSeconds) async {
    if (state.isSyncing) return;
    state = const ProgressSyncState(isSyncing: true);
    try {
      final result =
          await _service.syncProgress(bookId, paragraphOrder, sessionSeconds);
      state = ProgressSyncState(isSyncing: false, lastResult: result);
    } catch (_) {
      state = const ProgressSyncState(isSyncing: false);
    }
  }
}

final progressSyncProvider =
    StateNotifierProvider<ProgressSyncNotifier, ProgressSyncState>((ref) {
  return ProgressSyncNotifier(ref.read(progressServiceProvider));
});
