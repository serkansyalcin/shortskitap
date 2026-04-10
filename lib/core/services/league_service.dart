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

  Future<LeaderboardPageModel> getLeaderboard({
    int limit = 10,
    int offset = 0,
  }) async {
    final response = await _api.get(
      '/league/leaderboard',
      params: {'limit': limit, 'offset': offset},
    );
    final data = response.data['data'] as Map<String, dynamic>;
    return LeaderboardPageModel.fromJson(data);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final response = await _api.get('/league/history');
    return List<Map<String, dynamic>>.from(
      response.data['data'] as List<dynamic>,
    );
  }
}
