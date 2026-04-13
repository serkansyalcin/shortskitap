import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitaplig/app/providers/auth_provider.dart';

import '../../core/api/api_client.dart';
import '../../core/models/league_model.dart';
import '../../core/services/league_service.dart';

final leagueServiceProvider = Provider<LeagueService>((ref) {
  return LeagueService(ApiClient.instance);
});

final myLeagueProvider = FutureProvider<LeagueStatusModel>((ref) {
  final userId = ref.watch(authProvider.select((state) => state.user?.id));
  final activeProfileId = ref.watch(
    authProvider.select((state) => state.activeProfile?.id),
  );
  if (userId == null) {
    throw StateError('Lig verileri için giriş yapmalısın.');
  }
  if (activeProfileId == null) {
    throw StateError('Aktif okuyucu profili bulunamadı.');
  }
  return ref.read(leagueServiceProvider).getMyLeague();
});

class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;

  const LeaderboardState({
    this.entries = const <LeaderboardEntry>[],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntry>? entries,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    Object? error = _leaderboardNoChange,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: identical(error, _leaderboardNoChange) ? this.error : error,
    );
  }
}

const Object _leaderboardNoChange = Object();

class LeaderboardController extends StateNotifier<LeaderboardState> {
  LeaderboardController(this._ref)
    : super(const LeaderboardState(isLoading: true)) {
    loadInitial();
  }

  static const int _pageSize = 10;

  final Ref _ref;

  Future<void> loadInitial() async {
    final userId = _ref.read(authProvider.select((state) => state.user?.id));
    final activeProfileId = _ref.read(
      authProvider.select((state) => state.activeProfile?.id),
    );
    if (userId == null || activeProfileId == null) {
      state = const LeaderboardState();
      return;
    }

    state = state.copyWith(
      entries: const <LeaderboardEntry>[],
      isLoading: true,
      isLoadingMore: false,
      hasMore: false,
      error: null,
    );

    try {
      final page = await _ref
          .read(leagueServiceProvider)
          .getLeaderboard(limit: _pageSize, offset: 0);
      state = LeaderboardState(
        entries: page.entries,
        isLoading: false,
        isLoadingMore: false,
        hasMore: page.hasMore,
      );
    } catch (error) {
      state = LeaderboardState(
        isLoading: false,
        isLoadingMore: false,
        hasMore: false,
        error: error,
      );
    }
  }

  Future<void> refresh() => loadInitial();

  Future<void> loadMore() async {
    final userId = _ref.read(authProvider.select((state) => state.user?.id));
    final activeProfileId = _ref.read(
      authProvider.select((state) => state.activeProfile?.id),
    );
    if (userId == null ||
        activeProfileId == null ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final page = await _ref
          .read(leagueServiceProvider)
          .getLeaderboard(limit: _pageSize, offset: state.entries.length);

      state = state.copyWith(
        entries: [...state.entries, ...page.entries],
        isLoadingMore: false,
        hasMore: page.hasMore,
      );
    } catch (error) {
      state = state.copyWith(isLoadingMore: false, error: error);
    }
  }
}

final leaderboardProvider =
    StateNotifierProvider<LeaderboardController, LeaderboardState>((ref) {
      ref.watch(authProvider.select((state) => state.user?.id));
      ref.watch(authProvider.select((state) => state.activeProfile?.id));
      return LeaderboardController(ref);
    });

final leagueHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final userId = ref.watch(authProvider.select((state) => state.user?.id));
  final activeProfileId = ref.watch(
    authProvider.select((state) => state.activeProfile?.id),
  );
  if (userId == null || activeProfileId == null) {
    return const <Map<String, dynamic>>[];
  }
  return ref.read(leagueServiceProvider).getHistory();
});
