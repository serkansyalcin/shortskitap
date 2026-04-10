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
