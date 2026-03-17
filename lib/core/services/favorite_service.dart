import '../api/api_client.dart';
import '../models/favorite_model.dart';

class FavoriteService {
  final ApiClient _client = ApiClient.instance;

  Future<List<FavoriteModel>> getFavorites() async {
    final res = await _client.get('/favorites');
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
