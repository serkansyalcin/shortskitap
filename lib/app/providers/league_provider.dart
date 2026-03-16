import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/league_model.dart';
import '../../core/services/league_service.dart';

final leagueServiceProvider = Provider<LeagueService>((ref) {
  return LeagueService(ApiClient.instance);
});

final myLeagueProvider = FutureProvider<LeagueStatusModel>((ref) {
  return ref.read(leagueServiceProvider).getMyLeague();
});

final leaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  return ref.read(leagueServiceProvider).getLeaderboard();
});

final leagueHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.read(leagueServiceProvider).getHistory();
});
