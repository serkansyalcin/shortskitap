import '../api/api_client.dart';

class InteractionService {
  static final InteractionService _instance = InteractionService._();
  factory InteractionService() => _instance;
  InteractionService._();

  final ApiClient _apiClient = ApiClient.instance;

  Future<Map<String, dynamic>> submitAnswer({
    required int elementId,
    required dynamic answer,
    Map<String, dynamic>? payload,
  }) async {
    final data = <String, dynamic>{'answer': answer};

    if (payload != null) {
      data['payload'] = payload;
    }

    final response = await _apiClient.post(
      '/interactions/$elementId/submit',
      data: data,
    );

    return response.data as Map<String, dynamic>;
  }
}
