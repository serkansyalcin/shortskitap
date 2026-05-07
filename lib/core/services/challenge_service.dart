import '../api/api_client.dart';
import '../models/challenge_model.dart';

class ChallengeService {
  final ApiClient _client = ApiClient.instance;

  Future<List<ChallengeModel>> getChallenges() async {
    final res = await _client.get('/challenges');
    final data = res.data['data'] as List<dynamic>;
    return data
        .map((e) => ChallengeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> claimReward(int challengeId) =>
      _client.post('/challenges/$challengeId/claim');
}
