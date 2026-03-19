import '../api/api_client.dart';
import '../models/series_model.dart';

class SeriesService {
  final ApiClient _client = ApiClient.instance;

  Future<List<SeriesModel>> getSeries() async {
    final res = await _client.get('/series');
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => SeriesModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SeriesModel> getSeriesDetail(int seriesId) async {
    final res = await _client.get('/series/$seriesId');
    return SeriesModel.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}
