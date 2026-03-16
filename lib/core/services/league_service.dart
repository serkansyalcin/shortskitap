import 'package:kitaplig/core/api/api_client.dart';
import 'package:kitaplig/core/models/league_model.dart';

class LeagueService {
  final ApiClient _api;
  LeagueService(this._api);

  Future<LeagueStatusModel> getMyLeague() async {
    final response = await _api.get('/league/me');
    return LeagueStatusModel.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final response = await _api.get('/league/leaderboard');
    final data = response.data['data'] as Map<String, dynamic>;
    final entries = data['entries'] as List<dynamic>;
    return entries
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final response = await _api.get('/league/history');
    return List<Map<String, dynamic>>.from(
      response.data['data'] as List<dynamic>,
    );
  }
}
