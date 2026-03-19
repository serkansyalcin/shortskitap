import '../api/api_client.dart';
import '../models/character_model.dart';

class CharacterService {
  final ApiClient _client = ApiClient.instance;

  Future<List<CharacterModel>> getCharacters(int bookId) async {
    final res = await _client.get('/books/$bookId/characters');
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => CharacterModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
