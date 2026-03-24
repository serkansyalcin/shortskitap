import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitaplig/app/providers/auth_provider.dart';
import '../../core/api/api_client.dart';
import '../../core/models/league_model.dart';
import '../../core/services/league_service.dart';

final leagueServiceProvider = Provider<LeagueService>((ref) {
  return LeagueService(ApiClient.instance);
});

final myLeagueProvider = FutureProvider<LeagueStatusModel>((ref) {
  ref.watch(authProvider.select((state) => state.user?.id));
  return ref.read(leagueServiceProvider).getMyLeague();
});

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  ref.watch(authProvider.select((state) => state.user?.id));
  return ref.read(leagueServiceProvider).getLeaderboard();
});

final leagueHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  ref.watch(authProvider.select((state) => state.user?.id));
  return ref.read(leagueServiceProvider).getHistory();
});
