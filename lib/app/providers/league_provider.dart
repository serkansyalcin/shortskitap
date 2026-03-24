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
  if (userId == null) {
    throw StateError('Lig verileri için giriş yapmalısın.');
  }
  return ref.read(leagueServiceProvider).getMyLeague();
});

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  final userId = ref.watch(authProvider.select((state) => state.user?.id));
  if (userId == null) {
    return const <LeaderboardEntry>[];
  }
  return ref.read(leagueServiceProvider).getLeaderboard();
});

final leagueHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final userId = ref.watch(authProvider.select((state) => state.user?.id));
  if (userId == null) {
    return const <Map<String, dynamic>>[];
  }
  return ref.read(leagueServiceProvider).getHistory();
});
