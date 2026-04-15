import '../../../core/api/api_client.dart';
import '../../../core/models/book_model.dart';
import '../models/ai_story_generation_model.dart';
import '../models/ai_story_studio_config_model.dart';

class AiStoryService {
  final ApiClient _client = ApiClient.instance;

  Future<AiStoryStudioConfigModel> getStudioConfig() async {
    final response = await _client.get('/ai/story-studio/config');
    return AiStoryStudioConfigModel.fromJson(
      response.data['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<AiStoryGenerationModel> generateStory({
    required String type,
    required String title,
    required String theme,
    required String visibility,
    String? parentPin,
  }) async {
    final response = await _client.post(
      '/ai/stories/generate',
      data: {
        'type': type,
        'title': title,
        'theme': theme,
        'visibility': visibility,
        if (parentPin != null && parentPin.trim().isNotEmpty)
          'parent_pin': parentPin.trim(),
      },
    );

    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    return AiStoryGenerationModel.fromJson(
      data['generation'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<AiStoryGenerationModel> getGenerationStatus(int generationId) async {
    final response = await _client.get('/ai/stories/generations/$generationId');
    return AiStoryGenerationModel.fromJson(
      response.data['data'] as Map<String, dynamic>? ?? {},
    );
  }

  Future<List<BookModel>> getMyStories({String? visibility}) async {
    final response = await _client.get(
      '/me/ai-stories',
      params: visibility == null ? null : {'visibility': visibility},
    );
    final data = response.data['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => BookModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<BookModel>> getDiscoverStories({required bool isKids}) async {
    final response = await _client.get(
      '/discover/ai-stories',
      params: {'is_kids': isKids ? 1 : 0, 'limit': 12},
    );
    final data = response.data['data'] as List<dynamic>? ?? const [];
    return data
        .map((item) => BookModel.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<BookModel> updateVisibility({
    required int bookId,
    required String visibility,
    String? parentPin,
  }) async {
    final response = await _client.patch(
      '/me/ai-stories/$bookId/visibility',
      data: {
        'visibility': visibility,
        if (parentPin != null && parentPin.trim().isNotEmpty)
          'parent_pin': parentPin.trim(),
      },
    );

    final data =
        response.data['data'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    return BookModel.fromJson(data['book'] as Map<String, dynamic>? ?? {});
  }
}
