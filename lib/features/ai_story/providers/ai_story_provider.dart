import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/kids_provider.dart';
import '../../../core/models/book_model.dart';
import '../models/ai_story_studio_config_model.dart';
import '../services/ai_story_service.dart';

final aiStoryServiceProvider = Provider<AiStoryService>((ref) {
  return AiStoryService();
});

final aiStoryStudioConfigProvider =
    FutureProvider<AiStoryStudioConfigModel>((ref) async {
      final auth = ref.watch(authProvider);
      final activeProfileId = ref.watch(
        authProvider.select((state) => state.activeProfile?.id),
      );
      if (!auth.isAuthenticated || activeProfileId == null) {
        throw StateError('AI hikâye stüdyosu için oturum gerekli.');
      }

      return ref.read(aiStoryServiceProvider).getStudioConfig();
    });

final discoverAiStoriesProvider = FutureProvider<List<BookModel>>((ref) async {
  final isKids = ref.watch(kidsModeProvider);
  return ref.read(aiStoryServiceProvider).getDiscoverStories(isKids: isKids);
});

final myAiStoriesProvider = FutureProvider.family<List<BookModel>, String?>((
  ref,
  visibility,
) async {
  final auth = ref.watch(authProvider);
  final activeProfileId = ref.watch(
    authProvider.select((state) => state.activeProfile?.id),
  );
  if (!auth.isAuthenticated || activeProfileId == null) {
    return const <BookModel>[];
  }

  return ref.read(aiStoryServiceProvider).getMyStories(visibility: visibility);
});
