import 'package:kitaplig/core/api/api_client.dart';
import 'package:kitaplig/core/models/duel_model.dart';

class DuelService {
  final ApiClient _api;
  DuelService(this._api);

  Future<List<DuelModel>> getMyDuels() async {
    final response = await _api.get('/duels/me');
    final data = response.data['data'] as List<dynamic>;
    return data.map((e) => DuelModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DuelModel> challenge(int userId) async {
    final response = await _api.post('/duels/challenge/$userId');
    return DuelModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<bool> accept(int duelId) async {
    final response = await _api.post('/duels/$duelId/accept');
    return response.data['success'] as bool;
  }

  Future<bool> decline(int duelId) async {
    final response = await _api.post('/duels/$duelId/decline');
    return response.data['success'] as bool;
  }

  Future<DuelModel> getDuelDetails(int duelId) async {
    final response = await _api.get('/duels/$duelId');
    return DuelModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
