Future<String?> cacheAudioFile({
  required int bookId,
  required int paragraphId,
  required String audioUrl,
  String? currentLocalPath,
}) async {
  return currentLocalPath;
}

Future<void> deleteBookAudioCache(int bookId) async {}

Future<bool> localAudioFileExists(String path) async => false;

Future<String?> cacheIllustrationFile({
  required int bookId,
  required int paragraphId,
  required String imageUrl,
  String? currentLocalPath,
}) async {
  return currentLocalPath;
}

Future<void> deleteBookIllustrationCache(int bookId) async {}

Future<bool> localIllustrationFileExists(String path) async => false;
