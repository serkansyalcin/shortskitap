import '../api/api_client.dart';
import '../models/podcast_model.dart';

class PodcastService {
  final ApiClient _client = ApiClient.instance;

  Future<List<PodcastModel>> getPodcasts(int bookId) async {
    final res = await _client.get('/books/$bookId/podcasts');
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => PodcastModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
